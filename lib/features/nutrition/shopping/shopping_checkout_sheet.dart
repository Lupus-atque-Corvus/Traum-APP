import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';
import '../../budget/receipt_scanner.dart';

/// Writes real prices back to the grocery DB and books the cart total as a
/// single expense transaction. Returns the booked total. Pure DB logic — no UI —
/// so it can be unit-tested.
Future<double> finalizeShopping(
  TraumDatabase db, {
  required int? categoryId,
  required String description,
  required DateTime date,
  required String? receiptImagePath,
}) async {
  // Read items BEFORE opening the transaction (avoids running a stream query
  // inside a transaction).
  final items = await db.nutritionDao.watchAllShoppingItems().first;
  final cart =
      items.where((i) => i.checked && i.priceActual != null).toList();
  final total = cart.fold(0.0, (s, i) => s + (i.priceActual ?? 0));
  if (cart.isEmpty) return 0.0; // nothing to book → no ghost €0.00 expense

  // Atomic: either all price write-backs AND the expense row commit, or none.
  // (upsertActualGroceryPrice opens its own transaction; nested → savepoint.)
  await db.transaction(() async {
    for (final i in cart) {
      await db.nutritionDao.upsertActualGroceryPrice(
        name: i.name,
        category: i.category,
        unit: i.unit,
        actual: i.priceActual!,
      );
    }
    await db.budgetDao.insertTransaction(TransactionsCompanion.insert(
      amount: total,
      description: description.isEmpty ? 'Lebensmittel' : description,
      type: const Value('expense'),
      date: date,
      categoryId: Value(categoryId),
      receiptImagePath: Value(receiptImagePath),
    ));
  });

  return total;
}

class ShoppingCheckoutSheet extends ConsumerStatefulWidget {
  const ShoppingCheckoutSheet({super.key});

  @override
  ConsumerState<ShoppingCheckoutSheet> createState() =>
      _ShoppingCheckoutSheetState();
}

class _ShoppingCheckoutSheetState extends ConsumerState<ShoppingCheckoutSheet> {
  int? _categoryId;
  String _merchant = '';
  String? _receiptPath;
  bool _scanning = false;
  bool _saving = false;
  DateTime _date = DateTime.now();

  double _cartTotal(List<ShoppingListItem> items) => items
      .where((i) => i.checked && i.priceActual != null)
      .fold(0.0, (s, i) => s + (i.priceActual ?? 0));

  double _estTotal(List<ShoppingListItem> items) => items
      .where((i) => i.checked)
      .fold(0.0, (s, i) => s + (i.priceEstimated ?? 0));

  Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      final res = await ReceiptScanner.scanFromCamera();
      if (res != null) {
        if (!mounted) return;
        setState(() {
          _receiptPath = res.imagePath;
          if (res.detectedMerchant != null) _merchant = res.detectedMerchant!;
          if (res.detectedDate != null) _date = res.detectedDate!;
        });
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _book(List<ShoppingListItem> items) async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      await finalizeShopping(
        db,
        categoryId: _categoryId,
        description: _merchant,
        date: _date,
        receiptImagePath: _receiptPath,
      );
      if (!mounted) return;
      Navigator.of(context).pop(); // close checkout
      Navigator.of(context).pop(); // leave shopping mode
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Als Ausgabe in Finanzen gebucht ✓')));
    } catch (e, st) {
      debugPrint('finalizeShopping failed: $e\n$st');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Buchung fehlgeschlagen')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ref.watch(allShoppingItemsStreamProvider).valueOrNull ?? [];
    final cats =
        ref.watch(allBudgetCategoriesStreamProvider).valueOrNull ?? [];
    final expenseCats = cats.where((c) => c.isExpense).toList();

    // Auto-select a "Lebensmittel" category on first build, fall back to first
    if (_categoryId == null && expenseCats.isNotEmpty) {
      final lebensmittel = expenseCats
          .where((c) => c.name.toLowerCase().contains('lebensmittel'))
          .toList();
      _categoryId = lebensmittel.isNotEmpty
          ? lebensmittel.first.id
          : expenseCats.first.id;
    }

    final total = _cartTotal(items);
    final est = _estTotal(items);
    final diff = est - total;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(2))),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: TraumColors.gradientNutrition,
                borderRadius: BorderRadius.circular(TraumRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GESAMT BEZAHLT',
                      style: TextStyle(
                          color: Color(0xB30D0D1A),
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                  Text('${total.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: const TextStyle(
                          color: Color(0xFF0D0D1A),
                          fontFamily: 'DMSans',
                          fontSize: 30,
                          fontWeight: FontWeight.w800)),
                  if (diff.abs() >= 0.01)
                    Text(
                        diff > 0
                            ? '${diff.toStringAsFixed(2).replaceAll('.', ',')} € unter Schätzung 🎉'
                            : '${(-diff).toStringAsFixed(2).replaceAll('.', ',')} € über Schätzung',
                        style: const TextStyle(
                            color: Color(0xCC0D0D1A),
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Tile(
              icon: _scanning
                  ? Icons.hourglass_top_rounded
                  : (_receiptPath != null
                      ? Icons.check_circle_rounded
                      : Icons.receipt_long_rounded),
              label: _scanning
                  ? 'Kassenzettel wird analysiert…'
                  : (_receiptPath != null
                      ? 'Kassenzettel angehängt'
                      : 'Kassenzettel scannen'),
              onTap: _scanning ? null : _scan,
            ),
            const SizedBox(height: 8),
            _CategoryPicker(
              categories: expenseCats,
              selectedId: _categoryId,
              onSelected: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: (_saving || total <= 0) ? null : () => _book(items),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: TraumColors.gradientNutrition,
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                ),
                child: Center(
                  child: Text(_saving ? 'Buchen…' : '→ Als Ausgabe buchen',
                      style: const TextStyle(
                          color: Color(0xFF0D0D1A),
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: Row(children: [
          Icon(icon, color: TraumColors.mintGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: TraumColors.onBackgroundMuted),
        ]),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<BudgetCategory> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;
  const _CategoryPicker(
      {required this.categories,
      required this.selectedId,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const _Tile(
          icon: Icons.shopping_basket_rounded,
          label: 'Keine Budget-Kategorie vorhanden');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map((c) {
          final sel = c.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(c.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? TraumColors.mintGreenDim
                    : TraumColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: sel
                    ? Border.all(color: TraumColors.mintGreen)
                    : null,
              ),
              child: Text('${c.emoji ?? '🛒'} ${c.name}',
                  style: TextStyle(
                      color: sel
                          ? TraumColors.mintGreen
                          : TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

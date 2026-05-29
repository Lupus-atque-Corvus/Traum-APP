import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'amount_entry_sheet.dart';
import 'barcode_scanner_screen.dart';
import 'nutrition_providers.dart';

class MealTemplateSheet extends ConsumerStatefulWidget {
  final String mealType;
  final String date;

  const MealTemplateSheet({
    super.key,
    required this.mealType,
    required this.date,
  });

  @override
  ConsumerState<MealTemplateSheet> createState() =>
      _MealTemplateSheetState();
}

class _MealTemplateSheetState
    extends ConsumerState<MealTemplateSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      ref.read(productSearchQueryProvider.notifier).state =
          _searchCtrl.text.trim();
    });
  }

  @override
  void dispose() {
    ref.read(productSearchQueryProvider.notifier).state = '';
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAmount(BuildContext ctx, FoodProduct p) {
    Navigator.pop(ctx); // close template sheet first
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmountEntrySheet(
        product: p,
        mealType: widget.mealType,
        date: widget.date,
      ),
    );
  }

  Future<void> _openScanner(BuildContext ctx) async {
    final product = await Navigator.push<FoodProduct>(
      ctx,
      MaterialPageRoute(
          builder: (_) => const BarcodeScannerScreen()),
    );
    if (product != null && ctx.mounted) {
      _openAmount(ctx, product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productSearchProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: TraumColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TraumColors.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Lebensmittel suchen...',
                  hintStyle: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundSubtle,
                      fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: TraumColors.onBackgroundMuted),
                  filled: true,
                  fillColor: TraumColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _openScanner(context),
              icon: const Icon(Icons.qr_code_scanner,
                  color: TraumColors.mintGreen),
            ),
          ]),
        ),
        Expanded(
          child: productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const Center(
                  child: Text('Keine Produkte gefunden',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackgroundMuted)),
                );
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (_, i) {
                  final p = products[i];
                  return ListTile(
                    title: Text(p.name,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackground,
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(
                        '${p.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackgroundMuted,
                            fontSize: 12)),
                    trailing: const Icon(
                        Icons.add_circle_outline,
                        color: TraumColors.mintGreen),
                    onTap: () => _openAmount(context, p),
                  );
                },
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: TraumColors.mintGreen,
                    strokeWidth: 2)),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ]),
    );
  }
}

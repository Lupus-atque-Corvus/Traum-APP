import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';
import 'shopping_checkout_sheet.dart';

/// In-store mode: tap an item to put it in the cart and type its real price.
/// The hero counts the real total live against the estimate.
class ShoppingModeScreen extends ConsumerWidget {
  const ShoppingModeScreen({super.key});

  double _realTotal(List<ShoppingListItem> items) => items
      .where((i) => i.checked)
      .fold(0.0, (s, i) => s + (i.priceActual ?? 0));

  double _estTotal(List<ShoppingListItem> items) =>
      items.fold(0.0, (s, i) => s + (i.priceEstimated ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allShoppingItemsStreamProvider);
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        title: Text(AppLocalizations.of(context)!.inStore,
            style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
      ),
      body: itemsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: TraumColors.mintGreen)),
        error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.errorWithDetail(e.toString()))),
        data: (items) {
          final inCart = items.where((i) => i.checked).length;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: TraumColors.gradientNutrition,
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.inCartStatus(inCart, items.length),
                        style: const TextStyle(
                            color: Color(0xB30D0D1A),
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        '${_realTotal(items).toStringAsFixed(2).replaceAll('.', ',')} €',
                        style: const TextStyle(
                            color: Color(0xFF0D0D1A),
                            fontFamily: 'DMSans',
                            fontSize: 30,
                            fontWeight: FontWeight.w800)),
                    Text(
                        'Budget (geschätzt): ${_estTotal(items).toStringAsFixed(2).replaceAll('.', ',')} €',
                        style: const TextStyle(
                            color: Color(0xCC0D0D1A),
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: items
                    .map((item) => _CartRow(item: item))
                    .toList(),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GestureDetector(
                  onTap: inCart == 0
                      ? null
                      : () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: TraumColors.background,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24))),
                            builder: (_) => const ShoppingCheckoutSheet(),
                          ),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: inCart == 0
                          ? TraumColors.surfaceVariant
                          : TraumColors.amberGold,
                      borderRadius: BorderRadius.circular(TraumRadius.card),
                    ),
                    child: Center(
                      child: Text('✓  Einkauf abschließen',
                          style: TextStyle(
                              color: inCart == 0
                                  ? TraumColors.onBackgroundMuted
                                  : const Color(0xFF0D0D1A),
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  final ShoppingListItem item;
  const _CartRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(nutritionDaoProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: item.checked
            ? Border.all(color: TraumColors.mintGreen, width: 1.5)
            : null,
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => dao.updateShoppingItem(ShoppingListItemsCompanion(
            id: Value(item.id),
            checked: Value(!item.checked),
          )),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: item.checked
                  ? TraumColors.mintGreen
                  : Colors.transparent,
              border: Border.all(
                  color: item.checked
                      ? TraumColors.mintGreen
                      : TraumColors.onBackgroundSubtle,
                  width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.checked
                ? const Icon(Icons.check, size: 18, color: Color(0xFF0D0D1A))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(item.name,
              style: TextStyle(
                  color: item.checked
                      ? TraumColors.onBackground
                      : TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ),
        SizedBox(
          width: 88,
          child: TextFormField(
            key: Key('price_field_${item.id}'),
            initialValue: item.priceActual
                    ?.toStringAsFixed(2)
                    .replaceAll('.', ',') ??
                '',
            enabled: item.checked,
            textAlign: TextAlign.right,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                color: TraumColors.mintGreen,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              isDense: true,
              suffixText: '€',
              suffixStyle: const TextStyle(
                  color: TraumColors.mintGreen, fontFamily: 'DMSans'),
              hintText: item.priceEstimated
                      ?.toStringAsFixed(2)
                      .replaceAll('.', ',') ??
                  '0,00',
              hintStyle: const TextStyle(
                  color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
              border: InputBorder.none,
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v.replaceAll(',', '.').trim());
              dao.updateShoppingItem(ShoppingListItemsCompanion(
                id: Value(item.id),
                priceActual: Value(parsed),
              ));
            },
          ),
        ),
      ]),
    );
  }
}

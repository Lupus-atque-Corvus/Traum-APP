import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';
import 'add_shopping_item_sheet.dart';
import 'shopping_mode_screen.dart';
import 'shopping_templates_sheet.dart';

/// Layout-A shopping overview: a hero with the estimated total, items grouped
/// by category, urgency dots, and an entry point into shopping mode. Shared by
/// the Einkauf tab and the standalone shopping screen.
class ShoppingListView extends ConsumerWidget {
  /// When true, renders its own scroll padding for a full-screen context.
  final bool standalone;
  const ShoppingListView({super.key, this.standalone = false});

  static double _estimatedTotal(List<ShoppingListItem> items) => items
      .where((i) => !i.checked)
      .fold(0.0, (sum, i) => sum + (i.priceEstimated ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allShoppingItemsStreamProvider);

    return itemsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: TraumColors.mintGreen, strokeWidth: 2)),
      error: (e, _) => Center(
          child: Text(AppLocalizations.of(context)!.errorWithDetail(e.toString()),
              style: const TextStyle(color: TraumColors.roseRed))),
      data: (items) {
        final open = items.where((i) => !i.checked).toList();
        final grouped = <String, List<ShoppingListItem>>{};
        for (final item in open) {
          final cat = item.category ?? 'Sonstiges';
          grouped.putIfAbsent(cat, () => []).add(item);
        }
        for (final list in grouped.values) {
          list.sort((a, b) =>
              (b.isUrgent ? 1 : 0).compareTo(a.isUrgent ? 1 : 0));
        }
        final checked = items.where((i) => i.checked).toList();

        return Stack(children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, standalone ? 96 : 110),
            children: [
              _HeroSummary(
                total: _estimatedTotal(items),
                itemCount: open.length,
                doneCount: checked.length,
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(AppLocalizations.of(context)!.shoppingListEmpty,
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackgroundMuted)),
                  ),
                ),
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                  child: Text(entry.key.toUpperCase(),
                      style: const TextStyle(
                          color: TraumColors.mintGreen,
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ),
                ...entry.value.map((item) => _ItemRow(item: item)),
              ],
              if (checked.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.doneUpper,
                          style: TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                      GestureDetector(
                        onTap: () => ref
                            .read(nutritionDaoProvider)
                            .deleteCheckedShoppingItems(),
                        child: Text(AppLocalizations.of(context)!.deleteCompleted,
                            style: TextStyle(
                                color: TraumColors.roseRed,
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                ...checked.map((item) => _ItemRow(item: item)),
              ],
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(children: [
              _CircleAction(
                icon: Icons.bookmark_border_rounded,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: TraumColors.surfaceElevated,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(TraumRadius.card))),
                  builder: (_) => const ShoppingTemplatesSheet(),
                ),
              ),
              const SizedBox(width: 10),
              _CircleAction(
                icon: Icons.add_rounded,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: TraumColors.surfaceElevated,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(TraumRadius.card))),
                  builder: (_) => const AddShoppingItemSheet(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: items.isEmpty
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ShoppingModeScreen())),
                  child: Opacity(
                    opacity: items.isEmpty ? 0.45 : 1.0,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: TraumColors.gradientNutrition,
                        borderRadius: BorderRadius.circular(TraumRadius.card),
                      ),
                      child: const Center(
                        child: Text('🛒  Einkaufen starten',
                            style: TextStyle(
                                color: Color(0xFF0D0D1A),
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}

class _HeroSummary extends StatelessWidget {
  final double total;
  final int itemCount;
  final int doneCount;
  const _HeroSummary(
      {required this.total,
      required this.itemCount,
      required this.doneCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: TraumColors.gradientNutrition,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.estimatedUpper,
              style: TextStyle(
                  color: Color(0xB30D0D1A),
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text('${total.toStringAsFixed(2).replaceAll('.', ',')} €',
              style: const TextStyle(
                  color: Color(0xFF0D0D1A),
                  fontFamily: 'DMSans',
                  fontSize: 30,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('$itemCount Artikel · $doneCount erledigt',
              style: const TextStyle(
                  color: Color(0xCC0D0D1A),
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  final ShoppingListItem item;
  const _ItemRow({required this.item});

  String? _subtitle() {
    final parts = <String>[];
    if (item.quantity != null) {
      final q = item.quantity!;
      parts.add(
          '${q == q.floorToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(1)}'
          '${item.unit != null ? ' ${item.unit}' : ''}');
    } else if (item.unit != null) {
      parts.add(item.unit!);
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = _subtitle();
    final price = item.priceActual ?? item.priceEstimated;
    return Dismissible(
      key: ValueKey('shop_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => ref.read(nutritionDaoProvider).deleteShoppingItem(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(children: [
            Checkbox(
              value: item.checked,
              activeColor: TraumColors.mintGreen,
              checkColor: Colors.white,
              onChanged: (v) => ref.read(nutritionDaoProvider).updateShoppingItem(
                ShoppingListItemsCompanion(
                  id: Value(item.id),
                  checked: Value(v ?? false),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: TextStyle(
                          color: item.checked
                              ? TraumColors.onBackgroundSubtle
                              : TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                          decoration: item.checked
                              ? TextDecoration.lineThrough
                              : null)),
                  if (sub != null)
                    Text(sub,
                        style: const TextStyle(
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 12)),
                ],
              ),
            ),
            if (item.isUrgent && !item.checked)
              Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                      color: TraumColors.roseRed, shape: BoxShape.circle)),
            if (price != null)
              Text(
                  '${item.priceActual == null ? '~' : ''}${price.toStringAsFixed(2).replaceAll('.', ',')} €',
                  style: TextStyle(
                      color: item.checked
                          ? TraumColors.onBackgroundSubtle
                          : TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: Icon(icon, color: TraumColors.mintGreen),
      ),
    );
  }
}

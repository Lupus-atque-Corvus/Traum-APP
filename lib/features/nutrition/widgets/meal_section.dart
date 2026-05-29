import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart';
import '../barcode_scanner_screen.dart';
import '../amount_entry_sheet.dart';
import '../meal_template_sheet.dart';
import '../nutrition_providers.dart';

class MealSection extends ConsumerWidget {
  final String mealType;
  final String date;
  final List<MealEntry> entries;

  const MealSection({
    super.key,
    required this.mealType,
    required this.date,
    required this.entries,
  });

  String get _label => switch (mealType) {
        'breakfast' => 'FRÜHSTÜCK',
        'lunch' => 'MITTAG',
        'dinner' => 'ABEND',
        'snack' => 'SNACK',
        _ => mealType.toUpperCase(),
      };

  double get _totalCal =>
      entries.fold(0.0, (s, e) => s + e.calories);
  double get _totalProtein =>
      entries.fold(0.0, (s, e) => s + e.protein);
  double get _totalCarbs =>
      entries.fold(0.0, (s, e) => s + e.carbs);
  double get _totalFat =>
      entries.fold(0.0, (s, e) => s + e.fat);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(_label,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: TraumColors.mintGreen,
                      letterSpacing: 0.8)),
              const Spacer(),
              GestureDetector(
                onTap: () => _openSheet(context),
                child: const Icon(Icons.add_circle_outline,
                    color: TraumColors.mintGreen, size: 22),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openScanner(context, ref),
                child: const Icon(Icons.qr_code_scanner,
                    color: TraumColors.onBackgroundMuted,
                    size: 20),
              ),
            ]),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Nichts eingetragen',
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundSubtle,
                        fontSize: 13)),
              )
            else ...[
              const SizedBox(height: 4),
              ...entries.map((e) =>
                  _EntryRow(entry: e, ref: ref)),
              const Divider(
                  color: TraumColors.surfaceVariant,
                  height: 16),
              Text(
                'Gesamt: ${_totalCal.toStringAsFixed(0)} kcal · '
                '${_totalProtein.toStringAsFixed(0)}g P · '
                '${_totalCarbs.toStringAsFixed(0)}g C · '
                '${_totalFat.toStringAsFixed(0)}g F',
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: TraumColors.onBackgroundMuted),
              ),
            ],
          ]),
    );
  }

  void _openSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MealTemplateSheet(
          mealType: mealType, date: date),
    );
  }

  Future<void> _openScanner(
      BuildContext ctx, WidgetRef ref) async {
    final product = await Navigator.push<FoodProduct>(
      ctx,
      MaterialPageRoute(
          builder: (_) => const BarcodeScannerScreen()),
    );
    if (product != null && ctx.mounted) {
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AmountEntrySheet(
            product: product,
            mealType: mealType,
            date: date),
      );
    }
  }
}

class _EntryRow extends StatelessWidget {
  final MealEntry entry;
  final WidgetRef ref;

  const _EntryRow({required this.entry, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline,
            color: TraumColors.roseRed),
      ),
      onDismissed: (_) async {
        await ref
            .read(mealEntriesDaoProvider)
            .deleteEntry(entry.id);
        ref.invalidate(todaysMealsProvider);
        ref.invalidate(todaysMacrosProvider);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID ${entry.productId}',
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackground,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Text(
                    '${entry.amountGrams.toStringAsFixed(0)}g · '
                    '${entry.calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted,
                        fontSize: 11)),
              ],
            ),
          ),
          Text(
              'P:${entry.protein.toStringAsFixed(0)} '
              'C:${entry.carbs.toStringAsFixed(0)} '
              'F:${entry.fat.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackgroundMuted,
                  fontSize: 11)),
        ]),
      ),
    );
  }
}

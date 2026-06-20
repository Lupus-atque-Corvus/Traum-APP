import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/traum_card.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/colors.dart';
import '../budget_helpers.dart';
import '../budget_providers.dart';

class BudgetOverviewCard extends ConsumerWidget {
  const BudgetOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    final ym = (month.year, month.month);
    final catsAsync = ref.watch(budgetCategoriesWithSpendingProvider(ym));
    final currency = ref.watch(currencySymbolProvider);

    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text(
              'Budgetübersicht',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                color: TraumColors.onBackground,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(Routes.budgetStats),
              child: const Text(
                'Mehr ›',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.amberGold,
                  fontSize: 13,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          catsAsync.when(
            data: (cats) => cats.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Keine Budgetkategorien mit Limit konfiguriert.',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    children: cats
                        .map((cat) => _BudgetCategoryRow(cat: cat, currency: currency))
                        .toList(),
                  ),
            loading: () => const SizedBox(
              height: 40,
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: TraumColors.amberGold),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  final BudgetCategoryWithSpending cat;
  final String currency;

  const _BudgetCategoryRow({required this.cat, required this.currency});

  @override
  Widget build(BuildContext context) {
    final barColor = cat.isOverBudget
        ? TraumColors.roseRed
        : cat.ratio > 0.85
            ? TraumColors.coralOrange
            : cat.category.color != null
                ? Color(cat.category.color!)
                : TraumColors.amberGold;
    final percent = (cat.ratio * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: barColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  cat.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cat.name,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w500,
                  color: TraumColors.onBackground,
                  fontSize: 14,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency${fmtAmount(cat.spent)} von $currency${fmtAmount(cat.budgetLimit)}',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted,
                    fontSize: 12,
                  ),
                ),
                Row(children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      color: barColor,
                      fontSize: 12,
                    ),
                  ),
                  if (cat.isOverBudget) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.warning_amber_rounded,
                        color: TraumColors.roseRed, size: 14),
                  ],
                ]),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cat.ratio,
              minHeight: 6,
              backgroundColor: TraumColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

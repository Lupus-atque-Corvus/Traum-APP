import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/traum_card.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/colors.dart';
import '../budget_helpers.dart';
import '../budget_providers.dart';
import 'hidden_amount.dart';

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
    final remaining = cat.budgetLimit - cat.spent;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final pacingRatio = (now.day / daysInMonth).clamp(0.0, 1.0);

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
              child: Row(children: [
                Flexible(
                  child: Text(
                    cat.name,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w500,
                      color: TraumColors.onBackground,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cat.isOverBudget) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: TraumColors.roseRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ÜBER',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: TraumColors.roseRed,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                HiddenAmount(
                  child: Text(
                    '$currency${fmtAmount(cat.spent)} von $currency${fmtAmount(cat.budgetLimit)}',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                HiddenAmount(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        color: barColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.isOverBudget
                          ? '+$currency${fmtAmount(remaining.abs())}'
                          : 'noch $currency${fmtAmount(remaining)}',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: cat.isOverBudget
                            ? TraumColors.roseRed
                            : TraumColors.onBackgroundMuted,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: cat.ratio.clamp(0.0, 1.0),
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Soll-Tempo-Marker
                  Positioned(
                    left: (width * pacingRatio - 1)
                        .clamp(0.0, width - 2),
                    top: -2,
                    bottom: -2,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

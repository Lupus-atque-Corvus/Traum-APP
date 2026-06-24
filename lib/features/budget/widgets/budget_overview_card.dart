import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/colors.dart';
import '../budget_category_icons.dart';
import '../budget_helpers.dart';
import '../budget_providers.dart';
import '../budget_scale.dart';
import 'hidden_amount.dart';

class BudgetOverviewCard extends ConsumerWidget {
  const BudgetOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    final ym = (month.year, month.month);
    final catsAsync = ref.watch(budgetCategoriesWithSpendingProvider(ym));
    final currency = ref.watch(currencySymbolProvider);

    return _BudgetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text(
              'Budgets',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                color: TraumColors.onBackground,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            // Soll-Legende (Pacing-Marker Erklärung)
            Row(children: [
              Container(
                width: bs(10),
                height: bs(1.5),
                color: Colors.white.withValues(alpha: 0.5),
              ),
              SizedBox(width: bs(3)),
              const Text(
                'Soll',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 8,
                  color: TraumColors.onBackgroundMuted,
                ),
              ),
            ]),
            SizedBox(width: bs(8)),
            GestureDetector(
              onTap: () => context.push(Routes.budgetCategories),
              child: const Text(
                'Verwalten ›',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: TraumColors.amberGold,
                ),
              ),
            ),
          ]),
          SizedBox(height: bs(6)),
          catsAsync.when(
            data: (cats) => cats.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: bs(8)),
                    child: const Text(
                      'Keine Budgetkategorien mit Limit konfiguriert.',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < cats.length; i++)
                        _BudgetCategoryRow(
                          cat: cats[i],
                          currency: currency,
                          isFirst: i == 0,
                        ),
                    ],
                  ),
            loading: () => SizedBox(
              height: bs(40),
              child: const Center(
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

class _BudgetContainer extends StatelessWidget {
  final Widget child;
  const _BudgetContainer({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(bs(13)),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(bs(16)),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: bs(1)),
        ),
        child: child,
      );
}

class _BudgetCategoryRow extends StatelessWidget {
  final BudgetCategoryWithSpending cat;
  final String currency;
  final bool isFirst;

  const _BudgetCategoryRow({
    required this.cat,
    required this.currency,
    required this.isFirst,
  });

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
    final pacingRatio = pacingLeftFraction(daysInMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst)
          Divider(
            color: Colors.white.withValues(alpha: 0.05),
            height: bs(1),
            thickness: bs(1),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: bs(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: bs(30),
                  height: bs(30),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(bs(8)),
                  ),
                  child: Center(
                    child: budgetCategoryGlyph(cat.emoji,
                        color: barColor, size: bs(14)),
                  ),
                ),
                SizedBox(width: bs(10)),
                Expanded(
                  child: Row(children: [
                    Flexible(
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                          color: TraumColors.onBackground,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cat.isOverBudget) ...[
                      SizedBox(width: bs(6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: bs(4), vertical: bs(1)),
                        decoration: BoxDecoration(
                          color: TraumColors.roseRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(bs(3)),
                        ),
                        child: const Text(
                          'ÜBER',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: TraumColors.roseRed,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
                SizedBox(width: bs(8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    HiddenAmount(
                      child: Text(
                        '$currency${fmtAmount(cat.spent)} von $currency${fmtAmount(cat.budgetLimit)}',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackgroundMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    HiddenAmount(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            color: barColor,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: bs(6)),
                        Text(
                          cat.isOverBudget
                              ? '+$currency${fmtAmount(remaining.abs())}'
                              : 'noch $currency${fmtAmount(remaining)}',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 8,
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
              SizedBox(height: bs(6)),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: bs(4),
                        decoration: BoxDecoration(
                          color: TraumColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(bs(2)),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: cat.ratio.clamp(0.0, 1.0),
                        child: Container(
                          height: bs(4),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: cat.isOverBudget
                                ? BorderRadius.horizontal(
                                    left: Radius.circular(bs(2)))
                                : BorderRadius.circular(bs(2)),
                          ),
                        ),
                      ),
                      // Überlauf-Indikator (nur wenn > 100 %)
                      if (cat.isOverBudget)
                        Positioned(
                          right: 0,
                          top: -2,
                          bottom: -2,
                          child: Container(
                            width: bs(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  TraumColors.roseRed,
                                  TraumColors.roseRed.withValues(alpha: 0),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.horizontal(
                                  right: Radius.circular(bs(3))),
                            ),
                          ),
                        ),
                      // Soll-Tempo-Marker (breiter, mit Glow)
                      if (kShowBudgetPacing)
                        Positioned(
                          left: (width * pacingRatio - bs(1.5))
                              .clamp(0.0, width - bs(3)),
                          top: -3,
                          bottom: -3,
                          child: Container(
                            width: bs(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(bs(2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  blurRadius: bs(6),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

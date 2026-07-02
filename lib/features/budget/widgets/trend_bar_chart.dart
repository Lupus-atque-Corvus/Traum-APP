import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../budget_providers.dart';
import '../budget_scale.dart';

// Local card container — same pattern as Tasks 3–4
class _LocalCard extends StatelessWidget {
  final Widget child;

  const _LocalCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(bs(13)),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(bs(16)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}

class TrendBarChart extends ConsumerStatefulWidget {
  const TrendBarChart({super.key});

  @override
  ConsumerState<TrendBarChart> createState() => _TrendBarChartState();
}

class _TrendBarChartState extends ConsumerState<TrendBarChart> {
  int? _touchedGroupIndex;

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(selectedTrendPeriodProvider);
    final barsAsync = ref.watch(trendDataProvider(period));

    return _LocalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(Routes.budgetStats),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.budgetTrend,
                  style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: TraumColors.onBackgroundMuted,
                  size: 18,
                ),
              ],
            ),
          ),
          SizedBox(height: bs(8)),
          // Period tabs — horizontal scrollbar, kein Umbruch
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TrendPeriod.values.map((p) {
                final isSelected = p == period;
                final label = switch (p) {
                  TrendPeriod.week => 'Woche',
                  TrendPeriod.month => 'Monat',
                  TrendPeriod.sixMonths => '6 Monate',
                  TrendPeriod.year => 'Jahr',
                };
                return Padding(
                  padding: EdgeInsets.only(right: bs(8)),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(selectedTrendPeriodProvider.notifier).state =
                            p,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: bs(8), vertical: bs(3)),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TraumColors.amberGold
                            : TraumColors.background,
                        borderRadius: BorderRadius.circular(bs(11)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: bs(16)),
          barsAsync.when(
            data: (bars) {
              if (bars.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(bs(24)),
                    child: const Text(
                      'Keine Daten',
                      style: TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ),
                );
              }
              final maxY = bars
                      .map((b) =>
                          b.income > b.expenses ? b.income : b.expenses)
                      .fold(0.0, (a, b) => a > b ? a : b) *
                  1.2;
              return SizedBox(
                height: bs(72),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY > 0 ? maxY : 1,
                    barTouchData: BarTouchData(
                      touchCallback: (event, response) {
                        final groupIndex =
                            response?.spot?.touchedBarGroupIndex;
                        setState(() {
                          _touchedGroupIndex = groupIndex;
                        });
                        if (event is FlTapUpEvent && groupIndex == null) {
                          context.push(Routes.budgetStats);
                        }
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem:
                            (group, groupIndex, rod, rodIndex) {
                          final bar = bars[groupIndex];
                          final isIncome = rodIndex == 0;
                          return BarTooltipItem(
                            isIncome
                                ? '+${bar.income.toStringAsFixed(0)}'
                                : '-${bar.expenses.toStringAsFixed(0)}',
                            TextStyle(
                              color: isIncome
                                  ? TraumColors.mintGreen
                                  : TraumColors.roseRed,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= bars.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: EdgeInsets.only(top: bs(4)),
                              child: Text(
                                bars[i].label,
                                style: const TextStyle(
                                  color: TraumColors.onBackgroundMuted,
                                  fontFamily: 'DMSans',
                                  fontSize: 7,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(bars.length, (i) {
                      final bar = bars[i];
                      final isTouched = i == _touchedGroupIndex;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: bar.income,
                            color: TraumColors.mintGreen
                                .withValues(alpha: isTouched ? 1.0 : 0.7),
                            width: bs(9),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(bs(2))),
                          ),
                          BarChartRodData(
                            toY: bar.expenses,
                            color: TraumColors.roseRed
                                .withValues(alpha: isTouched ? 1.0 : 0.7),
                            width: bs(9),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(bs(2))),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                    color: TraumColors.amberGold),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                '$e',
                style:
                    const TextStyle(color: TraumColors.roseRed),
              ),
            ),
          ),
          // Legend
          SizedBox(height: bs(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                  color: TraumColors.mintGreen,
                  label: AppLocalizations.of(context)!.budgetIncome),
              SizedBox(width: bs(12)),
              _LegendDot(
                  color: TraumColors.roseRed,
                  label: AppLocalizations.of(context)!.budgetExpenses),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: bs(6),
        height: bs(6),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      SizedBox(width: bs(4)),
      Text(
        label,
        style: const TextStyle(
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
          fontSize: 8,
        ),
      ),
    ]);
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/components.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../budget_providers.dart';

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

    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verlauf',
            style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // Period tabs
          Wrap(
            spacing: 8,
            children: TrendPeriod.values.map((p) {
              final isSelected = p == period;
              final label = switch (p) {
                TrendPeriod.week => 'Woche',
                TrendPeriod.month => 'Monat',
                TrendPeriod.sixMonths => '6 Monate',
                TrendPeriod.year => 'Jahr',
              };
              return GestureDetector(
                onTap: () =>
                    ref.read(selectedTrendPeriodProvider.notifier).state =
                        p,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TraumColors.amberGold
                        : TraumColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          barsAsync.when(
            data: (bars) {
              if (bars.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
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
                height: 160,
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
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                bars[i].label,
                                style: const TextStyle(
                                  color: TraumColors.onBackgroundMuted,
                                  fontFamily: 'DMSans',
                                  fontSize: 10,
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
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: TraumColors.surfaceVariant,
                        strokeWidth: 1,
                      ),
                      drawVerticalLine: false,
                    ),
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
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: bar.expenses,
                            color: TraumColors.roseRed
                                .withValues(alpha: isTouched ? 1.0 : 0.7),
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                  color: TraumColors.mintGreen,
                  label: AppLocalizations.of(context)!.budgetIncome),
              const SizedBox(width: 16),
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
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
          fontSize: 11,
        ),
      ),
    ]);
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/components.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../budget_forecast.dart';
import '../budget_providers.dart';

class BudgetHeaderCard extends ConsumerWidget {
  const BudgetHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    final ym = (month.year, month.month);
    final prevMonth = month.month == 1
        ? DateTime(month.year - 1, 12)
        : DateTime(month.year, month.month - 1);
    final prevYm = (prevMonth.year, prevMonth.month);
    final summaryAsync = ref.watch(budgetSummaryProvider(ym));
    final prevSummaryAsync = ref.watch(budgetSummaryProvider(prevYm));
    final spotsAsync = ref.watch(dailyBalanceSpotsProvider(ym));
    final currency = ref.watch(currencySymbolProvider);
    final visible = ref.watch(budgetBalanceVisibleProvider);
    final monthNames = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
    ];

    return TraumCard(
      borderColor: TraumColors.amberGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: TraumColors.onBackgroundMuted,
                ),
                onPressed: () =>
                    ref.read(selectedBudgetMonthProvider.notifier).state =
                        DateTime(month.year, month.month - 1),
              ),
              Text(
                '${monthNames[month.month - 1]} ${month.year}',
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: TraumColors.onBackgroundMuted,
                ),
                onPressed: () {
                  final next = DateTime(month.year, month.month + 1);
                  if (next.isBefore(DateTime(
                      DateTime.now().year, DateTime.now().month + 1))) {
                    ref.read(selectedBudgetMonthProvider.notifier).state =
                        next;
                  }
                },
              ),
            ],
          ),
          // Balance label
          const Text(
            'Verfügbares Guthaben',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          summaryAsync.when(
            data: (summary) {
              final isPositive = summary.balance >= 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          visible
                              ? '${summary.balance.toStringAsFixed(2)} $currency'
                              : '*** $currency',
                          style: TextStyle(
                            color: isPositive
                                ? TraumColors.mintGreen
                                : TraumColors.roseRed,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            fontSize: 34,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          visible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: TraumColors.onBackgroundMuted,
                        ),
                        onPressed: () => ref
                            .read(budgetBalanceVisibleProvider.notifier)
                            .state = !visible,
                      ),
                    ],
                  ),
                  // Previous month comparison badge
                  if (prevSummaryAsync.value != null &&
                      prevSummaryAsync.value!.balance != 0)
                    _ComparisonBadge(
                      current: summary.balance,
                      previous: prevSummaryAsync.value!.balance,
                    ),
                  // Sparkline
                  spotsAsync.when(
                    data: (spots) {
                      if (spots.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        height: 48,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineTouchData:
                                const LineTouchData(enabled: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: TraumColors.amberGold,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: TraumColors.amberGold
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox(height: 48),
                  ),
                  const SizedBox(height: 12),
                  // Income / Expenses / Saved
                  Row(
                    children: [
                      _StatCol(
                        icon: Icons.arrow_downward_rounded,
                        color: TraumColors.mintGreen,
                        label: 'Einnahmen',
                        value:
                            '${summary.income.toStringAsFixed(0)} $currency',
                      ),
                      const SizedBox(width: 1),
                      _StatCol(
                        icon: Icons.arrow_upward_rounded,
                        color: TraumColors.roseRed,
                        label: 'Ausgaben',
                        value:
                            '${summary.expenses.toStringAsFixed(0)} $currency',
                      ),
                      _StatCol(
                        icon: Icons.savings_rounded,
                        color: TraumColors.amberGold,
                        label: 'Gespart',
                        value: summary.income > 0
                            ? '${((1 - summary.expenses / summary.income) * 100).clamp(0, 100).toStringAsFixed(0)}%'
                            : '0%',
                      ),
                    ],
                  ),
                  // Forecast
                  _ForecastRow(summary: summary, month: month),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(
                color: TraumColors.amberGold),
            error: (e, _) => Text(
              '$e',
              style: const TextStyle(color: TraumColors.roseRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCol({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 10,
          ),
        ),
      ]),
    );
  }
}

class _ComparisonBadge extends StatelessWidget {
  final double current;
  final double previous;

  const _ComparisonBadge({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final pct = (diff / previous.abs() * 100).abs();
    final isUp = diff >= 0;
    final color = isUp ? TraumColors.mintGreen : TraumColors.roseRed;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '${pct.toStringAsFixed(0)}% vs. letzter Monat',
            style: TextStyle(
              color: color,
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final BudgetSummary summary;
  final DateTime month;

  const _ForecastRow({required this.summary, required this.month});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isSameMonth =
        now.year == month.year && now.month == month.month;
    if (!isSameMonth) return const SizedBox.shrink();

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final forecast = BudgetForecast.forecastEndOfMonth(
      currentBalance: summary.balance,
      dayOfMonth: now.day,
      daysInMonth: daysInMonth,
    );
    if (forecast == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card / 2),
        ),
        child: Text(
          'Prognose: Bei aktuellem Tempo hast du am Monatsende ~${forecast.toStringAsFixed(0)} übrig.',
          style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

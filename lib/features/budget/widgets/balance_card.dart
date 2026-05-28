import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/traum_card.dart';
import '../../../core/theme/colors.dart';
import '../budget_helpers.dart';
import '../budget_providers.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(budgetBalanceVisibleProvider);
    final month = ref.watch(selectedBudgetMonthProvider);
    final ym = (month.year, month.month);
    final totalAsync = ref.watch(totalAccountBalanceProvider);
    final changeAsync = ref.watch(monthlyBalanceChangeProvider);
    final spotsAsync = ref.watch(dailyBalanceSpotsProvider(ym));

    return TraumCard(
      borderColor: TraumColors.mintGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text(
              'Gesamtsaldo',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                color: TraumColors.onBackground,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  ref.read(budgetBalanceVisibleProvider.notifier).state =
                      !visible,
              child: Icon(
                visible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: TraumColors.onBackgroundMuted,
                size: 18,
              ),
            ),
            const Spacer(),
            const Icon(Icons.more_horiz,
                color: TraumColors.onBackgroundMuted, size: 20),
          ]),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              totalAsync.when(
                data: (total) => Text(
                  visible ? '€${fmtAmount(total)}' : '€ ••••••',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    color: TraumColors.onBackground,
                    fontSize: 32,
                  ),
                ),
                loading: () => const Text(
                  '€ —',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    color: TraumColors.onBackground,
                    fontSize: 32,
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 10),
              changeAsync.when(
                data: (change) =>
                    change != null ? _TrendBadge(change: change) : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'vs. letzter Monat',
            style: TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackgroundMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: spotsAsync.when(
              data: (spots) => spots.isEmpty
                  ? const SizedBox.shrink()
                  : _BalanceAreaChart(spots: spots),
              loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: TraumColors.mintGreen),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceAreaChart extends StatelessWidget {
  final List<FlSpot> spots;

  const _BalanceAreaChart({required this.spots});

  @override
  Widget build(BuildContext context) {
    final monthAbbr = _monthAbbr();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (v, _) => Text(
                '${(v / 1000).toStringAsFixed(0)}k €',
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackgroundSubtle,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final day = v.toInt() + 1;
                if (day != 1 && day % 7 != 0 && day != spots.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '$day. $monthAbbr',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundSubtle,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => TraumColors.surfaceVariant,
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(0)} €',
                      const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackground,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: TraumColors.mintGreen,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, index) {
                if (index != spots.length - 1) {
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeColor: Colors.transparent,
                    strokeWidth: 0,
                  );
                }
                return FlDotCirclePainter(
                  radius: 5,
                  color: TraumColors.mintGreen,
                  strokeColor: TraumColors.background,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TraumColors.mintGreen.withValues(alpha: 0.3),
                  TraumColors.mintGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr() {
    const names = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
    ];
    return names[DateTime.now().month - 1];
  }
}

class _TrendBadge extends StatelessWidget {
  final double change;

  const _TrendBadge({required this.change});

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color =
        isPositive ? TraumColors.mintGreen : TraumColors.roseRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
          size: 12,
        ),
        const SizedBox(width: 2),
        Text(
          '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
          style: TextStyle(
            fontFamily: 'DMSans',
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ]),
    );
  }
}

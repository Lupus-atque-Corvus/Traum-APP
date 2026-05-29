import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../nutrition_providers.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<DailyCalories> data;
  final int kcalGoal;

  const WeeklyBarChart(
      {super.key, required this.data, required this.kcalGoal});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = (kcalGoal * 1.2).ceilToDouble();
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: TraumColors.surfaceVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final d = data[i].date;
                  final wd = (d.weekday - 1) % 7;
                  return Text(weekdays[wd],
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10,
                          color: TraumColors.onBackgroundMuted));
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: kcalGoal.toDouble(),
              color:
                  TraumColors.mintGreen.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ]),
          barGroups: data.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final entryDay = DateTime(
                d.date.year, d.date.month, d.date.day);
            final isToday = entryDay == today;
            final overGoal = d.calories > kcalGoal;
            final color = overGoal
                ? TraumColors.coralOrange
                : TraumColors.mintGreen;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d.calories > 0 ? d.calories : 0,
                  color: color.withValues(
                      alpha: isToday ? 1.0 : 0.5),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

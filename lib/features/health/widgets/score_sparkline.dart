import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class ScoreSparkline extends StatelessWidget {
  final List<int> scores; // 7 values, oldest first
  final int currentScore;

  const ScoreSparkline({
    super.key,
    required this.scores,
    required this.currentScore,
  });

  @override
  Widget build(BuildContext context) {
    if (scores.length < 2) {
      return const SizedBox(height: 60);
    }

    final lineColor = currentScore >= 70
        ? TraumColors.mintGreen
        : currentScore >= 55
            ? TraumColors.amberGold
            : TraumColors.roseRed;

    final spots = scores.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final now = DateTime.now();
    final labels = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return weekdays[day.weekday - 1];
    });

    return SizedBox(
      height: 80,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Text(
                    labels[i],
                    style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  final isToday = index == scores.length - 1;
                  return FlDotCirclePainter(
                    radius: isToday ? 5 : 2.5,
                    color: isToday ? TraumColors.coralOrange : lineColor,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: 0.3),
                    lineColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

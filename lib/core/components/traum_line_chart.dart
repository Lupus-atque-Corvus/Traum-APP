import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class TraumLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final List<String> xLabels;
  final Color color;
  final LinearGradient? gradient;
  final double? minY;
  final double? maxY;
  final double height;

  const TraumLineChart({
    super.key,
    required this.spots,
    required this.xLabels,
    this.color = TraumColors.cyanBlue,
    this.gradient,
    this.minY,
    this.maxY,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Noch keine Daten',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontSize: 13,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= xLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    xLabels[idx],
                    style: const TextStyle(
                      fontSize: 10,
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: FlDotData(
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

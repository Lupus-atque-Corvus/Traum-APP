import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class DonutChart extends StatelessWidget {
  final List<DonutSection> sections;
  final double size;
  final double centerHoleRadius;

  const DonutChart({
    super.key,
    required this.sections,
    this.size = 160,
    this.centerHoleRadius = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Text(
            'Keine Daten',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontSize: 12,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: PieChart(
        PieChartData(
          sections: sections
              .map((s) => PieChartSectionData(
                    value: s.value,
                    color: s.color,
                    radius: size / 2 * (1 - centerHoleRadius),
                    showTitle: false,
                  ))
              .toList(),
          centerSpaceRadius: size / 2 * centerHoleRadius,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}

class DonutSection {
  final double value;
  final Color color;
  final String label;

  const DonutSection({
    required this.value,
    required this.color,
    required this.label,
  });
}

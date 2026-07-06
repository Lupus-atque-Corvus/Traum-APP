import 'package:flutter/material.dart';
import '../../../core/components/donut_chart.dart';
import '../../../core/theme/colors.dart';

/// A donut showing achieved vs. open items (e.g. "3/5 Ziele erreicht") with
/// a center label. Stacks the shared `DonutChart` (core/components) with a
/// centered text overlay — `DonutChart` itself has no center-content slot,
/// so this composes rather than modifying the shared widget.
class GoalDonut extends StatelessWidget {
  final int achieved;
  final int total;
  final double size;
  final Color achievedColor;
  final Color openColor;
  final String? centerLabel;

  const GoalDonut({
    super.key,
    required this.achieved,
    required this.total,
    this.size = 160,
    this.achievedColor = TraumColors.lavender,
    this.openColor = TraumColors.surfaceVariant,
    this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final open = (total - achieved).clamp(0, total);
    final sections = total <= 0
        ? <DonutSection>[]
        : [
            DonutSection(
              value: achieved.toDouble(),
              color: achievedColor,
              label: 'Erreicht',
            ),
            if (open > 0)
              DonutSection(
                value: open.toDouble(),
                color: openColor,
                label: 'Offen',
              ),
          ];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DonutChart(sections: sections, size: size),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel ?? '$achieved/$total',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: size * 0.14,
                  fontWeight: FontWeight.w800,
                  color: TraumColors.onBackground,
                ),
              ),
              Text(
                'Ziele',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: size * 0.075,
                  fontWeight: FontWeight.w500,
                  color: TraumColors.onBackgroundMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

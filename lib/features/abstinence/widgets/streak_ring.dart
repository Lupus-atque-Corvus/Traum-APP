import 'package:flutter/material.dart';
import '../../../core/components/circular_progress_ring.dart';
import '../../../core/theme/colors.dart';

/// A [CircularProgressRing] pre-composed with a big center number and a
/// small unit label underneath — the "42 Tage" / "4/6 heute" style display
/// used on the Fortschritt tab (streaks, daily habit completion, ...).
///
/// Reuses the shared `CircularProgressRing` (core/components) via its
/// existing `center` slot rather than forking the painter.
class StreakRing extends StatelessWidget {
  final double value;
  final String bigNumber;
  final String unitLabel;
  final double size;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const StreakRing({
    super.key,
    required this.value,
    required this.bigNumber,
    required this.unitLabel,
    this.size = 120,
    this.color = TraumColors.roseRed,
    this.trackColor = TraumColors.surfaceVariant,
    this.strokeWidth = 10,
  });

  @override
  Widget build(BuildContext context) {
    return CircularProgressRing(
      value: value,
      size: size,
      color: color,
      trackColor: trackColor,
      strokeWidth: strokeWidth,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bigNumber,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: size * 0.24,
              fontWeight: FontWeight.w800,
              color: TraumColors.onBackground,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unitLabel,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: size * 0.1,
              fontWeight: FontWeight.w500,
              color: TraumColors.onBackgroundMuted,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

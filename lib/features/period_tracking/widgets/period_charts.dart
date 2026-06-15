import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

// ---------------------------------------------------------------------------
// CycleLengthChart
// ---------------------------------------------------------------------------

/// A horizontal bar chart showing recent cycle lengths.
///
/// Bars outside the 21–35 day normal range are highlighted in amber;
/// all other bars use [TraumColors.periodRose].
/// At most the last 12 lengths are displayed.
class CycleLengthChart extends StatelessWidget {
  final List<int> lengths;
  final int avgLength;

  const CycleLengthChart({
    super.key,
    required this.lengths,
    required this.avgLength,
  });

  @override
  Widget build(BuildContext context) {
    if (lengths.isEmpty) return const SizedBox.shrink();

    final recent = lengths.length > 12
        ? lengths.sublist(lengths.length - 12)
        : lengths;

    final maxVal =
        recent.fold<int>(0, (a, b) => a > b ? a : b).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: recent.map((len) {
        final height = maxVal > 0 ? (len / maxVal) * 80 : 4.0;
        // Out-of-normal-range (< 21 or > 35 days) → amber highlight
        final isOutOfRange = len < 21 || len > 35;
        final barColor = isOutOfRange
            ? TraumColors.amberGold.withValues(alpha: 0.7)
            : TraumColors.periodRose.withValues(alpha: 0.7);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: height.clamp(4.0, 80.0),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$len',
                  style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// BbtChart
// ---------------------------------------------------------------------------

/// A polyline chart of Basal Body Temperature (BBT) readings.
///
/// Draws the temperature line scaled to the min/max of the data set.
/// If all readings have the same temperature ([range] == 0) the line is
/// centred in the paint area to avoid a divide-by-zero.
/// A horizontal "cover line" is drawn at the max of the first ≤6 readings.
/// Requires at least two data points; returns [SizedBox.shrink] otherwise.
class BbtChart extends StatelessWidget {
  final List<({DateTime date, double temp})> points;

  const BbtChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 64,
      child: CustomPaint(
        painter: _BbtPainter(points: points),
        size: Size.infinite,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BbtPainter
// ---------------------------------------------------------------------------

class _BbtPainter extends CustomPainter {
  final List<({DateTime date, double temp})> points;

  const _BbtPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // Sort defensively by date ascending.
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));

    final temps = sorted.map((p) => p.temp).toList();
    final minTemp = temps.fold<double>(temps.first, math.min);
    final maxTemp = temps.fold<double>(temps.first, math.max);
    final range = maxTemp - minTemp;

    // Map a temperature value to a y-coordinate (0 = top, size.height = bottom).
    double yFor(double temp) {
      if (range == 0) {
        // All temps equal — centre the line.
        return size.height / 2;
      }
      // Invert: higher temp → lower y value (closer to top).
      return size.height - ((temp - minTemp) / range) * size.height;
    }

    // Build the polyline path.
    final polylinePaint = Paint()
      ..color = TraumColors.ovulationCyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < sorted.length; i++) {
      final x = i / (sorted.length - 1) * size.width;
      final y = yFor(sorted[i].temp);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, polylinePaint);

    // Cover line: horizontal at the max temp of the first ≤6 readings.
    final preOvulation = sorted.take(6).toList();
    final coverTemp =
        preOvulation.map((p) => p.temp).fold<double>(preOvulation.first.temp, math.max);
    final coverY = yFor(coverTemp);

    final coverPaint = Paint()
      ..color = TraumColors.ovulationCyan.withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw as a dashed line.
    const dashWidth = 6.0;
    const dashGap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, coverY),
        Offset(math.min(x + dashWidth, size.width), coverY),
        coverPaint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_BbtPainter oldDelegate) => oldDelegate.points != points;
}

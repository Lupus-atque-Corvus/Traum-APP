import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// Circular cycle progress ring. [progress] is 0..1 around the cycle; the arc
/// is painted in [TraumColors.periodRose] with the center showing the cycle day
/// and phase label (hero card of the period dashboard).
class CycleRing extends StatelessWidget {
  final int? cycleDay;
  final String phaseLabel;
  final double progress;
  final String? centerSubtitle;

  const CycleRing({
    super.key,
    required this.cycleDay,
    required this.phaseLabel,
    required this.progress,
    this.centerSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: CustomPaint(
        painter: _RingPainter(progress.clamp(0.0, 1.0)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(phaseLabel,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 11)),
              Text(cycleDay?.toString() ?? '–',
                  style: const TextStyle(
                      color: TraumColors.periodRose,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w800,
                      fontSize: 34)),
              if (centerSubtitle != null)
                Text(centerSubtitle!,
                    style: const TextStyle(
                        color: TraumColors.ovulationCyan,
                        fontFamily: 'DMSans',
                        fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    const stroke = 12.0;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = TraumColors.surfaceVariant;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = TraumColors.periodRose;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

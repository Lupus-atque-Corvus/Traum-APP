import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class CircularScoreRing extends StatelessWidget {
  final int score;
  final double size;

  const CircularScoreRing({super.key, required this.score, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.6,
      child: CustomPaint(
        painter: _RingPainter(score: score),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int score;

  _RingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.85;
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;
    const startAngle = pi;
    const sweepAngle = pi;

    // Track
    final trackPaint = Paint()
      ..color = TraumColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Progress with gradient
    final fraction = (score / 100).clamp(0.0, 1.0);
    if (fraction > 0) {
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      final gradientPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: const [
            TraumColors.roseRed,
            TraumColors.amberGold,
            TraumColors.mintGreen,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle * fraction,
        false,
        gradientPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.score != score;
}

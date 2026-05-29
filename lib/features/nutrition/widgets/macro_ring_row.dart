import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class MacroRingRow extends StatelessWidget {
  final double calories;
  final double caloriesGoal;
  final double protein;
  final double proteinGoal;
  final double carbs;
  final double carbsGoal;
  final double fat;
  final double fatGoal;

  const MacroRingRow({
    super.key,
    required this.calories,
    required this.caloriesGoal,
    required this.protein,
    required this.proteinGoal,
    required this.carbs,
    required this.carbsGoal,
    required this.fat,
    required this.fatGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Ring('Kalorien', calories, caloriesGoal, 'kcal',
            TraumColors.coralOrange),
        _Ring('Protein', protein, proteinGoal, 'g',
            TraumColors.indigoBlue),
        _Ring('Carbs', carbs, carbsGoal, 'g',
            TraumColors.amberGold),
        _Ring(
            'Fett', fat, fatGoal, 'g', TraumColors.cyanBlue),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  const _Ring(
      this.label, this.value, this.goal, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    final double progress =
        (goal > 0 ? value / goal : 0.0).clamp(0.0, 1.0);
    return Column(children: [
      SizedBox(
        width: 64,
        height: 64,
        child: CustomPaint(
          painter:
              _RingPainter(progress: progress, color: color),
          child: Center(
            child: Text(
              value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)}k'
                  : value.toStringAsFixed(0),
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              color: TraumColors.onBackgroundMuted)),
      Text(
        '${goal.toStringAsFixed(0)} $unit',
        style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            color: TraumColors.onBackgroundSubtle),
      ),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress;
}

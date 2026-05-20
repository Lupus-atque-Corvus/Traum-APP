import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExerciseIcon extends StatelessWidget {
  final String muscleGroup;
  final double size;

  const ExerciseIcon({
    super.key,
    required this.muscleGroup,
    this.size = 44,
  });

  static const Map<String, String> _assetMap = {
    'chest':     'assets/exercises/icons/chest.svg',
    'back':      'assets/exercises/icons/back.svg',
    'shoulders': 'assets/exercises/icons/shoulders.svg',
    'biceps':    'assets/exercises/icons/biceps.svg',
    'triceps':   'assets/exercises/icons/triceps.svg',
    'legs':      'assets/exercises/icons/legs.svg',
    'core':      'assets/exercises/icons/core.svg',
    'cardio':    'assets/exercises/icons/cardio.svg',
    'full_body': 'assets/exercises/icons/full_body.svg',
  };

  static const Map<String, Color> _colorMap = {
    'chest':     Color(0xFFFF6B6B),
    'back':      Color(0xFF4ECDC4),
    'shoulders': Color(0xFFA78BFA),
    'biceps':    Color(0xFFF59E0B),
    'triceps':   Color(0xFFFB923C),
    'legs':      Color(0xFF60A5FA),
    'core':      Color(0xFF34D399),
    'cardio':    Color(0xFFF472B6),
    'full_body': Color(0xFF94A3B8),
  };

  static Color muscleGroupColor(String muscleGroup) =>
      _colorMap[muscleGroup] ?? const Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final asset = _assetMap[muscleGroup] ?? _assetMap['full_body']!;
    final color = muscleGroupColor(muscleGroup);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: SvgPicture.asset(asset),
      ),
    );
  }
}

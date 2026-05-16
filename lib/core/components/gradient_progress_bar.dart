import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GradientProgressBar extends StatelessWidget {
  final double value;
  final LinearGradient gradient;
  final double height;
  final Color trackColor;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.gradient = TraumColors.gradientWarm,
    this.height = 8,
    this.trackColor = TraumColors.surfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (_, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * clamped,
              height: height,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

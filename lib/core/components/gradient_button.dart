import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final Widget? icon;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.gradient = TraumColors.gradientWarm,
    this.icon,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: onPressed != null ? gradient : null,
          color: onPressed == null ? TraumColors.surfaceVariant : null,
          borderRadius: BorderRadius.circular(TraumRadius.button),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              label,
              style: TextStyle(
                color: onPressed != null
                    ? Colors.white
                    : TraumColors.onBackgroundMuted,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';

class TraumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Color? color;

  const TraumCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: borderColor != null
              ? Border.all(
                  color: borderColor!.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

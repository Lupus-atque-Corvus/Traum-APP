import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppointmentChip extends StatelessWidget {
  final String title;
  final String time;
  final Color color;
  final VoidCallback? onTap;

  const AppointmentChip({
    super.key,
    required this.title,
    required this.time,
    this.color = TraumColors.lavender,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
                fontFamily: 'DMSans',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w500,
                fontFamily: 'DMSans',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

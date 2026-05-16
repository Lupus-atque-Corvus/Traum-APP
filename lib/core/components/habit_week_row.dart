import 'package:flutter/material.dart';
import '../theme/colors.dart';

class HabitWeekRow extends StatelessWidget {
  final String habitName;
  final List<bool> weekStatus;

  const HabitWeekRow({
    super.key,
    required this.habitName,
    required this.weekStatus,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final today = DateTime.now().weekday - 1;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            habitName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(7, (i) {
          final done = i < weekStatus.length && weekStatus[i];
          final isToday = i == today;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done
                    ? TraumColors.mintGreen
                    : isToday
                        ? TraumColors.coralDim
                        : TraumColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: TraumColors.coralOrange, width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: done
                        ? Colors.white
                        : TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

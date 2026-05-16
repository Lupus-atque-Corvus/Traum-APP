import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MedicationDotRow extends StatelessWidget {
  final String name;
  final List<String> times;
  final List<bool> taken;

  const MedicationDotRow({
    super.key,
    required this.name,
    required this.times,
    required this.taken,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
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
        Wrap(
          spacing: 4,
          children: List.generate(
            times.length,
            (i) => Tooltip(
              message: times[i],
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (i < taken.length && taken[i])
                      ? TraumColors.mintGreen
                      : TraumColors.roseRed,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

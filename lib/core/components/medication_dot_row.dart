import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../l10n/app_localizations.dart';

class MedicationDotRow extends StatelessWidget {
  final String name;
  final List<String> times;
  final List<bool> taken;

  /// Optional: called with the dot index when a dot is tapped (mark taken/untaken).
  final void Function(int index)? onTapDot;

  const MedicationDotRow({
    super.key,
    required this.name,
    required this.times,
    required this.taken,
    this.onTapDot,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          children: List.generate(times.length, (i) {
            final isTaken = i < taken.length && taken[i];
            final dot = Tooltip(
              message: times[i],
              child: GestureDetector(
                onTap: onTapDot == null ? null : () => onTapDot!(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTaken
                          ? TraumColors.mintGreen
                          : TraumColors.roseRed,
                    ),
                  ),
                ),
              ),
            );
            return Semantics(
              button: onTapDot != null,
              label: isTaken
                  ? l10n.a11yMedicationDoseTaken(name, times[i])
                  : l10n.a11yMedicationDoseNotTaken(name, times[i]),
              child: ExcludeSemantics(child: dot),
            );
          }),
        ),
      ],
    );
  }
}

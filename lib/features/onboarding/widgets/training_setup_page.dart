import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/components/components.dart';
import '../../../l10n/app_localizations.dart';

class TrainingSetupPage extends StatelessWidget {
  final String level;
  final String goal;
  final int daysPerWeek;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onGoalChanged;
  final ValueChanged<int> onDaysChanged;
  final VoidCallback onNext;

  const TrainingSetupPage({
    super.key,
    required this.level,
    required this.goal,
    required this.daysPerWeek,
    required this.onLevelChanged,
    required this.onGoalChanged,
    required this.onDaysChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = TraumColors.coralOrange;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(l10n.obTrainingTitle,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans')),
          const SizedBox(height: 8),
          Text(l10n.obTrainingSubtitle,
              style: const TextStyle(
                  fontSize: 14,
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans')),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.obTrainingLevel,
                      style: const TextStyle(
                          fontSize: 13,
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans')),
                  const SizedBox(height: 8),
                  _ChipRow(
                    options: [
                      ('beginner', l10n.obLevelBeginner),
                      ('intermediate', l10n.obLevelIntermediate),
                      ('advanced', l10n.obLevelAdvanced),
                    ],
                    selected: level,
                    color: accent,
                    onSelect: onLevelChanged,
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.obTrainingGoalLabel,
                      style: const TextStyle(
                          fontSize: 13,
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans')),
                  const SizedBox(height: 8),
                  _ChipRow(
                    options: [
                      ('muscle', l10n.obGoalMuscle),
                      ('lose', l10n.obGoalLose),
                      ('fitness', l10n.obGoalFitness),
                    ],
                    selected: goal,
                    color: accent,
                    onSelect: onGoalChanged,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.obTrainingPerWeek,
                          style: const TextStyle(
                              fontSize: 14,
                              color: TraumColors.onBackground,
                              fontFamily: 'DMSans')),
                      Text('$daysPerWeek',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: accent,
                              fontFamily: 'DMSans')),
                    ],
                  ),
                  Slider(
                    value: daysPerWeek.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    activeColor: accent,
                    onChanged: (v) => onDaysChanged(v.toInt()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(label: l10n.next, onPressed: onNext),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final Color color;
  final ValueChanged<String> onSelect;
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSel = o.$1 == selected;
        return GestureDetector(
          onTap: () => onSelect(o.$1),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel
                  ? color.withValues(alpha: 0.15)
                  : TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.chip),
              border: Border.all(
                  color: isSel ? color : TraumColors.surfaceVariant),
            ),
            child: Text(o.$2,
                style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'DMSans',
                    fontWeight:
                        isSel ? FontWeight.w600 : FontWeight.normal,
                    color: isSel
                        ? color
                        : TraumColors.onBackgroundMuted)),
          ),
        );
      }).toList(),
    );
  }
}

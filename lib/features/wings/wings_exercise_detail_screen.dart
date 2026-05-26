import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'wings_data.dart';

class WingsExerciseDetailScreen extends StatelessWidget {
  final String exerciseId;

  const WingsExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exercise = findExerciseById(exerciseId);

    if (exercise == null) {
      return Scaffold(
        backgroundColor: TraumColors.background,
        appBar: AppBar(backgroundColor: TraumColors.surface),
        body: Center(
          child: Text(
            l10n.wingsExerciseNotFound,
            style: const TextStyle(color: TraumColors.onBackgroundMuted),
          ),
        ),
      );
    }

    final diffColor = difficultyColor(exercise.difficulty);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.surface,
        elevation: 0,
        title: Text(
          exercise.name,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
            color: TraumColors.onBackground,
          ),
        ),
        leading: const BackButton(color: TraumColors.onBackground),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Difficulty + Category chips
          Wrap(
            spacing: 8,
            children: [
              _Chip(
                label: difficultyLabel(exercise.difficulty),
                color: diffColor,
              ),
              _Chip(
                label: categoryLabel(exercise.category),
                color: TraumColors.onBackgroundMuted,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Muscles
          _Section(
            title: l10n.wingsMuscles,
            child: Text(
              exercise.muscles,
              style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _Section(
            title: l10n.wingsOverview,
            child: Text(
              exercise.description,
              style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Instructions
          if (exercise.instructions.isNotEmpty) ...[
            _Section(
              title: l10n.wingsInstructions,
              child: Column(
                children: exercise.instructions.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 10, top: 1),
                          decoration: BoxDecoration(
                            color: TraumColors.cyanDim,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                color: TraumColors.cyanBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: TraumColors.onBackground,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (!exercise.hasDetail) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TraumColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.wingsComingSoon,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackgroundMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Good Form
          if (exercise.goodForm.isNotEmpty) ...[
            _Section(
              title: l10n.wingsGoodForm,
              child: Column(
                children: exercise.goodForm
                    .map((cue) => _FormCue(text: cue, isGood: true))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Bad Form
          if (exercise.badForm.isNotEmpty) ...[
            _Section(
              title: l10n.wingsBadForm,
              child: Column(
                children: exercise.badForm
                    .map((cue) => _FormCue(text: cue, isGood: false))
                    .toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DMSans',
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.cyanBlue,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FormCue extends StatelessWidget {
  final String text;
  final bool isGood;

  const _FormCue({required this.text, required this.isGood});

  @override
  Widget build(BuildContext context) {
    final color = isGood ? TraumColors.mintGreen : TraumColors.roseRed;
    final icon = isGood ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

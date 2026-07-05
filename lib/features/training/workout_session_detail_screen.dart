import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'muscle_groups.dart';
import 'widgets/exercise_icon.dart';

class WorkoutSessionDetailScreen extends ConsumerWidget {
  final int sessionId;
  const WorkoutSessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(setsForSessionProvider(sessionId));
    final exercisesAsync = ref.watch(allExercisesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.workoutDetails,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: setsAsync.when(
        data: (sets) => exercisesAsync.when(
          data: (exercises) {
            if (sets.isEmpty) {
              return Center(
                child: Text(AppLocalizations.of(context)!.noSetsRecorded,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans')),
              );
            }

            final grouped = <int, List<WorkoutSet>>{};
            for (final s in sets) {
              grouped.putIfAbsent(s.exerciseId, () => []).add(s);
            }

            final totalVolume = sets.fold(
                0.0,
                (v, s) =>
                    v + ((s.weightKg ?? 0) * (s.reps ?? 1)));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TraumColors.surface,
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    border: Border.all(
                        color: TraumColors.coralOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: _StatChip(
                        label: AppLocalizations.of(context)!.exercises,
                        value: '${grouped.length}',
                        color: TraumColors.coralOrange,
                      ),
                    ),
                    Expanded(
                      child: _StatChip(
                        label: AppLocalizations.of(context)!.setsLabel,
                        value: '${sets.length}',
                        color: TraumColors.mintGreen,
                      ),
                    ),
                    Expanded(
                      child: _StatChip(
                        label: AppLocalizations.of(context)!.volumeKg,
                        value: totalVolume.toStringAsFixed(0),
                        color: TraumColors.lavender,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                ...grouped.entries.map((entry) {
                  final ex = exercises.cast<Exercise?>().firstWhere(
                      (e) => e?.id == entry.key, orElse: () => null);
                  return _ExerciseGroup(
                    exerciseName: ex?.name ?? 'Übung #${entry.key}',
                    muscleGroup: ex?.muscleGroup ?? '',
                    sets: entry.value,
                    onExerciseTap: () =>
                        context.go('/training/exercise/${entry.key}/progress'),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: TraumColors.coralOrange)),
          error: (e, _) => Center(child: Text('$e')),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.coralOrange)),
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.error}: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 20)),
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 11)),
    ]);
  }
}

class _ExerciseGroup extends StatelessWidget {
  final String exerciseName;
  final String muscleGroup;
  final List<WorkoutSet> sets;
  final VoidCallback onExerciseTap;

  const _ExerciseGroup({
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: onExerciseTap,
            leading: ExerciseIcon(
                muscleGroup: canonicalMuscleGroup(muscleGroup), size: 36),
            title: Text(exerciseName,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700)),
            subtitle: muscleGroup.isNotEmpty
                ? Text(muscleGroup,
                    style: const TextStyle(
                        color: TraumColors.coralOrange,
                        fontFamily: 'DMSans',
                        fontSize: 12))
                : null,
            trailing: const Icon(Icons.chevron_right_rounded,
                color: TraumColors.onBackgroundSubtle),
          ),
          const Divider(height: 1, color: TraumColors.surfaceVariant),
          ...sets.map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Text(AppLocalizations.of(context)!.setLabel(s.setNumber),
                      style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (s.weightKg != null)
                    Text('${s.weightKg} kg',
                        style: const TextStyle(
                            color: TraumColors.onBackground,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w500)),
                  if (s.weightKg != null && s.reps != null)
                    const Text('  ×  ',
                        style: TextStyle(
                            color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
                  if (s.reps != null)
                    Text(AppLocalizations.of(context)!.repsCount(s.reps!),
                        style: const TextStyle(
                            color: TraumColors.onBackground,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w500)),
                ]),
              )),
        ],
      ),
    );
  }
}

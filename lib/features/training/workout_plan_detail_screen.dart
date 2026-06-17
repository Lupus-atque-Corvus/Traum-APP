import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/exercise_icon.dart';

String _muscleGroupKey(String germanKey) {
  switch (germanKey) {
    case 'Brust': return 'chest';
    case 'Rücken': return 'back';
    case 'Schulter': return 'shoulders';
    case 'Bizeps': return 'biceps';
    case 'Trizeps': return 'triceps';
    case 'Bauch': return 'core';
    case 'Beine': return 'legs';
    case 'Gesäß': return 'legs';
    case 'Waden': return 'legs';
    case 'Ganzkörper': return 'full_body';
    default: return 'full_body';
  }
}

class WorkoutPlanDetailScreen extends ConsumerWidget {
  final int planId;
  const WorkoutPlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(allWorkoutPlansStreamProvider);
    final daysAsync = ref.watch(workoutDaysForPlanProvider(planId));

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: plansAsync.when(
          data: (plans) {
            final plan = plans.cast<WorkoutPlan?>().firstWhere(
                (p) => p?.id == planId, orElse: () => null);
            return Text(plan?.name ?? AppLocalizations.of(context)!.trainingPlan,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700));
          },
          loading: () => Text(AppLocalizations.of(context)!.trainingPlan,
              style: const TextStyle(
                  color: TraumColors.onBackground, fontFamily: 'DMSans')),
          error: (_, _) => Text(AppLocalizations.of(context)!.trainingPlan),
        ),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded, color: TraumColors.coralOrange, size: 28),
            tooltip: AppLocalizations.of(context)!.startWorkout,
            onPressed: () => context.go('/training/active'),
          ),
        ],
      ),
      body: daysAsync.when(
        data: (days) {
          if (days.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noTrainingDays,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (ctx, i) => _DayCard(
              day: days[i],
              dayNumber: i + 1,
              onStartWorkout: () => context.go('/training/active'),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.coralOrange)),
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.error}: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: GradientButton(
          label: AppLocalizations.of(context)!.startWorkout,
          onPressed: () => context.go('/training/active'),
        ),
      ),
    );
  }
}

class _DayCard extends ConsumerWidget {
  final WorkoutDay day;
  final int dayNumber;
  final VoidCallback onStartWorkout;

  const _DayCard({
    required this.day,
    required this.dayNumber,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekDays = AppLocalizations.of(context)!.weekdaysShort.split(',');
    final exercisesAsync = ref.watch(dayExercisesProvider(day.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                    color: TraumColors.coralDim, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    day.dayOfWeek != null
                        ? weekDays[(day.dayOfWeek! - 1).clamp(0, 6)]
                        : '$dayNumber',
                    style: const TextStyle(
                        color: TraumColors.coralOrange,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(day.name,
                    style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_outline_rounded,
                    color: TraumColors.coralOrange, size: 28),
                onPressed: onStartWorkout,
              ),
            ]),
          ),
          // Exercise rows
          exercisesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(
                    AppLocalizations.of(context)!.noExercises,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 13),
                  ),
                );
              }
              return Column(
                children: entries.map((entry) =>
                  _ExerciseRow(dayExercise: entry)
                ).toList(),
              );
            },
            loading: () => const SizedBox(
                height: 32,
                child: Center(child: CircularProgressIndicator(
                    strokeWidth: 2, color: TraumColors.coralOrange))),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ExerciseRow extends ConsumerWidget {
  final WorkoutDayExercise dayExercise;
  const _ExerciseRow({required this.dayExercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(allExercisesStreamProvider);
    return exercisesAsync.when(
      data: (exercises) {
        final exercise = exercises.cast<Exercise?>().firstWhere(
          (e) => e?.id == dayExercise.exerciseId,
          orElse: () => null,
        );
        if (exercise == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(children: [
            ExerciseIcon(muscleGroup: _muscleGroupKey(exercise.muscleGroup), size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(exercise.name,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
            ),
            Text(
              '${dayExercise.defaultSets}x${dayExercise.defaultReps}',
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 12),
            ),
          ]),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

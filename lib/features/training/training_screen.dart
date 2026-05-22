import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/navigation/routes.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final activePlanAsync = ref.watch(activePlanProvider);
    final activePlan = activePlanAsync.valueOrNull;

    final days = activePlan != null
        ? ref.watch(workoutDaysForPlanProvider(activePlan.id)).valueOrNull ?? []
        : <WorkoutDay>[];

    final sessions =
        ref.watch(trainingSessionsThisWeekProvider).valueOrNull ?? [];

    final streak = ref.watch(workoutStreakProvider).valueOrNull ?? 0;

    final recentSets =
        ref.watch(recentTrainingSetsProvider(7)).valueOrNull ?? [];

    final exercises =
        ref.watch(allExercisesStreamProvider).valueOrNull ?? [];

    final totalVolume = recentSets.fold<double>(
      0.0,
      (sum, s) => sum + (s.weightKg ?? 0) * (s.reps ?? 1),
    );

    // Volume per muscle group for chart
    final Map<String, double> muscleVolume = {};
    for (final s in recentSets) {
      if (s.weightKg == null || s.reps == null) continue;
      final ex = exercises.cast<Exercise?>().firstWhere(
          (e) => e?.id == s.exerciseId, orElse: () => null);
      if (ex == null) continue;
      final mg = ex.muscleGroup;
      muscleVolume[mg] = (muscleVolume[mg] ?? 0) + s.weightKg! * s.reps!;
    }
    final sortedMuscles = muscleVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final today = DateTime.now().weekday;
    final WorkoutDay? todayDay = days.where((d) => d.dayOfWeek == today).isNotEmpty
        ? days.firstWhere((d) => d.dayOfWeek == today)
        : null;

    final todayExerciseCount = todayDay != null
        ? (ref.watch(dayExercisesProvider(todayDay.id)).valueOrNull ?? []).length
        : 0;

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        title: Text(l10n.training),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.routines),
        backgroundColor: TraumColors.coralOrange,
        label: Text(
          l10n.createRoutine,
          style: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Week overview section
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                  child: Column(children: [
                    _WeekStrip(
                      plannedDows: days
                          .where((d) => d.dayOfWeek != null)
                          .map((d) => d.dayOfWeek!)
                          .toList(),
                      completedDates:
                          sessions.map((s) => s.startedAt).toList(),
                    ),
                    const SizedBox(height: 14),
                    _StatsRow(
                      completed: sessions.length,
                      planned: days.length,
                      volumeKg: totalVolume,
                      streak: streak,
                    ),
                    const SizedBox(height: 14),
                    _TodayCard(
                        todayDay: todayDay,
                        exerciseCount: todayExerciseCount),
                    const SizedBox(height: 20),
                  ]),
                ),
                TraumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: l10n.muscleGroupVolume,
                        actionLabel: '${l10n.moreLabel} ›',
                        onAction: () => context.push(Routes.muscleHeatmap),
                      ),
                      const SizedBox(height: 12),
                      if (sortedMuscles.isEmpty)
                        Center(
                          child: Text(
                            l10n.noMuscleDataThisWeek,
                            style: const TextStyle(
                              fontSize: 13,
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        )
                      else
                        _MuscleVolumeChart(muscles: sortedMuscles),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TraumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: l10n.myRoutines,
                        actionLabel: '${l10n.all} ›',
                        onAction: () => context.push(Routes.routines),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noRoutinesCreated,
                        style: const TextStyle(
                          fontSize: 13,
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Muscle Volume Chart ──────────────────────────────────────────────────────

class _MuscleVolumeChart extends StatelessWidget {
  final List<MapEntry<String, double>> muscles;

  const _MuscleVolumeChart({required this.muscles});

  @override
  Widget build(BuildContext context) {
    final top = muscles.take(6).toList();
    final maxVol = top.first.value;

    return Column(
      children: top.asMap().entries.map((e) {
        final ratio = maxVol > 0 ? (e.value.value / maxVol).clamp(0.0, 1.0) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(
              width: 72,
              child: Text(
                e.value.key,
                style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: TraumColors.mintGreen.withValues(
                          alpha: 0.5 + 0.5 * ratio),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Text(
                e.value.value >= 1000
                    ? '${(e.value.value / 1000).toStringAsFixed(1)}t'
                    : '${e.value.value.toInt()} kg',
                style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 11,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// ─── Week Strip ───────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  final List<int> plannedDows;
  final List<DateTime> completedDates;

  const _WeekStrip({required this.plannedDows, required this.completedDates});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final labels = AppLocalizations.of(context)!.weekdaysShort.split(',');

    return Row(
      children: List.generate(7, (i) {
        final dow = i + 1;
        final isToday = dow == today;
        final isPlanned = plannedDows.contains(dow);
        final isCompleted = completedDates.any((d) => d.weekday == dow);

        Color dotColor;
        if (isCompleted) {
          dotColor = TraumColors.mintGreen;
        } else if (isPlanned) {
          dotColor = TraumColors.coralOrange;
        } else {
          dotColor = TraumColors.surfaceVariant;
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isToday
                  ? TraumColors.coralOrange.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(
                      color: TraumColors.coralOrange.withValues(alpha: 0.4))
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  labels[i],
                  style: TextStyle(
                      color: isToday
                          ? TraumColors.coralOrange
                          : TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 12),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: dotColor, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int completed;
  final int planned;
  final double volumeKg;
  final int streak;

  const _StatsRow({
    required this.completed,
    required this.planned,
    required this.volumeKg,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String volLabel;
    if (volumeKg >= 1000) {
      volLabel = '${(volumeKg / 1000).toStringAsFixed(1)}t';
    } else {
      volLabel = '${volumeKg.toInt()} kg';
    }

    return Row(children: [
      _StatTile(value: '$completed', label: l10n.completedThisWeek),
      const SizedBox(width: 8),
      _StatTile(value: '$planned', label: l10n.plannedThisWeek),
      const SizedBox(width: 8),
      _StatTile(value: volLabel, label: l10n.weeklyVolume),
      const SizedBox(width: 8),
      _StatTile(
        value: '$streak',
        label: l10n.workoutStreak,
        icon: streak > 0 ? Icons.local_fire_department_rounded : null,
        iconColor: TraumColors.coralOrange,
      ),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _StatTile({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: Column(children: [
          if (icon != null)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: iconColor ?? TraumColors.coralOrange, size: 14),
              const SizedBox(width: 3),
              Text(value,
                  style: TextStyle(
                      color: iconColor ?? TraumColors.coralOrange,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
            ])
          else
            Text(value,
                style: const TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ─── Today Card ───────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final WorkoutDay? todayDay;
  final int exerciseCount;

  const _TodayCard({this.todayDay, required this.exerciseCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (todayDay == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: Row(children: [
          const Icon(Icons.self_improvement_rounded,
              color: TraumColors.onBackgroundMuted, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(l10n.restDay,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ),
          TextButton(
            onPressed: () => context.go(Routes.activeWorkout),
            child: Text(l10n.freeTraining,
                style: const TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontSize: 13)),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.coralOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border:
            Border.all(color: TraumColors.coralOrange.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(todayDay!.name,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 3),
              Text(AppLocalizations.of(context)!.exercisesToday(exerciseCount),
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
            ],
          ),
        ),
        FilledButton(
          onPressed: () => context.go(Routes.activeWorkout),
          style: FilledButton.styleFrom(
            backgroundColor: TraumColors.coralOrange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TraumRadius.button)),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: Text(l10n.startWorkout,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ]),
    );
  }
}

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
import 'muscle_groups.dart';
import 'widgets/body_map_widget.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final activePlanAsync = ref.watch(activePlanProvider);
    final activePlan = activePlanAsync.value;

    final days = activePlan != null
        ? ref.watch(workoutDaysForPlanProvider(activePlan.id)).value ?? []
        : <WorkoutDay>[];

    final sessions = ref.watch(trainingSessionsThisWeekProvider).value ?? [];

    final streak = ref.watch(workoutStreakProvider).value ?? 0;

    final recentSets = ref.watch(recentTrainingSetsProvider(7)).value ?? [];

    final exercises = ref.watch(allExercisesStreamProvider).value ?? [];

    final sessions72h = ref.watch(sessionsLast72hProvider).value ?? [];

    final recentSets72h = ref.watch(recentTrainingSetsProvider(3)).value ?? [];

    final plans = ref.watch(allWorkoutPlansStreamProvider).value ?? [];

    final totalVolume = recentSets.fold<double>(
      0.0,
      (sum, s) => sum + (s.weightKg ?? 0) * (s.reps ?? 1),
    );

    // Heat map: muscle -> most recent session time
    final sessionById = {for (final s in sessions72h) s.id: s};
    final Map<String, DateTime> muscleLastTrainedAt = {};
    for (final set in recentSets72h) {
      final session = sessionById[set.sessionId];
      if (session == null) continue;
      final ex = exercises.cast<Exercise?>().firstWhere(
        (e) => e?.id == set.exerciseId,
        orElse: () => null,
      );
      if (ex == null) continue;
      final muscles = BodyMapWidget.musclesForGroup(
        canonicalMuscleGroup(ex.muscleGroup),
      );
      for (final muscle in muscles) {
        final existing = muscleLastTrainedAt[muscle];
        if (existing == null || session.startedAt.isAfter(existing)) {
          muscleLastTrainedAt[muscle] = session.startedAt;
        }
      }
    }

    final today = DateTime.now().weekday;
    final WorkoutDay? todayDay =
        days.where((d) => d.dayOfWeek == today).isNotEmpty
        ? days.firstWhere((d) => d.dayOfWeek == today)
        : null;

    final todayExerciseCount = todayDay != null
        ? (ref.watch(dayExercisesProvider(todayDay.id)).value ?? []).length
        : 0;

    // Last completed session time label
    final completedSessions =
        sessions72h.where((s) => s.completedAt != null).toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final lastSession = completedSessions.isNotEmpty
        ? completedSessions.first
        : null;

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        title: Text(
          l10n.training,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: TraumColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
              color: TraumColors.onBackgroundMuted,
            ),
            onPressed: () => context.push(Routes.workoutHistory),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.activeWorkout),
        backgroundColor: TraumColors.coralOrange,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Last workout subtitle
                if (lastSession != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      _lastWorkoutLabel(lastSession.startedAt, l10n),
                      style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                // Week strip
                _WeekStrip(
                  plannedDows: days
                      .where((d) => d.dayOfWeek != null)
                      .map((d) => d.dayOfWeek!)
                      .toList(),
                  completedDates: sessions.map((s) => s.startedAt).toList(),
                ),
                const SizedBox(height: 14),

                // Stats row
                _StatsRow(
                  completed: sessions.length,
                  planned: days.length,
                  volumeKg: totalVolume,
                  streak: streak,
                ),
                const SizedBox(height: 14),

                // Today card
                _TodayCard(
                  todayDay: todayDay,
                  exerciseCount: todayExerciseCount,
                ),
                const SizedBox(height: 16),

                // ── Heat Map ──────────────────────────────────────────────
                _HeatMapCard(heatMap: muscleLastTrainedAt, l10n: l10n),
                const SizedBox(height: 12),

                // ── Daily Routines (morning/evening stretching) ──────────
                const _DailyRoutinesCard(),
                const SizedBox(height: 12),

                // ── Routines ──────────────────────────────────────────────
                _RoutinesSection(plans: plans, l10n: l10n),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _lastWorkoutLabel(DateTime dt, AppLocalizations l10n) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Last workout ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Last workout ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Last workout yesterday';
    return 'Last workout ${diff.inDays} days ago';
  }
}

// ─── Heat Map Card ────────────────────────────────────────────────────────────

class _HeatMapCard extends StatelessWidget {
  final Map<String, DateTime> heatMap;
  final AppLocalizations l10n;

  const _HeatMapCard({required this.heatMap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(TraumRadius.card),
      onTap: () => context.push(Routes.muscleHeatmap),
      child: Container(
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.muscleHeatmapTitle,
                    style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '72h',
                  style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Front + Back body maps
            Row(
              children: [
                Expanded(
                  child: BodyMapWidget(
                    primaryMuscles: const [],
                    secondaryMuscles: const [],
                    heatMap: heatMap,
                    showBack: false,
                    height: 180,
                  ),
                ),
                Expanded(
                  child: BodyMapWidget(
                    primaryMuscles: const [],
                    secondaryMuscles: const [],
                    heatMap: heatMap,
                    showBack: true,
                    height: 180,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: const Color(0xFFE97B4A), label: '24h'),
                const SizedBox(width: 16),
                _LegendItem(color: const Color(0xFFA0442A), label: '48h'),
                const SizedBox(width: 16),
                _LegendItem(color: const Color(0xFF5C2116), label: '72h'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─── Daily Routines Card (Morning / Evening) ─────────────────────────────────

class _DailyRoutinesCard extends ConsumerWidget {
  const _DailyRoutinesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final morningPlans =
        ref.watch(routinesByTypeProvider('morning')).value ?? [];
    final eveningPlans =
        ref.watch(routinesByTypeProvider('evening')).value ?? [];

    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dailyRoutines,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          _RoutineSlotRow(
            icon: Icons.wb_sunny_rounded,
            iconColor: TraumColors.amberGold,
            label: l10n.morningRoutine,
            planType: 'morning',
            plan: morningPlans.isNotEmpty ? morningPlans.first : null,
          ),
          const SizedBox(height: 14),
          _RoutineSlotRow(
            icon: Icons.nightlight_round,
            iconColor: TraumColors.lavender,
            label: l10n.eveningRoutine,
            planType: 'evening',
            plan: eveningPlans.isNotEmpty ? eveningPlans.first : null,
          ),
        ],
      ),
    );
  }
}

class _RoutineSlotRow extends ConsumerWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String planType;
  final WorkoutPlan? plan;

  const _RoutineSlotRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.planType,
    required this.plan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plan = this.plan;

    WorkoutDay? day;
    int exerciseCount = 0;
    if (plan != null) {
      final days = ref.watch(workoutDaysForPlanProvider(plan.id)).value ?? [];
      day = days.isNotEmpty ? days.first : null;
      if (day != null) {
        exerciseCount =
            (ref.watch(dayExercisesProvider(day.id)).value ?? []).length;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                plan != null
                    ? '${plan.name} · $exerciseCount ${l10n.exercises}'
                    : l10n.noRoutinesYet,
                style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (plan != null && day != null)
          TextButton(
            onPressed: () =>
                context.push(Routes.activeWorkoutPath(dayId: day!.id)),
            style: TextButton.styleFrom(
              backgroundColor: iconColor.withValues(alpha: 0.15),
              foregroundColor: iconColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TraumRadius.button),
              ),
            ),
            child: Text(
              l10n.startRoutine,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          )
        else
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: iconColor),
            onPressed: () =>
                context.push(Routes.newRoutinePath(type: planType)),
          ),
      ],
    );
  }
}

// ─── Routines Section ─────────────────────────────────────────────────────────

class _RoutinesSection extends StatelessWidget {
  final List<WorkoutPlan> plans;
  final AppLocalizations l10n;

  const _RoutinesSection({required this.plans, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.myRoutines,
                  style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push(Routes.routines),
                child: Text(
                  '${l10n.all} ›',
                  style: const TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (plans.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5),
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noRoutines,
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.tapToCreateRoutine,
                        style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...plans
              .take(3)
              .map(
                (plan) => _RoutineCard(
                  plan: plan,
                  onTap: () => context.go('/training/plan/${plan.id}'),
                ),
              ),
        if (plans.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () => context.push(Routes.routines),
              child: Center(
                child: Text(
                  '${l10n.all} (${plans.length}) ›',
                  style: const TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback onTap;

  const _RoutineCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: plan.isActive
                ? TraumColors.coralOrange.withValues(alpha: 0.4)
                : TraumColors.surfaceVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: plan.isActive
                    ? TraumColors.coralDim
                    : TraumColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                color: plan.isActive
                    ? TraumColors.coralOrange
                    : TraumColors.onBackgroundMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (plan.description != null)
                    Text(
                      plan.description!,
                      style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (plan.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TraumColors.coralDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Active',
                  style: const TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: TraumColors.onBackgroundSubtle,
                size: 20,
              ),
          ],
        ),
      ),
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
        final isCompleted = completedDates.any((d) => d.weekday == dow);
        final isPlanned = plannedDows.contains(dow);

        return Expanded(
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
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? TraumColors.coralOrange
                      : isToday
                      ? TraumColors.coralOrange.withValues(alpha: 0.15)
                      : isPlanned
                      ? TraumColors.surfaceVariant
                      : TraumColors.surfaceVariant.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: isToday && !isCompleted
                      ? Border.all(color: TraumColors.coralOrange, width: 1.5)
                      : null,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : isPlanned && !isToday
                    ? null
                    : null,
              ),
            ],
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

    return Row(
      children: [
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
      ],
    );
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
        child: Column(
          children: [
            if (icon != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? TraumColors.coralOrange,
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: iconColor ?? TraumColors.coralOrange,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              )
            else
              Text(
                value,
                style: const TextStyle(
                  color: TraumColors.coralOrange,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
        child: Row(
          children: [
            const Icon(
              Icons.self_improvement_rounded,
              color: TraumColors.onBackgroundMuted,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.restDay,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(Routes.activeWorkout),
              child: Text(
                l10n.freeTraining,
                style: const TextStyle(
                  color: TraumColors.coralOrange,
                  fontFamily: 'DMSans',
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.coralOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(
          color: TraumColors.coralOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todayDay!.name,
                  style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLocalizations.of(context)!.exercisesToday(exerciseCount),
                  style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => context.go(Routes.activeWorkout),
            style: FilledButton.styleFrom(
              backgroundColor: TraumColors.coralOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TraumRadius.button),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              l10n.startWorkout,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/components/components.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart'
    show Exercise, WorkoutDay, WorkoutSession, WorkoutSet;
import '../home_tile.dart';
import '../home_widget_frame.dart';
import '../home_widget_registry.dart';

// ─── One-shot snapshot providers ─────────────────────────────────────────────
// These read via DAO `getX()` methods (not drift `.watch()` streams) so no
// query-stream close timer lingers after the widget tree is disposed in tests.

/// All exercises, one-shot (mirrors `allExercisesStreamProvider` without the
/// stream timer). Used to map sets → muscle groups.
final _exercisesSnapshotProvider =
    FutureProvider.autoDispose<List<Exercise>>((ref) async {
  return ref.watch(trainingDaoProvider).getAllExercisesOnce();
});

/// Days of the currently active plan, one-shot.
final _activePlanDaysProvider =
    FutureProvider.autoDispose<List<WorkoutDay>>((ref) async {
  final plan = await ref.watch(activePlanProvider.future);
  if (plan == null) return const [];
  return ref.watch(trainingDaoProvider).getDaysForPlan(plan.id);
});

/// Recent workout sessions (last ~365 days), one-shot, ordered desc.
final _recentSessionsProvider =
    FutureProvider.autoDispose<List<WorkoutSession>>((ref) async {
  final cutoff = DateTime.now().subtract(const Duration(days: 365));
  final sessions =
      await ref.watch(trainingDaoProvider).getSessionsAfter(cutoff);
  sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return sessions;
});

final Map<HomeWidgetType, HomeWidgetDescriptor> trainingHomeWidgets = {
  HomeWidgetType.nextWorkout: HomeWidgetDescriptor(
    title: 'Nächstes Workout',
    group: HomeWidgetGroup.training,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: Routes.training,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Nächstes Workout',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.training,
      child: const _NextWorkoutContent(),
    ),
  ),
  HomeWidgetType.weeklyVolume: HomeWidgetDescriptor(
    title: 'Wochen-Volumen',
    group: HomeWidgetGroup.training,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.training,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Wochen-Volumen',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.training,
      child: const _WeeklyVolumeContent(),
    ),
  ),
  HomeWidgetType.muscleHeatmap: HomeWidgetDescriptor(
    title: 'Muskeln',
    group: HomeWidgetGroup.training,
    accent: TraumColors.roseRed,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.training,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Muskeln',
      accent: TraumColors.roseRed,
      size: size,
      route: Routes.training,
      child: const _MuscleHeatmapContent(),
    ),
  ),
  HomeWidgetType.lastWorkout: HomeWidgetDescriptor(
    title: 'Letztes Workout',
    group: HomeWidgetGroup.training,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.training,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Letztes Workout',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.training,
      child: const _LastWorkoutContent(),
    ),
  ),
  HomeWidgetType.trainingStreak: HomeWidgetDescriptor(
    title: 'Trainings-Streak',
    group: HomeWidgetGroup.training,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.training,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Trainings-Streak',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.training,
      child: const _TrainingStreakContent(),
    ),
  ),
  HomeWidgetType.weeklyWorkouts: HomeWidgetDescriptor(
    title: 'Wochen-Workouts',
    group: HomeWidgetGroup.training,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.training,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Wochen-Workouts',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.training,
      child: const _WeeklyWorkoutsContent(),
    ),
  ),
  HomeWidgetType.personalRecords: HomeWidgetDescriptor(
    title: 'Rekorde',
    group: HomeWidgetGroup.training,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: Routes.training,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Rekorde',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.training,
      child: const _PersonalRecordsContent(),
    ),
  ),
  HomeWidgetType.restTimerQuick: HomeWidgetDescriptor(
    title: 'Rest-Timer',
    group: HomeWidgetGroup.training,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.training,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Rest-Timer',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.training,
      child: const _RestTimerQuickContent(),
    ),
  ),
};

// ─── Shared display helpers ──────────────────────────────────────────────────
class _EmptyDash extends StatelessWidget {
  const _EmptyDash();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '—',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: TraumColors.onBackgroundMuted,
        fontFamily: 'DMSans',
      ),
    );
  }
}

class _ValueUnit extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  const _ValueUnit({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';

// ─── Next workout ─────────────────────────────────────────────────────────────
class _NextWorkoutContent extends ConsumerWidget {
  const _NextWorkoutContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider).value;
    final days = ref.watch(_activePlanDaysProvider).value;

    if (plan == null || days == null || days.isEmpty) {
      return const Center(child: _EmptyDash());
    }

    // Prefer the day matching today's weekday, else the first day by sortOrder.
    final today = DateTime.now().weekday; // 1=Mon..7=Sun
    final ordered = [...days]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final WorkoutDay day = ordered.firstWhere(
      (d) => d.dayOfWeek == today,
      orElse: () => ordered.first,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          plan.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Weekly volume ────────────────────────────────────────────────────────────
class _WeeklyVolumeContent extends ConsumerWidget {
  const _WeeklyVolumeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sets logged in the last 7 days as the week's volume metric.
    final sets = ref.watch(recentTrainingSetsProvider(7)).value;
    if (sets == null) {
      return const _ValueUnit(
        value: '0',
        unit: 'Sätze',
        color: TraumColors.amberGold,
      );
    }
    final working = sets.where((s) => !s.isWarmup).length;
    return _ValueUnit(
      value: '$working',
      unit: working == 1 ? 'Satz' : 'Sätze',
      color: TraumColors.amberGold,
    );
  }
}

// ─── Muscle heatmap (simple bars per group) ──────────────────────────────────
class _MuscleHeatmapContent extends ConsumerWidget {
  const _MuscleHeatmapContent();

  static const _muscleGroups = [
    'Brust',
    'Rücken',
    'Schulter',
    'Beine',
    'Arme',
    'Bauch',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(recentTrainingSetsProvider(7)).value;
    final exercises = ref.watch(_exercisesSnapshotProvider).value;

    if (sets == null || exercises == null || sets.isEmpty) {
      return const Center(
        child: Text(
          'Noch keine Daten',
          style: TextStyle(
            fontSize: 13,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      );
    }

    final byId = {for (final e in exercises) e.id: e};
    // Count working sets per raw muscle group, then collapse to display groups.
    final counts = <String, int>{};
    for (final s in sets) {
      if (s.isWarmup) continue;
      final ex = byId[s.exerciseId];
      if (ex == null) continue;
      final group = _displayGroup(ex.muscleGroup);
      counts[group] = (counts[group] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return const Center(
        child: Text(
          'Noch keine Daten',
          style: TextStyle(
            fontSize: 13,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      );
    }
    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in _muscleGroups)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _MuscleBar(
              label: group,
              count: counts[group] ?? 0,
              value: maxCount > 0 ? (counts[group] ?? 0) / maxCount : 0.0,
            ),
          ),
      ],
    );
  }

  static String _displayGroup(String raw) {
    switch (raw) {
      case 'Bizeps':
      case 'Trizeps':
      case 'Unterarme':
        return 'Arme';
      case 'Gesäß':
      case 'Waden':
        return 'Beine';
      default:
        return raw;
    }
  }
}

class _MuscleBar extends StatelessWidget {
  final String label;
  final int count;
  final double value;
  const _MuscleBar({
    required this.label,
    required this.count,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        Expanded(
          child: GradientProgressBar(
            value: value.clamp(0.0, 1.0),
            height: 6,
            gradient: const LinearGradient(
              colors: [TraumColors.roseRed, TraumColors.roseRed],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 22,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Last workout ─────────────────────────────────────────────────────────────
class _LastWorkoutContent extends ConsumerWidget {
  const _LastWorkoutContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(_recentSessionsProvider).value;
    if (sessions == null || sessions.isEmpty) {
      return const Center(child: _EmptyDash());
    }
    final last = sessions.first;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatDate(last.startedAt),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: TraumColors.mintGreen,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _relativeLabel(last.startedAt),
          style: const TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }

  static String _relativeLabel(DateTime d) {
    final now = DateTime.now();
    final days =
        DateTime(now.year, now.month, now.day).difference(
          DateTime(d.year, d.month, d.day),
        ).inDays;
    if (days <= 0) return 'Heute';
    if (days == 1) return 'Gestern';
    return 'vor $days Tagen';
  }
}

// ─── Training streak (consecutive weeks with ≥1 workout) ──────────────────────
class _TrainingStreakContent extends ConsumerWidget {
  const _TrainingStreakContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(_recentSessionsProvider).value;
    if (sessions == null || sessions.isEmpty) {
      return const _ValueUnit(
        value: '0',
        unit: 'Wochen',
        color: TraumColors.amberGold,
      );
    }

    // Set of ISO week-start (Monday) dates that have at least one session.
    final weekStarts = <DateTime>{};
    for (final s in sessions) {
      weekStarts.add(_weekStart(s.startedAt));
    }

    var streak = 0;
    var cursor = _weekStart(DateTime.now());
    // Allow the current week to be empty (streak continues from last week).
    if (!weekStarts.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 7));
    }
    while (weekStarts.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 7));
    }

    return _ValueUnit(
      value: '$streak',
      unit: streak == 1 ? 'Woche' : 'Wochen',
      color: TraumColors.amberGold,
    );
  }

  static DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}

// ─── Weekly workouts ──────────────────────────────────────────────────────────
class _WeeklyWorkoutsContent extends ConsumerWidget {
  const _WeeklyWorkoutsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(trainingSessionsThisWeekProvider).value;
    final count = sessions?.length ?? 0;
    return _ValueUnit(
      value: '$count',
      unit: count == 1 ? 'Workout' : 'Workouts',
      color: TraumColors.cyanBlue,
    );
  }
}

// ─── Personal records (top weight per exercise, last 365 days) ────────────────
class _PersonalRecordsContent extends ConsumerWidget {
  const _PersonalRecordsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(recentTrainingSetsProvider(365)).value;
    final exercises = ref.watch(_exercisesSnapshotProvider).value;

    if (sets == null || exercises == null) {
      return const Center(child: _EmptyDash());
    }

    final byId = {for (final e in exercises) e.id: e};
    // Best weight per exercise.
    final best = <int, WorkoutSet>{};
    for (final s in sets) {
      final w = s.weightKg;
      if (w == null || w <= 0) continue;
      final cur = best[s.exerciseId];
      if (cur == null || (cur.weightKg ?? 0) < w) {
        best[s.exerciseId] = s;
      }
    }
    if (best.isEmpty) {
      return const Center(child: _EmptyDash());
    }

    final entries = best.entries.toList()
      ..sort((a, b) => (b.value.weightKg ?? 0).compareTo(a.value.weightKg ?? 0));
    final top = entries.take(3).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in top)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    byId[e.key]?.name ?? 'Übung',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(e.value.weightKg ?? 0).toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TraumColors.amberGold,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Rest timer quick (inline countdown) ──────────────────────────────────────
class _RestTimerQuickContent extends StatefulWidget {
  const _RestTimerQuickContent();

  @override
  State<_RestTimerQuickContent> createState() => _RestTimerQuickContentState();
}

class _RestTimerQuickContentState extends State<_RestTimerQuickContent> {
  static const int _defaultSeconds = 90;
  int _remaining = _defaultSeconds;
  Timer? _timer;

  bool get _running => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _timer = null);
      return;
    }
    if (_remaining <= 0) _remaining = _defaultSeconds;
    setState(() {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remaining <= 1) {
          t.cancel();
          setState(() {
            _remaining = 0;
            _timer = null;
          });
        } else {
          setState(() => _remaining--);
        }
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _timer = null;
      _remaining = _defaultSeconds;
    });
  }

  String get _label {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final showCountdown = _running || _remaining != _defaultSeconds;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _toggle,
          onLongPress: _reset,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TraumColors.mintGreen.withValues(alpha: 0.15),
              border: Border.all(color: TraumColors.mintGreen, width: 2),
            ),
            child: Icon(
              _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: TraumColors.mintGreen,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          showCountdown ? _label : 'Start',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TraumColors.mintGreen,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

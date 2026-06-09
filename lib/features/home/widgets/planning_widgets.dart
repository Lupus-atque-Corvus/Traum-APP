import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart'
    show Appointment, Habit, HabitLog, Medication, Todo;
import '../home_tile.dart';
import '../home_widget_frame.dart';
import '../home_widget_registry.dart';

// ─── One-shot providers (plain queries, no .watch() stream) ─────────────────
final _todosSnapshotProvider =
    FutureProvider.autoDispose<List<Todo>>((ref) {
  return ref.watch(planningDaoProvider).getAllTodos();
});

final _todayAppointmentsProvider =
    FutureProvider.autoDispose<List<Appointment>>((ref) {
  return ref.watch(planningDaoProvider).getAppointmentsForDate(DateTime.now());
});

final _nextAppointmentProvider =
    FutureProvider.autoDispose<Appointment?>((ref) {
  return ref.watch(planningDaoProvider).getNextAppointment();
});

final _habitsSnapshotProvider =
    FutureProvider.autoDispose<List<Habit>>((ref) {
  return ref.watch(planningDaoProvider).getAllHabits();
});

final _habitLogsTodayProvider =
    FutureProvider.autoDispose<List<HabitLog>>((ref) {
  return ref.watch(planningDaoProvider).getHabitLogsForDate(DateTime.now());
});

final _recentHabitLogsProvider =
    FutureProvider.autoDispose<List<HabitLog>>((ref) {
  return ref.watch(planningDaoProvider).getRecentHabitLogs();
});

final _activeMedicationsProvider =
    FutureProvider.autoDispose<List<Medication>>((ref) {
  return ref.watch(medicationDaoProvider).getActiveMedications();
});

final Map<HomeWidgetType, HomeWidgetDescriptor> planningHomeWidgets = {
  HomeWidgetType.openTodos: HomeWidgetDescriptor(
    title: 'Offene Todos',
    group: HomeWidgetGroup.planning,
    accent: TraumColors.lavender,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.small, HomeTileSize.wide},
    route: Routes.planning,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Offene Todos',
      accent: TraumColors.lavender,
      size: size,
      route: Routes.planning,
      child: _OpenTodosContent(size: size),
    ),
  ),
  HomeWidgetType.todayAppointments: HomeWidgetDescriptor(
    title: 'Heute',
    group: HomeWidgetGroup.planning,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: Routes.planning,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Heute',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.planning,
      child: const _TodayAppointmentsContent(),
    ),
  ),
  HomeWidgetType.habitsToday: HomeWidgetDescriptor(
    title: 'Gewohnheiten',
    group: HomeWidgetGroup.planning,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.small, HomeTileSize.wide},
    route: Routes.planning,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Gewohnheiten',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.planning,
      child: _HabitsTodayContent(size: size),
    ),
  ),
  HomeWidgetType.medicationsToday: HomeWidgetDescriptor(
    title: 'Medikamente',
    group: HomeWidgetGroup.planning,
    accent: TraumColors.roseRed,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.medication,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Medikamente',
      accent: TraumColors.roseRed,
      size: size,
      route: Routes.medication,
      child: const _MedicationsTodayContent(),
    ),
  ),
  HomeWidgetType.nextAppointmentCountdown: HomeWidgetDescriptor(
    title: 'Nächster Termin',
    group: HomeWidgetGroup.planning,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.planning,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Nächster Termin',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.planning,
      child: const _NextAppointmentCountdownContent(),
    ),
  ),
  HomeWidgetType.overdueTodos: HomeWidgetDescriptor(
    title: 'Überfällig',
    group: HomeWidgetGroup.planning,
    accent: TraumColors.roseRed,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.planning,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Überfällig',
      accent: TraumColors.roseRed,
      size: size,
      route: Routes.planning,
      child: const _OverdueTodosContent(),
    ),
  ),
  HomeWidgetType.bestHabitStreak: HomeWidgetDescriptor(
    title: 'Beste Serie',
    group: HomeWidgetGroup.planning,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.planning,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Beste Serie',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.planning,
      child: const _BestHabitStreakContent(),
    ),
  ),
};

// ─── Shared display helpers ─────────────────────────────────────────────────
class _BigCount extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  const _BigCount({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '—';
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
              color: isEmpty ? TraumColors.onBackgroundMuted : color,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

class _EmptyLabel extends StatelessWidget {
  final String text;
  const _EmptyLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13,
        color: TraumColors.onBackgroundMuted,
        fontFamily: 'DMSans',
      ),
    );
  }
}

// ─── Open todos ─────────────────────────────────────────────────────────────
class _OpenTodosContent extends ConsumerWidget {
  final HomeTileSize size;
  const _OpenTodosContent({required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(_todosSnapshotProvider).value;
    final open = (todos ?? []).where((t) => !t.done).toList();

    if (open.isEmpty) {
      return const _EmptyLabel('Keine');
    }

    if (size == HomeTileSize.small) {
      return _BigCount(
        value: '${open.length}',
        unit: open.length == 1 ? 'Todo' : 'Todos',
        color: TraumColors.lavender,
      );
    }

    final preview = open.take(3).toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${open.length} offen',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TraumColors.lavender,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 6),
        for (final t in preview)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 5, color: TraumColors.lavender),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Today's appointments ─────────────────────────────────────────────────────
class _TodayAppointmentsContent extends ConsumerWidget {
  const _TodayAppointmentsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appts = ref.watch(_todayAppointmentsProvider).value;
    if (appts == null || appts.isEmpty) {
      return const _EmptyLabel('Keine Termine');
    }

    final preview = appts.take(3).toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in preview)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                Text(
                  a.allDay ? '—' : _hhmm(a.startTime),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TraumColors.cyanBlue,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Habits today ─────────────────────────────────────────────────────────────
class _HabitsTodayContent extends ConsumerWidget {
  final HomeTileSize size;
  const _HabitsTodayContent({required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(_habitsSnapshotProvider).value;
    final todayLogs = ref.watch(_habitLogsTodayProvider).value;

    final total = habits?.length ?? 0;
    if (total == 0) {
      return const _EmptyLabel('—');
    }

    final doneIds = (todayLogs ?? [])
        .where((l) => l.done)
        .map((l) => l.habitId)
        .toSet();
    final done = doneIds.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$done',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.mintGreen,
                  fontFamily: 'DMSans',
                ),
              ),
              TextSpan(
                text: ' / $total',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'heute erledigt',
          style: TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
        if (size == HomeTileSize.wide && total > 0) ...[
          const SizedBox(height: 8),
          _HabitDots(done: done, total: total),
        ],
      ],
    );
  }
}

class _HabitDots extends StatelessWidget {
  final int done;
  final int total;
  const _HabitDots({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final count = total > 7 ? 7 : total;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              i < done ? Icons.circle : Icons.circle_outlined,
              size: 9,
              color: i < done
                  ? TraumColors.mintGreen
                  : TraumColors.onBackgroundMuted,
            ),
          ),
      ],
    );
  }
}

// ─── Medications today ────────────────────────────────────────────────────────
class _MedicationsTodayContent extends ConsumerWidget {
  const _MedicationsTodayContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(_activeMedicationsProvider).value;
    final dueToday = (meds ?? [])
        .where((m) => m.timings.trim().isNotEmpty && m.timings.trim() != '[]')
        .length;

    if (dueToday == 0) {
      return const _EmptyLabel('Keine');
    }
    return _BigCount(
      value: '$dueToday',
      unit: 'heute fällig',
      color: TraumColors.roseRed,
    );
  }
}

// ─── Next appointment countdown ────────────────────────────────────────────────
class _NextAppointmentCountdownContent extends ConsumerWidget {
  const _NextAppointmentCountdownContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(_nextAppointmentProvider).value;
    if (next == null) {
      return const _EmptyLabel('—');
    }
    final diff = next.startTime.difference(DateTime.now());
    String value;
    String unit;
    if (diff.inMinutes < 0) {
      value = 'jetzt';
      unit = '';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      if (h < 1) {
        value = 'in ${diff.inMinutes}';
        unit = diff.inMinutes == 1 ? 'Minute' : 'Minuten';
      } else {
        value = 'in $h';
        unit = h == 1 ? 'Stunde' : 'Stunden';
      }
    } else {
      final d = diff.inDays;
      value = 'in $d';
      unit = d == 1 ? 'Tag' : 'Tagen';
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: TraumColors.cyanBlue,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 11,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          next.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Overdue todos ──────────────────────────────────────────────────────────────
class _OverdueTodosContent extends ConsumerWidget {
  const _OverdueTodosContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(_todosSnapshotProvider).value;
    final now = DateTime.now();
    final overdue = (todos ?? [])
        .where((t) =>
            !t.done && t.dueDate != null && t.dueDate!.isBefore(now))
        .length;

    return _BigCount(
      value: '$overdue',
      unit: 'überfällig',
      color: TraumColors.roseRed,
    );
  }
}

// ─── Best habit streak ──────────────────────────────────────────────────────────
class _BestHabitStreakContent extends ConsumerWidget {
  const _BestHabitStreakContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(_habitsSnapshotProvider).value;
    final logs = ref.watch(_recentHabitLogsProvider).value;

    if (habits == null || habits.isEmpty || logs == null) {
      return const _EmptyLabel('—');
    }

    // For each habit, count consecutive days ending today (or yesterday) with a
    // completed log. Best current streak across all habits wins.
    final byHabit = <int, Set<int>>{};
    for (final l in logs) {
      if (!l.done) continue;
      final d = l.logDate;
      final dayKey = DateTime(d.year, d.month, d.day)
          .difference(DateTime(2000))
          .inDays;
      (byHabit[l.habitId] ??= {}).add(dayKey);
    }

    final now = DateTime.now();
    final todayKey =
        DateTime(now.year, now.month, now.day).difference(DateTime(2000)).inDays;

    var best = 0;
    for (final days in byHabit.values) {
      // Streak may end today or yesterday (today not yet logged).
      final start = days.contains(todayKey)
          ? todayKey
          : (days.contains(todayKey - 1) ? todayKey - 1 : null);
      if (start == null) continue;
      var anchor = start;
      var streak = 0;
      while (days.contains(anchor)) {
        streak++;
        anchor -= 1;
      }
      if (streak > best) best = streak;
    }

    if (best == 0) {
      return _BigCount(
        value: '0',
        unit: 'Tage',
        color: TraumColors.amberGold,
      );
    }
    return _BigCount(
      value: '$best',
      unit: best == 1 ? 'Tag' : 'Tage',
      color: TraumColors.amberGold,
    );
  }
}

String _hhmm(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

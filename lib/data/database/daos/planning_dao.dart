import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'planning_dao.g.dart';

@DriftAccessor(tables: [Appointments, Todos, Goals, SubTasks, Habits, HabitLogs])
class PlanningDao extends DatabaseAccessor<TraumDatabase>
    with _$PlanningDaoMixin {
  PlanningDao(super.db);

  // Appointments
  Stream<List<Appointment>> watchAllAppointments() =>
      select(appointments).watch();

  Stream<List<Appointment>> watchAppointmentsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(appointments)
          ..where((t) =>
              t.startTime.isBiggerOrEqualValue(start) &
              t.startTime.isSmallerThanValue(end)))
        .watch();
  }

  Future<List<Appointment>> getAllAppointments() => select(appointments).get();

  /// One-shot list of appointments for [date] (used by home widgets).
  Future<List<Appointment>> getAppointmentsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(appointments)
          ..where((t) =>
              t.startTime.isBiggerOrEqualValue(start) &
              t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  /// One-shot next upcoming appointment from [from] (used by home widgets).
  Future<Appointment?> getNextAppointment([DateTime? from]) {
    final ref = from ?? DateTime.now();
    return (select(appointments)
          ..where((t) => t.startTime.isBiggerOrEqualValue(ref))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Appointment?> getAppointmentById(int id) =>
      (select(appointments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertAppointment(AppointmentsCompanion entry) =>
      into(appointments).insert(entry);

  Future<bool> updateAppointment(AppointmentsCompanion entry) =>
      update(appointments).replace(
        entry.copyWith(updatedAt: Value(DateTime.now())),
      );

  Future<void> updateExternalEventId(int id, String? externalEventId) =>
      (update(appointments)..where((t) => t.id.equals(id))).write(
        AppointmentsCompanion(
          externalEventId: Value(externalEventId),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> deleteAppointment(int id) =>
      (delete(appointments)..where((t) => t.id.equals(id))).go();

  // Reserved for CalendarSyncService conflict resolution — not yet called because
  // device_calendar v4.x does not expose lastModifiedDate. Will be used when upgrading
  // to a version that provides per-event modification timestamps.
  Future<void> updateAppointmentFromDevice({
    required int id,
    required String title,
    String? description,
    String? location,
    required DateTime startTime,
    DateTime? endTime,
    required bool allDay,
    required DateTime updatedAt,
  }) =>
      (update(appointments)..where((t) => t.id.equals(id))).write(
        AppointmentsCompanion(
          title: Value(title),
          description: Value(description),
          location: Value(location),
          startTime: Value(startTime),
          endTime: Value(endTime),
          allDay: Value(allDay),
          updatedAt: Value(updatedAt),
        ),
      );

  // Todos
  Stream<List<Todo>> watchAllTodos() =>
      (select(todos)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  /// One-shot list of all todos (used by home widgets).
  Future<List<Todo>> getAllTodos() =>
      (select(todos)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<int> insertTodo(TodosCompanion entry) => into(todos).insert(entry);

  Future<bool> updateTodo(TodosCompanion entry) =>
      update(todos).replace(entry);

  Future<int> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  // Goals
  Stream<List<Goal>> watchAllGoals() => select(goals).watch();

  Future<int> insertGoal(GoalsCompanion entry) => into(goals).insert(entry);

  Future<bool> updateGoal(GoalsCompanion entry) =>
      update(goals).replace(entry);

  Future<int> deleteGoal(int id) =>
      (delete(goals)..where((t) => t.id.equals(id))).go();

  // SubTasks
  Stream<List<SubTask>> watchSubTasksForGoal(int goalId) =>
      (select(subTasks)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<int> insertSubTask(SubTasksCompanion entry) =>
      into(subTasks).insert(entry);

  Future<bool> updateSubTask(SubTasksCompanion entry) =>
      update(subTasks).replace(entry);

  Future<int> deleteSubTask(int id) =>
      (delete(subTasks)..where((t) => t.id.equals(id))).go();

  // Habits
  Stream<List<Habit>> watchAllHabits() => select(habits).watch();

  /// One-shot list of all habits (used by home widgets).
  Future<List<Habit>> getAllHabits() => select(habits).get();

  Future<int> insertHabit(HabitsCompanion entry) => into(habits).insert(entry);

  Future<bool> updateHabit(HabitsCompanion entry) =>
      update(habits).replace(entry);

  Future<int> deleteHabit(int id) =>
      (delete(habits)..where((t) => t.id.equals(id))).go();

  // HabitLogs
  Stream<List<HabitLog>> watchHabitLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(habitLogs)
          ..where((t) =>
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerThanValue(end)))
        .watch();
  }

  /// One-shot completed habit logs for [date] (used by home widgets).
  Future<List<HabitLog>> getHabitLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(habitLogs)
          ..where((t) =>
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerThanValue(end)))
        .get();
  }

  /// One-shot habit logs from the last [days] days across all habits (used by
  /// home widgets for streak computation).
  Future<List<HabitLog>> getRecentHabitLogs({int days = 60}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final start = DateTime(cutoff.year, cutoff.month, cutoff.day);
    return (select(habitLogs)..where((t) => t.logDate.isBiggerOrEqualValue(start)))
        .get();
  }

  Future<int> insertHabitLog(HabitLogsCompanion entry) =>
      into(habitLogs).insert(entry);

  Future<int> deleteHabitLog(int habitId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (delete(habitLogs)
          ..where((t) =>
              t.habitId.equals(habitId) &
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerThanValue(end)))
        .go();
  }

  Future<List<HabitLog>> getHabitLogsForLast7Days(int habitId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return (select(habitLogs)
          ..where((t) =>
              t.habitId.equals(habitId) &
              t.logDate.isBiggerOrEqualValue(cutoff)))
        .get();
  }
}

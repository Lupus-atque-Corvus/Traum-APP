import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'planning_dao.g.dart';

@DriftAccessor(tables: [Appointments, Todos, TodoSubItems, Goals, SubTasks, Habits, HabitLogs])
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

  Future<int> insertAppointment(AppointmentsCompanion entry) =>
      into(appointments).insert(entry);

  Future<bool> updateAppointment(AppointmentsCompanion entry) =>
      update(appointments).replace(entry);

  Future<int> deleteAppointment(int id) =>
      (delete(appointments)..where((t) => t.id.equals(id))).go();

  // Todos
  Stream<List<Todo>> watchAllTodos() =>
      (select(todos)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<int> insertTodo(TodosCompanion entry) => into(todos).insert(entry);

  Future<bool> updateTodo(TodosCompanion entry) =>
      update(todos).replace(entry);

  Future<int> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  Stream<List<Todo>> watchTodosByList(String? listName) {
    return (select(todos)
          ..where((t) => listName == null
              ? t.listName.isNull()
              : t.listName.equals(listName))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<String>> getDistinctLists() async {
    final rows = await (select(todos)
          ..where((t) => t.listName.isNotNull()))
        .get();
    return rows.map((r) => r.listName!).toSet().toList()..sort();
  }

  // TodoSubItems
  Stream<List<TodoSubItem>> watchSubItemsForTodo(int todoId) =>
      (select(todoSubItems)
            ..where((t) => t.todoId.equals(todoId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<int> insertSubItem(TodoSubItemsCompanion entry) =>
      into(todoSubItems).insert(entry);

  Future<bool> updateSubItem(TodoSubItemsCompanion entry) =>
      update(todoSubItems).replace(entry);

  Future<int> deleteSubItem(int id) =>
      (delete(todoSubItems)..where((t) => t.id.equals(id))).go();

  Future<int> deleteSubItemsForTodo(int todoId) =>
      (delete(todoSubItems)..where((t) => t.todoId.equals(todoId))).go();

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

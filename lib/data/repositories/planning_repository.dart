import 'package:drift/drift.dart';
import '../database/traum_database.dart';

class PlanningRepository {
  final PlanningDao _dao;
  PlanningRepository(this._dao);

  // Appointments
  Stream<List<Appointment>> watchAllAppointments() =>
      _dao.watchAllAppointments();
  Stream<List<Appointment>> watchAppointmentsForDate(DateTime date) =>
      _dao.watchAppointmentsForDate(date);
  Future<int> addAppointment(AppointmentsCompanion entry) =>
      _dao.insertAppointment(entry);
  Future<bool> updateAppointment(AppointmentsCompanion entry) =>
      _dao.updateAppointment(entry);
  Future<int> deleteAppointment(int id) => _dao.deleteAppointment(id);

  // Todos
  Stream<List<Todo>> watchAllTodos() => _dao.watchAllTodos();
  Future<int> addTodo(TodosCompanion entry) => _dao.insertTodo(entry);
  Future<bool> updateTodo(TodosCompanion entry) => _dao.updateTodo(entry);
  Future<int> deleteTodo(int id) => _dao.deleteTodo(id);
  Future<bool> toggleTodo(Todo todo) {
    return _dao.updateTodo(TodosCompanion(
      id: Value(todo.id),
      done: Value(!todo.done),
      completedAt: Value(!todo.done ? DateTime.now() : null),
    ));
  }

  // Goals
  Stream<List<Goal>> watchAllGoals() => _dao.watchAllGoals();
  Future<int> addGoal(GoalsCompanion entry) => _dao.insertGoal(entry);
  Future<bool> updateGoal(GoalsCompanion entry) => _dao.updateGoal(entry);
  Future<int> deleteGoal(int id) => _dao.deleteGoal(id);

  // SubTasks
  Stream<List<SubTask>> watchSubTasksForGoal(int goalId) =>
      _dao.watchSubTasksForGoal(goalId);
  Future<int> addSubTask(SubTasksCompanion entry) => _dao.insertSubTask(entry);
  Future<bool> updateSubTask(SubTasksCompanion entry) =>
      _dao.updateSubTask(entry);
  Future<int> deleteSubTask(int id) => _dao.deleteSubTask(id);

  // Habits
  Stream<List<Habit>> watchAllHabits() => _dao.watchAllHabits();
  Future<int> addHabit(HabitsCompanion entry) => _dao.insertHabit(entry);
  Future<bool> updateHabit(HabitsCompanion entry) => _dao.updateHabit(entry);
  Future<int> deleteHabit(int id) => _dao.deleteHabit(id);

  // HabitLogs
  Stream<List<HabitLog>> watchHabitLogsForDate(DateTime date) =>
      _dao.watchHabitLogsForDate(date);
  Future<void> toggleHabitLog(int habitId, DateTime date, bool done) async {
    if (done) {
      await _dao.insertHabitLog(HabitLogsCompanion(
        habitId: Value(habitId),
        logDate: Value(date),
        done: const Value(true),
      ));
    } else {
      await _dao.deleteHabitLog(habitId, date);
    }
  }
  Future<List<HabitLog>> getHabitLogsForLast7Days(int habitId) =>
      _dao.getHabitLogsForLast7Days(habitId);
}

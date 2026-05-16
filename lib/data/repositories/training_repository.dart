import '../database/traum_database.dart';

class TrainingRepository {
  final TrainingDao _dao;
  TrainingRepository(this._dao);

  Stream<List<WorkoutPlan>> watchAllPlans() => _dao.watchAllPlans();
  Future<WorkoutPlan?> getActivePlan() => _dao.getActivePlan();
  Future<int> addPlan(WorkoutPlansCompanion e) => _dao.insertPlan(e);
  Future<bool> updatePlan(WorkoutPlansCompanion e) => _dao.updatePlan(e);
  Future<int> deletePlan(int id) => _dao.deletePlan(id);

  Stream<List<WorkoutDay>> watchDaysForPlan(int planId) =>
      _dao.watchDaysForPlan(planId);
  Future<int> addDay(WorkoutDaysCompanion e) => _dao.insertDay(e);
  Future<bool> updateDay(WorkoutDaysCompanion e) => _dao.updateDay(e);
  Future<int> deleteDay(int id) => _dao.deleteDay(id);

  Stream<List<Exercise>> watchAllExercises() => _dao.watchAllExercises();
  Stream<List<Exercise>> watchExercisesByMuscleGroup(String group) =>
      _dao.watchExercisesByMuscleGroup(group);
  Future<int> addExercise(ExercisesCompanion e) => _dao.insertExercise(e);
  Future<bool> updateExercise(ExercisesCompanion e) => _dao.updateExercise(e);
  Future<int> deleteExercise(int id) => _dao.deleteExercise(id);

  Stream<List<WorkoutSession>> watchAllSessions() => _dao.watchAllSessions();
  Future<WorkoutSession?> getSessionById(int id) => _dao.getSessionById(id);
  Future<List<WorkoutSession>> getSessionsThisWeek() =>
      _dao.getSessionsThisWeek();
  Future<int> addSession(WorkoutSessionsCompanion e) => _dao.insertSession(e);
  Future<bool> updateSession(WorkoutSessionsCompanion e) =>
      _dao.updateSession(e);
  Future<int> deleteSession(int id) => _dao.deleteSession(id);

  Stream<List<WorkoutSet>> watchSetsForSession(int sessionId) =>
      _dao.watchSetsForSession(sessionId);
  Future<int> addSet(WorkoutSetsCompanion e) => _dao.insertSet(e);
  Future<bool> updateSet(WorkoutSetsCompanion e) => _dao.updateSet(e);
  Future<int> deleteSet(int id) => _dao.deleteSet(id);
}

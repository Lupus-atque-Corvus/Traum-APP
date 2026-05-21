import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'training_dao.g.dart';

@DriftAccessor(tables: [
  WorkoutPlans, WorkoutDays, Exercises,
  WorkoutSessions, WorkoutSets, WorkoutDayExercises,
])
class TrainingDao extends DatabaseAccessor<TraumDatabase>
    with _$TrainingDaoMixin {
  TrainingDao(super.db);

  // WorkoutPlans
  Stream<List<WorkoutPlan>> watchAllPlans() => select(workoutPlans).watch();

  Future<WorkoutPlan?> getActivePlan() =>
      (select(workoutPlans)..where((t) => t.isActive.equals(true)))
          .getSingleOrNull();

  Future<int> insertPlan(WorkoutPlansCompanion entry) =>
      into(workoutPlans).insert(entry);

  Future<bool> updatePlan(WorkoutPlansCompanion entry) =>
      update(workoutPlans).replace(entry);

  Future<int> deletePlan(int id) =>
      (delete(workoutPlans)..where((t) => t.id.equals(id))).go();

  // WorkoutDays
  Stream<List<WorkoutDay>> watchDaysForPlan(int planId) =>
      (select(workoutDays)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<int> insertDay(WorkoutDaysCompanion entry) =>
      into(workoutDays).insert(entry);

  Future<bool> updateDay(WorkoutDaysCompanion entry) =>
      update(workoutDays).replace(entry);

  Future<int> deleteDay(int id) =>
      (delete(workoutDays)..where((t) => t.id.equals(id))).go();

  // Exercises
  Stream<List<Exercise>> watchAllExercises() => select(exercises).watch();

  Stream<List<Exercise>> watchExercisesByMuscleGroup(String muscleGroup) =>
      (select(exercises)..where((t) => t.muscleGroup.equals(muscleGroup)))
          .watch();

  Future<int> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry);

  Future<bool> updateExercise(ExercisesCompanion entry) =>
      update(exercises).replace(entry);

  Future<int> deleteExercise(int id) =>
      (delete(exercises)..where((t) => t.id.equals(id))).go();

  Future<void> toggleBookmark(int exerciseId, bool value) =>
      (update(exercises)..where((t) => t.id.equals(exerciseId)))
          .write(ExercisesCompanion(isBookmarked: Value(value)));

  Stream<List<Exercise>> watchBookmarkedExercises() =>
      (select(exercises)..where((t) => t.isBookmarked.equals(true))).watch();

  // WorkoutSessions
  Stream<List<WorkoutSession>> watchAllSessions() =>
      (select(workoutSessions)
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .watch();

  Future<WorkoutSession?> getSessionById(int id) =>
      (select(workoutSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<WorkoutSession>> getSessionsThisWeek() {
    final monday = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    return (select(workoutSessions)
          ..where((t) => t.startedAt.isBiggerOrEqualValue(weekStart)))
        .get();
  }

  Future<List<WorkoutSession>> getSessionsAfter(DateTime date) =>
      (select(workoutSessions)
            ..where((t) => t.startedAt.isBiggerOrEqualValue(date)))
          .get();

  Future<int> insertSession(WorkoutSessionsCompanion entry) =>
      into(workoutSessions).insert(entry);

  Future<bool> updateSession(WorkoutSessionsCompanion entry) =>
      update(workoutSessions).replace(entry);

  Future<int> deleteSession(int id) =>
      (delete(workoutSessions)..where((t) => t.id.equals(id))).go();

  // WorkoutSets
  Stream<List<WorkoutSet>> watchSetsForSession(int sessionId) =>
      (select(workoutSets)..where((t) => t.sessionId.equals(sessionId)))
          .watch();

  Future<List<WorkoutSet>> getRecentSets(Duration since) {
    final cutoff = DateTime.now().subtract(since);
    final query = select(workoutSets).join([
      innerJoin(workoutSessions,
          workoutSessions.id.equalsExp(workoutSets.sessionId)),
    ])
      ..where(workoutSessions.startedAt.isBiggerOrEqualValue(cutoff));
    return query
        .map((row) => row.readTable(workoutSets))
        .get();
  }

  Future<int> insertSet(WorkoutSetsCompanion entry) =>
      into(workoutSets).insert(entry);

  Future<bool> updateSet(WorkoutSetsCompanion entry) =>
      update(workoutSets).replace(entry);

  Future<int> deleteSet(int id) =>
      (delete(workoutSets)..where((t) => t.id.equals(id))).go();

  // WorkoutDayExercises
  Future<List<WorkoutDayExercise>> getDayExercises(int dayId) =>
      (select(workoutDayExercises)
            ..where((t) => t.dayId.equals(dayId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<WorkoutDayExercise>> watchDayExercises(int dayId) =>
      (select(workoutDayExercises)
            ..where((t) => t.dayId.equals(dayId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<int> insertDayExercise(WorkoutDayExercisesCompanion entry) =>
      into(workoutDayExercises).insert(entry);

  Future<bool> updateDayExercise(WorkoutDayExercisesCompanion entry) =>
      update(workoutDayExercises).replace(entry);

  Future<int> deleteDayExercise(int id) =>
      (delete(workoutDayExercises)..where((t) => t.id.equals(id))).go();

  Future<void> deleteDayExercisesForDay(int dayId) =>
      (delete(workoutDayExercises)..where((t) => t.dayId.equals(dayId))).go();
}

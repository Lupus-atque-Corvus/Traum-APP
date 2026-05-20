import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;

  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('insert and query WorkoutDayExercise', () async {
    final planId = await db.trainingDao.insertPlan(
      WorkoutPlansCompanion.insert(name: 'Test Plan'),
    );
    final dayId = await db.trainingDao.insertDay(
      WorkoutDaysCompanion.insert(planId: planId, name: 'Day A'),
    );
    final exerciseId = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Bankdruecken', muscleGroup: 'chest'),
    );

    await db.trainingDao.insertDayExercise(
      WorkoutDayExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: exerciseId,
        sortOrder: const Value(0),
        defaultSets: const Value(4),
        defaultReps: const Value(8),
      ),
    );

    final rows = await db.trainingDao.getDayExercises(dayId);
    expect(rows.length, 1);
    expect(rows.first.exerciseId, exerciseId);
    expect(rows.first.defaultSets, 4);
  });

  test('watchDayExercises emits ordered results', () async {
    final planId = await db.trainingDao.insertPlan(
      WorkoutPlansCompanion.insert(name: 'Plan'),
    );
    final dayId = await db.trainingDao.insertDay(
      WorkoutDaysCompanion.insert(planId: planId, name: 'Day A'),
    );
    final exId1 = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Exercise A', muscleGroup: 'chest'),
    );
    final exId2 = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Exercise B', muscleGroup: 'back'),
    );

    await db.trainingDao.insertDayExercise(
      WorkoutDayExercisesCompanion.insert(
        dayId: dayId, exerciseId: exId2, sortOrder: const Value(1),
      ),
    );
    await db.trainingDao.insertDayExercise(
      WorkoutDayExercisesCompanion.insert(
        dayId: dayId, exerciseId: exId1, sortOrder: const Value(0),
      ),
    );

    final rows = await db.trainingDao.watchDayExercises(dayId).first;
    expect(rows.length, 2);
    expect(rows[0].exerciseId, exId1); // sortOrder 0 first
    expect(rows[1].exerciseId, exId2); // sortOrder 1 second
  });

  test('deleteDayExercise removes single row', () async {
    final planId = await db.trainingDao.insertPlan(
      WorkoutPlansCompanion.insert(name: 'Plan'),
    );
    final dayId = await db.trainingDao.insertDay(
      WorkoutDaysCompanion.insert(planId: planId, name: 'Day A'),
    );
    final exId = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Exercise', muscleGroup: 'legs'),
    );
    final rowId = await db.trainingDao.insertDayExercise(
      WorkoutDayExercisesCompanion.insert(dayId: dayId, exerciseId: exId),
    );

    await db.trainingDao.deleteDayExercise(rowId);
    final rows = await db.trainingDao.getDayExercises(dayId);
    expect(rows, isEmpty);
  });

  test('deleteDayExercisesForDay removes all rows for day', () async {
    final planId = await db.trainingDao.insertPlan(
      WorkoutPlansCompanion.insert(name: 'Plan'),
    );
    final dayId = await db.trainingDao.insertDay(
      WorkoutDaysCompanion.insert(planId: planId, name: 'Day A'),
    );
    final exId = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Exercise', muscleGroup: 'core'),
    );
    await db.trainingDao.insertDayExercise(
      WorkoutDayExercisesCompanion.insert(dayId: dayId, exerciseId: exId),
    );
    await db.trainingDao.insertDayExercise(
      WorkoutDayExercisesCompanion.insert(dayId: dayId, exerciseId: exId),
    );

    await db.trainingDao.deleteDayExercisesForDay(dayId);
    final rows = await db.trainingDao.getDayExercises(dayId);
    expect(rows, isEmpty);
  });
}

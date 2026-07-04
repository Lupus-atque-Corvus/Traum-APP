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

  // Task 7.3: active-workout prefill (routine "Starten") builds its exercise
  // blocks from exactly this data source — getDayExercises(dayId) joined with
  // exercise lookup. This test locks in that the day's saved exercises + their
  // per-exercise defaults (sets/reps/rest) round-trip correctly and in order,
  // which is what the screen's prefill maps 1:1 into blocks/sets.
  test(
    'getDayExercises + exercise lookup yields ordered rows with correct '
    'defaults for active-workout prefill',
    () async {
      final planId = await db.trainingDao.insertPlan(
        WorkoutPlansCompanion.insert(name: 'Morgenroutine', planType: const Value('morning')),
      );
      final dayId = await db.trainingDao.insertDay(
        WorkoutDaysCompanion.insert(planId: planId, name: 'Routine'),
      );
      final exId1 = await db.trainingDao.insertExercise(
        ExercisesCompanion.insert(name: 'Dehnen', muscleGroup: 'core'),
      );
      final exId2 = await db.trainingDao.insertExercise(
        ExercisesCompanion.insert(name: 'Liegestuetze', muscleGroup: 'chest'),
      );

      await db.trainingDao.insertDayExercise(
        WorkoutDayExercisesCompanion.insert(
          dayId: dayId,
          exerciseId: exId1,
          sortOrder: const Value(0),
          defaultSets: const Value(2),
          defaultReps: const Value(15),
          defaultRestSeconds: const Value(30),
        ),
      );
      await db.trainingDao.insertDayExercise(
        WorkoutDayExercisesCompanion.insert(
          dayId: dayId,
          exerciseId: exId2,
          sortOrder: const Value(1),
          defaultSets: const Value(3),
          defaultReps: const Value(12),
          defaultRestSeconds: const Value(60),
        ),
      );

      final dayExercises = await db.trainingDao.getDayExercises(dayId);
      expect(dayExercises.length, 2);

      final allExercises = await db.trainingDao.getAllExercisesOnce();
      final exerciseById = {for (final e in allExercises) e.id: e};

      expect(dayExercises[0].exerciseId, exId1);
      expect(exerciseById[dayExercises[0].exerciseId]!.name, 'Dehnen');
      expect(dayExercises[0].defaultSets, 2);
      expect(dayExercises[0].defaultReps, 15);
      expect(dayExercises[0].defaultRestSeconds, 30);

      expect(dayExercises[1].exerciseId, exId2);
      expect(exerciseById[dayExercises[1].exerciseId]!.name, 'Liegestuetze');
      expect(dayExercises[1].defaultSets, 3);
      expect(dayExercises[1].defaultReps, 12);
      expect(dayExercises[1].defaultRestSeconds, 60);

      // Empty/deleted-day guard: an unknown dayId must yield no rows, never throw.
      final emptyRows = await db.trainingDao.getDayExercises(dayId + 999);
      expect(emptyRows, isEmpty);
    },
  );
}

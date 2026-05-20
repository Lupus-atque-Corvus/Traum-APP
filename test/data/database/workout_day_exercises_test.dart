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
}

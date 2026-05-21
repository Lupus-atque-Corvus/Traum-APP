import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('Exercise has isBookmarked column defaulting to false', () async {
    final id = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Bankdrücken', muscleGroup: 'Brust'),
    );
    final ex = await (db.select(db.exercises)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(ex.isBookmarked, false);
    expect(ex.primaryMuscles, '[]');
    expect(ex.secondaryMuscles, '[]');
    expect(ex.difficulty, null);
  });

  test('toggleBookmark flips isBookmarked', () async {
    final id = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Kniebeugen', muscleGroup: 'Beine'),
    );
    await db.trainingDao.toggleBookmark(id, true);
    final ex = await (db.select(db.exercises)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(ex.isBookmarked, true);
  });

  test('WorkoutDayExercise has defaultRestSeconds column defaulting to 90', () async {
    final planId = await db.trainingDao.insertPlan(
        WorkoutPlansCompanion.insert(name: 'Plan'));
    final dayId = await db.trainingDao.insertDay(
        WorkoutDaysCompanion.insert(planId: planId, name: 'Tag A'));
    final exId = await db.trainingDao.insertExercise(
        ExercisesCompanion.insert(name: 'Test', muscleGroup: 'Brust'));
    await db.trainingDao.insertDayExercise(
        WorkoutDayExercisesCompanion.insert(dayId: dayId, exerciseId: exId));
    final rows = await db.trainingDao.getDayExercises(dayId);
    expect(rows.first.defaultRestSeconds, 90);
  });
}

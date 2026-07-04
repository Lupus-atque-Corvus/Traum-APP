import 'package:drift/drift.dart' show Value;
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
    final ex = await (db.select(
      db.exercises,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(ex.isBookmarked, false);
    expect(ex.primaryMuscles, '[]');
    expect(ex.secondaryMuscles, '[]');
    expect(ex.difficulty, null);
  });

  test('setBookmarked sets isBookmarked', () async {
    final id = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Kniebeugen', muscleGroup: 'Beine'),
    );
    await db.trainingDao.setBookmarked(id, true);
    final ex = await (db.select(
      db.exercises,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(ex.isBookmarked, true);
  });

  test('watchBookmarkedExercises emits bookmarked exercises', () async {
    final id = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Klimmzüge', muscleGroup: 'Rücken'),
    );
    await db.trainingDao.setBookmarked(id, true);
    final bookmarked = await db.trainingDao.watchBookmarkedExercises().first;
    expect(bookmarked.length, 1);
    expect(bookmarked.first.id, id);
    expect(bookmarked.first.isBookmarked, true);
  });

  test(
    'WorkoutDayExercise has defaultRestSeconds column defaulting to 90',
    () async {
      final planId = await db.trainingDao.insertPlan(
        WorkoutPlansCompanion.insert(name: 'Plan'),
      );
      final dayId = await db.trainingDao.insertDay(
        WorkoutDaysCompanion.insert(planId: planId, name: 'Tag A'),
      );
      final exId = await db.trainingDao.insertExercise(
        ExercisesCompanion.insert(name: 'Test', muscleGroup: 'Brust'),
      );
      await db.trainingDao.insertDayExercise(
        WorkoutDayExercisesCompanion.insert(dayId: dayId, exerciseId: exId),
      );
      final rows = await db.trainingDao.getDayExercises(dayId);
      expect(rows.first.defaultRestSeconds, 90);
    },
  );

  test('WorkoutPlan.planType defaults to workout', () async {
    final planId = await db.trainingDao.insertPlan(
      WorkoutPlansCompanion.insert(name: 'Plan A'),
    );
    final plan = await (db.select(
      db.workoutPlans,
    )..where((t) => t.id.equals(planId))).getSingle();
    expect(plan.planType, 'workout');
  });

  test('watchPlansByType returns only plans of the given type', () async {
    await db.trainingDao.insertPlan(
      WorkoutPlansCompanion.insert(name: 'Push Day'),
    );
    await db.trainingDao.insertPlan(
      WorkoutPlansCompanion.insert(
        name: 'Morning Stretch',
        planType: const Value('morning'),
      ),
    );
    await db.trainingDao.insertPlan(
      WorkoutPlansCompanion.insert(
        name: 'Evening Stretch',
        planType: const Value('evening'),
      ),
    );

    final morning = await db.trainingDao.watchPlansByType('morning').first;
    expect(morning.length, 1);
    expect(morning.first.name, 'Morning Stretch');

    final evening = await db.trainingDao.watchPlansByType('evening').first;
    expect(evening.length, 1);
    expect(evening.first.name, 'Evening Stretch');

    final workout = await db.trainingDao.watchPlansByType('workout').first;
    expect(workout.length, 1);
    expect(workout.first.name, 'Push Day');
  });

  test(
    'watchDailyRoutinePlans returns morning + evening but not workout',
    () async {
      await db.trainingDao.insertPlan(
        WorkoutPlansCompanion.insert(name: 'Push Day'),
      );
      await db.trainingDao.insertPlan(
        WorkoutPlansCompanion.insert(
          name: 'Morning Stretch',
          planType: const Value('morning'),
        ),
      );
      await db.trainingDao.insertPlan(
        WorkoutPlansCompanion.insert(
          name: 'Evening Stretch',
          planType: const Value('evening'),
        ),
      );

      final daily = await db.trainingDao.watchDailyRoutinePlans().first;
      expect(daily.length, 2);
      expect(daily.map((p) => p.name).toSet(), {
        'Morning Stretch',
        'Evening Stretch',
      });
    },
  );
}

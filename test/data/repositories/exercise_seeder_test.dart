import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/repositories/exercise_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install seeds every exercise incl. stretching, sets both flags',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await ExerciseSeeder.seedIfNeeded(db, prefs);

    final all = await db.select(db.exercises).get();
    expect(all, isNotEmpty);
    final names = all.map((e) => e.name).toSet();
    expect(names, contains('Nacken-Seitdehnung'));
    final stretching =
        all.where((e) => e.name == 'Nacken-Seitdehnung').single;
    expect(stretching.muscleGroup, 'shoulders');

    expect(prefs.getBool('exercises_seeded'), isTrue);
    expect(prefs.getBool('exercises_seeded_v2'), isTrue);
  });

  test(
      'existing install (v1 seeded, v2 missing) only adds stretching, '
      'never touches a user-customized existing row', () async {
    SharedPreferences.setMockInitialValues({'exercises_seeded': true});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // Simulate a pre-v2 install: "Plank" already exists (from core.json)
    // but the user customized its instructions. No stretching rows yet.
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            name: 'Plank',
            muscleGroup: 'core',
            instructions: const Value('Meine eigene Notiz'),
          ),
        );
    final beforeCount = (await db.select(db.exercises).get()).length;
    expect(beforeCount, 1);

    await ExerciseSeeder.seedIfNeeded(db, prefs);

    final all = await db.select(db.exercises).get();

    // The custom row must be untouched (not overwritten by re-seeding).
    final plank = all.where((e) => e.name == 'Plank').single;
    expect(plank.instructions, 'Meine eigene Notiz');

    // Stretching exercises got added, with their real muscle group.
    final stretching =
        all.where((e) => e.name == 'Nacken-Seitdehnung').toList();
    expect(stretching, hasLength(1));
    expect(stretching.single.muscleGroup, 'shoulders');
    expect(all.where((e) => e.name == 'Armkreisen'), hasLength(1));

    expect(prefs.getBool('exercises_seeded_v2'), isTrue);

    // Calling again must be a no-op (idempotent, no duplicates).
    final countAfterFirstV2 = all.length;
    await ExerciseSeeder.seedIfNeeded(db, prefs);
    final afterSecond = await db.select(db.exercises).get();
    expect(afterSecond.length, countAfterFirstV2);
  });
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/repositories/exercise_library_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'seeds the extended library (815 exercises) with decoded muscle JSON; '
      're-seeding is a no-op; a pre-existing customized row keeps its '
      'equipment/instructions but gets its empty muscle lists filled',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // Simulate a pre-existing hand-seeded/user-customized "Step Jack" row
    // (the asset's first entry) — its custom fields must NOT be clobbered.
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            name: 'Step Jack',
            muscleGroup: 'legs',
            equipment: const Value('Meine Ausrüstung'),
            instructions: const Value('Meine eigene Anleitung'),
          ),
        );

    await ExerciseLibrarySeeder.seedIfNeeded(db, prefs);

    final all = await db.select(db.exercises).get();
    expect(all.length, greaterThan(800));

    // Custom row: equipment/instructions untouched (no-clobber)...
    final stepJack = all.where((e) => e.name == 'Step Jack').single;
    expect(stepJack.equipment, 'Meine Ausrüstung');
    expect(stepJack.instructions, 'Meine eigene Anleitung');
    // ...but its previously-empty muscle lists got filled in from the asset.
    final stepJackPrimary =
        (jsonDecode(stepJack.primaryMuscles) as List).cast<String>();
    expect(stepJackPrimary, contains('quadriceps'));

    // A freshly-inserted exercise decodes its muscle JSON correctly.
    final langsame =
        all.where((e) => e.name == 'Langsame Kniebeuge').single;
    final primary =
        (jsonDecode(langsame.primaryMuscles) as List).cast<String>();
    expect(primary, ['quadriceps']);
    final secondary =
        (jsonDecode(langsame.secondaryMuscles) as List).cast<String>();
    expect(secondary, containsAll(['abdominals', 'glutes', 'hamstrings']));
    expect(langsame.isCustom, isFalse);

    expect(prefs.getBool('exercise_library_seeded_v1'), isTrue);

    // Re-seeding is a no-op (guarded by the prefs flag) — no duplicates.
    final countAfterFirst = all.length;
    await ExerciseLibrarySeeder.seedIfNeeded(db, prefs);
    final afterSecond = await db.select(db.exercises).get();
    expect(afterSecond.length, countAfterFirst);
  });
}

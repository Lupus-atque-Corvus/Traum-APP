import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/traum_database.dart';

class ExerciseSeeder {
  static const _muscleGroups = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
    'legs', 'core', 'cardio', 'full_body', 'stretching',
  ];

  /// Legacy guard: once true, the very first (full) seed already ran.
  static const _seededKeyV1 = 'exercises_seeded';

  /// Guard for the v2 top-up seed (e.g. newly added stretching exercises).
  /// Installs that already ran the v1 seed only get exercises whose name
  /// isn't present yet — existing rows (possibly user-edited) are never
  /// touched or overwritten.
  static const _seededKeyV2 = 'exercises_seeded_v2';

  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    final seededV1 = prefs.getBool(_seededKeyV1) == true;
    if (!seededV1) {
      final existing = await db.select(db.exercises).get();
      if (existing.isEmpty) {
        // Fresh install: seed everything from scratch.
        await _seedGroups(db, insertOnConflictUpdate: true);
        await prefs.setBool(_seededKeyV1, true);
        await prefs.setBool(_seededKeyV2, true);
        return;
      }
      // Exercises already present but the flag was never set (older
      // install predating this guard) — mark v1 done, fall through to the
      // v2 top-up below instead of re-seeding everything.
      await prefs.setBool(_seededKeyV1, true);
    }

    if (prefs.getBool(_seededKeyV2) == true) return;

    // Existing install: only add exercises that aren't present yet (by
    // name), so custom-edited rows are never clobbered.
    final existingNames =
        (await db.select(db.exercises).get()).map((e) => e.name).toSet();
    await _seedGroups(
      db,
      insertOnConflictUpdate: false,
      skipNames: existingNames,
    );
    await prefs.setBool(_seededKeyV2, true);
  }

  static Future<void> _seedGroups(
    TraumDatabase db, {
    required bool insertOnConflictUpdate,
    Set<String> skipNames = const {},
  }) async {
    for (final group in _muscleGroups) {
      try {
        final data = await rootBundle.loadString('assets/exercises/$group.json');
        final List<dynamic> exercises = jsonDecode(data) as List<dynamic>;
        for (final ex in exercises) {
          final name = ex['name'] as String;
          if (!insertOnConflictUpdate && skipNames.contains(name)) continue;
          final companion = ExercisesCompanion(
            name: Value(name),
            muscleGroup: Value(ex['muscleGroup'] as String? ?? group),
            equipment: Value(ex['equipment'] as String?),
            instructions: Value(ex['instructions'] as String?),
            isCustom: const Value(false),
          );
          if (insertOnConflictUpdate) {
            await db.into(db.exercises).insertOnConflictUpdate(companion);
          } else {
            await db.into(db.exercises).insert(companion);
          }
        }
      } catch (_) {
        // Asset not found yet — skip
      }
    }
  }
}

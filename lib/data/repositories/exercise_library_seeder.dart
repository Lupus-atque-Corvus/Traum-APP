import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/traum_database.dart';

/// Seeds the extended offline exercise library generated in Task 9.1
/// (`assets/exercises/exercises_extended.json`, ~815 wger exercises with
/// canonical muscle groups + body-map muscle names + German instructions).
///
/// Follows the same no-clobber discipline as [ExerciseSeeder]'s v2 top-up:
/// - Exercise not present yet (by name) → INSERT with `isCustom: false`.
/// - Exercise already present (hand-seeded or user-customized) → only fill
///   fields that are still empty (`primaryMuscles == '[]'`, empty/absent
///   equipment/instructions). Never overwrites anything already set.
///
/// IMPORTANT: must run *after* [ExerciseSeeder] has finished on a fresh
/// install (not concurrently) — both write to the same `Exercises` table,
/// and this seeder's name-lookup needs to see ExerciseSeeder's rows to avoid
/// inserting duplicate-name exercises. See invocation in `main.dart`.
class ExerciseLibrarySeeder {
  static const _assetPath = 'assets/exercises/exercises_extended.json';
  static const _seededKey = 'exercise_library_seeded_v1';

  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_seededKey) == true) return;

    String raw;
    try {
      raw = await rootBundle.loadString(_assetPath);
    } catch (_) {
      // Asset not available yet — nothing to seed, don't retry every launch.
      await prefs.setBool(_seededKey, true);
      return;
    }

    final List<dynamic> entries = jsonDecode(raw) as List<dynamic>;
    final existing = await db.select(db.exercises).get();
    final byName = <String, Exercise>{for (final e in existing) e.name: e};

    final toInsert = <ExercisesCompanion>[];
    final toUpdate = <(int, ExercisesCompanion)>[];
    final seenNames = <String>{};

    for (final entry in entries) {
      final map = entry as Map<String, dynamic>;
      final name = map['name'] as String;

      // The generated asset itself has no duplicate names, but guard against
      // it anyway so a re-generated asset can never double-insert.
      if (!seenNames.add(name)) continue;

      final muscleGroup = map['muscleGroup'] as String? ?? 'full_body';
      final primary = ((map['primaryMuscles'] as List<dynamic>?) ?? const [])
          .cast<String>();
      final secondary =
          ((map['secondaryMuscles'] as List<dynamic>?) ?? const [])
              .cast<String>();
      final equipment = map['equipment'] as String?;
      final instructions = map['instructions'] as String?;

      final existingRow = byName[name];
      if (existingRow == null) {
        toInsert.add(ExercisesCompanion.insert(
          name: name,
          muscleGroup: muscleGroup,
          primaryMuscles: Value(jsonEncode(primary)),
          secondaryMuscles: Value(jsonEncode(secondary)),
          equipment: Value(equipment),
          instructions: Value(instructions),
          isCustom: const Value(false),
        ));
        continue;
      }

      // Already present — fill only currently-empty fields.
      var primaryVal = const Value<String>.absent();
      if (existingRow.primaryMuscles == '[]' && primary.isNotEmpty) {
        primaryVal = Value(jsonEncode(primary));
      }
      var secondaryVal = const Value<String>.absent();
      if (existingRow.secondaryMuscles == '[]' && secondary.isNotEmpty) {
        secondaryVal = Value(jsonEncode(secondary));
      }
      var equipmentVal = const Value<String?>.absent();
      if ((existingRow.equipment == null || existingRow.equipment!.isEmpty) &&
          equipment != null && equipment.isNotEmpty) {
        equipmentVal = Value(equipment);
      }
      var instructionsVal = const Value<String?>.absent();
      if ((existingRow.instructions == null ||
              existingRow.instructions!.isEmpty) &&
          instructions != null && instructions.isNotEmpty) {
        instructionsVal = Value(instructions);
      }

      if (primaryVal.present ||
          secondaryVal.present ||
          equipmentVal.present ||
          instructionsVal.present) {
        toUpdate.add((
          existingRow.id,
          ExercisesCompanion(
            primaryMuscles: primaryVal,
            secondaryMuscles: secondaryVal,
            equipment: equipmentVal,
            instructions: instructionsVal,
          ),
        ));
      }
    }

    // Single batched transaction — 815 rows worth of inserts/updates commit
    // in well under 100ms locally, so no need to defer past first frame.
    await db.batch((batch) {
      if (toInsert.isNotEmpty) {
        batch.insertAll(db.exercises, toInsert);
      }
      for (final (id, companion) in toUpdate) {
        batch.update(db.exercises, companion, where: (t) => t.id.equals(id));
      }
    });

    await prefs.setBool(_seededKey, true);
  }
}

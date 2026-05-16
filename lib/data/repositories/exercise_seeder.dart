import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/traum_database.dart';

class ExerciseSeeder {
  static const _muscleGroups = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
    'legs', 'core', 'cardio', 'full_body',
  ];

  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool('exercises_seeded') == true) return;
    final existing = await db.select(db.exercises).get();
    if (existing.isNotEmpty) {
      await prefs.setBool('exercises_seeded', true);
      return;
    }

    for (final group in _muscleGroups) {
      try {
        final data = await rootBundle.loadString('assets/exercises/$group.json');
        final List<dynamic> exercises = jsonDecode(data) as List<dynamic>;
        for (final ex in exercises) {
          await db.into(db.exercises).insertOnConflictUpdate(
            ExercisesCompanion(
              name: Value(ex['name'] as String),
              muscleGroup: Value(group),
              equipment: Value(ex['equipment'] as String?),
              instructions: Value(ex['instructions'] as String?),
              isCustom: const Value(false),
            ),
          );
        }
      } catch (_) {
        // Asset not found yet — skip
      }
    }

    await prefs.setBool('exercises_seeded', true);
  }
}

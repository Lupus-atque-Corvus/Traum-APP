import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/traum_database.dart';

class SupplementSeeder {
  static const _categories = [
    'vitamins', 'minerals', 'amino_acids', 'protein', 'omega',
    'adaptogens', 'pre_workout', 'gut_health', 'creatine',
  ];

  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool('supplements_seeded') == true) return;

    for (final category in _categories) {
      try {
        final data = await rootBundle.loadString(
          'assets/supplements/$category.json',
        );
        final List<dynamic> items = jsonDecode(data) as List<dynamic>;
        for (final item in items) {
          await db.into(db.supplements).insertOnConflictUpdate(
            SupplementsCompanion(
              name: Value(item['name'] as String),
              category: Value(category),
              dosageAmount: Value(item['dosage'] as String?),
              dosageUnit: Value(item['unit'] as String?),
              isActive: const Value(false),
            ),
          );
        }
      } catch (_) {
        // Asset not found yet — skip
      }
    }

    await prefs.setBool('supplements_seeded', true);
  }
}

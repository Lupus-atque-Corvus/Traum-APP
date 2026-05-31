import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/traum_database.dart';

class SubstanceDatabaseSeeder {
  static const _seededKey = 'substance_db_seeded_v1';

  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_seededKey) == true) return;

    try {
      final raw = await rootBundle.loadString('assets/substances.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

      final companions = list.map((j) {
        final name = j['name'] as String;
        return SubstanceDatabaseEntriesCompanion.insert(
          id: j['id'] as String,
          name: name,
          nameLower: name.toLowerCase(),
          type: j['type'] as String,
          category: Value(j['category'] as String?),
          mechanism: Value(j['mechanism'] as String?),
          commonDosage: Value(j['commonDosage'] as String?),
          adverseEventsJson: Value(
            jsonEncode(j['adverseEvents'] ?? []),
          ),
          interactionsJson: Value(
            jsonEncode(j['interactions'] ?? []),
          ),
        );
      }).toList();

      await db.substanceDatabaseDao.bulkInsert(companions);
      await prefs.setBool(_seededKey, true);
    } catch (_) {
      // Seed fails atomically (one bad entry aborts all) — next start retries
    }
  }
}

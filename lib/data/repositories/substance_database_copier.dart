import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/traum_database.dart';

class SubstanceDatabaseCopier {
  static const _copiedKey = 'substance_db_copied_v1';

  static Future<void> copyIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_copiedKey) == true) return;

    try {
      // Load bundled SQLite asset and write to a temp file
      final bytes = await rootBundle.load('assets/substances.db');
      final tmpDir = await getTemporaryDirectory();
      final tmpFile = File(p.join(tmpDir.path, 'substances_src.db'));
      await tmpFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      // Open the bundled DB with sqlite3 (read-only)
      final src = sqlite3.open(tmpFile.path, mode: OpenMode.readOnly);
      final rows = src.select(
        'SELECT id, name, name_lower, type, category, mechanism, '
        'common_dosage, adverse_events_json, interactions_json '
        'FROM substance_database_entries',
      );

      final companions = rows.map((r) {
        return SubstanceDatabaseEntriesCompanion.insert(
          id: r['id'] as String,
          name: r['name'] as String,
          nameLower: r['name_lower'] as String,
          type: r['type'] as String,
          category: Value(r['category'] as String?),
          mechanism: Value(r['mechanism'] as String?),
          commonDosage: Value(r['common_dosage'] as String?),
          adverseEventsJson: Value(
            (r['adverse_events_json'] as String?) ?? '[]',
          ),
          interactionsJson: Value(
            (r['interactions_json'] as String?) ?? '[]',
          ),
        );
      }).toList();

      src.dispose();
      await tmpFile.delete();

      await db.substanceDatabaseDao.bulkInsert(companions);
      await prefs.setBool(_copiedKey, true);
    } catch (_) {
      // Copy fails atomically — next start retries
    }
  }
}

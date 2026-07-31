import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:traum/data/database/traum_database.dart';

void main() {
  test('upgrading from v22 drops substance_database_entries', () async {
    // Build a raw v22-shaped DB by opening an in-memory sqlite3 connection,
    // creating just the one legacy table, then handing it to Drift at
    // schemaVersion 22 so onUpgrade(22 -> 23) runs for real.
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE substance_database_entries (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        name_lower TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        mechanism TEXT,
        common_dosage TEXT,
        adverse_events_json TEXT NOT NULL DEFAULT '[]',
        interactions_json TEXT NOT NULL DEFAULT '[]'
      )
    ''');
    // TraumDatabase's beforeOpen hook unconditionally upserts a singleton
    // row into cycle_profile after every migration run, regardless of
    // which schema areas actually changed. A real v22 install always has
    // this table (it predates v22 by many versions), so it must be present
    // for the raw seed to behave like a real upgrade.
    raw.execute('''
      CREATE TABLE cycle_profile (
        id INTEGER NOT NULL PRIMARY KEY,
        menarche_date INTEGER,
        luteal_phase_override INTEGER
      )
    ''');
    // A real v22 install always has the Graffiti-Map tables too (they predate
    // v22 by many versions, introduced at schemaVersion 12) — the v23->v24
    // tower-import migration (if (from < 24)) alters map_markers and reads
    // map_collections, so both must exist for the raw seed to behave like a
    // real upgrade instead of failing on a fixture-only gap.
    raw.execute('''
      CREATE TABLE map_collections (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_hex TEXT,
        has_rating INTEGER NOT NULL DEFAULT 0,
        multi_photo INTEGER NOT NULL DEFAULT 0,
        field_config TEXT NOT NULL DEFAULT '{}',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE map_markers (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL REFERENCES map_collections(id),
        title TEXT NOT NULL DEFAULT '',
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        note TEXT NOT NULL DEFAULT '',
        hashtags TEXT NOT NULL DEFAULT '',
        rating REAL,
        custom_fields TEXT NOT NULL DEFAULT '{}',
        is_hidden INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    // Existiert in echten Datenbanken seit v12 — wird ab der v26-Migration
    // gebraucht (Index auf marker_id).
    raw.execute('''
      CREATE TABLE marker_photos (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        marker_id INTEGER NOT NULL REFERENCES map_markers(id),
        photo_path TEXT NOT NULL,
        thumbnail_path TEXT,
        width_px INTEGER,
        height_px INTEGER,
        latitude REAL,
        longitude REAL,
        taken_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    raw.execute('PRAGMA user_version = 22');

    final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
    // Touch the DB to force Drift to run its migration/beforeOpen sequence.
    await db.customSelect('SELECT 1').get();

    final tables = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='substance_database_entries'",
    ).get();
    expect(tables, isEmpty);

    await db.close();
  });
}

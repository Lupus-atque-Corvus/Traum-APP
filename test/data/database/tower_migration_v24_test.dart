import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:traum/data/database/traum_database.dart';

/// Baut eine minimale, aber realistische v23-Datenbank (nur die für die
/// v23->v24-Migration relevanten Tabellen) und öffnet sie mit [TraumDatabase],
/// damit onUpgrade(23 -> 24) wirklich läuft.
void _seedV23Schema(sqlite3.Database raw) {
  raw.execute('''
    CREATE TABLE cycle_profile (
      id INTEGER NOT NULL PRIMARY KEY,
      menarche_date INTEGER,
      luteal_phase_override INTEGER
    )
  ''');
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
  // Existiert in echten Datenbanken seit v7 — muss vorhanden sein, damit die
  // v27-Migration (Mehrfach-Tagebücher) ihre `ADD COLUMN diary_id` findet.
  raw.execute('''
    CREATE TABLE diary_entries (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      media_path TEXT NOT NULL,
      media_type TEXT NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      thumbnail_path TEXT,
      duration_seconds INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void main() {
  test('v23 -> v24: normal upgrade merges tower fields without throwing',
      () async {
    final raw = sqlite3.sqlite3.openInMemory();
    _seedV23Schema(raw);
    raw.execute(
      "INSERT INTO map_collections (name, icon_name, field_config, created_at) "
      "VALUES ('Türme', 'tower', '{\"rating\":true,\"multiPhoto\":true,\"fields\":[]}', 0)",
    );
    raw.execute('PRAGMA user_version = 23');

    final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();

    final cols = await db
        .customSelect("SELECT name FROM pragma_table_info('map_markers')")
        .get();
    expect(cols.map((r) => r.read<String>('name')), contains('osm_id'));

    final cfg = await db.customSelect(
      "SELECT field_config FROM map_collections WHERE icon_name = 'tower'",
    ).getSingle();
    expect(cfg.read<String>('field_config'), contains('towerType'));

    await db.close();
  });

  test(
      're-running the migration after a previously-added osm_id column does '
      'not crash with "duplicate column name"', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    _seedV23Schema(raw);
    // Simuliert einen vorherigen, abgebrochenen Migrationsversuch: die Spalte
    // wurde schon angelegt, aber user_version wurde nie auf 24 gesetzt (weil
    // ein späterer Schritt im selben Block geworfen hat).
    raw.execute('ALTER TABLE map_markers ADD COLUMN osm_id TEXT');
    raw.execute(
      "INSERT INTO map_collections (name, icon_name, field_config, created_at) "
      "VALUES ('Türme', 'tower', '{\"rating\":true,\"multiPhoto\":true,\"fields\":[]}', 0)",
    );
    raw.execute('PRAGMA user_version = 23');

    final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
    // Darf NICHT werfen — das ist genau der Bug, der einer echten Installation
    // die App dauerhaft unstartbar gemacht hätte.
    await db.customSelect('SELECT 1').get();
    await db.close();
  });

  test(
      'malformed field_config (missing fields key, invalid JSON) is tolerated',
      () async {
    final raw = sqlite3.sqlite3.openInMemory();
    _seedV23Schema(raw);
    raw.execute(
      "INSERT INTO map_collections (name, icon_name, field_config, created_at) "
      "VALUES ('Türme A', 'tower', '{}', 0)", // kein 'fields'-Key
    );
    raw.execute(
      "INSERT INTO map_collections (name, icon_name, field_config, created_at) "
      "VALUES ('Türme B', 'tower', 'not json at all', 0)", // kaputtes JSON
    );
    raw.execute('PRAGMA user_version = 23');

    final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();

    final rows = await db.customSelect(
      "SELECT field_config FROM map_collections WHERE icon_name = 'tower'",
    ).get();
    for (final r in rows) {
      expect(r.read<String>('field_config'), contains('towerType'));
    }

    await db.close();
  });
}

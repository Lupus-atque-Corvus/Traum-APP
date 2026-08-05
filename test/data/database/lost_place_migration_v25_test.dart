import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:traum/data/database/traum_database.dart';

/// Baut eine minimale, aber realistische v24-Datenbank (nur die für die
/// v24->v25-Migration relevanten Tabellen, inkl. der v24-Spalte `osm_id`),
/// damit onUpgrade(24 -> 25) wirklich läuft.
void _seedV24Schema(sqlite3.Database raw) {
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
      created_at INTEGER NOT NULL,
      osm_id TEXT
    )
  ''');
  raw.execute(
    'CREATE UNIQUE INDEX idx_map_markers_osm_id ON map_markers (osm_id) '
    'WHERE osm_id IS NOT NULL',
  );
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
  test('v24 -> v25: adds external_id column and unique partial index',
      () async {
    final raw = sqlite3.sqlite3.openInMemory();
    _seedV24Schema(raw);
    raw.execute(
      "INSERT INTO map_collections (name, icon_name, field_config, created_at) "
      "VALUES ('Lost Places', 'home_broken', '{}', 0)",
    );
    raw.execute('PRAGMA user_version = 24');

    final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();

    final cols = await db
        .customSelect("SELECT name FROM pragma_table_info('map_markers')")
        .get();
    expect(cols.map((r) => r.read<String>('name')), contains('external_id'));

    // Unique partial index enforced: two NULLs allowed, two identical
    // non-null values rejected.
    await db.customStatement(
      "INSERT INTO map_markers (collection_id, created_at) VALUES (1, 0)",
    );
    await db.customStatement(
      "INSERT INTO map_markers (collection_id, created_at) VALUES (1, 0)",
    );
    await db.customStatement(
      "INSERT INTO map_markers (collection_id, created_at, external_id) "
      "VALUES (1, 0, 'lostfoundations:1')",
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO map_markers (collection_id, created_at, external_id) "
        "VALUES (1, 0, 'lostfoundations:1')",
      ),
      throwsA(anything),
    );

    await db.close();
  });

  test(
      're-running the migration after a previously-added external_id column '
      'does not crash with "duplicate column name"', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    _seedV24Schema(raw);
    // Simuliert einen vorherigen, abgebrochenen Migrationsversuch: die Spalte
    // wurde schon angelegt, aber user_version wurde nie auf 25 gesetzt.
    raw.execute('ALTER TABLE map_markers ADD COLUMN external_id TEXT');
    raw.execute('PRAGMA user_version = 24');

    final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
    // Darf NICHT werfen — das ist genau der Bug, der einer echten Installation
    // die App dauerhaft unstartbar gemacht hätte.
    await db.customSelect('SELECT 1').get();
    await db.close();
  });
}

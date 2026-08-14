import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:traum/data/database/traum_database.dart';

/// Minimale v25-Datenbank (nur die für die v25→v26-Migration relevanten
/// Tabellen, inkl. der v24/v25-Spalten `osm_id`/`external_id`).
void _seedV25Schema(sqlite3.Database raw) {
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
      osm_id TEXT,
      external_id TEXT
    )
  ''');
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

Future<List<String>> _indexNames(TraumDatabase db, String table) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
        variables: [Variable<String>(table)],
      )
      .get();
  return rows.map((r) => r.read<String>('name')).toList();
}

void main() {
  test('v25 -> v26: legt die Karten-Performance-Indizes an', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    _seedV25Schema(raw);
    raw.execute('PRAGMA user_version = 25');

    final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();

    expect(
      await _indexNames(db, 'map_markers'),
      contains('idx_map_markers_collection_pos'),
    );
    expect(
      await _indexNames(db, 'marker_photos'),
      contains('idx_marker_photos_marker'),
    );

    await db.close();
  });

  test(
    'der Index wird für die Kartenausschnitt-Abfrage tatsächlich genutzt',
    () async {
      final raw = sqlite3.sqlite3.openInMemory();
      _seedV25Schema(raw);
      raw.execute('PRAGMA user_version = 25');

      final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
      await db.customSelect('SELECT 1').get();

      // Ohne Zeilen entscheidet sich SQLite ggf. gegen den Index — genug Zeilen
      // einfügen, damit der Query-Planer ihn realistisch bewertet.
      raw.execute(
        "INSERT INTO map_collections (name, icon_name, created_at) "
        "VALUES ('Türme', 'tower', 0)",
      );
      final stmt = raw.prepare(
        'INSERT INTO map_markers (collection_id, latitude, longitude, created_at) '
        'VALUES (1, ?, ?, 0)',
      );
      for (var i = 0; i < 2000; i++) {
        stmt.execute([40.0 + i / 1000.0, 8.0 + i / 1000.0]);
      }
      stmt.dispose();
      raw.execute('ANALYZE');

      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM map_markers '
            'WHERE collection_id = 1 AND latitude BETWEEN 40.5 AND 40.6 '
            'AND longitude BETWEEN 8.5 AND 8.6',
          )
          .get();
      final detail = plan.map((r) => r.read<String>('detail')).join(' | ');

      // Entscheidend: kein vollständiger Tabellenscan mehr.
      expect(detail, contains('idx_map_markers_collection_pos'));
      expect(detail, isNot(contains('SCAN map_markers')));

      await db.close();
    },
  );

  test(
    'createMapPerformanceIndexes ist idempotent (Neuinstallations-Pfad)',
    () async {
      final raw = sqlite3.sqlite3.openInMemory();
      _seedV25Schema(raw);
      raw.execute('PRAGMA user_version = 25');

      final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
      await db.customSelect('SELECT 1').get();

      // Migration hat die Indizes bereits angelegt — der zusätzliche Aufruf aus
      // main.dart darf deshalb nicht werfen.
      await db.createMapPerformanceIndexes();
      await db.createMapPerformanceIndexes();

      expect(
        await _indexNames(db, 'map_markers'),
        contains('idx_map_markers_collection_pos'),
      );

      await db.close();
    },
  );
}

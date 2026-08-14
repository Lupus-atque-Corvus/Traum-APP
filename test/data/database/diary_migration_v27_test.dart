import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:traum/data/database/traum_database.dart';

/// Minimale, aber realistische v26-Datenbank (nur `cycle_profile`, das
/// `beforeOpen` bei jedem Start anfasst, und `diary_entries`, das seit v7
/// existiert und die für v27 relevante Migration ist).
void _seedV26Schema(sqlite3.Database raw) {
  raw.execute('''
    CREATE TABLE cycle_profile (
      id INTEGER NOT NULL PRIMARY KEY,
      menarche_date INTEGER,
      luteal_phase_override INTEGER
    )
  ''');
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
  test(
    'v26 -> v27: legt ein Default-Tagebuch an und befüllt bestehende Einträge',
    () async {
      final raw = sqlite3.sqlite3.openInMemory();
      _seedV26Schema(raw);
      raw.execute(
        "INSERT INTO diary_entries "
        "(date, media_path, media_type, note, created_at, updated_at) "
        "VALUES ('2026-01-01', '/tmp/a.jpg', 'photo', '', 0, 0)",
      );
      raw.execute(
        "INSERT INTO diary_entries "
        "(date, media_path, media_type, note, created_at, updated_at) "
        "VALUES ('2026-01-02', '/tmp/b.jpg', 'photo', '', 0, 0)",
      );
      raw.execute('PRAGMA user_version = 26');

      final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
      await db.customSelect('SELECT 1').get();

      final diaries = await db.diariesDao.getAll();
      expect(diaries, hasLength(1));
      expect(diaries.single.name, 'Mein Tagebuch');

      final entries = await db.diaryDao.getAllEntries(diaries.single.id);
      expect(entries, hasLength(2));

      await db.close();
    },
  );

  test('v26 -> v27 läuft ohne bestehende Einträge fehlerfrei durch', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    _seedV26Schema(raw);
    raw.execute('PRAGMA user_version = 26');

    final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();

    final diaries = await db.diariesDao.getAll();
    expect(diaries, hasLength(1));

    await db.close();
  });
}

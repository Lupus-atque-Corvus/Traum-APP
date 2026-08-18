import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:traum/data/database/traum_database.dart';

/// Realistische v28-Datenbank — genau der Zustand, den jedes Bestandsgerät
/// nach der v27→v28-Migration hat: `diaries` + `diary_entries.diary_id`
/// existieren bereits, und der Unique-Index ist (fälschlich) PARTIAL
/// (`WHERE diary_id IS NOT NULL`). Das ist der reale Bug-Reproduktionspfad —
/// eine frische `createAll()`-Installation hätte stattdessen einen
/// nicht-partiellen `UNIQUE`-Tabellen-Constraint aus `uniqueKeys` und würde
/// den Bug nicht zeigen.
void _seedV28Schema(sqlite3.Database raw) {
  raw.execute('''
    CREATE TABLE cycle_profile (
      id INTEGER NOT NULL PRIMARY KEY,
      menarche_date INTEGER,
      luteal_phase_override INTEGER
    )
  ''');
  raw.execute('''
    CREATE TABLE diaries (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      icon_name TEXT NOT NULL,
      color_hex TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  ''');
  raw.execute('''
    CREATE TABLE diary_entries (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      diary_id INTEGER REFERENCES diaries (id),
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
  raw.execute(
    'CREATE UNIQUE INDEX idx_diary_entries_diary_date '
    'ON diary_entries (diary_id, date) WHERE diary_id IS NOT NULL',
  );
  raw.execute(
    'CREATE INDEX idx_diary_entries_diary_created '
    'ON diary_entries (diary_id, created_at)',
  );
  raw.execute(
    "INSERT INTO diaries (id, name, icon_name, created_at) "
    "VALUES (1, 'Mein Tagebuch', 'book', 0)",
  );
}

void main() {
  test(
    'upsertEntry speichert einen neuen Tagebuch-Eintrag auf einer '
    'migrierten (v28→latest) Datenbank, ohne zu werfen',
    () async {
      final raw = sqlite3.sqlite3.openInMemory();
      _seedV28Schema(raw);
      raw.execute('PRAGMA user_version = 28');

      final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
      await db.customSelect('SELECT 1').get();

      // Genau der reale Flow aus DiaryCaptureSheet._save(): erster Speichern-
      // Tap für ein neues Foto an einem neuen Datum. Auf einer echten,
      // migrierten Datenbank warf das bislang schon HIER, unabhängig von
      // einem tatsächlichen Konflikt (SQLite löst den ON-CONFLICT-Ziel-Index
      // beim Statement-Prepare auf, nicht erst beim Ausführen).
      await db.diaryDao.upsertEntry(
        DiaryEntriesCompanion(
          diaryId: const Value(1),
          date: const Value('2026-08-18'),
          mediaPath: const Value('/tmp/a.jpg'),
          mediaType: const Value('photo'),
          note: const Value('erster Eintrag'),
          createdAt: Value(DateTime(2026, 8, 18)),
          updatedAt: Value(DateTime(2026, 8, 18)),
        ),
      );

      final entries = await db.diaryDao.getAllEntries(1);
      expect(entries, hasLength(1));
      expect(entries.single.note, 'erster Eintrag');

      await db.close();
    },
  );

  test(
    'upsertEntry aktualisiert (statt dupliziert) einen bestehenden Eintrag '
    'für denselben Tag auf einer migrierten Datenbank',
    () async {
      final raw = sqlite3.sqlite3.openInMemory();
      _seedV28Schema(raw);
      raw.execute('PRAGMA user_version = 28');

      final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
      await db.customSelect('SELECT 1').get();

      Future<void> save(String note) => db.diaryDao.upsertEntry(
        DiaryEntriesCompanion(
          diaryId: const Value(1),
          date: const Value('2026-08-18'),
          mediaPath: const Value('/tmp/a.jpg'),
          mediaType: const Value('photo'),
          note: Value(note),
          createdAt: Value(DateTime(2026, 8, 18)),
          updatedAt: Value(DateTime(2026, 8, 18)),
        ),
      );

      await save('erster Eintrag');
      await save('überarbeiteter Eintrag (Retake)');

      final entries = await db.diaryDao.getAllEntries(1);
      expect(entries, hasLength(1));
      expect(entries.single.note, 'überarbeiteter Eintrag (Retake)');

      await db.close();
    },
  );
}

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:traum/data/database/traum_database.dart';

/// Exercises the FULL migration chain (v1 → current) in one run.
///
/// Every other migration test in this directory starts no earlier than v22
/// (see `substances_v23_migration_test.dart` and newer) — meaning nobody who
/// has skipped updates since a genuinely old install (v1–v21, e.g. v0.2.x)
/// has ever had their upgrade path exercised by a test. This fixture starts
/// at the very first schema version instead.
///
/// Only 9 tables need to be hand-seeded here — every other table in the app
/// is created *by* a `migrator.createTable(...)` step somewhere between v2
/// and v28, so walking the chain from v1 creates them automatically. The 9
/// below are exactly the tables that receive a `migrator.addColumn(...)` at
/// some point but are never created by any step — i.e. they must already
/// exist in their pre-migration ("v1") shape, with none of the columns added
/// later. (Verified against the full migration source: every
/// `migrator.addColumn(x, ...)` target across v2–v28 is either one of these
/// 9, or a table created earlier in the same walked range.)
/// `substance_database_entries` is the 9th: no step creates it anymore (the
/// v9→v10 step that used to was excised once the table was fully retired),
/// but the v23 step still drops it — so it must be seeded too, exactly like
/// in `substances_v23_migration_test.dart`.
void main() {
  test('upgrading from v1 runs every migration step without error', () async {
    final raw = sqlite3.sqlite3.openInMemory();

    raw.execute('''
      CREATE TABLE exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        equipment TEXT,
        instructions TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0
      )
    ''');
    raw.execute('''
      CREATE TABLE transactions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category_id INTEGER,
        type TEXT NOT NULL DEFAULT 'expense',
        date INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE appointments (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        location TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        all_day INTEGER NOT NULL DEFAULT 0,
        recurrence_rule TEXT,
        color INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE supplements (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        dosage_amount TEXT,
        dosage_unit TEXT,
        timings TEXT NOT NULL DEFAULT '[]',
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE shopping_list_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        quantity REAL,
        unit TEXT,
        checked INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE abstinence_trackers (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        emoji TEXT,
        start_date INTEGER NOT NULL,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE debts (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        creditor TEXT NOT NULL,
        original_amount REAL NOT NULL,
        remaining_amount REAL NOT NULL,
        interest_rate REAL NOT NULL DEFAULT 0,
        due_date INTEGER,
        note TEXT,
        is_paid_off INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE workout_plans (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
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

    // A little pre-existing user data, to confirm it survives the entire
    // chain untouched (beyond the new columns each step adds).
    raw.execute(
      "INSERT INTO exercises (name, muscle_group) VALUES ('Kniebeugen', 'Beine')",
    );
    raw.execute(
      "INSERT INTO transactions (amount, description, date, created_at) "
      "VALUES (42.5, 'Alt-Buchung', 0, 0)",
    );
    raw.execute(
      "INSERT INTO workout_plans (name, created_at) VALUES ('Alter Plan', 0)",
    );

    raw.execute('PRAGMA user_version = 1');

    final db = TraumDatabase.forTesting(NativeDatabase.opened(raw));
    // Touch the DB to force Drift to run the full migration/beforeOpen chain.
    await db.customSelect('SELECT 1').get();

    expect(db.schemaVersion, 29);

    // Pre-existing rows survived, with later-added columns at their default.
    final exercise = await (db.select(
      db.exercises,
    )..where((t) => t.name.equals('Kniebeugen'))).getSingle();
    expect(exercise.isBookmarked, false);
    expect(exercise.primaryMuscles, '[]');

    final tx = await (db.select(
      db.transactions,
    )..where((t) => t.description.equals('Alt-Buchung'))).getSingle();
    expect(tx.type, 'expense');
    expect(tx.accountId, isNull); // added at v18, no value to migrate

    final plan = await (db.select(
      db.workoutPlans,
    )..where((t) => t.name.equals('Alter Plan'))).getSingle();
    expect(plan.planType, 'workout'); // added at v22, defaulted

    // v23: legacy offline substance DB fully dropped.
    final legacyTable = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name='substance_database_entries'",
        )
        .get();
    expect(legacyTable, isEmpty);

    // v27: multi-diary migration ran on an (empty, freshly-created-by-v7)
    // diary_entries table — default diary must still exist.
    final diaries = await db.diariesDao.getAll();
    expect(diaries, hasLength(1));
    expect(diaries.single.name, 'Mein Tagebuch');

    // v28: the new unique + lookup indexes exist.
    final indexes = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='index' "
          "AND name IN ('idx_diary_entries_diary_date', "
          "'idx_diary_entries_diary_created')",
        )
        .get();
    expect(indexes, hasLength(2));

    // v29: the diary_entries unique index is no longer partial — the real
    // upsertEntry() flow (as used by DiaryCaptureSheet._save()) must work
    // end-to-end after a full v1->latest migration chain, not just in
    // isolation (see diary_upsert_migration_v29_test.dart for the focused
    // regression test of the underlying bug).
    await db.diaryDao.upsertEntry(
      DiaryEntriesCompanion(
        diaryId: Value(diaries.single.id),
        date: const Value('2026-08-18'),
        mediaPath: const Value('/tmp/legacy-chain.jpg'),
        mediaType: const Value('photo'),
        note: const Value('voller Migrationspfad'),
        createdAt: Value(DateTime(2026, 8, 18)),
        updatedAt: Value(DateTime(2026, 8, 18)),
      ),
    );

    await db.close();
  });
}

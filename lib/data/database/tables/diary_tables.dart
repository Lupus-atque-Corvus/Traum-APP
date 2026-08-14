import 'package:drift/drift.dart';

/// Ein Tagebuch (Nutzer können mehrere parallel führen, z.B. eigenes
/// Tagebuch + eins für eine Reise oder mit einer anderen Person).
class Diaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Nullable, damit die Spalte per Migration ergänzt werden kann (SQLite
  // erlaubt ALTER TABLE ADD COLUMN NOT NULL nur mit statischem Default —
  // ungeeignet für eine Fremdschlüssel-ID). Die App setzt beim Anlegen eines
  // Eintrags immer einen Wert; bestehende Zeilen werden bei der Migration
  // auf das Default-Tagebuch zurückbefüllt.
  IntColumn get diaryId => integer().nullable().references(Diaries, #id)();
  TextColumn get date => text()();
  TextColumn get mediaPath => text()();
  TextColumn get mediaType => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Ermöglicht ein echtes `ON CONFLICT`-Upsert in DiaryDao.upsertEntry —
  // ohne diese Deklaration legt `createAll()` (Neuinstallationen, Tests) die
  // Tabelle ohne den Constraint an, den die v27→v28-Migration Bestands-
  // installationen nachträgt.
  @override
  List<Set<Column>> get uniqueKeys => [
    {diaryId, date},
  ];
}

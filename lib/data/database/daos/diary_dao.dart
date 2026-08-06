import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'diary_dao.g.dart';

@DriftAccessor(tables: [DiaryEntries])
class DiaryDao extends DatabaseAccessor<TraumDatabase> with _$DiaryDaoMixin {
  DiaryDao(super.db);

  Future<DiaryEntry?> getEntryForDate(int diaryId, String date) =>
      (select(diaryEntries)
            ..where((t) => t.diaryId.equals(diaryId) & t.date.equals(date)))
          .getSingleOrNull();

  Future<List<DiaryEntry>> getEntriesForMonth(
      int diaryId, int year, int month) {
    final prefix = '${year.toString().padLeft(4, '0')}'
        '-${month.toString().padLeft(2, '0')}';
    return (select(diaryEntries)
          ..where((t) =>
              t.diaryId.equals(diaryId) & t.date.like('$prefix%')))
        .get();
  }

  Future<List<DiaryEntry>> getRecentEntries(int diaryId, int days) {
    final from = DateTime.now().subtract(Duration(days: days));
    return (select(diaryEntries)
          ..where((t) =>
              t.diaryId.equals(diaryId) &
              t.createdAt.isBiggerOrEqualValue(from))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Alle Einträge eines Tagebuchs, unabhängig vom Datum — genutzt beim
  /// Löschen eines Tagebuchs, um vor dem DB-Löschen die zugehörigen
  /// Medien-Dateien auf der Festplatte aufzuräumen.
  Future<List<DiaryEntry>> getAllEntries(int diaryId) =>
      (select(diaryEntries)..where((t) => t.diaryId.equals(diaryId))).get();

  /// Echtes Upsert über den fachlichen Schlüssel (Tagebuch, Datum) — nicht
  /// über die Primärschlüssel-`id`, die der Aufrufer beim Anlegen eines neuen
  /// Eintrags nie kennt. Setzt einen Unique-Index auf
  /// `(diary_id, date)` voraus (Migration v28); ohne ihn würde SQLite den
  /// `ON CONFLICT`-Zielkonflikt nicht auflösen können und stattdessen jedes
  /// Mal eine neue Zeile einfügen.
  Future<void> upsertEntry(DiaryEntriesCompanion entry) => into(diaryEntries)
      .insert(
        entry,
        onConflict: DoUpdate(
          (_) => entry,
          target: [diaryEntries.diaryId, diaryEntries.date],
        ),
      );

  Future<void> deleteEntry(int id) =>
      (delete(diaryEntries)..where((t) => t.id.equals(id))).go();

  Future<List<String>> getDatesWithEntries(int diaryId) =>
      (select(diaryEntries)
            ..where((t) => t.diaryId.equals(diaryId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .map((e) => e.date)
          .get();

  Future<DiaryEntry?> getLastEntry(int diaryId) =>
      (select(diaryEntries)
            ..where((t) => t.diaryId.equals(diaryId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> getTotalCount(int diaryId) => (selectOnly(diaryEntries)
        ..addColumns([diaryEntries.id.count()])
        ..where(diaryEntries.diaryId.equals(diaryId)))
      .map((r) => r.read(diaryEntries.id.count())!)
      .getSingle();

  /// Video-Einträge über ALLE Tagebücher hinweg, denen noch ein
  /// Vorschaubild fehlt — genutzt vom einmaligen Backfill für Einträge, die
  /// vor v0.8.9 angelegt wurden (damals wurde `thumbnailPath` beim Speichern
  /// hart auf `null` gesetzt).
  Future<List<DiaryEntry>> getVideoEntriesMissingThumbnail() =>
      (select(diaryEntries)
            ..where((t) =>
                t.mediaType.equals('video') & t.thumbnailPath.isNull()))
          .get();

  Future<void> updateThumbnail(int id, String thumbnailPath) =>
      (update(diaryEntries)..where((t) => t.id.equals(id))).write(
        DiaryEntriesCompanion(thumbnailPath: Value(thumbnailPath)),
      );

  Future<List<String>> getDatesLastYear(int diaryId) {
    final yearAgo = DateTime.now().subtract(const Duration(days: 365));
    return (select(diaryEntries)
          ..where((t) =>
              t.diaryId.equals(diaryId) &
              t.createdAt.isBiggerOrEqualValue(yearAgo))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .map((e) => e.date)
        .get();
  }
}

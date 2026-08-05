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

  Future<void> upsertEntry(DiaryEntriesCompanion entry) =>
      into(diaryEntries).insertOnConflictUpdate(entry);

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

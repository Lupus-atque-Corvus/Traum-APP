import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'diary_dao.g.dart';

@DriftAccessor(tables: [DiaryEntries])
class DiaryDao extends DatabaseAccessor<TraumDatabase> with _$DiaryDaoMixin {
  DiaryDao(super.db);

  Future<DiaryEntry?> getEntryForDate(String date) =>
      (select(diaryEntries)..where((t) => t.date.equals(date)))
          .getSingleOrNull();

  Future<List<DiaryEntry>> getEntriesForMonth(int year, int month) {
    final prefix = '${year.toString().padLeft(4, '0')}'
        '-${month.toString().padLeft(2, '0')}';
    return (select(diaryEntries)..where((t) => t.date.like('$prefix%'))).get();
  }

  Future<List<DiaryEntry>> getRecentEntries(int days) {
    final from = DateTime.now().subtract(Duration(days: days));
    return (select(diaryEntries)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(from))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> upsertEntry(DiaryEntriesCompanion entry) =>
      into(diaryEntries).insertOnConflictUpdate(entry);

  Future<void> deleteEntry(int id) =>
      (delete(diaryEntries)..where((t) => t.id.equals(id))).go();

  Future<List<String>> getDatesWithEntries() =>
      (select(diaryEntries)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .map((e) => e.date)
          .get();

  Future<DiaryEntry?> getLastEntry() =>
      (select(diaryEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> getTotalCount() =>
      (selectOnly(diaryEntries)..addColumns([diaryEntries.id.count()]))
          .map((r) => r.read(diaryEntries.id.count())!)
          .getSingle();

  Future<List<String>> getDatesLastYear() {
    final yearAgo = DateTime.now().subtract(const Duration(days: 365));
    return (select(diaryEntries)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(yearAgo))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .map((e) => e.date)
        .get();
  }
}

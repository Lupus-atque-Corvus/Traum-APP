import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'supplement_dao.g.dart';

@DriftAccessor(tables: [Supplements, SupplementLogs])
class SupplementDao extends DatabaseAccessor<TraumDatabase>
    with _$SupplementDaoMixin {
  SupplementDao(super.db);

  Stream<List<Supplement>> watchAllSupplements() =>
      select(supplements).watch();

  Stream<List<Supplement>> watchActiveSupplements() =>
      (select(supplements)..where((t) => t.isActive.equals(true))).watch();

  Future<int> insertSupplement(SupplementsCompanion entry) =>
      into(supplements).insert(entry);

  Future<bool> updateSupplement(SupplementsCompanion entry) =>
      update(supplements).replace(entry);

  Future<int> deleteSupplement(int id) =>
      (delete(supplements)..where((t) => t.id.equals(id))).go();

  Stream<List<SupplementLog>> watchLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(supplementLogs)
          ..where((t) =>
              t.takenAt.isBiggerOrEqualValue(start) &
              t.takenAt.isSmallerThanValue(end)))
        .watch();
  }

  Future<int> insertLog(SupplementLogsCompanion entry) =>
      into(supplementLogs).insert(entry);

  Future<int> deleteLog(int id) =>
      (delete(supplementLogs)..where((t) => t.id.equals(id))).go();

  Future<int> getCount() async {
    final result = await select(supplements).get();
    return result.length;
  }

  Future<int> getActiveCount() async {
    final result = await (select(supplements)
          ..where((t) => t.isActive.equals(true)))
        .get();
    return result.length;
  }

  Future<int> getTakenCountToday() async {
    final todayStart = DateTime.now();
    final start = DateTime(todayStart.year, todayStart.month, todayStart.day);
    final end = start.add(const Duration(days: 1));
    final result = await (select(supplementLogs)
          ..where((t) =>
              t.takenAt.isBiggerOrEqualValue(start) &
              t.takenAt.isSmallerThanValue(end)))
        .get();
    return result.length;
  }
}

import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'period_dao.g.dart';

@DriftAccessor(tables: [PeriodEntries, CycleCalculations, PeriodSymptoms, DailyLogs, CycleProfile])
class PeriodDao extends DatabaseAccessor<TraumDatabase> with _$PeriodDaoMixin {
  PeriodDao(super.db);

  // PeriodEntries
  Stream<List<PeriodEntry>> watchAllPeriodEntries() =>
      (select(periodEntries)..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
          .watch();

  Future<List<PeriodEntry>> getAllPeriodEntries() =>
      (select(periodEntries)..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
          .get();

  Future<PeriodEntry?> getLatestPeriodEntry() =>
      (select(periodEntries)..orderBy([(t) => OrderingTerm.desc(t.startDate)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertPeriodEntry(PeriodEntriesCompanion entry) =>
      into(periodEntries).insert(entry);

  Future<bool> updatePeriodEntry(PeriodEntriesCompanion entry) =>
      update(periodEntries).replace(entry);

  Future<int> deletePeriodEntry(int id) =>
      (delete(periodEntries)..where((t) => t.id.equals(id))).go();

  // CycleCalculations
  Stream<List<CycleCalculation>> watchAllCalculations() =>
      select(cycleCalculations).watch();

  /// One-shot read of the cycle calculation for a given period entry — used by
  /// home widgets (no stream timer).
  Future<CycleCalculation?> getCalculationForEntry(int periodEntryId) =>
      (select(cycleCalculations)
            ..where((t) => t.periodEntryId.equals(periodEntryId))
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertCalculation(CycleCalculationsCompanion entry) =>
      into(cycleCalculations).insert(entry);

  Future<bool> updateCalculation(CycleCalculationsCompanion entry) =>
      update(cycleCalculations).replace(entry);

  // PeriodSymptoms
  Stream<List<PeriodSymptom>> watchSymptomsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(periodSymptoms)
          ..where((t) =>
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerThanValue(end)))
        .watch();
  }

  Stream<List<PeriodSymptom>> watchAllSymptoms() =>
      (select(periodSymptoms)..orderBy([(t) => OrderingTerm.desc(t.logDate)]))
          .watch();

  Future<int> insertSymptom(PeriodSymptomsCompanion entry) =>
      into(periodSymptoms).insert(entry);

  Future<int> deleteSymptom(int id) =>
      (delete(periodSymptoms)..where((t) => t.id.equals(id))).go();

  // DailyLogs ───────────────────────────────────────────────
  Future<DailyLog?> getDailyLogForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(dailyLogs)
          ..where((t) =>
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerThanValue(end))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert or replace the daily log for its calendar day.
  Future<int> upsertDailyLog(DailyLogsCompanion entry) async {
    assert(entry.logDate.present, 'upsertDailyLog requires a logDate');
    final date = entry.logDate.value;
    final existing = await getDailyLogForDate(date);
    if (existing == null) {
      return into(dailyLogs).insert(entry);
    }
    await (update(dailyLogs)..where((t) => t.id.equals(existing.id)))
        .write(entry);
    return existing.id;
  }

  /// Streams [DailyLog]s with [start] inclusive and [end] exclusive.
  Stream<List<DailyLog>> watchDailyLogsInRange(DateTime start, DateTime end) =>
      (select(dailyLogs)
            ..where((t) =>
                t.logDate.isBiggerOrEqualValue(start) &
                t.logDate.isSmallerThanValue(end))
            ..orderBy([(t) => OrderingTerm.asc(t.logDate)]))
          .watch();

  Stream<List<DailyLog>> watchAllDailyLogs() =>
      (select(dailyLogs)..orderBy([(t) => OrderingTerm.asc(t.logDate)])).watch();

  // CycleProfile ────────────────────────────────────────────
  Future<CycleProfileData> getCycleProfile() async {
    final row = await (select(cycleProfile)..where((t) => t.id.equals(0)))
        .getSingleOrNull();
    if (row != null) return row;
    await into(cycleProfile).insert(
      const CycleProfileCompanion(id: Value(0)),
      mode: InsertMode.insertOrIgnore,
    );
    return (select(cycleProfile)..where((t) => t.id.equals(0))).getSingle();
  }

  Stream<CycleProfileData?> watchCycleProfile() =>
      (select(cycleProfile)..where((t) => t.id.equals(0))).watchSingleOrNull();

  Future<void> updateCycleProfile(CycleProfileCompanion entry) async {
    await (update(cycleProfile)..where((t) => t.id.equals(0)))
        .write(entry.copyWith(id: const Value(0)));
  }
}

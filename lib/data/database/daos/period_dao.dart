import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'period_dao.g.dart';

@DriftAccessor(tables: [PeriodEntries, CycleCalculations, PeriodSymptoms])
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
}

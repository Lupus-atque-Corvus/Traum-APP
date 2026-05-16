import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'medication_dao.g.dart';

@DriftAccessor(tables: [Medications, MedicationLogs])
class MedicationDao extends DatabaseAccessor<TraumDatabase>
    with _$MedicationDaoMixin {
  MedicationDao(super.db);

  Stream<List<Medication>> watchAllMedications() =>
      select(medications).watch();

  Stream<List<Medication>> watchActiveMedications() =>
      (select(medications)..where((t) => t.isActive.equals(true))).watch();

  Future<int> insertMedication(MedicationsCompanion entry) =>
      into(medications).insert(entry);

  Future<bool> updateMedication(MedicationsCompanion entry) =>
      update(medications).replace(entry);

  Future<int> deleteMedication(int id) =>
      (delete(medications)..where((t) => t.id.equals(id))).go();

  Stream<List<MedicationLog>> watchLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(medicationLogs)
          ..where((t) =>
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end)))
        .watch();
  }

  Future<int> insertLog(MedicationLogsCompanion entry) =>
      into(medicationLogs).insert(entry);

  Future<bool> updateLog(MedicationLogsCompanion entry) =>
      update(medicationLogs).replace(entry);

  Future<int> deleteLog(int id) =>
      (delete(medicationLogs)..where((t) => t.id.equals(id))).go();

  Future<int> getActiveCount() async {
    final result = await (select(medications)
          ..where((t) => t.isActive.equals(true)))
        .get();
    return result.length;
  }

  Future<int> getTakenCountToday() async {
    final todayStart = DateTime.now();
    final start = DateTime(todayStart.year, todayStart.month, todayStart.day);
    final end = start.add(const Duration(days: 1));
    final result = await (select(medicationLogs)
          ..where((t) =>
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end) &
              t.taken.equals(true)))
        .get();
    return result.length;
  }
}

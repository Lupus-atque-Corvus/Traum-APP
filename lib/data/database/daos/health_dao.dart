import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'health_dao.g.dart';

@DriftAccessor(
    tables: [WeightLogs, BodyMeasurements, SleepLogs, MoodLogs, PhotoLogs])
class HealthDao extends DatabaseAccessor<TraumDatabase> with _$HealthDaoMixin {
  HealthDao(super.db);

  // WeightLogs
  Stream<List<WeightLog>> watchAllWeightLogs() =>
      (select(weightLogs)..orderBy([(t) => OrderingTerm.desc(t.logDate)]))
          .watch();

  Future<WeightLog?> getLatestWeight() =>
      (select(weightLogs)..orderBy([(t) => OrderingTerm.desc(t.logDate)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertWeightLog(WeightLogsCompanion entry) =>
      into(weightLogs).insert(entry);

  Future<int> deleteWeightLog(int id) =>
      (delete(weightLogs)..where((t) => t.id.equals(id))).go();

  // BodyMeasurements
  Stream<List<BodyMeasurement>> watchAllMeasurements() =>
      (select(bodyMeasurements)
            ..orderBy([(t) => OrderingTerm.desc(t.logDate)]))
          .watch();

  Future<int> insertMeasurement(BodyMeasurementsCompanion entry) =>
      into(bodyMeasurements).insert(entry);

  Future<int> deleteMeasurement(int id) =>
      (delete(bodyMeasurements)..where((t) => t.id.equals(id))).go();

  // SleepLogs
  Stream<List<SleepLog>> watchAllSleepLogs() =>
      (select(sleepLogs)..orderBy([(t) => OrderingTerm.desc(t.bedtime)]))
          .watch();

  Future<List<SleepLog>> getRecentSleepLogs(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (select(sleepLogs)..where((t) => t.bedtime.isBiggerOrEqualValue(cutoff)))
        .get();
  }

  Future<List<SleepLog>> getSleepLogsAfter(DateTime date) =>
      (select(sleepLogs)..where((t) => t.bedtime.isBiggerOrEqualValue(date)))
          .get();

  Future<List<MoodLog>> getMoodLogsAfter(DateTime date) =>
      (select(moodLogs)..where((t) => t.logDate.isBiggerOrEqualValue(date)))
          .get();

  Future<int> insertSleepLog(SleepLogsCompanion entry) =>
      into(sleepLogs).insert(entry);

  Future<int> deleteSleepLog(int id) =>
      (delete(sleepLogs)..where((t) => t.id.equals(id))).go();

  // MoodLogs
  Stream<List<MoodLog>> watchAllMoodLogs() =>
      (select(moodLogs)..orderBy([(t) => OrderingTerm.desc(t.logDate)]))
          .watch();

  Future<MoodLog?> getLatestMood() =>
      (select(moodLogs)..orderBy([(t) => OrderingTerm.desc(t.logDate)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertMoodLog(MoodLogsCompanion entry) =>
      into(moodLogs).insert(entry);

  Future<int> deleteMoodLog(int id) =>
      (delete(moodLogs)..where((t) => t.id.equals(id))).go();

  // PhotoLogs
  Stream<List<PhotoLog>> watchAllPhotoLogs() =>
      (select(photoLogs)..orderBy([(t) => OrderingTerm.desc(t.logDate)]))
          .watch();

  Future<int> insertPhotoLog(PhotoLogsCompanion entry) =>
      into(photoLogs).insert(entry);

  Future<int> deletePhotoLog(int id) =>
      (delete(photoLogs)..where((t) => t.id.equals(id))).go();

  Stream<List<PhotoLog>> watchDiaryLogs() =>
      (select(photoLogs)
            ..where((t) => t.category.equals('diary'))
            ..orderBy([(t) => OrderingTerm.desc(t.logDate)]))
          .watch();

  Future<PhotoLog?> getDiaryLogForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(photoLogs)
          ..where((t) =>
              t.category.equals('diary') &
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerThanValue(end)))
        .getSingleOrNull();
  }
}

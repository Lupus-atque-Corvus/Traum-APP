import '../database/traum_database.dart';

class HealthRepository {
  final HealthDao _dao;
  HealthRepository(this._dao);

  Stream<List<WeightLog>> watchAllWeightLogs() => _dao.watchAllWeightLogs();
  Future<WeightLog?> getLatestWeight() => _dao.getLatestWeight();
  Future<int> addWeightLog(WeightLogsCompanion e) => _dao.insertWeightLog(e);
  Future<int> deleteWeightLog(int id) => _dao.deleteWeightLog(id);

  Stream<List<BodyMeasurement>> watchAllMeasurements() =>
      _dao.watchAllMeasurements();
  Future<int> addMeasurement(BodyMeasurementsCompanion e) =>
      _dao.insertMeasurement(e);
  Future<int> deleteMeasurement(int id) => _dao.deleteMeasurement(id);

  Stream<List<SleepLog>> watchAllSleepLogs() => _dao.watchAllSleepLogs();
  Future<List<SleepLog>> getRecentSleepLogs(int days) =>
      _dao.getRecentSleepLogs(days);
  Future<int> addSleepLog(SleepLogsCompanion e) => _dao.insertSleepLog(e);
  Future<int> deleteSleepLog(int id) => _dao.deleteSleepLog(id);

  Stream<List<MoodLog>> watchAllMoodLogs() => _dao.watchAllMoodLogs();
  Future<MoodLog?> getLatestMood() => _dao.getLatestMood();
  Future<int> addMoodLog(MoodLogsCompanion e) => _dao.insertMoodLog(e);
  Future<int> deleteMoodLog(int id) => _dao.deleteMoodLog(id);

  Stream<List<PhotoLog>> watchAllPhotoLogs() => _dao.watchAllPhotoLogs();
  Future<int> addPhotoLog(PhotoLogsCompanion e) => _dao.insertPhotoLog(e);
  Future<int> deletePhotoLog(int id) => _dao.deletePhotoLog(id);
}

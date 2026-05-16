import '../database/traum_database.dart';

class MedicationRepository {
  final MedicationDao _dao;
  MedicationRepository(this._dao);

  Stream<List<Medication>> watchAllMedications() => _dao.watchAllMedications();
  Stream<List<Medication>> watchActiveMedications() =>
      _dao.watchActiveMedications();
  Future<int> addMedication(MedicationsCompanion e) =>
      _dao.insertMedication(e);
  Future<bool> updateMedication(MedicationsCompanion e) =>
      _dao.updateMedication(e);
  Future<int> deleteMedication(int id) => _dao.deleteMedication(id);

  Stream<List<MedicationLog>> watchLogsForDate(DateTime date) =>
      _dao.watchLogsForDate(date);
  Future<int> addLog(MedicationLogsCompanion e) => _dao.insertLog(e);
  Future<bool> updateLog(MedicationLogsCompanion e) => _dao.updateLog(e);
  Future<int> deleteLog(int id) => _dao.deleteLog(id);
}

import '../database/traum_database.dart';

class PeriodRepository {
  final PeriodDao _dao;
  PeriodRepository(this._dao);

  Stream<List<PeriodEntry>> watchAllPeriodEntries() =>
      _dao.watchAllPeriodEntries();
  Future<List<PeriodEntry>> getAllPeriodEntries() => _dao.getAllPeriodEntries();
  Future<PeriodEntry?> getLatestPeriodEntry() => _dao.getLatestPeriodEntry();
  Future<int> addPeriodEntry(PeriodEntriesCompanion e) =>
      _dao.insertPeriodEntry(e);
  Future<bool> updatePeriodEntry(PeriodEntriesCompanion e) =>
      _dao.updatePeriodEntry(e);
  Future<int> deletePeriodEntry(int id) => _dao.deletePeriodEntry(id);

  Stream<List<CycleCalculation>> watchAllCalculations() =>
      _dao.watchAllCalculations();
  Future<int> addCalculation(CycleCalculationsCompanion e) =>
      _dao.insertCalculation(e);
  Future<bool> updateCalculation(CycleCalculationsCompanion e) =>
      _dao.updateCalculation(e);

  Stream<List<PeriodSymptom>> watchSymptomsForDate(DateTime date) =>
      _dao.watchSymptomsForDate(date);
  Stream<List<PeriodSymptom>> watchAllSymptoms() => _dao.watchAllSymptoms();
  Future<int> addSymptom(PeriodSymptomsCompanion e) => _dao.insertSymptom(e);
  Future<int> deleteSymptom(int id) => _dao.deleteSymptom(id);
}

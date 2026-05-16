import '../database/traum_database.dart';

class SupplementRepository {
  final SupplementDao _dao;
  SupplementRepository(this._dao);

  Stream<List<Supplement>> watchAllSupplements() => _dao.watchAllSupplements();
  Stream<List<Supplement>> watchActiveSupplements() =>
      _dao.watchActiveSupplements();
  Future<int> addSupplement(SupplementsCompanion e) => _dao.insertSupplement(e);
  Future<bool> updateSupplement(SupplementsCompanion e) =>
      _dao.updateSupplement(e);
  Future<int> deleteSupplement(int id) => _dao.deleteSupplement(id);
  Future<int> getCount() => _dao.getCount();

  Stream<List<SupplementLog>> watchLogsForDate(DateTime date) =>
      _dao.watchLogsForDate(date);
  Future<int> addLog(SupplementLogsCompanion e) => _dao.insertLog(e);
  Future<int> deleteLog(int id) => _dao.deleteLog(id);
}

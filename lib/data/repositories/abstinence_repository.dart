import 'package:drift/drift.dart';
import '../database/traum_database.dart';

class AbstinenceRepository {
  final AbstinenceDao _dao;
  AbstinenceRepository(this._dao);

  Stream<List<AbstinenceTracker>> watchAllTrackers() =>
      _dao.watchAllTrackers();
  Stream<List<AbstinenceTracker>> watchActiveTrackers() =>
      _dao.watchActiveTrackers();
  Future<int> addTracker(AbstinenceTrackersCompanion e) =>
      _dao.insertTracker(e);
  Future<bool> updateTracker(AbstinenceTrackersCompanion e) =>
      _dao.updateTracker(e);
  Future<int> deleteTracker(int id) => _dao.deleteTracker(id);

  Stream<List<AbstinenceEvent>> watchEventsForTracker(int trackerId) =>
      _dao.watchEventsForTracker(trackerId);
  Future<int> addEvent(AbstinenceEventsCompanion e) => _dao.insertEvent(e);
  Future<int> deleteEvent(int id) => _dao.deleteEvent(id);

  Future<int> recordRelapse(int trackerId, DateTime newStart) async {
    await _dao.insertEvent(AbstinenceEventsCompanion(
      trackerId: Value(trackerId),
      type: const Value('relapse'),
      eventDate: Value(DateTime.now()),
    ));
    return _dao.updateTracker(AbstinenceTrackersCompanion(
      id: Value(trackerId),
      startDate: Value(newStart),
    )).then((_) => 0);
  }
}

import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'abstinence_dao.g.dart';

@DriftAccessor(tables: [AbstinenceTrackers, AbstinenceEvents])
class AbstinenceDao extends DatabaseAccessor<TraumDatabase>
    with _$AbstinenceDaoMixin {
  AbstinenceDao(super.db);

  Stream<List<AbstinenceTracker>> watchAllTrackers() =>
      select(abstinenceTrackers).watch();

  Stream<List<AbstinenceTracker>> watchActiveTrackers() =>
      (select(abstinenceTrackers)..where((t) => t.isActive.equals(true)))
          .watch();

  Future<int> insertTracker(AbstinenceTrackersCompanion entry) =>
      into(abstinenceTrackers).insert(entry);

  Future<bool> updateTracker(AbstinenceTrackersCompanion entry) =>
      update(abstinenceTrackers).replace(entry);

  Future<int> deleteTracker(int id) =>
      (delete(abstinenceTrackers)..where((t) => t.id.equals(id))).go();

  Stream<List<AbstinenceEvent>> watchEventsForTracker(int trackerId) =>
      (select(abstinenceEvents)
            ..where((t) => t.trackerId.equals(trackerId))
            ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
          .watch();

  Future<int> insertEvent(AbstinenceEventsCompanion entry) =>
      into(abstinenceEvents).insert(entry);

  Future<int> deleteEvent(int id) =>
      (delete(abstinenceEvents)..where((t) => t.id.equals(id))).go();
}

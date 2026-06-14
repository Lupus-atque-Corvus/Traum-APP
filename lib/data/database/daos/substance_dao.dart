import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'substance_dao.g.dart';

@DriftAccessor(tables: [SubstanceCaches, SubstanceIntakeLogs])
class SubstanceDao extends DatabaseAccessor<TraumDatabase>
    with _$SubstanceDaoMixin {
  SubstanceDao(super.db);

  Future<SubstanceCache?> findById(String id) =>
      (select(substanceCaches)..where((t) => t.substanceId.equals(id)))
          .getSingleOrNull();

  Future<List<SubstanceCache>> searchByName(String query) =>
      (select(substanceCaches)
            ..where((t) => t.name.lower().contains(query.toLowerCase())))
          .get();

  Future<void> upsert(SubstanceCachesCompanion entry) =>
      into(substanceCaches).insertOnConflictUpdate(entry);

  // ── Intake log ─────────────────────────────────────────────────────────────

  Future<int> insertIntake(SubstanceIntakeLogsCompanion entry) =>
      into(substanceIntakeLogs).insert(entry);

  Future<int> deleteIntake(int id) =>
      (delete(substanceIntakeLogs)..where((t) => t.id.equals(id))).go();

  Stream<List<SubstanceIntakeLog>> watchAllIntakes() =>
      (select(substanceIntakeLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
          .watch();

  Future<SubstanceIntakeLog?> getLastIntake() =>
      (select(substanceIntakeLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.takenAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> getIntakeCountToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final rows = await (select(substanceIntakeLogs)
          ..where((t) => t.takenAt.isBetweenValues(start, end)))
        .get();
    return rows.length;
  }
}

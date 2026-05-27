import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'substance_dao.g.dart';

@DriftAccessor(tables: [SubstanceCaches])
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
}

import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'substance_database_dao.g.dart';

@DriftAccessor(tables: [SubstanceDatabaseEntries])
class SubstanceDatabaseDao extends DatabaseAccessor<TraumDatabase>
    with _$SubstanceDatabaseDaoMixin {
  SubstanceDatabaseDao(super.db);

  Future<int> count() async {
    final countExp = substanceDatabaseEntries.id.count();
    final query = selectOnly(substanceDatabaseEntries)
      ..addColumns([countExp]);
    return (await query.getSingle()).read(countExp) ?? 0;
  }

  Future<List<SubstanceDatabaseEntry>> search(String queryLower) =>
      (select(substanceDatabaseEntries)
            ..where((t) => t.nameLower.like('%$queryLower%'))
            ..orderBy([(t) => OrderingTerm.asc(t.name)])
            ..limit(30))
          .get();

  Future<void> bulkInsert(
      List<SubstanceDatabaseEntriesCompanion> entries) async {
    await batch((b) =>
        b.insertAllOnConflictUpdate(substanceDatabaseEntries, entries));
  }

  Future<void> clearAll() => delete(substanceDatabaseEntries).go();
}

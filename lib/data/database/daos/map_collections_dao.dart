import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'map_collections_dao.g.dart';

@DriftAccessor(tables: [MapCollections])
class MapCollectionsDao extends DatabaseAccessor<TraumDatabase>
    with _$MapCollectionsDaoMixin {
  MapCollectionsDao(super.db);

  Future<List<MapCollection>> getAll() =>
      (select(mapCollections)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<MapCollection?> getById(int id) =>
      (select(mapCollections)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insert(MapCollectionsCompanion c) =>
      into(mapCollections).insert(c);

  Future<bool> updateCollection(MapCollection c) =>
      update(mapCollections).replace(c);

  Future<void> deleteCollection(int id) =>
      (delete(mapCollections)..where((t) => t.id.equals(id))).go();

  Future<int> nextSortOrder() async {
    final all = await getAll();
    return all.isEmpty
        ? 0
        : all.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }
}

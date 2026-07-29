import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'map_markers_dao.g.dart';

@DriftAccessor(tables: [MapMarkers])
class MapMarkersDao extends DatabaseAccessor<TraumDatabase>
    with _$MapMarkersDaoMixin {
  MapMarkersDao(super.db);

  Future<List<MapMarker>> getByCollection(int collectionId) =>
      (select(mapMarkers)
            ..where((t) => t.collectionId.equals(collectionId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<MapMarker?> getById(int id) =>
      (select(mapMarkers)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// One-shot read of all markers across collections — used by home widgets.
  Future<List<MapMarker>> getAll() =>
      (select(mapMarkers)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<MapMarker>> search(int collectionId, String q) =>
      (select(mapMarkers)
            ..where((t) =>
                t.collectionId.equals(collectionId) &
                (t.note.like('%$q%') |
                    t.hashtags.like('%$q%') |
                    t.locationName.like('%$q%') |
                    t.title.like('%$q%')))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<int> insert(MapMarkersCompanion c) => into(mapMarkers).insert(c);

  Future<void> updateMarker(MapMarker m) => update(mapMarkers).replace(m);

  Future<void> deleteMarker(int id) =>
      (delete(mapMarkers)..where((t) => t.id.equals(id))).go();

  /// OSM-IDs bereits importierter Marker einer Collection — primärer
  /// Dedupe-Schlüssel für den Türme-Import.
  Future<Set<String>> getOsmIds(int collectionId) async {
    final rows = await (select(mapMarkers)
          ..where((t) =>
              t.collectionId.equals(collectionId) & t.osmId.isNotNull()))
        .get();
    return rows.map((r) => r.osmId!).toSet();
  }

  /// Koordinaten aller Marker mit Position einer Collection — Fallback-Dedupe
  /// für Türme, die vor dem Import-Feature manuell angelegt wurden (ohne osmId).
  Future<List<(double, double)>> getCoordinates(int collectionId) async {
    final rows = await (select(mapMarkers)
          ..where((t) =>
              t.collectionId.equals(collectionId) &
              t.latitude.isNotNull() &
              t.longitude.isNotNull()))
        .get();
    return rows.map((r) => (r.latitude!, r.longitude!)).toList();
  }

  /// Fügt neue Marker gebündelt ein (z.B. ein Import-Chunk). Kein
  /// Conflict-Handling — Dedupe passiert vorher in der aufrufenden Logik.
  Future<int> bulkInsertNew(List<MapMarkersCompanion> rows) async {
    await batch((b) => b.insertAll(mapMarkers, rows));
    return rows.length;
  }
}

import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'marker_photos_dao.g.dart';

@DriftAccessor(tables: [MarkerPhotos, MapMarkers])
class MarkerPhotosDao extends DatabaseAccessor<TraumDatabase>
    with _$MarkerPhotosDaoMixin {
  MarkerPhotosDao(super.db);

  /// One-shot read of all photos (most recent first) — used by home widgets.
  Future<List<MarkerPhoto>> getAll() =>
      (select(markerPhotos)..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
          .get();

  Future<List<MarkerPhoto>> getByMarker(int markerId) =>
      (select(markerPhotos)
            ..where((t) => t.markerId.equals(markerId))
            ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
          .get();

  /// Fotos für mehrere Marker in einer einzigen Query statt einer Query pro
  /// Marker — verhindert das N+1-Problem beim Zusammenstellen einer
  /// Marker-Liste (z.B. für die Kartenansicht) mit vielen Markern.
  Future<Map<int, List<MarkerPhoto>>> getByMarkerIds(
      List<int> markerIds) async {
    if (markerIds.isEmpty) return {};
    final rows = await (select(markerPhotos)
          ..where((t) => t.markerId.isIn(markerIds))
          ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
        .get();
    final byMarker = <int, List<MarkerPhoto>>{};
    for (final row in rows) {
      byMarker.putIfAbsent(row.markerId, () => []).add(row);
    }
    return byMarker;
  }

  /// Alle Fotos einer Collection (über den zugehörigen Marker gejoint).
  Future<List<MarkerPhoto>> getByCollection(int collectionId) {
    final query = select(markerPhotos).join([
      innerJoin(mapMarkers, mapMarkers.id.equalsExp(markerPhotos.markerId)),
    ])..where(mapMarkers.collectionId.equals(collectionId));
    return query.map((row) => row.readTable(markerPhotos)).get();
  }

  Future<int> insert(MarkerPhotosCompanion c) => into(markerPhotos).insert(c);

  /// Hängt ein Foto an einen anderen Marker um.
  Future<void> moveToMarker(int photoId, int markerId) =>
      (update(markerPhotos)..where((t) => t.id.equals(photoId)))
          .write(MarkerPhotosCompanion(markerId: Value(markerId)));

  Future<void> deletePhoto(int id) =>
      (delete(markerPhotos)..where((t) => t.id.equals(id))).go();
}

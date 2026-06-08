import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'marker_photos_dao.g.dart';

@DriftAccessor(tables: [MarkerPhotos, MapMarkers])
class MarkerPhotosDao extends DatabaseAccessor<TraumDatabase>
    with _$MarkerPhotosDaoMixin {
  MarkerPhotosDao(super.db);

  Future<List<MarkerPhoto>> getByMarker(int markerId) =>
      (select(markerPhotos)
            ..where((t) => t.markerId.equals(markerId))
            ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
          .get();

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

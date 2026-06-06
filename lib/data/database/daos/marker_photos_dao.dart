import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'marker_photos_dao.g.dart';

@DriftAccessor(tables: [MarkerPhotos])
class MarkerPhotosDao extends DatabaseAccessor<TraumDatabase>
    with _$MarkerPhotosDaoMixin {
  MarkerPhotosDao(super.db);

  Future<List<MarkerPhoto>> getByMarker(int markerId) =>
      (select(markerPhotos)
            ..where((t) => t.markerId.equals(markerId))
            ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
          .get();

  Future<int> insert(MarkerPhotosCompanion c) => into(markerPhotos).insert(c);

  Future<void> deletePhoto(int id) =>
      (delete(markerPhotos)..where((t) => t.id.equals(id))).go();
}

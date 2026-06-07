import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('marker photo stores and reads its own coordinates', () async {
    final collId = await db.mapCollectionsDao.insert(
      MapCollectionsCompanion.insert(
          name: 'C', iconName: 'map', createdAt: DateTime.now()),
    );
    final markerId = await db.mapMarkersDao.insert(
      MapMarkersCompanion.insert(collectionId: collId, createdAt: DateTime.now()),
    );
    final photoId = await db.markerPhotosDao.insert(
      MarkerPhotosCompanion.insert(
        markerId: markerId,
        photoPath: '/tmp/a.jpg',
        latitude: const Value(52.5),
        longitude: const Value(13.4),
        takenAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    final photos = await db.markerPhotosDao.getByMarker(markerId);
    expect(photos.single.id, photoId);
    expect(photos.single.latitude, 52.5);
    expect(photos.single.longitude, 13.4);
  });
}

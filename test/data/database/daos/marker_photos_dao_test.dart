import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TraumDatabase db;
  late int collectionId;
  setUp(() async {
    db = TraumDatabase.forTesting(NativeDatabase.memory());
    collectionId = await db.mapCollectionsDao.insert(
      MapCollectionsCompanion.insert(
        name: 'Test',
        iconName: 'tower',
        createdAt: DateTime.now(),
      ),
    );
  });
  tearDown(() => db.close());

  Future<int> addMarker() => db.mapMarkersDao.insert(
        MapMarkersCompanion.insert(
          collectionId: collectionId,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> addPhoto(int markerId, String path) =>
      db.markerPhotosDao.insert(MarkerPhotosCompanion.insert(
        markerId: markerId,
        photoPath: path,
        takenAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

  group('getByMarkerIds', () {
    test('returns an empty map for an empty id list', () async {
      expect(await db.markerPhotosDao.getByMarkerIds(const []), isEmpty);
    });

    test('groups photos by marker id in a single query', () async {
      final m1 = await addMarker();
      final m2 = await addMarker();
      final m3 = await addMarker(); // no photos
      await addPhoto(m1, '/a.jpg');
      await addPhoto(m1, '/b.jpg');
      await addPhoto(m2, '/c.jpg');

      final result = await db.markerPhotosDao.getByMarkerIds([m1, m2, m3]);

      expect(result[m1]?.map((p) => p.photoPath).toSet(),
          {'/a.jpg', '/b.jpg'});
      expect(result[m2]?.map((p) => p.photoPath).toList(), ['/c.jpg']);
      expect(result.containsKey(m3), isFalse);
    });

    test('does not return photos belonging to markers outside the id list',
        () async {
      final m1 = await addMarker();
      final m2 = await addMarker();
      await addPhoto(m1, '/a.jpg');
      await addPhoto(m2, '/b.jpg');

      final result = await db.markerPhotosDao.getByMarkerIds([m1]);

      expect(result.keys, [m1]);
    });
  });
}

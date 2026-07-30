import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

Future<int> _insertCollection(TraumDatabase db, {String iconName = 'tower'}) {
  return db.mapCollectionsDao.insert(MapCollectionsCompanion.insert(
    name: 'Test',
    iconName: iconName,
    createdAt: DateTime.now(),
  ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('countAll', () {
    test('returns 0 for an empty table', () async {
      expect(await db.mapMarkersDao.countAll(), 0);
    });

    test('counts markers across all collections without loading rows',
        () async {
      final a = await _insertCollection(db, iconName: 'a');
      final b = await _insertCollection(db, iconName: 'b');
      for (var i = 0; i < 5; i++) {
        await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
          collectionId: a,
          createdAt: DateTime.now(),
        ));
      }
      for (var i = 0; i < 3; i++) {
        await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
          collectionId: b,
          createdAt: DateTime.now(),
        ));
      }
      expect(await db.mapMarkersDao.countAll(), 8);
    });
  });

  group('getMostRecentByCollection', () {
    test('returns null for a collection with no markers', () async {
      final id = await _insertCollection(db);
      expect(await db.mapMarkersDao.getMostRecentByCollection(id), isNull);
    });

    test('returns the most recently created marker for that collection',
        () async {
      final id = await _insertCollection(db);
      final other = await _insertCollection(db, iconName: 'other');
      await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
        collectionId: id,
        title: const Value('older'),
        createdAt: DateTime(2020),
      ));
      final newestId =
          await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
        collectionId: id,
        title: const Value('newest'),
        createdAt: DateTime(2024),
      ));
      await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
        collectionId: other,
        title: const Value('wrong collection'),
        createdAt: DateTime(2030),
      ));

      final result = await db.mapMarkersDao.getMostRecentByCollection(id);
      expect(result?.id, newestId);
      expect(result?.title, 'newest');
    });
  });

  group('getByCollectionInBounds', () {
    test('only returns markers inside the given lat/lon range', () async {
      final id = await _insertCollection(db);
      Future<void> addAt(double lat, double lon) =>
          db.mapMarkersDao.insert(MapMarkersCompanion.insert(
            collectionId: id,
            latitude: Value(lat),
            longitude: Value(lon),
            createdAt: DateTime.now(),
          ));

      await addAt(52.0, 13.0); // inside
      await addAt(52.5, 13.5); // inside (edge)
      await addAt(10.0, 10.0); // outside (lat)
      await addAt(52.0, 100.0); // outside (lon)

      final result = await db.mapMarkersDao.getByCollectionInBounds(
        id,
        minLat: 51.0,
        maxLat: 53.0,
        minLon: 12.0,
        maxLon: 14.0,
      );

      expect(result.length, 2);
      expect(result.every((m) => m.latitude! >= 51.0 && m.latitude! <= 53.0),
          isTrue);
    });

    test('ignores markers from other collections', () async {
      final id = await _insertCollection(db);
      final other = await _insertCollection(db, iconName: 'other');
      await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
        collectionId: id,
        latitude: const Value(52.0),
        longitude: const Value(13.0),
        createdAt: DateTime.now(),
      ));
      await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
        collectionId: other,
        latitude: const Value(52.0),
        longitude: const Value(13.0),
        createdAt: DateTime.now(),
      ));

      final result = await db.mapMarkersDao.getByCollectionInBounds(
        id,
        minLat: 51.0,
        maxLat: 53.0,
        minLon: 12.0,
        maxLon: 14.0,
      );

      expect(result.length, 1);
    });

    test('respects the limit parameter', () async {
      final id = await _insertCollection(db);
      for (var i = 0; i < 10; i++) {
        await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
          collectionId: id,
          latitude: const Value(52.0),
          longitude: const Value(13.0),
          createdAt: DateTime.now(),
        ));
      }

      final result = await db.mapMarkersDao.getByCollectionInBounds(
        id,
        minLat: 51.0,
        maxLat: 53.0,
        minLon: 12.0,
        maxLon: 14.0,
        limit: 4,
      );

      expect(result.length, 4);
    });

    test('markers without coordinates are excluded', () async {
      final id = await _insertCollection(db);
      await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
        collectionId: id,
        createdAt: DateTime.now(),
        // no latitude/longitude
      ));

      final result = await db.mapMarkersDao.getByCollectionInBounds(
        id,
        minLat: -90.0,
        maxLat: 90.0,
        minLon: -180.0,
        maxLon: 180.0,
      );

      expect(result, isEmpty);
    });
  });
}

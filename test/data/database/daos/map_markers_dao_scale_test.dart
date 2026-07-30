import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/repositories/map_collection_seeder.dart';
import 'package:traum/data/repositories/tower_data_seeder.dart';

/// Regression test at real scale: seeds the actual ~413k-row bundled towers
/// dataset and proves the bounded/counted queries this hotfix introduced
/// stay fast, instead of only checking correctness against a handful of
/// synthetic rows. This is the exact scale that made the map screen
/// unusable before the fix (unbounded getByCollection + N+1 photo queries).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'countAll and getByCollectionInBounds stay fast against the real ~413k tower dataset',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await MapCollectionSeeder.seedIfNeeded(db, prefs);
    await TowerDataSeeder.seedIfNeeded(db, prefs);

    final collections = await db.mapCollectionsDao.getAll();
    final towerCollection =
        collections.firstWhere((c) => c.iconName == 'tower');

    final countSw = Stopwatch()..start();
    final total = await db.mapMarkersDao.countAll();
    countSw.stop();
    expect(total, greaterThan(300000));
    expect(countSw.elapsedMilliseconds, lessThan(2000),
        reason: 'countAll() must not degrade into a full-table scan+load');

    // A real-world city-sized bounding box (Berlin) — should return a small
    // fraction of the ~413k total, not all of them, and do so quickly.
    final boundsSw = Stopwatch()..start();
    final inView = await db.mapMarkersDao.getByCollectionInBounds(
      towerCollection.id,
      minLat: 52.3,
      maxLat: 52.7,
      minLon: 13.0,
      maxLon: 13.7,
    );
    boundsSw.stop();
    expect(inView.length, lessThan(2000));
    expect(boundsSw.elapsedMilliseconds, lessThan(2000),
        reason:
            'a viewport-bounded query must not scale with total dataset size');

    // Photo batch-fetch for a realistic viewport-sized marker set must be a
    // single query, not one query per marker (the original N+1 bug).
    final photoSw = Stopwatch()..start();
    final photos = await db.markerPhotosDao
        .getByMarkerIds(inView.map((m) => m.id).toList());
    photoSw.stop();
    expect(photos, isA<Map<int, dynamic>>());
    expect(photoSw.elapsedMilliseconds, lessThan(1000));
  }, timeout: const Timeout(Duration(minutes: 3)));
}

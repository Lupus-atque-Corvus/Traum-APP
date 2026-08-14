import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/repositories/map_collection_seeder.dart';
import 'package:traum/data/repositories/tower_data_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'seedIfNeeded fills the Türme collection once and is idempotent',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = TraumDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await MapCollectionSeeder.seedIfNeeded(db, prefs);
      await TowerDataSeeder.seedIfNeeded(db, prefs);

      final collections = await db.mapCollectionsDao.getAll();
      final towerCollection = collections.firstWhere(
        (c) => c.iconName == 'tower',
      );
      final markers = await db.mapMarkersDao.getByCollection(
        towerCollection.id,
      );

      expect(markers.length, greaterThan(300000));
      expect(markers.every((m) => m.osmId != null), isTrue);
      expect(markers.any((m) => m.customFields.contains('Funkmast')), isTrue);

      // Second run must not duplicate.
      await TowerDataSeeder.seedIfNeeded(db, prefs);
      final afterSecond = await db.mapMarkersDao.getByCollection(
        towerCollection.id,
      );
      expect(afterSecond.length, markers.length);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'does nothing (no flag) if the Türme collection does not exist yet',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = TraumDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      // MapCollectionSeeder deliberately not run first.

      await TowerDataSeeder.seedIfNeeded(db, prefs);

      expect(prefs.getBool('tower_data_seeded_v1'), isNull);
      final all = await db.mapMarkersDao.getAll();
      expect(all, isEmpty);
    },
  );

  test('does not set the flag when seeding fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await MapCollectionSeeder.seedIfNeeded(db, prefs);
    // Drop the table so the seeder's bulk insert throws a real SQL error,
    // exercising the catch block and the "flag stays unset" invariant.
    await db.customStatement('DROP TABLE map_markers');

    await TowerDataSeeder.seedIfNeeded(db, prefs);

    expect(prefs.getBool('tower_data_seeded_v1'), isNull);
  });

  test('secondary guard: existing osmId rows skip re-seeding', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await MapCollectionSeeder.seedIfNeeded(db, prefs);
    final collections = await db.mapCollectionsDao.getAll();
    final towerCollection = collections.firstWhere(
      (c) => c.iconName == 'tower',
    );
    await db.mapMarkersDao.insert(
      MapMarkersCompanion.insert(
        collectionId: towerCollection.id,
        osmId: const Value('node/1'),
        createdAt: DateTime.now(),
      ),
    );

    await TowerDataSeeder.seedIfNeeded(db, prefs);

    expect(prefs.getBool('tower_data_seeded_v1'), isTrue);
    final markers = await db.mapMarkersDao.getByCollection(towerCollection.id);
    expect(markers.length, 1); // did not bulk-insert the real dataset on top
  });
}

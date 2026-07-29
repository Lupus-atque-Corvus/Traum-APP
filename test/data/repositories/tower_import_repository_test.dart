import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/repositories/overpass_tower_repository.dart';
import 'package:traum/data/repositories/tower_import_repository.dart';

class _FakeOverpassTowerRepository extends OverpassTowerRepository {
  final List<OverpassTowerResult> results;
  _FakeOverpassTowerRepository(this.results);

  @override
  Future<List<OverpassTowerResult>> fetchTowers(OverpassAreaQuery query) async =>
      results;
}

void main() {
  late TraumDatabase db;
  late int collectionId;

  setUp(() async {
    db = TraumDatabase.forTesting(NativeDatabase.memory());
    collectionId = await db.mapCollectionsDao.insert(
      MapCollectionsCompanion.insert(
        name: 'Türme',
        iconName: 'tower',
        fieldConfig: const Value('{}'),
        createdAt: DateTime.now(),
      ),
    );
  });
  tearDown(() => db.close());

  test(
      'dedupes by osmId and coordinate tolerance, inserts new towers with '
      'correct customFields', () async {
    // Bestandsmarker: einer bereits importiert (osmId), einer manuell
    // angelegt (keine osmId, aber Koordinate identisch mit einem Ergebnis).
    await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
      collectionId: collectionId,
      latitude: const Value(52.5),
      longitude: const Value(13.4),
      osmId: const Value('node/1'),
      createdAt: DateTime.now(),
    ));
    await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
      collectionId: collectionId,
      latitude: const Value(48.1351),
      longitude: const Value(11.5820),
      createdAt: DateTime.now(),
    ));

    final fake = _FakeOverpassTowerRepository(const [
      OverpassTowerResult(osmId: 'node/1', latitude: 52.5, longitude: 13.4),
      OverpassTowerResult(
          osmId: 'node/2', latitude: 48.1351, longitude: 11.5820),
      OverpassTowerResult(
        osmId: 'node/3',
        latitude: 50.0,
        longitude: 8.0,
        name: 'Neuer Funkmast',
        towerType: 'communication',
        heightMeters: '60',
        operatorName: 'Vodafone',
      ),
    ]);

    final repo = TowerImportRepository(db.mapMarkersDao, fake);
    final events = await repo
        .importTowers(
          collectionId: collectionId,
          query: const OverpassBboxQuery(south: 0, west: 0, north: 90, east: 90),
        )
        .toList();

    final last = events.last;
    expect(last.total, 3);
    expect(last.imported, 1);
    expect(last.skipped, 2);
    expect(last.errors, 0);

    final markers = await db.mapMarkersDao.getByCollection(collectionId);
    expect(markers.length, 3); // 2 Bestand + 1 neu
    final newMarker = markers.firstWhere((m) => m.osmId == 'node/3');
    expect(newMarker.title, 'Neuer Funkmast');
    expect(newMarker.customFields, contains('Funkmast'));
    expect(newMarker.customFields, contains('60'));
    expect(newMarker.customFields, contains('Vodafone'));
  });

  test('re-importing the same result set skips everything (osmId dedupe)',
      () async {
    final fake = _FakeOverpassTowerRepository(const [
      OverpassTowerResult(osmId: 'node/9', latitude: 1.0, longitude: 1.0),
    ]);
    final repo = TowerImportRepository(db.mapMarkersDao, fake);
    const query = OverpassBboxQuery(south: 0, west: 0, north: 2, east: 2);

    final first = await repo
        .importTowers(collectionId: collectionId, query: query)
        .toList();
    expect(first.last.imported, 1);

    final second = await repo
        .importTowers(collectionId: collectionId, query: query)
        .toList();
    expect(second.last.imported, 0);
    expect(second.last.skipped, 1);
  });

  test('empty Overpass result yields a single zero-progress event', () async {
    final repo =
        TowerImportRepository(db.mapMarkersDao, _FakeOverpassTowerRepository(const []));
    final events = await repo
        .importTowers(
          collectionId: collectionId,
          query: const OverpassBboxQuery(south: 0, west: 0, north: 1, east: 1),
        )
        .toList();
    expect(events, hasLength(1));
    expect(events.single.total, 0);
    expect(events.single.imported, 0);
  });
}

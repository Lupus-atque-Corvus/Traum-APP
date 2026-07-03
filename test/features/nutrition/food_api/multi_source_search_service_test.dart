import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/nutrition/food_api/food_source.dart';
import 'package:traum/features/nutrition/food_api/multi_source_search_service.dart';

/// Test-Double für [FoodSource]: liefert vorab festgelegte Ergebnisse ohne
/// Netzwerk.
class _FakeSource implements FoodSource {
  @override
  final String id;
  final List<FoodSearchResult> results;

  _FakeSource(this.id, this.results);

  @override
  Future<List<FoodSearchResult>> search(String query) async => results;
}

/// Test-Double, das immer wirft — simuliert eine Quelle, die down ist.
class _FailingSource implements FoodSource {
  @override
  String get id => 'failing';

  @override
  Future<List<FoodSearchResult>> search(String query) async {
    throw Exception('network down');
  }
}

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('localToResults', () {
    test('maps FoodProduct fields to FoodSearchResult with source local', () async {
      final id = await db.foodProductsDao.insertProduct(
        FoodProductsCompanion.insert(
          name: 'Haferflocken',
          brand: const Value('Marke'),
          barcode: const Value('123456'),
          caloriesPer100g: 370,
          proteinPer100g: 13.5,
          carbsPer100g: 58.7,
          fatPer100g: 7.0,
          createdAt: DateTime.now(),
        ),
      );
      final product = (await db.foodProductsDao.getById(id))!;

      final results = localToResults([product]);
      expect(results, hasLength(1));
      expect(results.single.source, 'local');
      expect(results.single.sourceId, id.toString());
      expect(results.single.name, 'Haferflocken');
      expect(results.single.barcode, '123456');
      expect(results.single.kcalPer100g, 370);
    });
  });

  group('MultiSourceSearchService.search', () {
    test('combines local + remote sources into a ranked list', () async {
      await db.foodProductsDao.insertProduct(
        FoodProductsCompanion.insert(
          name: 'Reis',
          caloriesPer100g: 130,
          proteinPer100g: 2.7,
          carbsPer100g: 28,
          fatPer100g: 0.3,
          createdAt: DateTime.now(),
        ),
      );

      final remoteOff = _FakeSource('off', [
        const FoodSearchResult(
          name: 'Reis Basmati',
          kcalPer100g: 350,
          proteinPer100g: 7,
          carbsPer100g: 78,
          fatPer100g: 0.6,
          source: 'off',
          sourceId: 'off-1',
        ),
      ]);

      final service = MultiSourceSearchService([remoteOff], db.foodProductsDao);
      final results = await service.search('reis');

      expect(results, isNotEmpty);
      expect(results.any((r) => r.source == 'local'), isTrue);
      expect(results.any((r) => r.source == 'off'), isTrue);
    });

    test('a failing source is swallowed — other sources still return',
        () async {
      final ok = _FakeSource('usda', [
        const FoodSearchResult(
          name: 'Chicken breast',
          kcalPer100g: 165,
          proteinPer100g: 31,
          carbsPer100g: 0,
          fatPer100g: 3.6,
          source: 'usda',
          sourceId: 'usda-1',
        ),
      ]);
      final failing = _FailingSource();

      final service =
          MultiSourceSearchService([ok, failing], db.foodProductsDao);
      final results = await service.search('chicken');

      expect(results, hasLength(1));
      expect(results.single.source, 'usda');
    });

    test('empty query returns no results without querying sources',
        () async {
      final source = _FakeSource('off', [
        const FoodSearchResult(
          name: 'Should not appear',
          kcalPer100g: 100,
          proteinPer100g: 1,
          carbsPer100g: 1,
          fatPer100g: 1,
          source: 'off',
        ),
      ]);
      final service = MultiSourceSearchService([source], db.foodProductsDao);
      final results = await service.search('   ');
      expect(results, isEmpty);
    });
  });

  group('FoodProductsDao.upsertFromSource', () {
    test('inserts a new product when nothing matches', () async {
      final companion = FoodProductsCompanion.insert(
        name: 'Neues Produkt',
        barcode: const Value('999'),
        caloriesPer100g: 200,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
        sourceApi: const Value('off'),
        sourceId: const Value('999'),
        createdAt: DateTime.now(),
      );
      final product = await db.foodProductsDao.upsertFromSource(companion);
      expect(product.name, 'Neues Produkt');

      final all = await db.foodProductsDao.getAll();
      expect(all, hasLength(1));
    });

    test('matches existing row by barcode and updates instead of duplicating',
        () async {
      final firstId = await db.foodProductsDao.insertProduct(
        FoodProductsCompanion.insert(
          name: 'Alter Name',
          barcode: const Value('4000'),
          caloriesPer100g: 100,
          proteinPer100g: 1,
          carbsPer100g: 1,
          fatPer100g: 1,
          createdAt: DateTime.now(),
        ),
      );

      final updateCompanion = FoodProductsCompanion.insert(
        name: 'Neuer Name',
        barcode: const Value('4000'),
        caloriesPer100g: 250,
        proteinPer100g: 9,
        carbsPer100g: 9,
        fatPer100g: 9,
        sourceApi: const Value('off'),
        sourceId: const Value('4000'),
        createdAt: DateTime.now(),
      );
      final product =
          await db.foodProductsDao.upsertFromSource(updateCompanion);

      expect(product.id, firstId);
      expect(product.name, 'Neuer Name');
      expect(product.caloriesPer100g, 250);

      final all = await db.foodProductsDao.getAll();
      expect(all, hasLength(1));
    });

    test('matches existing row by sourceApi+sourceId when no barcode',
        () async {
      final firstId = await db.foodProductsDao.insertProduct(
        FoodProductsCompanion.insert(
          name: 'USDA Cache',
          caloriesPer100g: 100,
          proteinPer100g: 1,
          carbsPer100g: 1,
          fatPer100g: 1,
          sourceApi: const Value('usda'),
          sourceId: const Value('42'),
          createdAt: DateTime.now(),
        ),
      );

      final updateCompanion = FoodProductsCompanion.insert(
        name: 'USDA Cache Refreshed',
        caloriesPer100g: 120,
        proteinPer100g: 2,
        carbsPer100g: 2,
        fatPer100g: 2,
        sourceApi: const Value('usda'),
        sourceId: const Value('42'),
        createdAt: DateTime.now(),
      );
      final product =
          await db.foodProductsDao.upsertFromSource(updateCompanion);

      expect(product.id, firstId);
      expect(product.name, 'USDA Cache Refreshed');

      final all = await db.foodProductsDao.getAll();
      expect(all, hasLength(1));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/nutrition/food_api/open_food_facts_source.dart';
import 'package:traum/features/nutrition/food_api/usda_source.dart';

void main() {
  test('OFF search JSON parses to results', () {
    final json = {
      'products': [
        {
          'product_name': 'Haferflocken',
          'brands': 'Marke',
          'code': '4000...',
          'nutriments': {
            'energy-kcal_100g': 370,
            'proteins_100g': 13.5,
            'carbohydrates_100g': 58.7,
            'fat_100g': 7.0,
          },
        }
      ]
    };
    final results = parseOffSearch(json);
    expect(results.single.name, 'Haferflocken');
    expect(results.single.kcalPer100g, 370);
    expect(results.single.source, 'off');
  });

  test('USDA search JSON parses to results (nutrient ids)', () {
    final json = {
      'foods': [
        {
          'description': 'Chicken breast',
          'fdcId': 12345,
          'foodNutrients': [
            {'nutrientId': 1008, 'value': 165.0}, // kcal
            {'nutrientId': 1003, 'value': 31.0}, // protein
            {'nutrientId': 1005, 'value': 0.0}, // carbs
            {'nutrientId': 1004, 'value': 3.6}, // fat
          ],
        }
      ]
    };
    final results = parseUsdaSearch(json);
    expect(results.single.proteinPer100g, 31.0);
    expect(results.single.source, 'usda');
  });

  test('OFF search sets sourceId from barcode/code and brand', () {
    final json = {
      'products': [
        {
          'product_name': 'Testprodukt',
          'brands': 'Marke X',
          'code': '4000123456',
          'image_thumb_url': 'https://example.com/img.jpg',
          'nutriments': {
            'energy-kcal_100g': 100,
            'proteins_100g': 1,
            'carbohydrates_100g': 2,
            'fat_100g': 3,
            'sugars_100g': 4,
            'fiber_100g': 5,
            'salt_100g': 0.6,
          },
        }
      ]
    };
    final results = parseOffSearch(json);
    final r = results.single;
    expect(r.sourceId, '4000123456');
    expect(r.barcode, '4000123456');
    expect(r.brand, 'Marke X');
    expect(r.imageUrl, 'https://example.com/img.jpg');
    expect(r.sugarPer100g, 4);
    expect(r.fiberPer100g, 5);
    expect(r.saltPer100g, 0.6);
  });

  test('OFF search is defensive against missing nutriments and skips products '
      'without a usable name', () {
    final json = {
      'products': [
        {'product_name': 'Ohne Nährwerte', 'code': '1'},
        {'code': '2'}, // no product_name -> should be skipped
        null, // malformed entry -> should be skipped
      ]
    };
    final results = parseOffSearch(json);
    expect(results.length, 1);
    expect(results.single.name, 'Ohne Nährwerte');
    expect(results.single.kcalPer100g, 0);
  });

  test('OFF search returns empty list when products key missing/malformed', () {
    expect(parseOffSearch({}), isEmpty);
    expect(parseOffSearch({'products': 'not a list'}), isEmpty);
  });

  test('USDA search sets sourceId from fdcId as String', () {
    final json = {
      'foods': [
        {
          'description': 'Apple',
          'fdcId': 987654,
          'foodNutrients': [
            {'nutrientId': 1008, 'value': 52.0},
            {'nutrientId': 2000, 'value': 10.4},
            {'nutrientId': 1079, 'value': 2.4},
            {'nutrientId': 1093, 'value': 1.0}, // sodium mg -> salt g
          ],
        }
      ]
    };
    final results = parseUsdaSearch(json);
    final r = results.single;
    expect(r.sourceId, '987654');
    expect(r.source, 'usda');
    expect(r.sugarPer100g, 10.4);
    expect(r.fiberPer100g, 2.4);
    // salt = sodium(mg) * 2.5 / 1000
    expect(r.saltPer100g, closeTo(0.0025, 1e-9));
  });

  test('USDA search is defensive against missing foodNutrients', () {
    final json = {
      'foods': [
        {'description': 'Mystery food', 'fdcId': 1},
        {'fdcId': 2}, // no description -> should be skipped
      ]
    };
    final results = parseUsdaSearch(json);
    expect(results.length, 1);
    expect(results.single.name, 'Mystery food');
    expect(results.single.kcalPer100g, 0);
  });

  test('USDA search returns empty list when foods key missing/malformed', () {
    expect(parseUsdaSearch({}), isEmpty);
    expect(parseUsdaSearch({'foods': 'not a list'}), isEmpty);
  });

  test('completeness reflects fraction of populated optional nutrient fields', () {
    final full = {
      'foods': [
        {
          'description': 'Complete food',
          'fdcId': 1,
          'foodNutrients': [
            {'nutrientId': 1008, 'value': 100.0},
            {'nutrientId': 1003, 'value': 1.0},
            {'nutrientId': 1005, 'value': 1.0},
            {'nutrientId': 1004, 'value': 1.0},
            {'nutrientId': 2000, 'value': 1.0},
            {'nutrientId': 1079, 'value': 1.0},
            {'nutrientId': 1093, 'value': 1.0},
          ],
        }
      ]
    };
    final sparse = {
      'foods': [
        {
          'description': 'Sparse food',
          'fdcId': 2,
          'foodNutrients': [
            {'nutrientId': 1008, 'value': 100.0},
          ],
        }
      ]
    };
    final fullResult = parseUsdaSearch(full).single;
    final sparseResult = parseUsdaSearch(sparse).single;
    expect(fullResult.completeness, 1.0);
    expect(sparseResult.completeness, lessThan(fullResult.completeness));
    expect(sparseResult.completeness, greaterThanOrEqualTo(0.0));
  });
}

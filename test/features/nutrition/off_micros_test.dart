import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/nutrition/open_food_facts_service.dart';

void main() {
  test('buildProductCompanion fills microsJson from nutriments', () {
    final c = buildProductCompanion('123', {
      'product_name': 'Orangensaft',
      'nutriments': {
        'energy-kcal_100g': 45,
        'proteins_100g': 0.7,
        'carbohydrates_100g': 10,
        'fat_100g': 0.2,
        'sugars_100g': 9,
        'vitamin-c_100g': 0.05, // 50 mg
        'calcium_100g': 0.011, // 11 mg
      },
    });
    expect(c.caloriesPer100g.value, 45);
    expect(c.sugarPer100g.value, 9);
    expect(c.microsJson.value, isNotNull);
    expect(c.microsJson.value, contains('vitC'));
    expect(c.microsJson.value, contains('calcium'));
  });

  test('buildProductCompanion leaves microsJson null when no micros', () {
    final c = buildProductCompanion('123', {
      'product_name': 'Wasser',
      'nutriments': {'energy-kcal_100g': 0},
    });
    expect(c.microsJson.value, isNull);
  });
}

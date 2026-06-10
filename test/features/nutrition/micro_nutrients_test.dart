import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/nutrition/micro_nutrients.dart';

void main() {
  group('MicroNutrients', () {
    test('fromJson(null) and fromJson("") yield empty', () {
      expect(MicroNutrients.fromJson(null).values, isEmpty);
      expect(MicroNutrients.fromJson('').values, isEmpty);
    });

    test('JSON roundtrip preserves values', () {
      const m = MicroNutrients({'vitC': 12.5, 'iron': 3.0});
      final back = MicroNutrients.fromJson(m.toJson());
      expect(back.values['vitC'], 12.5);
      expect(back.values['iron'], 3.0);
    });

    test('toNullableJson returns null when empty', () {
      expect(const MicroNutrients({}).toNullableJson(), isNull);
      expect(const MicroNutrients({'iron': 1.0}).toNullableJson(), isNotNull);
    });

    test('operator + sums keywise, union of keys', () {
      const a = MicroNutrients({'vitC': 10, 'iron': 2});
      const b = MicroNutrients({'vitC': 5, 'zinc': 1});
      final sum = a + b;
      expect(sum.values['vitC'], 15);
      expect(sum.values['iron'], 2);
      expect(sum.values['zinc'], 1);
    });

    test('scale multiplies all values', () {
      const a = MicroNutrients({'vitC': 10, 'iron': 2});
      final s = a.scale(0.5);
      expect(s.values['vitC'], 5);
      expect(s.values['iron'], 1);
    });
  });

  group('kNutrientCatalog', () {
    test('has the 12 expected keys in order', () {
      expect(kNutrientCatalog.map((n) => n.key).toList(), [
        'sugar', 'fiber', 'satFat', 'salt',
        'vitC', 'vitD', 'vitB12', 'calcium',
        'iron', 'magnesium', 'zinc', 'potassium',
      ]);
    });

    test('panel nutrients carry an OFF key, extended ones do not', () {
      final byKey = {for (final n in kNutrientCatalog) n.key: n};
      expect(byKey['sugar']!.offKey, isNull);
      expect(byKey['vitC']!.offKey, 'vitamin-c_100g');
      expect(byKey['vitD']!.unit, 'µg');
      expect(byKey['calcium']!.dailyRef, 1000);
    });
  });
}

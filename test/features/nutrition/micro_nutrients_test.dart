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

  group('normalizeDose', () {
    test('mg-nutrient: g→mg, mg→mg, µg→mg', () {
      expect(normalizeDose(1, 'g', 'iron'), 1000);
      expect(normalizeDose(14, 'mg', 'iron'), 14);
      expect(normalizeDose(1000, 'µg', 'iron'), 1);
    });

    test('µg-nutrient: mb→µg, µg→µg', () {
      expect(normalizeDose(1, 'mg', 'vitD'), 1000);
      expect(normalizeDose(20, 'µg', 'vitD'), 20);
    });

    test('IU only valid for vitD (µg = IU/40)', () {
      expect(normalizeDose(1000, 'IU', 'vitD'), 25);
      expect(normalizeDose(1000, 'IU', 'iron'), isNull);
    });

    test('non-convertible units yield null', () {
      expect(normalizeDose(1, 'Kapsel(n)', 'iron'), isNull);
      expect(normalizeDose(1, 'ml', 'magnesium'), isNull);
    });
  });

  group('suggestNutrientKey', () {
    test('maps common synonyms', () {
      expect(suggestNutrientKey('Vitamin D3'), 'vitD');
      expect(suggestNutrientKey('Cholecalciferol'), 'vitD');
      expect(suggestNutrientKey('Magnesiumcitrat'), 'magnesium');
      expect(suggestNutrientKey('B12 Tropfen'), 'vitB12');
      expect(suggestNutrientKey('Eisen Bisglycinat'), 'iron');
      expect(suggestNutrientKey('Zink'), 'zinc');
    });

    test('unknown name → null', () {
      expect(suggestNutrientKey('Kreatin'), isNull);
    });
  });

  group('supplementContribution', () {
    test('builds single-key MicroNutrients from dose', () {
      final c = supplementContribution(
          nutrientKey: 'vitD', dosageAmount: '1000', dosageUnit: 'IU');
      expect(c.values, {'vitD': 25});
    });

    test('empty when no nutrientKey', () {
      expect(supplementContribution(
              nutrientKey: null, dosageAmount: '400', dosageUnit: 'mg')
          .values, isEmpty);
    });

    test('empty when dose unparseable or non-convertible', () {
      expect(supplementContribution(
              nutrientKey: 'iron', dosageAmount: 'x', dosageUnit: 'mg')
          .values, isEmpty);
      expect(supplementContribution(
              nutrientKey: 'iron', dosageAmount: '1', dosageUnit: 'Kapsel(n)')
          .values, isEmpty);
    });
  });

  group('offProductMicros', () {
    test('normalizes OFF gram values to canonical units', () {
      final m = offProductMicros({
        'vitamin-c_100g': 0.06, // 60 mg
        'calcium_100g': 0.12,   // 120 mg
        'vitamin-d_100g': 0.00001, // 10 µg
      });
      expect(m.values['vitC'], closeTo(60, 0.001));
      expect(m.values['calcium'], closeTo(120, 0.001));
      expect(m.values['vitD'], closeTo(10, 0.001));
    });

    test('ignores missing / non-numeric fields', () {
      final m = offProductMicros({'iron_100g': 'n/a'});
      expect(m.values, isEmpty);
    });
  });
}

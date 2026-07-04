import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/nutrition/food_api/food_source.dart';
import 'package:traum/features/nutrition/food_api/multi_source_aggregator.dart';

FoodSearchResult _r({
  required String name,
  String? brand,
  required double kcal,
  double protein = 0,
  double carbs = 0,
  double fat = 0,
  double? sugar,
  double? fiber,
  double? salt,
  required String source,
  String? sourceId,
  String? barcode,
  String? imageUrl,
  int? localId,
}) {
  return FoodSearchResult(
    name: name,
    brand: brand,
    kcalPer100g: kcal,
    proteinPer100g: protein,
    carbsPer100g: carbs,
    fatPer100g: fat,
    sugarPer100g: sugar,
    fiberPer100g: fiber,
    saltPer100g: salt,
    source: source,
    sourceId: sourceId,
    barcode: barcode,
    imageUrl: imageUrl,
    localId: localId,
  );
}

void main() {
  group('normalize', () {
    test('lowercases, replaces Umlaute/ß, collapses whitespace, trims', () {
      expect(normalize('  Käse  Brötchen  '), 'kase brotchen');
      expect(normalize('WEISSBROT'), 'weissbrot');
      expect(normalize('Straße'), 'strasse');
      expect(normalize('Müsli  mit   Nüssen'), 'musli mit nussen');
    });
  });

  group('aggregateAndRank', () {
    test('empty sources produce empty result', () {
      expect(aggregateAndRank('apfel', []), isEmpty);
      expect(aggregateAndRank('apfel', [[], []]), isEmpty);
    });

    test('dedupe-merge: near-equal kcal (<10%) merges into one, averages '
        'macros, prefers first non-null descriptive field by priority', () {
      final local = _r(
        name: 'Apfel',
        brand: 'Bio',
        kcal: 100,
        protein: 0.3,
        carbs: 14,
        fat: 0.2,
        source: 'local',
      );
      final off = _r(
        name: 'Apfel',
        brand: 'Bio',
        kcal: 105,
        protein: 0.5,
        carbs: 13,
        fat: 0.4,
        sugar: 10.0,
        imageUrl: 'https://example.com/apfel.jpg',
        source: 'off',
      );

      final result = aggregateAndRank('apfel', [
        [local],
        [off],
      ]);

      expect(result.length, 1);
      final merged = result.single;
      expect(merged.source, 'merged');
      expect(merged.kcalPer100g, closeTo(102.5, 1e-9));
      expect(merged.proteinPer100g, closeTo(0.4, 1e-9));
      expect(merged.carbsPer100g, closeTo(13.5, 1e-9));
      expect(merged.fatPer100g, closeTo(0.3, 1e-9));
      // sugar only present on the off-result -> averaging non-null values
      // yields that single value, not null.
      expect(merged.sugarPer100g, closeTo(10.0, 1e-9));
      // fiber/salt absent on both -> stays null.
      expect(merged.fiberPer100g, isNull);
      expect(merged.saltPer100g, isNull);
      // imageUrl: local has none (null), off has one -> first non-null wins.
      expect(merged.imageUrl, 'https://example.com/apfel.jpg');
      // brand identical on both -> stays 'Bio'.
      expect(merged.brand, 'Bio');
    });

    test('conflict-keep-both: same name/brand but kcal >=10% apart keeps '
        'both results untouched', () {
      final local = _r(
        name: 'Riegel',
        brand: 'Marke',
        kcal: 100,
        source: 'local',
      );
      final off = _r(
        name: 'Riegel',
        brand: 'Marke',
        kcal: 130,
        source: 'off',
      );

      final result = aggregateAndRank('riegel', [
        [local],
        [off],
      ]);

      expect(result.length, 2);
      expect(result.map((r) => r.source).toSet(), {'local', 'off'});
      expect(result.every((r) => r.kcalPer100g == 100 || r.kcalPer100g == 130),
          isTrue);
    });

    test('merge boundary: exactly 10% relative deviation counts as conflict '
        '(not merged), just under 10% merges', () {
      // avg=100, diff=10 -> relative exactly 10% -> conflict.
      final boundaryConflict = aggregateAndRank('ding', [
        [_r(name: 'Ding', kcal: 95, source: 'local')],
        [_r(name: 'Ding', kcal: 105, source: 'off')],
      ]);
      expect(boundaryConflict.length, 2);

      // avg=100, diff=9 -> relative 9% -> merge.
      final justUnder = aggregateAndRank('ding', [
        [_r(name: 'Ding', kcal: 95.5, source: 'local')],
        [_r(name: 'Ding', kcal: 104.5, source: 'off')],
      ]);
      expect(justUnder.length, 1);
      expect(justUnder.single.source, 'merged');
    });

    test('exact-match-first: exact name match outranks prefix and word '
        'match when other factors are equal', () {
      final exact = _r(
        name: 'Apfel',
        kcal: 50,
        protein: 1,
        carbs: 1,
        fat: 1,
        sugar: 1,
        fiber: 1,
        salt: 1,
        source: 'local',
      );
      final prefix = _r(
        name: 'Apfelmus',
        kcal: 50,
        protein: 1,
        carbs: 1,
        fat: 1,
        sugar: 1,
        fiber: 1,
        salt: 1,
        source: 'local',
      );
      final word = _r(
        name: 'Bio Apfel Saft',
        kcal: 50,
        protein: 1,
        carbs: 1,
        fat: 1,
        sugar: 1,
        fiber: 1,
        salt: 1,
        source: 'local',
      );
      final none = _r(
        name: 'Birnensaft',
        kcal: 50,
        protein: 1,
        carbs: 1,
        fat: 1,
        sugar: 1,
        fiber: 1,
        salt: 1,
        source: 'local',
      );

      final result = aggregateAndRank('apfel', [
        [none, word, prefix, exact],
      ]);

      expect(result.map((r) => r.name).toList(),
          ['Apfel', 'Apfelmus', 'Bio Apfel Saft', 'Birnensaft']);
    });

    test('completeness-tiebreak: equal name-match tier, higher completeness '
        'ranks first', () {
      final complete = _r(
        name: 'Apfel',
        brand: 'MarkeA',
        kcal: 50,
        protein: 1,
        carbs: 1,
        fat: 1,
        sugar: 1,
        fiber: 1,
        salt: 1,
        source: 'local',
      );
      final sparse = _r(
        name: 'Apfel',
        brand: 'MarkeB',
        kcal: 50,
        protein: 1,
        carbs: 1,
        fat: 1,
        source: 'local',
      );

      // Different brands -> different dedupe key -> not merged, both kept.
      final result = aggregateAndRank('apfel', [
        [sparse, complete],
      ]);

      expect(result.length, 2);
      expect(result.first.brand, 'MarkeA');
      expect(result.last.brand, 'MarkeB');
    });

    test('deterministic tiebreak by normalized name when scores are equal',
        () {
      final banane = _r(name: 'Banane', kcal: 90, source: 'local');
      final apfel = _r(name: 'Apfel', kcal: 90, source: 'local');

      final result = aggregateAndRank('obst', [
        [banane, apfel],
      ]);

      expect(result.map((r) => r.name).toList(), ['Apfel', 'Banane']);
    });

    test('normalize is applied to the dedupe key so umlaut variants of the '
        'same product still merge', () {
      final variantA = _r(
        name: 'Käse',
        brand: 'Alpen',
        kcal: 300,
        source: 'local',
      );
      final variantB = _r(
        name: 'kase',
        brand: 'alpen',
        kcal: 305,
        source: 'off',
      );

      final result = aggregateAndRank('kase', [
        [variantA],
        [variantB],
      ]);

      expect(result.length, 1);
      expect(result.single.source, 'merged');
    });

    test('source priority ranking contributes to score ordering when name '
        'match and completeness are equal', () {
      final localResult = _r(
        name: 'Joghurt',
        brand: 'A',
        kcal: 60,
        source: 'local',
      );
      final usdaResult = _r(
        name: 'Joghurt',
        brand: 'B',
        kcal: 60,
        source: 'usda',
      );

      final result = aggregateAndRank('joghurt', [
        [usdaResult],
        [localResult],
      ]);

      expect(result.first.source, 'local');
      expect(result.last.source, 'usda');
    });

    test('merged-with-local: no barcode on either side, merged result '
        'carries the local contributor\'s localId (regression for '
        'stray-row bug — tapping a merged result must update the existing '
        'local product, not insert a duplicate)', () {
      final local = _r(
        name: 'Reis',
        kcal: 130,
        protein: 2.7,
        carbs: 28,
        fat: 0.3,
        source: 'local',
        localId: 42,
      );
      final off = _r(
        name: 'Reis',
        kcal: 132,
        protein: 2.6,
        carbs: 28.5,
        fat: 0.3,
        source: 'off',
      );

      final result = aggregateAndRank('reis', [
        [local],
        [off],
      ]);

      expect(result.length, 1);
      final merged = result.single;
      expect(merged.source, 'merged');
      expect(merged.barcode, isNull);
      expect(merged.localId, 42);
    });
  });
}

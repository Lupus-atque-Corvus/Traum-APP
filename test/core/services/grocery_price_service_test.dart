import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/services/grocery_price_service.dart';

void main() {
  group('normalizeName', () {
    test('lowercases, trims, strips diacritics and punctuation', () {
      expect(GroceryPriceService.normalizeName('  Äpfel! '), 'aepfel');
      expect(GroceryPriceService.normalizeName('Müsli-Riegel'), 'muesli riegel');
      expect(GroceryPriceService.normalizeName('Café  Crème'), 'cafe creme');
    });
  });

  group('match', () {
    final prices = [
      const PriceEntry(name: 'Milch', normalized: 'milch', price: 1.19, unit: 'L'),
      const PriceEntry(
          name: 'Bio Milch', normalized: 'bio milch', price: 1.59, unit: 'L'),
      const PriceEntry(
          name: 'Vollkornbrot', normalized: 'vollkornbrot', price: 2.49, unit: 'Stück'),
    ];

    test('exact normalized match wins', () {
      final m = GroceryPriceService.match('milch', prices);
      expect(m, isNotNull);
      expect(m!.name, 'Milch');
      expect(m.price, 1.19);
    });

    test('contains match when no exact', () {
      final m = GroceryPriceService.match('Vollkorn', prices);
      expect(m, isNotNull);
      expect(m!.name, 'Vollkornbrot');
    });

    test('fuzzy match tolerates a typo', () {
      final m = GroceryPriceService.match('Milhc', prices);
      expect(m, isNotNull);
      expect(m!.name, 'Milch');
    });

    test('returns null when nothing is close', () {
      expect(GroceryPriceService.match('Quantencomputer', prices), isNull);
    });

    test('returns null for empty query', () {
      expect(GroceryPriceService.match('   ', prices), isNull);
    });

    test('returns null for empty price list', () {
      expect(GroceryPriceService.match('Milch', const []), isNull);
    });

    test('contains prefers the most specific entry when query is a superstring',
        () {
      const ps = [
        PriceEntry(name: 'Milch', normalized: 'milch', price: 1.19),
        PriceEntry(name: 'Bio Vollmilch', normalized: 'bio vollmilch', price: 1.59),
      ];
      final m = GroceryPriceService.match('bio vollmilch extra', ps);
      expect(m, isNotNull);
      expect(m!.name, 'Bio Vollmilch');
    });
  });
}

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('grocery_prices.json is valid and well-formed', () async {
    final raw =
        await rootBundle.loadString('assets/data/grocery_prices.json');
    final list = jsonDecode(raw) as List<dynamic>;
    expect(list.length, greaterThan(750));

    for (final e in list) {
      final item = e as Map<String, dynamic>;
      expect(item['name'], isA<String>());
      expect(item['category'], isA<String>());
      expect(item['avgPrice'], isA<num>());
      expect(item['unit'], isA<String>());
    }

    // No duplicate names.
    final names = list.map((e) => (e as Map)['name'] as String).toSet();
    expect(names.length, list.length);
  });
}

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('grocery_prices.json is valid and well-formed', () async {
    final raw =
        await rootBundle.loadString('assets/data/grocery_prices.json');
    final list = jsonDecode(raw) as List<dynamic>;
    expect(list.length, greaterThan(300));
    final first = list.first as Map<String, dynamic>;
    expect(first.containsKey('name'), isTrue);
    expect(first.containsKey('category'), isTrue);
    expect(first['avgPrice'], isA<num>());
    // No duplicate names.
    final names = list.map((e) => (e as Map)['name'] as String).toSet();
    expect(names.length, list.length);
  });
}

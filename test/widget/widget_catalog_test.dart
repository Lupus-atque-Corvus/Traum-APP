import 'package:flutter_test/flutter_test.dart';
import 'package:traum/widget/widget_catalog.dart';

void main() {
  test('jeder Eintrag hat nicht-leere Pflichtfelder', () {
    expect(widgetCatalog, isNotEmpty);
    for (final e in widgetCatalog) {
      expect(e.key, isNotEmpty, reason: 'key leer');
      expect(e.title, isNotEmpty, reason: '${e.key}: title leer');
      expect(e.accentHex, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')),
          reason: '${e.key}: accentHex ungültig');
      expect(e.dataKeys, isNotEmpty, reason: '${e.key}: keine dataKeys');
    }
  });

  test('keys sind eindeutig', () {
    final keys = widgetCatalog.map((e) => e.key).toList();
    expect(keys.toSet().length, keys.length, reason: 'doppelte keys');
  });

  test('enthält das Übersicht-Tab-Widget', () {
    expect(widgetCatalog.any((e) => e.key == 'overview'), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/home/home_tile.dart';
import 'package:traum/widget/widget_catalog.dart';

void main() {
  test('Katalog enthält genau 12 Einträge', () {
    expect(widgetCatalog.length, 12);
  });

  test('jeder Eintrag hat nicht-leere Pflichtfelder', () {
    expect(widgetCatalog, isNotEmpty);
    for (final e in widgetCatalog) {
      expect(e.key, isNotEmpty, reason: 'key leer');
      expect(e.title, isNotEmpty, reason: '${e.key}: title leer');
      expect(e.accentHex, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')),
          reason: '${e.key}: accentHex ungültig');
      expect(e.slots, isNotEmpty, reason: '${e.key}: keine slots');
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

  test('dataKeys-Getter liefert alle Slot-Schlüssel inkl. Ziele', () {
    final overview = widgetCatalog.firstWhere((e) => e.key == 'overview');
    // overview hat 3 Slots mit goalKey + 1 ohne → 7 dataKeys
    expect(overview.dataKeys.length, 7);
    expect(overview.dataKeys, contains('health.steps'));
    expect(overview.dataKeys, contains('health.stepsGoal'));
    expect(overview.dataKeys, contains('planning.nextTodo'));
  });

  // ── Funktions-Katalog ───────────────────────────────────────────────────────
  test('Funktions-Katalog deckt alle HomeWidgetType ab', () {
    expect(functionCatalog, isNotEmpty);
    for (final e in functionCatalog) {
      expect(e.key, isNotEmpty);
      expect(e.slots, isNotEmpty, reason: '${e.key}: keine slots');
      expect(e.accentHex, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
    }
    final keys = functionCatalog.map((e) => e.key).toList();
    expect(keys.toSet().length, keys.length, reason: 'doppelte function keys');
  });

  test('functionCatalog hat einen Eintrag pro HomeWidgetType', () {
    final catalogKeys = functionCatalog.map((e) => e.key).toSet();
    for (final t in HomeWidgetType.values) {
      expect(catalogKeys.contains(t.name), isTrue, reason: 'fehlt: ${t.name}');
    }
  });
}

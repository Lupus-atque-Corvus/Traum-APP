import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/home/home_tile.dart';
import 'package:traum/widget/widget_catalog.dart';

/// Native-only v2-Visual-Widgets: erscheinen im Funktions-Widget-Picker,
/// haben aber bewusst KEINEN HomeWidgetType (kein In-App-Dashboard-Eintrag).
const kNativeOnlyV2Keys = <String>[
  'dailyGoals', 'stepsWeek', 'weightTrendChart', 'macroDonut', 'habitWeek', 'moodWeek',
  'waterBottle', 'monthTrendChart', 'morningRoutine', 'quoteOfDay', 'celebrate', 'countdown',
  'healthRings', 'sleepWeek', 'nutritionDash', 'mealsTodayList', 'trainingDash', 'volumeWeek',
  'todayAgenda', 'budgetDash', 'categoryDonut', 'diaryDash', 'abstinenceDash', 'substancesDash',
  'cycleRing', 'pinnedNoteCard', 'mapDash',
];

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

  test('functionCatalog = HomeWidgetType-Abdeckung + bekannte native-only Extras', () {
    final enumNames = HomeWidgetType.values.map((e) => e.name).toSet();
    final extra = functionCatalog
        .map((e) => e.key)
        .where((k) => !enumNames.contains(k))
        .toSet();
    expect(extra, equals(kNativeOnlyV2Keys.toSet()),
        reason: 'native-only Einträge müssen exakt kNativeOnlyV2Keys sein');
    expect(functionCatalog.length,
        HomeWidgetType.values.length + kNativeOnlyV2Keys.length);
  });

  test('functionCatalog enthält die v2-Widgets mit gültigem Template + Slots', () {
    final byKey = {for (final e in functionCatalog) e.key: e};
    const v2Templates = {
      WidgetTemplate.ring, WidgetTemplate.ringTrio, WidgetTemplate.barChart,
      WidgetTemplate.sparkline, WidgetTemplate.donut, WidgetTemplate.dashboard,
      WidgetTemplate.motivation, WidgetTemplate.list,
    };
    for (final k in kNativeOnlyV2Keys) {
      final e = byKey[k];
      expect(e, isNotNull, reason: 'fehlt: $k');
      expect(e!.slots, isNotEmpty, reason: '$k: keine Slots');
      expect(v2Templates.contains(e.template), isTrue,
          reason: '$k: ungültiges Template ${e.template}');
    }
  });
}

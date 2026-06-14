// ignore_for_file: avoid_print
/// Catalog generator: emits Kotlin + Swift mirror tables from widget_catalog.dart.
/// Usage: dart run tools/gen_widget_catalog.dart
library;

import 'dart:io';

import 'package:traum/widget/widget_catalog.dart';

// ── Route → groupLabel map ───────────────────────────────────────────────────

const _routeToGroup = <String, String>{
  '/home': 'Allgemein',
  '/health': 'Gesundheit',
  '/nutrition': 'Ernährung',
  '/training': 'Training',
  '/planning': 'Planung',
  '/budget': 'Budget',
  '/diary': 'Tagebuch',
  '/abstinence': 'Abstinenz',
  '/substances': 'Mittel',
  '/period': 'Zyklus',
  '/notes': 'Notizen',
  '/graffitimap': 'Karte',
};

String _groupLabel(String route) => _routeToGroup[route] ?? '';

String _esc(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

// ── Kotlin generation ────────────────────────────────────────────────────────

String _kotlinSlot(WidgetSlot slot) {
  final label = _esc(slot.label);
  final valueKey = _esc(slot.valueKey);
  final goalKey = slot.goalKey;
  if (goalKey != null) {
    return 'WidgetSlotDef("$label", "$valueKey", "${_esc(goalKey)}")';
  } else {
    return 'WidgetSlotDef("$label", "$valueKey", null)';
  }
}

String _kotlinEntry(WidgetCatalogEntry e) {
  final key = _esc(e.key);
  final title = _esc(e.title);
  final group = _esc(_groupLabel(e.route));
  final accent = _esc(e.accentHex);
  final template = e.template.name;
  final route = _esc(e.route);

  final slotsStr = e.slots.map((s) => '            ${_kotlinSlot(s)}').join(',\n');

  return '''        WidgetCatalogDef(
            key = "$key",
            title = "$title",
            groupLabel = "$group",
            accentHex = "$accent",
            template = "$template",
            route = "$route",
            slots = listOf(
$slotsStr,
            ),
        )''';
}

String generateKotlin() {
  final tabs = widgetCatalog.map(_kotlinEntry).join(',\n');
  final functions = functionCatalog.map(_kotlinEntry).join(',\n');

  return '''package de.traum.traum.widget

data class WidgetSlotDef(val label: String, val valueKey: String, val goalKey: String?)
data class WidgetCatalogDef(
    val key: String,
    val title: String,
    val groupLabel: String,
    val accentHex: String,
    val template: String,
    val route: String,
    val slots: List<WidgetSlotDef>,
)

object WidgetCatalog {
    val tabs = listOf(
$tabs,
    )
    val functions = listOf(
$functions,
    )
    fun byKey(k: String): WidgetCatalogDef? = (tabs + functions).firstOrNull { it.key == k }
}
''';
}

// ── Swift generation ─────────────────────────────────────────────────────────

String _swiftSlot(WidgetSlot slot) {
  final label = _esc(slot.label);
  final valueKey = _esc(slot.valueKey);
  final goalKey = slot.goalKey;
  if (goalKey != null) {
    return 'WidgetSlotDef(label: "$label", valueKey: "$valueKey", goalKey: "${_esc(goalKey)}")';
  } else {
    return 'WidgetSlotDef(label: "$label", valueKey: "$valueKey", goalKey: nil)';
  }
}

String _swiftEntry(WidgetCatalogEntry e) {
  final key = _esc(e.key);
  final title = _esc(e.title);
  final group = _esc(_groupLabel(e.route));
  final accent = _esc(e.accentHex);
  final template = e.template.name;
  final route = _esc(e.route);

  final slotsStr = e.slots.map((s) => '            ${_swiftSlot(s)}').join(',\n');

  return '''        WidgetCatalogDef(
            key: "$key",
            title: "$title",
            groupLabel: "$group",
            accentHex: "$accent",
            template: "$template",
            route: "$route",
            slots: [
$slotsStr,
            ]
        )''';
}

String generateSwift() {
  final tabs = widgetCatalog.map(_swiftEntry).join(',\n');
  final functions = functionCatalog.map(_swiftEntry).join(',\n');

  return '''struct WidgetSlotDef { let label: String; let valueKey: String; let goalKey: String? }
struct WidgetCatalogDef {
    let key: String
    let title: String
    let groupLabel: String
    let accentHex: String
    let template: String
    let route: String
    let slots: [WidgetSlotDef]
}

enum WidgetCatalogSwift {
    static let tabs: [WidgetCatalogDef] = [
$tabs,
    ]
    static let functions: [WidgetCatalogDef] = [
$functions,
    ]
    static func byKey(_ k: String) -> WidgetCatalogDef? {
        (tabs + functions).first { \$0.key == k }
    }
}
''';
}

// ── main ─────────────────────────────────────────────────────────────────────

void main() {
  final ktPath = 'android/app/src/main/kotlin/de/traum/traum/widget/WidgetCatalog.kt';
  final swiftPath = 'ios/TraumWidgets/WidgetCatalog.swift';

  File(ktPath).writeAsStringSync(generateKotlin());
  File(swiftPath).writeAsStringSync(generateSwift());

  print('Generated WidgetCatalog.kt + WidgetCatalog.swift');
}

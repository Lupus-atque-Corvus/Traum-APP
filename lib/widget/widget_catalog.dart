import 'widget_keys.dart';

/// Render-Vorlage eines Widgets. Wird in Kotlin/Swift gespiegelt.
enum WidgetTemplate { stat, progress, dualStat, list, overview }

/// Ein nativer Widget-Typ (Single Source of Truth, gespiegelt nach Kotlin/Swift).
class WidgetCatalogEntry {
  final String key;
  final String title;
  final String accentHex;
  final WidgetTemplate template;
  final String route;
  final List<String> dataKeys;
  const WidgetCatalogEntry({
    required this.key,
    required this.title,
    required this.accentHex,
    required this.template,
    required this.route,
    required this.dataKeys,
  });
}

/// Vollständiger nativer Katalog. Reihenfolge = Anzeige-Reihenfolge im Picker.
const List<WidgetCatalogEntry> widgetCatalog = [
  WidgetCatalogEntry(
    key: 'overview',
    title: 'Übersicht',
    accentHex: '#FF6B3D',
    template: WidgetTemplate.overview,
    route: '/home',
    dataKeys: [
      WidgetKeys.steps, WidgetKeys.stepsGoal,
      WidgetKeys.kcal, WidgetKeys.kcalGoal,
      WidgetKeys.waterMl, WidgetKeys.waterGoalMl,
      WidgetKeys.sleepHours, WidgetKeys.mood, WidgetKeys.nextTodo,
    ],
  ),
];

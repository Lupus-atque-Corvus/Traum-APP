import 'package:home_widget/home_widget.dart';

import 'widget_keys.dart';
import 'widget_snapshot.dart';

/// Schreibt Widget-Daten in den App-Group-Store und löst native Updates aus.
class WidgetDataService {
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(WidgetKeys.appGroupId);
  }

  /// Reine Aufbereitung der zu schreibenden Map (testbar).
  static Map<String, String> buildWriteMap(WidgetSnapshot snap,
      {DateTime? now}) {
    return {
      ...snap.toStringMap(),
      WidgetKeys.updatedAt: (now ?? DateTime.now().toUtc()).toIso8601String(),
    };
  }

  /// Persistiert den Snapshot und aktualisiert alle nativen Widgets.
  static Future<void> write(WidgetSnapshot snap) async {
    final map = buildWriteMap(snap);
    for (final e in map.entries) {
      await HomeWidget.saveWidgetData<String>(e.key, e.value);
    }
    await HomeWidget.updateWidget(
      androidName: 'TraumOverviewWidgetProvider',
      iOSName: 'TraumOverviewWidget',
    );
  }
}

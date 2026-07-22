import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

import 'widget_keys.dart';
import 'widget_snapshot.dart';

/// Schreibt Widget-Daten in den App-Group-Store und löst native Updates aus.
class WidgetDataService {
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(WidgetKeys.appGroupId);
  }

  /// Android-Provider-Klassennamen je Tab.
  static const List<String> androidWidgetNames = [
    'TraumOverviewWidgetProvider',
    'TraumHealthWidgetProvider',
    'TraumNutritionWidgetProvider',
    'TraumTrainingWidgetProvider',
    'TraumPlanningWidgetProvider',
    'TraumBudgetWidgetProvider',
    'TraumDiaryWidgetProvider',
    'TraumAbstinenceWidgetProvider',
    'TraumSubstancesWidgetProvider',
    'TraumPeriodWidgetProvider',
    'TraumNotesWidgetProvider',
    'TraumMapWidgetProvider',
  ];

  /// Voll-qualifizierter Klassenname des konfigurierbaren Funktions-Widgets.
  /// Liegt im `widget`-Unterpaket, daher NICHT über [androidName] (das würde
  /// `de.traum.traum.<name>` auflösen), sondern über `qualifiedAndroidName`.
  static const String androidFunctionWidget =
      'de.traum.traum.widget.TraumFunctionWidgetProvider';

  /// iOS-Widget-`kind`s je Tab (Klassenname ohne „Provider") + Funktions-Widget.
  /// `HomeWidget.updateWidget(iOSName:)` lädt nur eine Timeline `ofKind:` neu —
  /// es gibt kein Reload-All, daher muss jeder kind einzeln getriggert werden.
  static List<String> get iosWidgetKinds => [
        for (final n in androidWidgetNames) n.replaceAll('Provider', ''),
        'TraumFunctionWidget',
      ];

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
    // Android: 12 Tab-Provider (Paket de.traum.traum) ...
    for (final name in androidWidgetNames) {
      await HomeWidget.updateWidget(androidName: name);
    }
    // ... + Funktions-Provider (liegt im widget-Unterpaket).
    await HomeWidget.updateWidget(qualifiedAndroidName: androidFunctionWidget);
    // iOS: jeder Widget-kind muss einzeln neu geladen werden (kein Reload-All).
    // Nur auf iOS ausführen — auf Android ruft dieser Aufruf denselben nativen
    // Handler ohne androidName/qualifiedAndroidName (also mit name: null) auf
    // und wirft dort bei jedem Refresh eine ClassNotFoundException.
    if (Platform.isIOS) {
      for (final kind in iosWidgetKinds) {
        await HomeWidget.updateWidget(iOSName: kind);
      }
    }
  }
}

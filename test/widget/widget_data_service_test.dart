import 'package:flutter_test/flutter_test.dart';
import 'package:traum/widget/widget_keys.dart';
import 'package:traum/widget/widget_snapshot.dart';
import 'package:traum/widget/widget_data_service.dart';

void main() {
  test('buildWriteMap ergänzt updatedAt und übernimmt Snapshot-Keys', () {
    final map = WidgetDataService.buildWriteMap(
      WidgetSnapshot.empty(),
      now: DateTime.utc(2026, 6, 12, 10),
    );
    expect(map[WidgetKeys.steps], '0');
    expect(map[WidgetKeys.updatedAt], '2026-06-12T10:00:00.000Z');
  });

  test('androidWidgetNames enthält alle 12 Tab-Provider', () {
    expect(WidgetDataService.androidWidgetNames, containsAll(<String>[
      'TraumOverviewWidgetProvider', 'TraumHealthWidgetProvider',
      'TraumNutritionWidgetProvider', 'TraumTrainingWidgetProvider',
      'TraumPlanningWidgetProvider', 'TraumBudgetWidgetProvider',
      'TraumDiaryWidgetProvider', 'TraumAbstinenceWidgetProvider',
      'TraumSubstancesWidgetProvider', 'TraumPeriodWidgetProvider',
      'TraumNotesWidgetProvider', 'TraumMapWidgetProvider',
    ]));
    expect(WidgetDataService.androidWidgetNames.length, 12);
  });

  test('iosWidgetKinds spiegelt 12 Tabs (ohne "Provider") + Funktions-Widget', () {
    final kinds = WidgetDataService.iosWidgetKinds;
    expect(kinds.length, 13);
    expect(kinds, contains('TraumOverviewWidget'));
    expect(kinds, contains('TraumMapWidget'));
    expect(kinds, contains('TraumFunctionWidget'));
    // Kein kind trägt noch das "Provider"-Suffix.
    expect(kinds.any((k) => k.endsWith('Provider')), isFalse);
  });

  test('androidFunctionWidget ist voll-qualifiziert (widget-Unterpaket)', () {
    expect(WidgetDataService.androidFunctionWidget,
        'de.traum.traum.widget.TraumFunctionWidgetProvider');
  });
}

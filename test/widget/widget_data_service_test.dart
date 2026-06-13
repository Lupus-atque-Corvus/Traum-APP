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
}

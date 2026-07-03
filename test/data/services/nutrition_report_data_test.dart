import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/services/nutrition_report_data.dart';

void main() {
  test('buildDailySections groups entries by day and sums macros', () {
    final entries = [
      ReportEntry(day: DateTime(2026, 7, 1), meal: 'breakfast',
          foodName: 'Haferflocken', grams: 80,
          kcal: 296, protein: 10.8, carbs: 47.2, fat: 5.6),
      ReportEntry(day: DateTime(2026, 7, 1), meal: 'lunch',
          foodName: 'Hähnchenbrust', grams: 200,
          kcal: 330, protein: 62, carbs: 0, fat: 8),
    ];
    final sections = buildDailySections(entries);
    expect(sections, hasLength(1));
    expect(sections.first.totalKcal, closeTo(626, 0.1));
    expect(sections.first.totalProtein, closeTo(72.8, 0.1));
    expect(sections.first.meals.keys, containsAll(['breakfast', 'lunch']));
  });
}

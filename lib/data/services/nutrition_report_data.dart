/// Pure Dart aggregation model for the nutrition report PDF export.
///
/// Deliberately free of drift/flutter/pdf imports so it stays trivially
/// unit-testable. The pdf package and data fetching are wired in later
/// (Task 5.2's renderer); this file only groups already-fetched entries.
class ReportEntry {
  final DateTime day;
  final String meal; // breakfast|lunch|dinner|snack
  final String foodName;
  final double grams;
  final double kcal, protein, carbs, fat;
  const ReportEntry({required this.day, required this.meal,
      required this.foodName, required this.grams, required this.kcal,
      required this.protein, required this.carbs, required this.fat});
}

class DailySection {
  final DateTime day;
  final Map<String, List<ReportEntry>> meals;
  final double totalKcal, totalProtein, totalCarbs, totalFat;
  const DailySection({required this.day, required this.meals,
      required this.totalKcal, required this.totalProtein,
      required this.totalCarbs, required this.totalFat});
}

List<DailySection> buildDailySections(List<ReportEntry> entries) {
  final byDay = <DateTime, List<ReportEntry>>{};
  for (final e in entries) {
    final key = DateTime(e.day.year, e.day.month, e.day.day);
    byDay.putIfAbsent(key, () => []).add(e);
  }
  final days = byDay.keys.toList()..sort();
  return days.map((day) {
    final list = byDay[day]!;
    final meals = <String, List<ReportEntry>>{};
    for (final e in list) {
      meals.putIfAbsent(e.meal, () => []).add(e);
    }
    double sum(double Function(ReportEntry) f) =>
        list.fold(0.0, (a, e) => a + f(e));
    return DailySection(
      day: day, meals: meals,
      totalKcal: sum((e) => e.kcal), totalProtein: sum((e) => e.protein),
      totalCarbs: sum((e) => e.carbs), totalFat: sum((e) => e.fat),
    );
  }).toList();
}

import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'meal_entries_dao.g.dart';

@DriftAccessor(tables: [MealEntries])
class MealEntriesDao extends DatabaseAccessor<TraumDatabase>
    with _$MealEntriesDaoMixin {
  MealEntriesDao(super.db);

  Future<List<MealEntry>> getForDate(String date) =>
      (select(mealEntries)
            ..where((t) => t.date.equals(date))
            ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
          .get();

  /// Entries whose `date` (stored as `yyyy-MM-dd` text) falls within
  /// `[from, to]` inclusive. Follows the string-date convention already
  /// used by [getForDate] / `nutrition_providers.dart`'s `weeklyCaloriesProvider`
  /// rather than comparing against a `DateTimeColumn` (this table has none).
  Future<List<MealEntry>> getEntriesBetween(DateTime from, DateTime to) {
    final fromStr = _dateStr(from);
    final toStr = _dateStr(to);
    return (select(mealEntries)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(fromStr) &
              t.date.isSmallerOrEqualValue(toStr))
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.loggedAt),
          ]))
        .get();
  }

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int> insertEntry(MealEntriesCompanion entry) =>
      into(mealEntries).insert(entry);

  Future<int> deleteEntry(int id) =>
      (delete(mealEntries)..where((t) => t.id.equals(id))).go();

  Future<void> updateAmount(int id, double newGrams, double calories,
      double protein, double carbs, double fat) =>
      (update(mealEntries)..where((t) => t.id.equals(id))).write(
        MealEntriesCompanion(
          amountGrams: Value(newGrams),
          calories: Value(calories),
          protein: Value(protein),
          carbs: Value(carbs),
          fat: Value(fat),
        ),
      );
}

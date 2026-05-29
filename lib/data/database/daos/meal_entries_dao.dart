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

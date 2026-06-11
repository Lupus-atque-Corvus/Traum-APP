import 'package:drift/drift.dart';

class NutritionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get logDate => dateTime()();
  TextColumn get mealType => text().withDefault(const Constant('snack'))();
  TextColumn get foodName => text()();
  RealColumn get amountGrams => real()();
  RealColumn get kcal => real()();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get carbsG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real().withDefault(const Constant(0))();
  IntColumn get templateId => integer().nullable()();
}

class MealTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  RealColumn get servingSizeG => real()();
  RealColumn get kcalPer100g => real()();
  RealColumn get proteinPer100g => real().withDefault(const Constant(0))();
  RealColumn get carbsPer100g => real().withDefault(const Constant(0))();
  RealColumn get fatPer100g => real().withDefault(const Constant(0))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WaterLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get logDate => dateTime()();
  IntColumn get amountMl => integer()();
}

class ShoppingListItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class FoodProducts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get caloriesPer100g => real()();
  RealColumn get proteinPer100g => real()();
  RealColumn get carbsPer100g => real()();
  RealColumn get fatPer100g => real()();
  RealColumn get sugarPer100g => real().nullable()();
  RealColumn get fiberPer100g => real().nullable()();
  RealColumn get saltPer100g => real().nullable()();
  RealColumn get saturatedFatPer100g => real().nullable()();
  TextColumn get microsJson => text().nullable()();
  BoolColumn get isCustom =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUsed => dateTime().nullable()();
  IntColumn get useCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

class MealEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get mealType => text()();
  IntColumn get productId => integer()();
  RealColumn get amountGrams => real()();
  RealColumn get calories => real()();
  RealColumn get protein => real()();
  RealColumn get carbs => real()();
  RealColumn get fat => real()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get microsJson => text().nullable()();
}

class MealTemplateItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer()();
  IntColumn get productId => integer()();
  RealColumn get amountGrams => real()();
}

class WeeklyMealPlan extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get mealType => text()();
  IntColumn get templateId => integer().nullable()();
  IntColumn get productId => integer().nullable()();
  RealColumn get amountGrams => real().nullable()();
  BoolColumn get isLogged =>
      boolean().withDefault(const Constant(false))();
}

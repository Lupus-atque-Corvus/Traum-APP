import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/planning_tables.dart';
import 'tables/training_tables.dart';
import 'tables/health_tables.dart';
import 'tables/nutrition_tables.dart';
import 'tables/supplement_tables.dart';
import 'tables/medication_tables.dart';
import 'tables/abstinence_tables.dart';
import 'tables/budget_tables.dart';
import 'tables/period_tables.dart';

import 'daos/planning_dao.dart';
import 'daos/training_dao.dart';
import 'daos/health_dao.dart';
import 'daos/nutrition_dao.dart';
import 'daos/supplement_dao.dart';
import 'daos/medication_dao.dart';
import 'daos/abstinence_dao.dart';
import 'daos/budget_dao.dart';
import 'daos/period_dao.dart';

// Re-export all table types
export 'tables/planning_tables.dart';
export 'tables/training_tables.dart';
export 'tables/health_tables.dart';
export 'tables/nutrition_tables.dart';
export 'tables/supplement_tables.dart';
export 'tables/medication_tables.dart';
export 'tables/abstinence_tables.dart';
export 'tables/budget_tables.dart';
export 'tables/period_tables.dart';

// Re-export all DAO types
export 'daos/planning_dao.dart';
export 'daos/training_dao.dart';
export 'daos/health_dao.dart';
export 'daos/nutrition_dao.dart';
export 'daos/supplement_dao.dart';
export 'daos/medication_dao.dart';
export 'daos/abstinence_dao.dart';
export 'daos/budget_dao.dart';
export 'daos/period_dao.dart';

part 'traum_database.g.dart';

@DriftDatabase(
  tables: [
    // Planning (6)
    Appointments,
    Todos,
    Goals,
    SubTasks,
    Habits,
    HabitLogs,
    // Training (6)
    WorkoutPlans,
    WorkoutDays,
    Exercises,
    WorkoutSessions,
    WorkoutSets,
    WorkoutDayExercises,
    // Health (5)
    WeightLogs,
    BodyMeasurements,
    SleepLogs,
    MoodLogs,
    PhotoLogs,
    // Nutrition (4)
    NutritionLogs,
    MealTemplates,
    WaterLogs,
    ShoppingListItems,
    // Supplements (2)
    Supplements,
    SupplementLogs,
    // Medication (2)
    Medications,
    MedicationLogs,
    // Abstinence (2)
    AbstinenceTrackers,
    AbstinenceEvents,
    // Budget (4)
    BudgetCategories,
    Transactions,
    SavingsGoals,
    Debts,
    // Period (3)
    PeriodEntries,
    CycleCalculations,
    PeriodSymptoms,
  ],
  daos: [
    PlanningDao,
    TrainingDao,
    HealthDao,
    NutritionDao,
    SupplementDao,
    MedicationDao,
    AbstinenceDao,
    BudgetDao,
    PeriodDao,
  ],
)
class TraumDatabase extends _$TraumDatabase {
  TraumDatabase() : super(_openConnection());

  TraumDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(workoutDayExercises);
      }
      if (from < 3) {
        await migrator.addColumn(exercises, exercises.primaryMuscles);
        await migrator.addColumn(exercises, exercises.secondaryMuscles);
        await migrator.addColumn(exercises, exercises.difficulty);
        await migrator.addColumn(exercises, exercises.mechanic);
        await migrator.addColumn(exercises, exercises.force);
        await migrator.addColumn(exercises, exercises.imageUrl);
        await migrator.addColumn(exercises, exercises.isBookmarked);
        await migrator.addColumn(workoutDayExercises, workoutDayExercises.notes);
        await migrator.addColumn(workoutDayExercises, workoutDayExercises.defaultRestSeconds);
        await migrator.addColumn(workoutDayExercises, workoutDayExercises.progressionType);
        await migrator.addColumn(workoutDayExercises, workoutDayExercises.supersetGroup);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'traum.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

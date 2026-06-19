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
import 'tables/substance_tables.dart';
import 'tables/diary_tables.dart';
import 'tables/substance_database_table.dart';
import 'tables/notes_tables.dart';
import 'tables/graffiti_map_tables.dart';

import 'daos/planning_dao.dart';
import 'daos/training_dao.dart';
import 'daos/health_dao.dart';
import 'daos/nutrition_dao.dart';
import 'daos/supplement_dao.dart';
import 'daos/medication_dao.dart';
import 'daos/abstinence_dao.dart';
import 'daos/budget_dao.dart';
import 'daos/accounts_dao.dart';
import 'daos/period_dao.dart';
import 'daos/substance_dao.dart';
import 'daos/diary_dao.dart';
import 'daos/food_products_dao.dart';
import 'daos/meal_entries_dao.dart';
import 'daos/substance_database_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/map_collections_dao.dart';
import 'daos/map_markers_dao.dart';
import 'daos/marker_photos_dao.dart';

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
export 'tables/substance_tables.dart';
export 'tables/diary_tables.dart';
export 'tables/substance_database_table.dart';
export 'tables/notes_tables.dart';
export 'tables/graffiti_map_tables.dart';

// Re-export all DAO types
export 'daos/planning_dao.dart';
export 'daos/training_dao.dart';
export 'daos/health_dao.dart';
export 'daos/nutrition_dao.dart';
export 'daos/supplement_dao.dart';
export 'daos/medication_dao.dart';
export 'daos/abstinence_dao.dart';
export 'daos/budget_dao.dart';
export 'daos/accounts_dao.dart';
export 'daos/period_dao.dart';
export 'daos/substance_dao.dart';
export 'daos/diary_dao.dart';
export 'daos/food_products_dao.dart';
export 'daos/meal_entries_dao.dart';
export 'daos/substance_database_dao.dart';
export 'daos/notes_dao.dart';
export 'daos/map_collections_dao.dart';
export 'daos/map_markers_dao.dart';
export 'daos/marker_photos_dao.dart';

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
    // Shopping extended (3)
    GroceryPrices,
    ShoppingTemplates,
    ShoppingTemplateItems,
    // Supplements (2)
    Supplements,
    SupplementLogs,
    // Medication (2)
    Medications,
    MedicationLogs,
    // Abstinence (2)
    AbstinenceTrackers,
    AbstinenceEvents,
    // Budget (6)
    BudgetCategories,
    Transactions,
    SavingsGoals,
    Debts,
    QuickTemplates,
    Accounts,
    // Period (5)
    PeriodEntries,
    CycleCalculations,
    PeriodSymptoms,
    DailyLogs,
    CycleProfile,
    // Substance cache (1)
    SubstanceCaches,
    // Substance intake log (1)
    SubstanceIntakeLogs,
    // Diary (1)
    DiaryEntries,
    // Substance offline database (1)
    SubstanceDatabaseEntries,
    // Nutrition Extended (4)
    FoodProducts,
    MealEntries,
    MealTemplateItems,
    WeeklyMealPlan,
    // Notes (6)
    Notes,
    NoteFolders,
    NoteLinks,
    Tags,
    NoteTags,
    NoteTemplates,
    // Graffiti Map (3)
    MapCollections,
    MapMarkers,
    MarkerPhotos,
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
    AccountsDao,
    PeriodDao,
    SubstanceDao,
    DiaryDao,
    FoodProductsDao,
    MealEntriesDao,
    SubstanceDatabaseDao,
    NotesDao,
    MapCollectionsDao,
    MapMarkersDao,
    MarkerPhotosDao,
  ],
)
class TraumDatabase extends _$TraumDatabase {
  TraumDatabase() : super(_openConnection());

  TraumDatabase.forTesting(super.e);

  @override
  SubstanceDao get substanceDao => SubstanceDao(this);

  @override
  DiaryDao get diaryDao => DiaryDao(this);

  @override
  FoodProductsDao get foodProductsDao => FoodProductsDao(this);
  @override
  MealEntriesDao get mealEntriesDao => MealEntriesDao(this);

  @override
  SubstanceDatabaseDao get substanceDatabaseDao => SubstanceDatabaseDao(this);

  @override
  NotesDao get notesDao => NotesDao(this);

  @override
  MapCollectionsDao get mapCollectionsDao => MapCollectionsDao(this);

  @override
  MapMarkersDao get mapMarkersDao => MapMarkersDao(this);

  @override
  MarkerPhotosDao get markerPhotosDao => MarkerPhotosDao(this);

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _createNotesFtsObjects();
      await into(cycleProfile).insert(
        const CycleProfileCompanion(id: Value(0)),
        mode: InsertMode.insertOrIgnore,
      );
    },
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
      if (from < 4) {
        await migrator.createTable(substanceCaches);
      }
      if (from < 5) {
        await migrator.addColumn(transactions, transactions.receiptImagePath);
        await migrator.addColumn(transactions, transactions.isRecurring);
        await migrator.addColumn(transactions, transactions.recurringDay);
        await migrator.addColumn(transactions, transactions.templateName);
        await migrator.addColumn(transactions, transactions.splitFromId);
        await migrator.createTable(quickTemplates);
      }
      if (from < 6) {
        await migrator.createTable(accounts);
      }
      if (from < 7) {
        await migrator.createTable(diaryEntries);
      }
      if (from < 8) {
        await migrator.createTable(foodProducts);
        await migrator.createTable(mealEntries);
        await migrator.createTable(mealTemplateItems);
        await migrator.createTable(weeklyMealPlan);
      }
      if (from < 9) {
        await migrator.addColumn(appointments, appointments.externalEventId);
        await migrator.addColumn(appointments, appointments.updatedAt);
        // Seed updatedAt from createdAt so existing rows have a meaningful timestamp
        await customStatement('UPDATE appointments SET updated_at = created_at');
      }
      if (from < 10) {
        await migrator.createTable(substanceDatabaseEntries);
      }
      if (from < 11) {
        await migrator.createTable(notes);
        await migrator.createTable(noteFolders);
        await migrator.createTable(noteLinks);
        await migrator.createTable(tags);
        await migrator.createTable(noteTags);
        await migrator.createTable(noteTemplates);
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_note_links_source ON note_links (source_note_id)');
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_note_links_target ON note_links (target_note_id)');
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_note_tags_note ON note_tags (note_id)');
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_note_tags_tag ON note_tags (tag_id)');
      }
      if (from < 12) {
        await migrator.createTable(mapCollections);
        await migrator.createTable(mapMarkers);
        await migrator.createTable(markerPhotos);
      }
      if (from < 13) {
        await migrator.addColumn(markerPhotos, markerPhotos.latitude);
        await migrator.addColumn(markerPhotos, markerPhotos.longitude);
        await customStatement(
          'UPDATE marker_photos SET '
          'latitude = (SELECT latitude FROM map_markers WHERE map_markers.id = marker_photos.marker_id), '
          'longitude = (SELECT longitude FROM map_markers WHERE map_markers.id = marker_photos.marker_id)',
        );
      }
      if (from < 14) {
        await migrator.addColumn(foodProducts, foodProducts.microsJson);
        await migrator.addColumn(mealEntries, mealEntries.microsJson);
        await migrator.addColumn(supplements, supplements.nutrientKey);
      }
      if (from < 15) {
        await migrator.addColumn(
            shoppingListItems, shoppingListItems.priceEstimated);
        await migrator.addColumn(
            shoppingListItems, shoppingListItems.priceActual);
        await migrator.addColumn(
            shoppingListItems, shoppingListItems.isUrgent);
        await migrator.createTable(groceryPrices);
        await migrator.createTable(shoppingTemplates);
        await migrator.createTable(shoppingTemplateItems);
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grocery_prices_norm '
            'ON grocery_prices (name_normalized)');
      }
      if (from < 16) {
        await migrator.addColumn(
            abstinenceTrackers, abstinenceTrackers.costPerDay);
        await migrator.createTable(substanceIntakeLogs);
      }
      if (from < 17) {
        await migrator.createTable(dailyLogs);
        await migrator.createTable(cycleProfile);
        await into(cycleProfile).insert(
          const CycleProfileCompanion(id: Value(0)),
          mode: InsertMode.insertOrIgnore,
        );
      }
      if (from < 18) {
        await migrator.addColumn(transactions, transactions.accountId);
        await migrator.addColumn(transactions, transactions.toAccountId);
        await migrator.addColumn(transactions, transactions.lastPostedMonth);
      }
    },
  );

  /// Ob die FTS5-Volltextsuche in dieser SQLite-Laufzeit verfügbar ist.
  /// Auf Android/iOS (gebündeltes sqlite3 mit fts5) immer true; manche
  /// Desktop-/Test-Umgebungen ohne fts5-Modul setzen das auf false, ohne
  /// dass das Öffnen der Datenbank scheitert.
  bool ftsAvailable = true;

  /// Legt die FTS5-Virtual-Table `notes_fts` und die Sync-Trigger an.
  /// Idempotent (IF NOT EXISTS), wird bei jedem Öffnen aufgerufen, damit
  /// auch frische Installationen (onCreate via createAll, ohne Virtual-Table)
  /// die Suchinfrastruktur erhalten. Fehlt das fts5-Modul, degradiert die
  /// Suche sanft statt die gesamte App-Datenbank unbrauchbar zu machen.
  Future<void> _createNotesFtsObjects() async {
    try {
      await _createNotesFtsObjectsUnsafe();
      ftsAvailable = true;
    } catch (_) {
      // fts5 nicht verfügbar (z. B. System-SQLite ohne Modul) → Suche aus.
      ftsAvailable = false;
    }
  }

  Future<void> _createNotesFtsObjectsUnsafe() async {
    final existing = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='notes_fts'",
    ).get();
    final ftsExisted = existing.isNotEmpty;

    await customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5("
      "title, content, content='notes', content_rowid='id', "
      "tokenize='unicode61 remove_diacritics 2')",
    );
    // Wurde die FTS-Tabelle gerade erst erstellt, einmalig aus den bereits
    // vorhandenen Notizen befüllen (Upgrade-Pfad mit Bestandsnotizen).
    if (!ftsExisted) {
      await customStatement("INSERT INTO notes_fts(notes_fts) VALUES('rebuild')");
    }
    await customStatement(
      "CREATE TRIGGER IF NOT EXISTS notes_fts_ai AFTER INSERT ON notes BEGIN "
      "INSERT INTO notes_fts(rowid, title, content) "
      "VALUES (new.id, new.title, new.content); END",
    );
    await customStatement(
      "CREATE TRIGGER IF NOT EXISTS notes_fts_ad AFTER DELETE ON notes BEGIN "
      "INSERT INTO notes_fts(notes_fts, rowid, title, content) "
      "VALUES ('delete', old.id, old.title, old.content); END",
    );
    await customStatement(
      "CREATE TRIGGER IF NOT EXISTS notes_fts_au AFTER UPDATE ON notes BEGIN "
      "INSERT INTO notes_fts(notes_fts, rowid, title, content) "
      "VALUES ('delete', old.id, old.title, old.content); "
      "INSERT INTO notes_fts(rowid, title, content) "
      "VALUES (new.id, new.title, new.content); END",
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'traum.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

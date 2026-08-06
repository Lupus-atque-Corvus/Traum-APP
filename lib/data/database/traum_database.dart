import 'dart:convert';
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
import 'daos/diaries_dao.dart';
import 'daos/food_products_dao.dart';
import 'daos/meal_entries_dao.dart';
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
export 'daos/diaries_dao.dart';
export 'daos/food_products_dao.dart';
export 'daos/meal_entries_dao.dart';
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
    // Budget (7)
    BudgetCategories,
    Transactions,
    SavingsGoals,
    Debts,
    DebtItems,
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
    // Diary (2)
    Diaries,
    DiaryEntries,
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
    DiariesDao,
    FoodProductsDao,
    MealEntriesDao,
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
  DiariesDao get diariesDao => DiariesDao(this);

  @override
  FoodProductsDao get foodProductsDao => FoodProductsDao(this);
  @override
  MealEntriesDao get mealEntriesDao => MealEntriesDao(this);

  @override
  NotesDao get notesDao => NotesDao(this);

  @override
  MapCollectionsDao get mapCollectionsDao => MapCollectionsDao(this);

  @override
  MapMarkersDao get mapMarkersDao => MapMarkersDao(this);

  @override
  MarkerPhotosDao get markerPhotosDao => MarkerPhotosDao(this);

  @override
  int get schemaVersion => 28;

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
        await _addColumnIfMissing(
            migrator, exercises, exercises.primaryMuscles, 'primary_muscles');
        await _addColumnIfMissing(migrator, exercises,
            exercises.secondaryMuscles, 'secondary_muscles');
        await _addColumnIfMissing(
            migrator, exercises, exercises.difficulty, 'difficulty');
        await _addColumnIfMissing(
            migrator, exercises, exercises.mechanic, 'mechanic');
        await _addColumnIfMissing(
            migrator, exercises, exercises.force, 'force');
        await _addColumnIfMissing(
            migrator, exercises, exercises.imageUrl, 'image_url');
        await _addColumnIfMissing(
            migrator, exercises, exercises.isBookmarked, 'is_bookmarked');
        await _addColumnIfMissing(migrator, workoutDayExercises,
            workoutDayExercises.notes, 'notes');
        await _addColumnIfMissing(migrator, workoutDayExercises,
            workoutDayExercises.defaultRestSeconds, 'default_rest_seconds');
        await _addColumnIfMissing(migrator, workoutDayExercises,
            workoutDayExercises.progressionType, 'progression_type');
        await _addColumnIfMissing(migrator, workoutDayExercises,
            workoutDayExercises.supersetGroup, 'superset_group');
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
        await _addColumnIfMissing(migrator, appointments,
            appointments.externalEventId, 'external_event_id');
        await _addColumnIfMissing(
            migrator, appointments, appointments.updatedAt, 'updated_at');
        // Seed updatedAt from createdAt so existing rows have a meaningful timestamp
        await customStatement('UPDATE appointments SET updated_at = created_at');
      }
      // v10 created substance_database_entries here; that table (and the
      // legacy offline Substanz-DB it backed) is fully retired as of v23
      // (see `if (from < 23)` below), so there is nothing left to create
      // for installs upgrading through this step.
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
        await _addColumnIfMissing(
            migrator, markerPhotos, markerPhotos.latitude, 'latitude');
        await _addColumnIfMissing(
            migrator, markerPhotos, markerPhotos.longitude, 'longitude');
        await customStatement(
          'UPDATE marker_photos SET '
          'latitude = (SELECT latitude FROM map_markers WHERE map_markers.id = marker_photos.marker_id), '
          'longitude = (SELECT longitude FROM map_markers WHERE map_markers.id = marker_photos.marker_id)',
        );
      }
      if (from < 14) {
        await _addColumnIfMissing(
            migrator, foodProducts, foodProducts.microsJson, 'micros_json');
        await _addColumnIfMissing(
            migrator, mealEntries, mealEntries.microsJson, 'micros_json');
        await _addColumnIfMissing(
            migrator, supplements, supplements.nutrientKey, 'nutrient_key');
      }
      if (from < 15) {
        await _addColumnIfMissing(migrator, shoppingListItems,
            shoppingListItems.priceEstimated, 'price_estimated');
        await _addColumnIfMissing(migrator, shoppingListItems,
            shoppingListItems.priceActual, 'price_actual');
        await _addColumnIfMissing(migrator, shoppingListItems,
            shoppingListItems.isUrgent, 'is_urgent');
        await migrator.createTable(groceryPrices);
        await migrator.createTable(shoppingTemplates);
        await migrator.createTable(shoppingTemplateItems);
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grocery_prices_norm '
            'ON grocery_prices (name_normalized)');
      }
      if (from < 16) {
        await _addColumnIfMissing(migrator, abstinenceTrackers,
            abstinenceTrackers.costPerDay, 'cost_per_day');
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
        await _addColumnIfMissing(
            migrator, transactions, transactions.accountId, 'account_id');
        await _addColumnIfMissing(migrator, transactions,
            transactions.toAccountId, 'to_account_id');
        await _addColumnIfMissing(migrator, transactions,
            transactions.lastPostedMonth, 'last_posted_month');
      }
      if (from < 19) {
        await migrator.createTable(debtItems);
        await _addColumnIfMissing(
            migrator, debts, debts.paidAmount, 'paid_amount');
        // Bisher getilgten Anteil als paidAmount übernehmen.
        await customStatement(
            'UPDATE debts SET paid_amount = original_amount - remaining_amount');
        // Bestehenden Betrag jeder Schuld als eine Startposition migrieren.
        await customStatement(
            "INSERT INTO debt_items (debt_id, description, amount, created_at) "
            "SELECT id, 'Bestehender Betrag', original_amount, strftime('%s','now') "
            "FROM debts WHERE original_amount > 0");
      }
      if (from < 20) {
        await _addColumnIfMissing(migrator, appointments,
            appointments.sourceCalendarId, 'source_calendar_id');
        await _addColumnIfMissing(
            migrator, appointments, appointments.isAppOrigin, 'is_app_origin');
        await _addColumnIfMissing(
            migrator, appointments, appointments.lastSyncedAt, 'last_synced_at');
        // Bestand: alles mit externalEventId, das je gepullt wurde, ist nicht unterscheidbar —
        // konservativ: vorhandene externe Verknüpfungen als Geräte-Ursprung markieren.
        await customStatement(
            'UPDATE appointments SET is_app_origin = 0 WHERE external_event_id IS NOT NULL');
      }
      if (from < 21) {
        await _addColumnIfMissing(
            migrator, foodProducts, foodProducts.sourceApi, 'source_api');
        await _addColumnIfMissing(
            migrator, foodProducts, foodProducts.sourceId, 'source_id');
        // Bestand: Herkunft rückwirkend ableiten — Barcode-Produkte stammen aus OFF,
        // manuell angelegte Produkte sind 'custom'.
        await customStatement(
            "UPDATE food_products SET source_api = 'off' WHERE barcode IS NOT NULL AND is_custom = 0");
        await customStatement(
            "UPDATE food_products SET source_api = 'custom' WHERE is_custom = 1");
      }
      if (from < 22) {
        await _addColumnIfMissing(
            migrator, workoutPlans, workoutPlans.planType, 'plan_type');
      }
      if (from < 23) {
        // Alte Substanz-Offline-DB (SubstanceDatabaseEntries) ist durch die
        // neue Referenz-DB (assets/substances_reference.sqlite3, separate
        // sqlite3-Verbindung außerhalb von Drift) vollständig ersetzt.
        await migrator.deleteTable('substance_database_entries');
      }
      if (from < 24) {
        // Idempotent statt einmaligem ALTER TABLE: falls ein vorheriger
        // Migrationsversuch nach dem Hinzufügen der Spalte aus einem anderen
        // Grund abgebrochen ist (z.B. an einem inzwischen gefixten Bug weiter
        // unten in diesem Block), würde ein erneutes addColumn beim nächsten
        // App-Start mit "duplicate column name" abstürzen — und die App bliebe
        // dauerhaft unstartbar. Spaltenexistenz vorher prüfen macht diesen
        // Schritt sicher wiederholbar.
        final hasOsmId = await customSelect(
          "SELECT COUNT(*) AS c FROM pragma_table_info('map_markers') WHERE name = 'osm_id'",
        ).getSingle();
        if (hasOsmId.read<int>('c') == 0) {
          await migrator.addColumn(mapMarkers, mapMarkers.osmId);
        }
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_map_markers_osm_id '
          'ON map_markers (osm_id) WHERE osm_id IS NOT NULL',
        );

        // Bestehende Türme-Collections (aus MapCollectionSeeder, fields: []
        // zum Seed-Zeitpunkt) bekommen die 3 neuen Tower-Felder nachträglich
        // in field_config gemerged — NICHT überschrieben, damit vom User über
        // "Feld hinzufügen" selbst ergänzte Custom-Felder erhalten bleiben.
        // Die Feld-JSONs sind hier bewusst als Literal dupliziert (nicht aus
        // PredefinedFields importiert): Migrationen bleiben unabhängig von
        // künftigen Änderungen an Feature-Code.
        const newTowerFields = [
          {
            'key': 'towerType',
            'label': 'Turmtyp',
            'type': 'select',
            'iconName': 'cell_tower',
            'options': [
              {'value': 'Funkmast', 'colorHex': '00D4D4'},
              {'value': 'Sendemast', 'colorHex': '5B6CF9'},
              {'value': 'Sonstige', 'colorHex': '8888AA'},
            ],
          },
          {
            'key': 'towerHeight',
            'label': 'Höhe (m)',
            'type': 'text',
            'iconName': 'height',
            'options': [],
          },
          {
            'key': 'towerOperator',
            'label': 'Betreiber',
            'type': 'text',
            'iconName': 'business',
            'options': [],
          },
        ];
        final rows = await customSelect(
          "SELECT id, field_config FROM map_collections WHERE icon_name = 'tower'",
        ).get();
        for (final row in rows) {
          final id = row.read<int>('id');
          // Defensiv: reale Bestandsdaten können von der beim Schreiben dieser
          // Migration angenommenen Form abweichen (fehlendes/kaputtes JSON,
          // fehlender oder falsch typisierter 'fields'-Key, Nicht-Map-Einträge).
          // Eine Migration darf hierbei niemals werfen — sonst startet die App
          // für den betroffenen Nutzer nie wieder.
          Map<String, dynamic> cfg;
          try {
            final decoded = jsonDecode(row.read<String>('field_config'));
            cfg = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
          } catch (_) {
            cfg = <String, dynamic>{};
          }
          final rawFields = cfg['fields'];
          final fields = rawFields is List
              ? rawFields
                  .whereType<Map>()
                  .map((m) => Map<String, dynamic>.from(m))
                  .toList()
              : <Map<String, dynamic>>[];
          final existingKeys = fields.map((f) => f['key']).toSet();
          for (final f in newTowerFields) {
            if (!existingKeys.contains(f['key'])) fields.add(f);
          }
          cfg['fields'] = fields;
          await customStatement(
            'UPDATE map_collections SET field_config = ? WHERE id = ?',
            [jsonEncode(cfg), id],
          );
        }
      }
      if (from < 25) {
        // Analog zu osm_id (v24): idempotenter addColumn, damit ein
        // abgebrochener vorheriger Migrationsversuch die App nicht dauerhaft
        // startunfähig macht.
        final hasExternalId = await customSelect(
          "SELECT COUNT(*) AS c FROM pragma_table_info('map_markers') WHERE name = 'external_id'",
        ).getSingle();
        if (hasExternalId.read<int>('c') == 0) {
          await migrator.addColumn(mapMarkers, mapMarkers.externalId);
        }
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_map_markers_external_id '
          'ON map_markers (external_id) WHERE external_id IS NOT NULL',
        );
      }
      if (from < 26) {
        await _createMapPerformanceIndexes();
      }
      if (from < 27) {
        await _migrateToMultipleDiaries(migrator);
      }
      if (from < 28) {
        await _fixDiaryEntryDuplicates();
      }
    },
  );

  /// Fügt [column] zu [table] hinzu, außer sie existiert schon.
  ///
  /// Notwendig, weil `migrator.createTable(...)` eine Tabelle immer nach der
  /// heutigen, vollständigen Dart-Schema-Definition anlegt — nicht nach dem
  /// historischen Stand zum Zeitpunkt des jeweiligen Migrationsschritts. Ein
  /// Gerät, das viele Versionen auf einmal überspringt (z.B. eine seit
  /// v0.2.x nie aktualisierte Installation), kann dadurch auf ein frühes
  /// `createTable` treffen, das eine Spalte schon enthält, die ein späterer
  /// Schritt per `addColumn` nachträgt — ohne diese Absicherung schlägt das
  /// mit "duplicate column name" fehl und die App bliebe dauerhaft
  /// startunfähig. Empirisch verifiziert über einen echten Migrationstest ab
  /// Schema v1 (`test/data/database/legacy_v1_migration_test.dart`), der
  /// genau daran zuerst gescheitert ist (bei `workout_day_exercises.notes`).
  /// Folgt demselben Muster, das bereits für `osm_id`/`external_id` etabliert
  /// war (siehe v24/v25 oben) — hier nur als wiederverwendbarer Helfer statt
  /// dupliziertem Inline-Check an über zehn Stellen.
  Future<void> _addColumnIfMissing(
    Migrator migrator,
    TableInfo table,
    GeneratedColumn column,
    String columnName,
  ) async {
    final exists = await customSelect(
      "SELECT COUNT(*) AS c FROM pragma_table_info('${table.actualTableName}') "
      "WHERE name = '$columnName'",
    ).getSingle();
    if (exists.read<int>('c') == 0) {
      await migrator.addColumn(table, column);
    }
  }

  /// Behebt einen Bug, bei dem `upsertEntry` kein echtes Upsert war (kein
  /// Unique-Index, `id` wurde nie mitgegeben) — ein Doppel-Tap auf
  /// "Foto"/"Video" konnte zwei Zeilen für denselben Tag im selben Tagebuch
  /// anlegen. Räumt zuerst eventuell bereits entstandene Duplikate auf (behält
  /// je Gruppe die zuletzt angelegte Zeile), dann Unique-Index, damit ein
  /// echtes `ON CONFLICT`-Upsert möglich wird. Zusätzlich ein Index auf
  /// `(diary_id, created_at)` für die nach `createdAt` sortierten Abfragen
  /// (`getRecentEntries`, `getLastEntry`, `getDatesLastYear`) — bislang ein
  /// voller Tabellenscan pro Aufruf. Idempotent (`IF NOT EXISTS` bzw.
  /// wirkungslos bei bereits dedupliziertem Bestand).
  /// Wird an zwei Stellen aufgerufen: hier in der v27→v28-Migration
  /// (Bestandsinstallationen) und bei Neuinstallationen **nach** dem
  /// Diary-Seeder (`main.dart`) — dort läuft keine Migration.
  Future<void> ensureDiaryEntryIndexes() => _fixDiaryEntryDuplicates();

  Future<void> _fixDiaryEntryDuplicates() async {
    await customStatement(
      'DELETE FROM diary_entries '
      'WHERE diary_id IS NOT NULL AND id NOT IN ('
      '  SELECT MAX(id) FROM diary_entries '
      '  WHERE diary_id IS NOT NULL GROUP BY diary_id, date'
      ')',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_diary_entries_diary_date '
      'ON diary_entries (diary_id, date) WHERE diary_id IS NOT NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_diary_entries_diary_created '
      'ON diary_entries (diary_id, created_at)',
    );
  }

  /// Führt von einem einzelnen impliziten Tagebuch zu mehreren benannten
  /// Tagebüchern: legt die neue `diaries`-Tabelle an, erstellt ein
  /// Default-Tagebuch für den kompletten Bestand und befüllt `diary_id` bei
  /// allen vorhandenen `diary_entries` zurück. Idempotent (guard über
  /// pragma_table_info), damit ein abgebrochener vorheriger Versuch die App
  /// nicht dauerhaft startunfähig macht.
  Future<void> _migrateToMultipleDiaries(Migrator migrator) async {
    await migrator.createTable(diaries);
    final defaultDiaryId = await into(diaries).insert(
      DiariesCompanion.insert(
        name: 'Mein Tagebuch',
        iconName: 'book',
        createdAt: DateTime.now(),
      ),
    );
    final hasDiaryId = await customSelect(
      "SELECT COUNT(*) AS c FROM pragma_table_info('diary_entries') WHERE name = 'diary_id'",
    ).getSingle();
    if (hasDiaryId.read<int>('c') == 0) {
      await migrator.addColumn(diaryEntries, diaryEntries.diaryId);
    }
    await customStatement(
      'UPDATE diary_entries SET diary_id = ? WHERE diary_id IS NULL',
      [defaultDiaryId],
    );
  }

  /// Indizes für die Karten-Abfragepfade. Bis v25 existierten auf `map_markers`
  /// NUR die beiden Unique-Indizes für die Import-Deduplizierung (`osm_id`,
  /// `external_id`) — auf `collection_id` lag kein Index. Jede Abfrage nach
  /// Sammlung war damit ein vollständiger Tabellenscan; bei 496.000 Zeilen
  /// (413k Türme + 82k Lost Places) dauerte eine einzelne
  /// Kartenausschnitt-Abfrage ~2,3 s — und die läuft bei jedem Verschieben und
  /// Zoomen der Karte. Mit dem zusammengesetzten Index sind es ~0,06 s
  /// (gemessen an echten Gerätedaten, gleiches Ergebnis).
  ///
  /// `marker_photos.marker_id` hatte ebenfalls keinen Index, obwohl die
  /// Foto-Batch-Abfrage der Kartenansicht genau darauf filtert.
  ///
  /// Kosten: rund 14 MB zusätzliche Datenbankgröße, einmalig ~2,4 s beim
  /// Anlegen. Idempotent (`IF NOT EXISTS`), läuft daher auch bei einem
  /// abgebrochenen vorherigen Migrationsversuch gefahrlos erneut.
  ///
  /// Wird an zwei Stellen aufgerufen:
  /// * hier in der v25→v26-Migration (Bestandsinstallationen), und
  /// * bei Neuinstallationen **nach** den Seedern (`main.dart`) — dort läuft
  ///   keine Migration, und ein vorher angelegter Index würde den einmaligen
  ///   Import von ~496.000 Zeilen deutlich verlangsamen, weil er bei jeder
  ///   einzelnen Zeile mitgepflegt werden müsste.
  Future<void> createMapPerformanceIndexes() =>
      _createMapPerformanceIndexes();

  Future<void> _createMapPerformanceIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_map_markers_collection_pos '
      'ON map_markers (collection_id, latitude, longitude)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_marker_photos_marker '
      'ON marker_photos (marker_id)',
    );
  }

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/preferences_provider.dart';
import 'data/database/traum_database.dart';
import 'data/repositories/exercise_library_seeder.dart';
import 'data/repositories/exercise_seeder.dart';
import 'data/repositories/grocery_price_seeder.dart';
import 'data/repositories/map_collection_seeder.dart';
import 'data/repositories/substance_database_copier.dart';
import 'data/repositories/supplement_seeder.dart';
import 'data/services/recurring_poster.dart';
import 'widget/widget_data_service.dart';
import 'widget/widget_update_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final db = TraumDatabase();

  await Future.wait([
    WidgetDataService.init(),
    NotificationService.init(),
  ]);

  // Register the periodic background widget refresh (internally guarded).
  await registerWidgetPeriodicRefresh();

  // ExerciseSeeder must finish before ExerciseLibrarySeeder runs: the latter
  // looks up existing exercises by name to avoid inserting duplicates, so it
  // needs to see ExerciseSeeder's rows already committed. Both seeders write
  // to the same `Exercises` table, so this pair runs sequentially while the
  // remaining (unrelated-table) seeders still run concurrently.
  await ExerciseSeeder.seedIfNeeded(db, prefs);
  await ExerciseLibrarySeeder.seedIfNeeded(db, prefs);

  await Future.wait([
    SupplementSeeder.seedIfNeeded(db, prefs),
    SubstanceDatabaseCopier.copyIfNeeded(db, prefs),
    MapCollectionSeeder.seedIfNeeded(db, prefs),
    GroceryPriceSeeder.seedIfNeeded(db, prefs),
  ]);

  await RecurringPoster.runIfNeeded(db);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
      child: const TraumApp(),
    ),
  );
}

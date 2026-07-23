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

  // Surface rendering/layout exceptions (e.g. an invalid SliverGeometry) as a
  // visible error banner instead of a silent blank/black area — otherwise
  // such bugs are invisible during manual testing until logcat is checked.
  ErrorWidget.builder = (FlutterErrorDetails details) => Container(
        color: const Color(0xFF0D0D1A),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          'UI-Fehler: ${details.exceptionAsString()}',
          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );

  final prefs = await SharedPreferences.getInstance();
  final db = TraumDatabase();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
      child: const TraumApp(),
    ),
  );

  // Widget/notification init, WorkManager registration and seeders all run
  // after the first frame instead of blocking startup. None of them are
  // needed to draw the first frame, but each used to be awaited beforehand:
  // tz database load + several plugin/platform-channel round trips (widget
  // App Group, notification plugin + channels, WorkManager init) added real
  // delay before anything appeared on screen. Seeders additionally no-op
  // instantly via `seedIfNeeded` once their data already exists, so on every
  // launch except the very first this was pure overhead before the first
  // frame could even be drawn.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
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
  });
}

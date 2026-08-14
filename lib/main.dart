import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notifications/notification_scheduler.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/preferences_provider.dart';
import 'core/services/crash_log_service.dart';
import 'data/database/traum_database.dart';
import 'data/repositories/diary_seeder.dart';
import 'data/repositories/exercise_library_seeder.dart';
import 'data/repositories/exercise_seeder.dart';
import 'data/repositories/grocery_price_seeder.dart';
import 'data/repositories/lost_place_data_seeder.dart';
import 'data/repositories/map_collection_seeder.dart';
import 'data/repositories/substance_reference_db_copier.dart';
import 'data/repositories/supplement_seeder.dart';
import 'data/repositories/tower_data_seeder.dart';
import 'data/services/recurring_poster.dart';
import 'features/diary/diary_thumbnail_backfill.dart';
import 'widget/widget_data_service.dart';
import 'widget/widget_update_scheduler.dart';

void main() {
  // Wraps the entire body (including runApp) in a zone that catches errors
  // outside Flutter's own error path (e.g. in un-awaited Futures) — the
  // standard pattern for local crash logging without a cloud service.
  CrashLogService.runGuarded(_runApp);
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  CrashLogService.installFrameworkHandlers();

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

  // A plain ProviderContainer (attached via UncontrolledProviderScope rather
  // than ProviderScope's own internal one) so main() can reach providers
  // directly below — needed to rebuild scheduled notifications once at
  // startup, the same way rescheduleAllNotifications() is called after a
  // Settings toggle or medication change.
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
    ],
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const TraumApp()),
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
    await Future.wait([WidgetDataService.init(), NotificationService.init()]);
    // Rebuild every scheduled notification from current DB/prefs state on
    // every cold start — not just when a Settings toggle or medication is
    // touched. Without this, reminders configured in a previous app version
    // (or before notification permission was granted) never got a chance to
    // re-sync onto the current, correct scheduling logic; they just stayed
    // whatever they were (or weren't) until the user happened to touch a
    // notification setting again, which for most users is never.
    await rescheduleAllNotifications(container);
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
      SubstanceReferenceDbCopier.copyIfNeeded(prefs),
      MapCollectionSeeder.seedIfNeeded(db, prefs),
      GroceryPriceSeeder.seedIfNeeded(db, prefs),
      DiarySeeder.seedIfNeeded(db, prefs),
    ]);
    // Brauchen ihre jeweilige Collection aus MapCollectionSeeder — laufen
    // daher erst danach, nicht im selben Future.wait. Unabhängige Tabellen-
    // Bereiche (unterschiedliche Collections), daher parallel zueinander.
    await Future.wait([
      TowerDataSeeder.seedIfNeeded(db, prefs),
      LostPlaceDataSeeder.seedIfNeeded(db, prefs),
    ]);

    // Erst NACH den Karten-Seedern: bei einer Neuinstallation läuft keine
    // Migration, die Indizes müssen also hier angelegt werden — und zwar nach
    // dem Import, weil ein bereits bestehender Index den einmaligen Import von
    // ~496.000 Zeilen bei jeder Zeile mitgepflegt werden müsste. Idempotent
    // (`IF NOT EXISTS`), bei jedem weiteren Start also ein billiger No-Op.
    await db.createMapPerformanceIndexes();
    await db.ensureDiaryEntryIndexes();
    await DiaryThumbnailBackfill.runIfNeeded(db, prefs);

    await RecurringPoster.runIfNeeded(db);
  });
}

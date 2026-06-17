import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/providers/database_provider.dart';
import '../core/providers/preferences_provider.dart';
import '../data/database/traum_database.dart';
import 'widget_data_collector.dart';
import 'widget_data_service.dart';

/// Unique task name / identifier used for the periodic WorkManager background job.
const String kWidgetRefreshTask = 'de.traum.widget.refresh';

/// Refreshes homescreen widgets by collecting a new snapshot and writing it.
///
/// Accepts a [read] function so it works in any context (foreground widget,
/// background isolate). All errors are caught internally — callers never throw.
Future<void> refreshWidgetsFromRead(
  R Function<R>(ProviderListenable<R> provider) read,
) async {
  try {
    final snap = await WidgetDataCollector.collect(read);
    await WidgetDataService.write(snap);
  } catch (e, st) {
    debugPrint('[WidgetUpdateScheduler] refresh failed: $e\n$st');
  }
}

/// Entry point for the WorkManager background isolate.
///
/// Must be a top-level function annotated with `@pragma('vm:entry-point')` so
/// the AOT compiler keeps it alive.
@pragma('vm:entry-point')
void widgetWorkmanagerDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kWidgetRefreshTask) {
      ProviderContainer? container;
      try {
        // Re-initialise platform channels in the background isolate.
        final prefs = await SharedPreferences.getInstance();
        final db = TraumDatabase();
        await WidgetDataService.init();

        container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
        );

        await refreshWidgetsFromRead(container.read);
      } catch (e, st) {
        debugPrint('[widgetWorkmanagerDispatcher] task failed: $e\n$st');
        // Return true so WorkManager does not endlessly retry on data errors.
        return true;
      } finally {
        container?.dispose();
      }
    }
    return true;
  });
}

/// Initialises WorkManager and registers the periodic 30-minute widget refresh.
///
/// The entire body is wrapped in try/catch — a WorkManager failure must never
/// block or crash app startup.
Future<void> registerWidgetPeriodicRefresh() async {
  try {
    await Workmanager().initialize(widgetWorkmanagerDispatcher);
    await Workmanager().registerPeriodicTask(
      kWidgetRefreshTask,
      kWidgetRefreshTask,
      frequency: const Duration(minutes: 30),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e, st) {
    debugPrint('[registerWidgetPeriodicRefresh] init failed: $e\n$st');
  }
}

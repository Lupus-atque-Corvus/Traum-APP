import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/preferences_provider.dart';
import 'data/database/traum_database.dart';
import 'data/repositories/exercise_seeder.dart';
import 'data/repositories/substance_database_copier.dart';
import 'data/repositories/supplement_seeder.dart';
import 'widget/widget_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final db = TraumDatabase();

  await Future.wait([
    WidgetDataService.init(),
    NotificationService.init(),
  ]);

  await Future.wait([
    ExerciseSeeder.seedIfNeeded(db, prefs),
    SupplementSeeder.seedIfNeeded(db, prefs),
    SubstanceDatabaseCopier.copyIfNeeded(db, prefs),
  ]);

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

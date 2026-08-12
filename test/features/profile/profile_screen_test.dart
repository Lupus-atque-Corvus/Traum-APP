import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/core/providers/preferences_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/profile/profile_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(SharedPreferences prefs, TraumDatabase db) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfileScreen(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('renders without a stored weight log', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_wrap(prefs, db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Mein Profil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'derives the correct BMI category from height (default 175cm) and '
      'the latest weight log', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // 70kg at the default 175cm height -> BMI ~22.9 -> normal weight.
    await db.healthDao.insertWeightLog(WeightLogsCompanion.insert(
      weightKg: 70,
      logDate: DateTime.now(),
    ));

    await tester.pumpWidget(_wrap(prefs, db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Normalgewicht'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

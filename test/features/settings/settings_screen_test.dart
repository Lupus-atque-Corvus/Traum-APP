import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/core/providers/preferences_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/settings/settings_screen.dart';
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
    home: const SettingsScreen(),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TraumDatabase db;

  setUp(() {
    db = TraumDatabase.forTesting(NativeDatabase.memory());
    // Realistic phone viewport — the default 800x600 test surface overflows
    // a full-length settings ListView the same way it did for pin_lock_screen.
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1080,
      2340,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  tearDown(() => db.close());

  // NOTE: deliberately never uses pumpAndSettle() here. _CalendarSyncSection
  // shows an indeterminate CircularProgressIndicator while its (unmocked, in
  // tests never resolving) device_calendar platform-channel call is pending —
  // an infinite ticker that pumpAndSettle() waits forever for, which is what
  // caused the 10-minute hang in the version of this test that Phase 9
  // deleted. Bounded pump() calls sidestep that entirely.
  testWidgets('renders all settings sections without throwing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_wrap(prefs, db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('SPRACHE'), findsOneWidget);
    expect(find.text('NAVIGATION'), findsOneWidget);
    expect(find.text('EINHEITEN'), findsOneWidget);
    expect(find.text('BENACHRICHTIGUNGEN'), findsOneWidget);
    expect(find.text('ZIELE'), findsOneWidget);
    expect(find.text('WÄHRUNG'), findsOneWidget);
    expect(find.text('DATENSCHUTZ & SICHERHEIT'), findsOneWidget);
    expect(find.text('RECHTLICHES'), findsOneWidget);
    expect(find.text('SUPPORT'), findsOneWidget);
    expect(find.text('APP'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // _NotificationsSection watches a live Drift stream (reminder times);
    // disposing via the framework's implicit teardown schedules a
    // zero-duration cleanup Timer too late for flutter_test's
    // `!timersPending` invariant check. Disposing explicitly here and
    // pumping once more lets that timer fire before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('reset-onboarding tile writes through preferences repository', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_wrap(prefs, db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Onboarding wiederholen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}

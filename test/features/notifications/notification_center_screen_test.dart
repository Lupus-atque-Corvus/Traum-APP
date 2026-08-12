import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/notifications/notification_center_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(TraumDatabase db) => ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NotificationCenterScreen(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('shows the empty state when nothing is due', (tester) async {
    await tester.pumpWidget(_wrap(db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Alles erledigt — keine offenen Punkte'), findsOneWidget);
  });

  testWidgets(
      'shows localized sections for due medications, an appointment and '
      'open todos', (tester) async {
    await db.medicationDao.insertMedication(MedicationsCompanion.insert(
      name: 'Ibuprofen',
      timings: const Value('[{"time":"08:00","days":[1,2,3,4,5,6,7]}]'),
    ));
    await db.planningDao.insertAppointment(AppointmentsCompanion.insert(
      title: 'Zahnarzt',
      startTime: DateTime.now().add(const Duration(days: 1)),
    ));
    await db.planningDao.insertTodo(TodosCompanion.insert(
      title: 'Einkaufen',
    ));

    await tester.pumpWidget(_wrap(db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Medikamente heute'), findsOneWidget);
    expect(find.text('0 eingenommen · 1 aktiv'), findsOneWidget);
    expect(find.text('Nächster Termin'), findsOneWidget);
    expect(find.text('Zahnarzt'), findsOneWidget);
    expect(find.text('Offene Aufgaben'), findsOneWidget);
    expect(find.text('1 offen · Einkaufen'), findsOneWidget);
    expect(find.text('Alles erledigt — keine offenen Punkte'), findsNothing);
  });
}

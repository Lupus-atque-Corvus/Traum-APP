import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/period_tracking/period_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

void main() {
  testWidgets('PeriodScreen renders empty state without throwing',
      (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: const PeriodScreen(),
      ),
    ));

    // Let streams emit initial values
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(PeriodScreen), findsOneWidget);

    // Replace widget tree with an empty container before teardown so that
    // Drift's markAsClosed timer fires while fake-async is still running.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}

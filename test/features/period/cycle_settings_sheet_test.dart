import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/period_tracking/cycle_settings_sheet.dart';
import 'package:traum/l10n/app_localizations.dart';

void main() {
  testWidgets('CycleSettingsSheet reports menarche change via onSave',
      (tester) async {
    CycleProfileCompanion? saved;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: Scaffold(
        body: CycleSettingsSheet(
          menarcheDate: null,
          lutealPhaseOverride: null,
          onSave: (c) async => saved = c,
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('save_cycle_settings')));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
  });
}

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/period_tracking/daily_log_sheet.dart';
import 'package:traum/l10n/app_localizations.dart';

void main() {
  testWidgets('DailyLogSheet saves a daily log via onSave', (tester) async {
    DailyLogsCompanion? saved;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: Scaffold(
        body: DailyLogSheet(
          date: DateTime(2026, 6, 15),
          existing: null,
          onSave: (c) async => saved = c,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mood_3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save_daily_log')));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
    expect(saved!.mood, const Value(3));
  });

  testWidgets('DailyLogSheet adds a symptom via onAddSymptom', (tester) async {
    final added = <String>[];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: Scaffold(
        body: DailyLogSheet(
          date: DateTime(2026, 6, 15),
          existing: null,
          onSave: (_) async {},
          onAddSymptom: (name, intensity) async => added.add(name),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // 'Krämpfe' is the German translation of symptomCramps
    await tester.tap(find.text('Krämpfe').first);
    await tester.pumpAndSettle();
    expect(added, isNotEmpty);
    expect(added.first, 'Krämpfe');
  });
}

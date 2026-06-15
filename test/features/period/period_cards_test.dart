import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/period_tracking/cycle_analysis.dart';
import 'package:traum/features/period_tracking/widgets/period_cards.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('PredictionCard renders next-period days', (tester) async {
    final analysis = CycleAnalysis(
      nextPeriodPredicted: DateTime(2026, 6, 29),
      nextPeriodRangeStart: DateTime(2026, 6, 27),
      nextPeriodRangeEnd: DateTime(2026, 7, 1),
      ovulationDate: DateTime(2026, 6, 16),
      fertileWindowStart: DateTime(2026, 6, 12),
      fertileWindowEnd: DateTime(2026, 6, 17),
    );
    await tester.pumpWidget(_wrap(
        PredictionCard(analysis: analysis, today: DateTime(2026, 6, 15))));
    expect(find.textContaining('14'), findsWidgets);
  });

  testWidgets('HealthFlagsCard shows all-normal when no flags', (tester) async {
    await tester.pumpWidget(_wrap(const HealthFlagsCard(flags: [])));
    expect(find.textContaining('Normbereich'), findsOneWidget);
  });
}

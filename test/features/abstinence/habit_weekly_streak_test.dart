import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/abstinence/abstinence_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

/// Unmounts the widget tree and flushes Drift's stream-close timers so the
/// test does not trip the "Timer still pending" teardown check (see
/// test/features/budget/debts_screen_test.dart for the established pattern).
Future<void> _flushAndUnmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('a weekly habit shows a week-based streak, not a day-based one '
      '(regression: previously every habit used a consecutive-DAY streak '
      'regardless of its stored frequency, so a weekly habit logged '
      'faithfully every week still showed a streak of 0 or 1 because most '
      'days in between have no log)', (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final habitId = await db.planningDao.insertHabit(
      HabitsCompanion.insert(name: 'Yoga', frequency: const Value('weekly')),
    );

    // One log this week, one log last week — a real 2-week streak for a
    // weekly habit, but only 2 out of the last 14 days for a daily one.
    final now = DateTime.now();
    final thisWeekMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final lastWeekMonday = thisWeekMonday.subtract(const Duration(days: 7));
    await db.planningDao.insertHabitLog(
      HabitLogsCompanion.insert(habitId: habitId, logDate: thisWeekMonday),
    );
    await db.planningDao.insertHabitLog(
      HabitLogsCompanion.insert(habitId: habitId, logDate: lastWeekMonday),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AbstinenceScreen(),
        ),
      ),
    );
    // Bounded pumps, not pumpAndSettle: AbstinenceScreen's TabBarView
    // pre-builds neighbouring tabs, and something in that tree never
    // settles in the test harness (same established gotcha as the
    // modal-sheet transitions elsewhere in this suite — pumpAndSettle
    // hung for the full 10-minute test timeout here).
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Gewohnheiten'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.textContaining('2 Wochen in Folge'), findsOneWidget);
    // Must not fall back to the daily wording/count for a weekly habit.
    expect(find.textContaining('Tage in Folge'), findsNothing);

    await _flushAndUnmount(tester);
  });
}

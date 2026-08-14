import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/services/calendar_sync_service.dart'
    show NativeCalendar;
import 'package:traum/features/planning/calendar_picker_dialog.dart';
import 'package:traum/l10n/app_localizations.dart';

void main() {
  Widget wrap(
    List<NativeCalendar> calendars,
    List<String> initialIds,
    void Function(List<String>?) onResult,
  ) => MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          final result = await showCalendarPickerDialog(
            context,
            calendars,
            initialIds,
          );
          onResult(result);
        },
        child: const Text('open'),
      ),
    ),
  );

  testWidgets(
    'shows a hint instead of an empty list when there are no calendars',
    (tester) async {
      await tester.pumpWidget(wrap(const [], const [], (_) {}));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Keine Kalender gefunden.\nBitte schließe den Planner und öffne ihn erneut.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Done is disabled until at least one calendar is selected', (
    tester,
  ) async {
    List<String>? result = ['not called'];
    await tester.pumpWidget(
      wrap(
        [const NativeCalendar(id: 'a', name: 'Kalender A')],
        const [],
        (r) => result = r,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final doneButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Fertig'),
    );
    expect(doneButton.onPressed, isNull);

    await tester.tap(find.text('Kalender A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();

    expect(result, ['a']);
  });

  testWidgets('cancel returns null without changing the selection', (
    tester,
  ) async {
    List<String>? result = ['not called'];
    await tester.pumpWidget(
      wrap(
        [const NativeCalendar(id: 'a', name: 'Kalender A')],
        const ['a'],
        (r) => result = r,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}

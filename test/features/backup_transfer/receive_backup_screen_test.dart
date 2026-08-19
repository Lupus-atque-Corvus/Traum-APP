import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/core/services/backup_service.dart';
import 'package:traum/core/services/backup_transfer/backup_transfer_models.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/backup_transfer/receive_backup_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

import 'fakes.dart';

/// Same teardown pattern used throughout the widget-test suite (see
/// test/features/abstinence/habit_weekly_streak_test.dart) — unmounts and
/// flushes Drift's stream-close timers so the test doesn't trip the
/// "Timer still pending" check.
Future<void> _flushAndUnmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  late TraumDatabase db;

  setUp(() {
    db = TraumDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap(Widget child) => ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  /// Real `NetworkInterface.list()` I/O in `_start()` still needs the real
  /// event loop that only `runAsync` provides inside `testWidgets` — but
  /// unlike a real socket round-trip, this is a fast local enumeration
  /// call, so one bounded runAsync tick is all that's needed (no flakiness
  /// risk from real network timing).
  Future<void> pumpUntilReady(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
    });
    await tester.pump();
  }

  testWidgets('shows the pairing code once the server is ready', (
    tester,
  ) async {
    final server = FakeBackupReceiveServer(
      backupService: BackupService(db),
      info: PairingInfo(
        host: '10.0.0.5',
        port: 4321,
        code: PairingCode.tryParse('ABCD-EFGH')!,
      ),
    );
    await tester.pumpWidget(
      wrap(ReceiveBackupScreen(backupService: BackupService(db), server: server)),
    );
    await pumpUntilReady(tester);

    expect(find.textContaining('ABCD'), findsOneWidget);

    await _flushAndUnmount(tester);
  });

  testWidgets(
    'accepting both confirmations calls through to the server and shows success',
    (tester) async {
      final server = FakeBackupReceiveServer(backupService: BackupService(db));
      await tester.pumpWidget(
        wrap(
          ReceiveBackupScreen(backupService: BackupService(db), server: server),
        ),
      );
      await pumpUntilReady(tester);

      server.emit(TransferStatus.pendingConfirmation1, senderName: 'Test-Sender');
      await tester.pump();
      expect(find.textContaining('Test-Sender'), findsOneWidget);

      await tester.tap(find.text('Annehmen'));
      await tester.pump();
      expect(server.confirmation1Calls, [true]);

      server.emit(
        TransferStatus.pendingConfirmation2,
        preview: const BackupPreview(tableCount: 3, rowCount: 10, mediaCount: 1),
      );
      await tester.pump();
      expect(find.textContaining('Zeilen'), findsOneWidget);

      await tester.tap(find.text('Annehmen'));
      await tester.pump();
      expect(server.confirmation2Calls, [true]);

      server.emit(TransferStatus.done);
      await tester.pump();
      expect(find.textContaining('erfolgreich'), findsOneWidget);

      await _flushAndUnmount(tester);
    },
  );

  testWidgets('declining confirmation #1 shows the declined state', (
    tester,
  ) async {
    final server = FakeBackupReceiveServer(backupService: BackupService(db));
    await tester.pumpWidget(
      wrap(ReceiveBackupScreen(backupService: BackupService(db), server: server)),
    );
    await pumpUntilReady(tester);

    server.emit(TransferStatus.pendingConfirmation1, senderName: 'Test-Sender');
    await tester.pump();

    await tester.tap(find.text('Ablehnen'));
    await tester.pump();
    expect(server.confirmation1Calls, [false]);

    server.emit(TransferStatus.declined1);
    await tester.pump();
    expect(find.textContaining('abgelehnt'), findsOneWidget);

    await _flushAndUnmount(tester);
  });
}

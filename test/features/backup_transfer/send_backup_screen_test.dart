import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/core/services/backup_service.dart';
import 'package:traum/core/services/backup_transfer/backup_send_client.dart';
import 'package:traum/core/services/backup_transfer/backup_transfer_models.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/backup_transfer/send_backup_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

import 'fakes.dart';

Future<void> _flushAndUnmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// Not pumpAndSettle(): the manual-entry sheet's TextFields have a blinking
/// text cursor (a repeating Timer), which never "settles" by
/// pumpAndSettle's definition — same established gotcha noted elsewhere in
/// this suite for modal-sheet/tab-view transitions.
Future<void> _boundedPump(WidgetTester tester, {int times = 5}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _fakeBackupBytes = Uint8List.fromList([1, 2, 3, 4]);

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

  Future<void> fillManualEntryAndConnect(WidgetTester tester) async {
    await tester.tap(find.text('Code manuell eingeben'));
    await _boundedPump(tester);
    await tester.enterText(find.byType(TextField).at(0), '192.168.1.10');
    await tester.enterText(find.byType(TextField).at(1), '5000');
    await tester.enterText(find.byType(TextField).at(2), 'ABCD-EFGH');
    await tester.tap(find.text('Verbinden'));
    await _boundedPump(tester);
  }

  testWidgets('shows the manual-entry fallback once the backup is built', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SendBackupScreen(
          backupService: BackupService(db),
          debugBackupBytes: _fakeBackupBytes,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Code manuell eingeben'), findsOneWidget);

    await _flushAndUnmount(tester);
  });

  testWidgets('a successful send shows the done state', (tester) async {
    final fakeClient = FakeBackupSendClient(
      result: const BackupTransferResult(TransferStatus.done),
      statusesBeforeResult: [
        TransferStatus.pendingConfirmation1,
        TransferStatus.acceptedAwaitingUpload,
        TransferStatus.uploading,
      ],
    );
    await tester.pumpWidget(
      wrap(
        SendBackupScreen(
          backupService: BackupService(db),
          debugBackupBytes: _fakeBackupBytes,
          debugDeviceName: 'Test-Sender',
          clientFactory: () => fakeClient,
        ),
      ),
    );
    await tester.pump();

    await fillManualEntryAndConnect(tester);

    expect(fakeClient.capturedTarget?.host, '192.168.1.10');
    expect(fakeClient.capturedTarget?.port, 5000);
    expect(fakeClient.capturedDeviceName, 'Test-Sender');
    expect(find.textContaining('abgeschlossen'), findsOneWidget);

    await _flushAndUnmount(tester);
  });

  testWidgets('a declined send shows the declined state', (tester) async {
    final fakeClient = FakeBackupSendClient(
      result: const BackupTransferResult(TransferStatus.declined1),
    );
    await tester.pumpWidget(
      wrap(
        SendBackupScreen(
          backupService: BackupService(db),
          debugBackupBytes: _fakeBackupBytes,
          debugDeviceName: 'Test-Sender',
          clientFactory: () => fakeClient,
        ),
      ),
    );
    await tester.pump();

    await fillManualEntryAndConnect(tester);

    expect(find.textContaining('abgelehnt'), findsOneWidget);

    await _flushAndUnmount(tester);
  });
}

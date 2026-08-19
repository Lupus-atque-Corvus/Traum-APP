import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/services/backup_service.dart';
import 'package:traum/core/services/backup_transfer/backup_receive_server.dart';
import 'package:traum/core/services/backup_transfer/backup_send_client.dart';
import 'package:traum/core/services/backup_transfer/backup_transfer_models.dart';
import 'package:traum/data/database/traum_database.dart';

/// Watches [server]'s status stream and auto-responds the first time it
/// reaches [confirmation1] / [confirmation2], mirroring what a UI would do
/// when the user taps Accept — lets the happy-path test read top-to-bottom
/// instead of scattering listener setup through it.
StreamSubscription<TransferStatus> _autoRespond(
  BackupReceiveServer server, {
  required bool acceptFirst,
  required bool acceptSecond,
}) {
  var respondedFirst = false;
  var respondedSecond = false;
  return server.statusStream.listen((status) {
    if (status == TransferStatus.pendingConfirmation1 && !respondedFirst) {
      respondedFirst = true;
      server.respondToConfirmation1(acceptFirst);
    } else if (status == TransferStatus.pendingConfirmation2 && !respondedSecond) {
      respondedSecond = true;
      server.respondToConfirmation2(acceptSecond);
    }
  });
}

void main() {
  late TraumDatabase sourceDb;
  late TraumDatabase targetDb;

  setUp(() {
    sourceDb = TraumDatabase.forTesting(NativeDatabase.memory());
    targetDb = TraumDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await sourceDb.close();
    await targetDb.close();
  });

  Future<int> seedSourceRow() => sourceDb.foodProductsDao.insertProduct(
    FoodProductsCompanion.insert(
      name: 'Apfel',
      caloriesPer100g: 52,
      proteinPer100g: 0.3,
      carbsPer100g: 14,
      fatPer100g: 0.2,
      createdAt: DateTime.now(),
    ),
  );

  test('happy path: pair, accept twice, target DB ends up with the row', () async {
    final pid = await seedSourceRow();
    final backupBytes = (await BackupService(sourceDb).buildBackupZip()).zipBytes;

    final server = BackupReceiveServer(BackupService(targetDb));
    final info = await server.start();
    addTearDown(server.stop);
    final sub = _autoRespond(server, acceptFirst: true, acceptSecond: true);
    addTearDown(sub.cancel);

    final client = BackupSendClient(pollInterval: const Duration(milliseconds: 20));
    final result = await client.send(
      target: PairingInfo(host: '127.0.0.1', port: info.port, code: info.code),
      backupBytes: Uint8List.fromList(backupBytes),
      senderDeviceName: 'Test-Handy',
      senderPlatform: 'android',
    );

    expect(result.status, TransferStatus.done);

    final restored = await targetDb.foodProductsDao.getById(pid);
    expect(restored, isNotNull);
    expect(restored!.name, 'Apfel');
  });

  test('wrong pairing code is rejected, no session is created', () async {
    final server = BackupReceiveServer(BackupService(targetDb));
    final info = await server.start();
    addTearDown(server.stop);

    final client = BackupSendClient(pollInterval: const Duration(milliseconds: 20));
    final wrongInfo = PairingInfo(
      host: '127.0.0.1',
      port: info.port,
      code: PairingCode.generate(), // definitely not info.code
    );

    await expectLater(
      client.send(
        target: wrongInfo,
        backupBytes: Uint8List.fromList([1, 2, 3]),
        senderDeviceName: 'Test-Handy',
        senderPlatform: 'android',
      ),
      throwsA(isA<BackupTransferException>()),
    );
  });

  test('receiver declining confirmation #1 stops the transfer, no upload happens', () async {
    final pid = await seedSourceRow();
    final backupBytes = (await BackupService(sourceDb).buildBackupZip()).zipBytes;

    final server = BackupReceiveServer(BackupService(targetDb));
    final info = await server.start();
    addTearDown(server.stop);
    final sub = _autoRespond(server, acceptFirst: false, acceptSecond: true);
    addTearDown(sub.cancel);

    final client = BackupSendClient(pollInterval: const Duration(milliseconds: 20));
    final result = await client.send(
      target: PairingInfo(host: '127.0.0.1', port: info.port, code: info.code),
      backupBytes: Uint8List.fromList(backupBytes),
      senderDeviceName: 'Test-Handy',
      senderPlatform: 'android',
    );

    expect(result.status, TransferStatus.declined1);
    final restored = await targetDb.foodProductsDao.getById(pid);
    expect(restored, isNull);
  });

  test(
    'receiver declining confirmation #2 leaves the target DB untouched even though bytes were fully received',
    () async {
      final pid = await seedSourceRow();
      final backupBytes = (await BackupService(sourceDb).buildBackupZip()).zipBytes;

      final server = BackupReceiveServer(BackupService(targetDb));
      final info = await server.start();
      addTearDown(server.stop);
      final sub = _autoRespond(server, acceptFirst: true, acceptSecond: false);
      addTearDown(sub.cancel);

      final client = BackupSendClient(pollInterval: const Duration(milliseconds: 20));
      final result = await client.send(
        target: PairingInfo(host: '127.0.0.1', port: info.port, code: info.code),
        backupBytes: Uint8List.fromList(backupBytes),
        senderDeviceName: 'Test-Handy',
        senderPlatform: 'android',
      );

      expect(result.status, TransferStatus.declined2);
      // The preview must have been computed (proves bytes really arrived
      // and were decrypted) even though nothing was applied.
      expect(server.preview, isNotNull);
      expect(server.preview!.rowCount, greaterThanOrEqualTo(1));

      final restored = await targetDb.foodProductsDao.getById(pid);
      expect(restored, isNull);
    },
  );

  test('server reports the sender device name during confirmation #1', () async {
    final server = BackupReceiveServer(BackupService(targetDb));
    final info = await server.start();
    addTearDown(server.stop);

    final client = BackupSendClient(pollInterval: const Duration(milliseconds: 20));
    // Deliberately not awaited yet — it can't complete until
    // respondToConfirmation1 is called below, which happens after we've
    // observed the confirmation-1 state. Captured and awaited at the end so
    // nothing is left dangling across the test's teardown.
    final sendFuture = client.send(
      target: PairingInfo(host: '127.0.0.1', port: info.port, code: info.code),
      backupBytes: Uint8List.fromList([1, 2, 3]),
      senderDeviceName: 'Lupus-Desktop',
      senderPlatform: 'windows',
    );

    await server.statusStream.firstWhere(
      (s) => s == TransferStatus.pendingConfirmation1,
    );
    expect(server.pairedSenderName, 'Lupus-Desktop');
    server.respondToConfirmation1(false);

    final result = await sendFuture;
    expect(result.status, TransferStatus.declined1);
  });
}

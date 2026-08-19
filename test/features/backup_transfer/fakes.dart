import 'dart:async';
import 'dart:typed_data';

import 'package:traum/core/services/backup_service.dart';
import 'package:traum/core/services/backup_transfer/backup_receive_server.dart';
import 'package:traum/core/services/backup_transfer/backup_send_client.dart';
import 'package:traum/core/services/backup_transfer/backup_transfer_models.dart';

/// Test double for [BackupReceiveServer] — lets a widget test drive
/// [TransferStatus] transitions directly via [emit], with no real sockets.
/// Protocol correctness (the real server talking to a real client over a
/// real socket, both confirmations, declines, wrong codes, tamper
/// detection, ...) is already proven end-to-end by
/// backup_transfer_roundtrip_test.dart; this fake exists so the *screen*'s
/// job — mapping each status to the right dialog — can be tested fast and
/// deterministically instead of via flaky real I/O inside `testWidgets`.
class FakeBackupReceiveServer implements BackupReceiveServer {
  FakeBackupReceiveServer({
    required this.backupService,
    PairingInfo? info,
  }) : _startInfo =
           info ??
           PairingInfo(
             host: '192.168.1.42',
             port: 12345,
             code: PairingCode.generate(),
           );

  @override
  final BackupService backupService;

  final PairingInfo _startInfo;
  final _statusController = StreamController<TransferStatus>.broadcast();

  TransferStatus? _status;
  String? _senderName;

  final List<bool> confirmation1Calls = [];
  final List<bool> confirmation2Calls = [];
  bool stopped = false;

  @override
  Stream<TransferStatus> get statusStream => _statusController.stream;

  @override
  TransferStatus? get status => _status;

  @override
  String? get pairedSenderName => _senderName;

  @override
  BackupPreview? preview;

  @override
  Future<PairingInfo> start() async => _startInfo;

  @override
  Future<void> stop() async {
    stopped = true;
    await _statusController.close();
  }

  @override
  void respondToConfirmation1(bool accept) {
    confirmation1Calls.add(accept);
  }

  @override
  Future<void> respondToConfirmation2(bool accept) async {
    confirmation2Calls.add(accept);
  }

  /// Simulates the receive server reaching [status] — e.g. as if a real
  /// sender had just paired ([TransferStatus.pendingConfirmation1], with
  /// [senderName]) or finished uploading
  /// ([TransferStatus.pendingConfirmation2], with a decoded [preview]).
  void emit(TransferStatus status, {String? senderName, BackupPreview? preview}) {
    _status = status;
    if (senderName != null) _senderName = senderName;
    if (preview != null) this.preview = preview;
    _statusController.add(status);
  }
}

/// Test double for [BackupSendClient] — lets a widget test control exactly
/// what [SendBackupScreen] observes after "sending" (status stream +
/// terminal result) without opening a real socket. Same rationale as
/// [FakeBackupReceiveServer].
class FakeBackupSendClient implements BackupSendClient {
  FakeBackupSendClient({required this.result, this.statusesBeforeResult = const []});

  /// Emitted on [statusStream], in order, before [send] resolves with
  /// [result].
  final List<TransferStatus> statusesBeforeResult;
  final BackupTransferResult result;

  final _statusController = StreamController<TransferStatus>.broadcast();
  PairingInfo? capturedTarget;
  String? capturedDeviceName;
  String? capturedPlatform;

  @override
  Stream<TransferStatus> get statusStream => _statusController.stream;

  @override
  Future<BackupTransferResult> send({
    required PairingInfo target,
    required Uint8List backupBytes,
    required String senderDeviceName,
    required String senderPlatform,
  }) async {
    capturedTarget = target;
    capturedDeviceName = senderDeviceName;
    capturedPlatform = senderPlatform;
    for (final status in statusesBeforeResult) {
      _statusController.add(status);
      await Future<void>.delayed(Duration.zero);
    }
    return result;
  }
}

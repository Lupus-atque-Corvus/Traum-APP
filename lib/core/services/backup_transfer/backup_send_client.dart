import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'backup_receive_server.dart' show BackupReceiveServer;
import 'backup_transfer_crypto.dart';
import 'backup_transfer_models.dart';

class BackupTransferException implements Exception {
  final String message;
  const BackupTransferException(this.message);

  @override
  String toString() => 'BackupTransferException: $message';
}

class BackupTransferResult {
  final TransferStatus status;
  final BackupPreview? preview;
  const BackupTransferResult(this.status, {this.preview});
}

/// Sends a backup to a [BackupReceiveServer] on another device. Drives the
/// full protocol: pair, poll for Confirmation #1, upload, poll for
/// Confirmation #2 — see [BackupReceiveServer]'s doc comment for the wire
/// protocol both sides agree on.
class BackupSendClient {
  final http.Client _client;
  final Duration _pollInterval;

  BackupSendClient({
    http.Client? client,
    Duration pollInterval = const Duration(milliseconds: 750),
  }) : _client = client ?? http.Client(),
       _pollInterval = pollInterval;

  final _statusController = StreamController<TransferStatus>.broadcast();
  Stream<TransferStatus> get statusStream => _statusController.stream;

  Future<BackupTransferResult> send({
    required PairingInfo target,
    required Uint8List backupBytes,
    required String senderDeviceName,
    required String senderPlatform,
  }) async {
    final base = 'http://${target.host}:${target.port}/traum-transfer/v1';

    final pairResponse = await _client.post(
      Uri.parse('$base/pair'),
      headers: {
        'Authorization': 'Bearer ${target.code.formatted}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'senderDeviceName': senderDeviceName,
        'senderPlatform': senderPlatform,
      }),
    );
    if (pairResponse.statusCode != 202) {
      throw BackupTransferException('Pairing failed (${pairResponse.statusCode})');
    }
    final sessionId =
        (jsonDecode(pairResponse.body) as Map<String, dynamic>)['sessionId'] as String;
    _statusController.add(TransferStatus.pendingConfirmation1);

    final afterConfirm1 = await _pollUntil(base, sessionId, const {
      TransferStatus.acceptedAwaitingUpload,
      TransferStatus.declined1,
    });
    if (afterConfirm1 == TransferStatus.declined1) {
      return const BackupTransferResult(TransferStatus.declined1);
    }

    _statusController.add(TransferStatus.uploading);
    final key = await deriveTransferKey(target.code, sessionId);
    final encrypted = await encryptPayload(backupBytes, key);
    final uploadResponse = await _client.post(
      Uri.parse('$base/upload/$sessionId'),
      headers: {
        'Authorization': 'Bearer $sessionId',
        'Content-Type': 'application/octet-stream',
      },
      body: encrypted,
    );
    if (uploadResponse.statusCode != 200) {
      throw BackupTransferException('Upload failed (${uploadResponse.statusCode})');
    }

    final finalStatus = await _pollUntil(base, sessionId, const {
      TransferStatus.done,
      TransferStatus.declined2,
      TransferStatus.error,
    });
    final preview = await _fetchPreview(base, sessionId);
    return BackupTransferResult(finalStatus, preview: preview);
  }

  Future<BackupPreview?> _fetchPreview(String base, String sessionId) async {
    final response = await _client.get(Uri.parse('$base/status/$sessionId'));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final summary = body['summary'];
    return summary != null
        ? BackupPreview.fromJson(summary as Map<String, dynamic>)
        : null;
  }

  Future<TransferStatus> _pollUntil(
    String base,
    String sessionId,
    Set<TransferStatus> terminal,
  ) async {
    while (true) {
      final response = await _client.get(Uri.parse('$base/status/$sessionId'));
      if (response.statusCode != 200) {
        throw BackupTransferException('Status check failed (${response.statusCode})');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = BackupReceiveServer.statusFromWireName(body['status'] as String);
      if (status != null) {
        _statusController.add(status);
        if (terminal.contains(status)) return status;
      }
      await Future.delayed(_pollInterval);
    }
  }
}

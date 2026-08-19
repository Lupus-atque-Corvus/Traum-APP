import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../backup_service.dart';
import 'backup_transfer_crypto.dart';
import 'backup_transfer_models.dart';

/// Runs a short-lived local HTTP server so another device on the same LAN
/// can send a backup here. Bound only while this object is alive — callers
/// must call [stop] (e.g. in a screen's `dispose()`); this never listens in
/// the background.
///
/// Protocol (base path `/traum-transfer/v1`), all bodies JSON unless noted:
///  - `POST /pair` — `Authorization: Bearer <pairing code>` + sender name.
///    Wrong/expired code -> 403. Already paired -> 409 (one transfer at a
///    time). On success, transitions to [TransferStatus.pendingConfirmation1]
///    and returns a `sessionId`.
///  - `GET /status/{sessionId}` — polled by the sender; mirrors [status] and
///    [preview] once known. This is how the sender sees progress while the
///    receiver works through both confirmations, without a push channel.
///  - `POST /upload/{sessionId}` — raw AES-GCM-encrypted backup bytes, only
///    accepted in [TransferStatus.acceptedAwaitingUpload]. On completion,
///    decrypts, computes a [BackupPreview], and transitions to
///    [TransferStatus.pendingConfirmation2].
///
/// [BackupService.restoreFromBytes] is only ever called from
/// [respondToConfirmation2] — i.e. only in direct response to this device's
/// own user tapping Accept. There is no remote-triggered import.
class BackupReceiveServer {
  final BackupService backupService;

  BackupReceiveServer(this.backupService);

  HttpServer? _server;
  PairingSession? _session;
  String? _sessionId;
  String? _senderDeviceName;
  Uint8List? _decryptedBytes;

  final _statusController = StreamController<TransferStatus>.broadcast();
  Stream<TransferStatus> get statusStream => _statusController.stream;

  TransferStatus? _status;
  TransferStatus? get status => _status;
  String? get pairedSenderName => _senderDeviceName;
  BackupPreview? preview;

  void _setStatus(TransferStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Starts listening and returns the info to encode in the QR/PIN shown to
  /// the user. `host` in the returned [PairingInfo] is always `127.0.0.1` —
  /// picking the real advertisable LAN IP is a UI-layer concern (multiple
  /// candidate interfaces are possible, see the calling screen), not part of
  /// the protocol itself; callers building the actual QR should override it.
  Future<PairingInfo> start() async {
    _session = PairingSession(
      PairingCode.generate(),
      validFor: const Duration(minutes: 2),
    );
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    server.listen(_handleRequest);
    return PairingInfo(host: '127.0.0.1', port: server.port, code: _session!.code);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    await _statusController.close();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    // Expect /traum-transfer/v1/<endpoint>[/<sessionId>]
    if (segments.length < 3 ||
        segments[0] != 'traum-transfer' ||
        segments[1] != 'v1') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final endpoint = segments[2];
    try {
      switch (endpoint) {
        case 'pair':
          await _handlePair(request);
        case 'status':
          await _handleStatus(request, segments.length > 3 ? segments[3] : null);
        case 'upload':
          await _handleUpload(request, segments.length > 3 ? segments[3] : null);
        default:
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  String? _bearerToken(HttpRequest request) {
    final header = request.headers.value(HttpHeaders.authorizationHeader);
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  Future<void> _handlePair(HttpRequest request) async {
    final session = _session;
    if (session == null || _sessionId != null) {
      // Already mid-transfer (or never started) — only one at a time.
      request.response.statusCode = HttpStatus.conflict;
      request.response.write(jsonEncode({'error': 'already_paired'}));
      await request.response.close();
      return;
    }
    final token = _bearerToken(request);
    final candidate = token != null ? PairingCode.tryParse(token) : null;
    if (session.isExpired) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write(jsonEncode({'error': 'expired'}));
      await request.response.close();
      return;
    }
    if (candidate == null || !session.accepts(candidate)) {
      session.registerFailedAttempt();
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write(jsonEncode({'error': 'invalid_secret'}));
      await request.response.close();
      return;
    }

    final body = jsonDecode(await utf8.decodeStream(request)) as Map<String, dynamic>;
    _senderDeviceName = body['senderDeviceName'] as String? ?? 'Unknown device';
    _sessionId = _randomSessionId();
    _setStatus(TransferStatus.pendingConfirmation1);

    request.response.statusCode = HttpStatus.accepted;
    request.response.write(jsonEncode({'sessionId': _sessionId, 'status': 'pending_confirmation_1'}));
    await request.response.close();
  }

  Future<void> _handleStatus(HttpRequest request, String? sessionId) async {
    if (sessionId == null || sessionId != _sessionId) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    request.response.statusCode = HttpStatus.ok;
    request.response.write(
      jsonEncode({
        'status': _statusWireName(_status),
        if (preview != null) 'summary': preview!.toJson(),
      }),
    );
    await request.response.close();
  }

  Future<void> _handleUpload(HttpRequest request, String? sessionId) async {
    if (sessionId == null || sessionId != _sessionId) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    if (_status != TransferStatus.acceptedAwaitingUpload) {
      request.response.statusCode = HttpStatus.conflict;
      await request.response.close();
      return;
    }
    _setStatus(TransferStatus.uploading);

    final builder = BytesBuilder(copy: false);
    await for (final chunk in request) {
      builder.add(chunk);
    }
    final encrypted = builder.takeBytes();

    final key = await deriveTransferKey(_session!.code, _sessionId!);
    Uint8List decrypted;
    try {
      decrypted = await decryptPayload(encrypted, key);
    } catch (_) {
      _setStatus(TransferStatus.error);
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    _decryptedBytes = decrypted;

    try {
      preview = await backupService.previewBackup(decrypted);
    } catch (e) {
      _setStatus(TransferStatus.error);
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
      return;
    }

    _setStatus(TransferStatus.pendingConfirmation2);
    request.response.statusCode = HttpStatus.ok;
    await request.response.close();
  }

  /// Called by the receiving device's UI when the user answers the "accept
  /// this incoming transfer?" dialog.
  void respondToConfirmation1(bool accept) {
    if (_status != TransferStatus.pendingConfirmation1) return;
    _setStatus(
      accept ? TransferStatus.acceptedAwaitingUpload : TransferStatus.declined1,
    );
  }

  /// Called by the receiving device's UI when the user answers the "really
  /// import this?" dialog shown after the preview is known. This is the
  /// only path that ever writes to the database.
  Future<void> respondToConfirmation2(bool accept) async {
    if (_status != TransferStatus.pendingConfirmation2) return;
    if (!accept) {
      _setStatus(TransferStatus.declined2);
      return;
    }
    _setStatus(TransferStatus.importing);
    final result = await backupService.restoreFromBytes(_decryptedBytes!);
    _setStatus(result.success ? TransferStatus.done : TransferStatus.error);
  }

  static String _statusWireName(TransferStatus? status) => switch (status) {
    null => 'idle',
    TransferStatus.pendingConfirmation1 => 'pending_confirmation_1',
    TransferStatus.declined1 => 'declined_1',
    TransferStatus.acceptedAwaitingUpload => 'accepted_1_awaiting_upload',
    TransferStatus.uploading => 'uploading',
    TransferStatus.pendingConfirmation2 => 'pending_confirmation_2',
    TransferStatus.declined2 => 'declined_2',
    TransferStatus.importing => 'importing',
    TransferStatus.done => 'done',
    TransferStatus.error => 'error',
  };

  static TransferStatus? statusFromWireName(String name) => switch (name) {
    'pending_confirmation_1' => TransferStatus.pendingConfirmation1,
    'declined_1' => TransferStatus.declined1,
    'accepted_1_awaiting_upload' => TransferStatus.acceptedAwaitingUpload,
    'uploading' => TransferStatus.uploading,
    'pending_confirmation_2' => TransferStatus.pendingConfirmation2,
    'declined_2' => TransferStatus.declined2,
    'importing' => TransferStatus.importing,
    'done' => TransferStatus.done,
    'error' => TransferStatus.error,
    _ => null,
  };

  static String _randomSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

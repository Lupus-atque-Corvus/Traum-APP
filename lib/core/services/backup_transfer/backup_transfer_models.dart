import 'dart:math';
import 'dart:typed_data';

import 'package:clock/clock.dart';

/// Crockford Base32 — excludes I, L, O, U to avoid confusion with 1/0 when a
/// human types a code by hand. https://www.crockford.com/base32.html
const _crockfordAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// Encodes [bytes] as Crockford Base32, 5 bits per output character. The
/// last character may only use some of its 5 bits (padded with zero bits) —
/// callers that need an exact byte count back out of [_decodeCrockford] must
/// pick a byte length whose bit count is a multiple of 5 (5 bytes = 40 bits
/// = 8 characters, used throughout this file) to avoid needing to reason
/// about partial trailing bits at all.
String _encodeCrockford(Uint8List bytes) {
  var bitBuffer = 0;
  var bitCount = 0;
  final out = StringBuffer();
  for (final byte in bytes) {
    bitBuffer = (bitBuffer << 8) | byte;
    bitCount += 8;
    while (bitCount >= 5) {
      bitCount -= 5;
      out.write(_crockfordAlphabet[(bitBuffer >> bitCount) & 0x1F]);
    }
  }
  if (bitCount > 0) {
    out.write(_crockfordAlphabet[(bitBuffer << (5 - bitCount)) & 0x1F]);
  }
  return out.toString();
}

/// Decodes a Crockford Base32 string back to raw bytes, or `null` if it
/// contains characters outside the alphabet. `expectedByteLength` guards
/// against accepting a string that decodes to the wrong number of bytes.
Uint8List? _decodeCrockford(String input, int expectedByteLength) {
  var bitBuffer = 0;
  var bitCount = 0;
  final out = <int>[];
  for (final char in input.split('')) {
    final value = _crockfordAlphabet.indexOf(char);
    if (value == -1) return null;
    bitBuffer = (bitBuffer << 5) | value;
    bitCount += 5;
    if (bitCount >= 8) {
      bitCount -= 8;
      out.add((bitBuffer >> bitCount) & 0xFF);
    }
  }
  if (out.length != expectedByteLength) return null;
  return Uint8List.fromList(out);
}

/// A short-lived pairing secret, exchanged via QR code or typed by hand.
/// 5 random bytes (40 bits) — plenty for a value that's rate-limited and
/// expires within minutes (see [PairingSession]), while encoding cleanly to
/// exactly 8 Crockford characters with no partial-byte edge cases.
class PairingCode {
  final Uint8List bytes;

  const PairingCode(this.bytes);

  factory PairingCode.generate() {
    final random = Random.secure();
    final bytes = Uint8List(5);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return PairingCode(bytes);
  }

  /// Human/QR-friendly form, e.g. "ABCD-EFGH".
  String get formatted {
    final raw = _encodeCrockford(bytes);
    return '${raw.substring(0, 4)}-${raw.substring(4, 8)}';
  }

  static PairingCode? tryParse(String input) {
    final cleaned = input.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (cleaned.length != 8) return null;
    final bytes = _decodeCrockford(cleaned, 5);
    if (bytes == null) return null;
    return PairingCode(bytes);
  }

  @override
  bool operator ==(Object other) {
    if (other is! PairingCode) return false;
    if (bytes.length != other.bytes.length) return false;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(bytes);

  @override
  String toString() => formatted;
}

/// Receiver-side pairing state: the code it generated, when it expires, and
/// how many wrong attempts have been made against it. Never leaves the
/// receiving device — the sender only ever sees/sends the [PairingCode]
/// itself.
class PairingSession {
  final PairingCode code;
  final DateTime expiresAt;
  static const maxFailedAttempts = 5;

  int _failedAttempts = 0;
  bool _lockedOut = false;

  PairingSession(this.code, {required Duration validFor})
    : expiresAt = clock.now().add(validFor);

  bool get isExpired => clock.now().isAfter(expiresAt);
  bool get isLockedOut => _lockedOut;

  /// Records a failed pairing attempt. Returns `true` if this attempt just
  /// caused the session to lock out (the caller should treat this attempt,
  /// and all future ones, as rejected).
  bool registerFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= maxFailedAttempts) {
      _lockedOut = true;
      return true;
    }
    return false;
  }

  /// Whether [candidate] is accepted right now — must match the generated
  /// code, and the session must be neither expired nor locked out.
  bool accepts(PairingCode candidate) {
    if (isExpired || _lockedOut) return false;
    return candidate == code;
  }
}

/// Everything a sending device needs to reach a receiving device: encoded
/// into the QR code the receiver shows, and parsed back out by the sender
/// after scanning (or typed in manually via separate host/port/code fields,
/// which construct this directly without going through [tryParse]).
class PairingInfo {
  static const _scheme = 'traum-transfer';

  final String host;
  final int port;
  final PairingCode code;

  const PairingInfo({required this.host, required this.port, required this.code});

  Uri toUri() => Uri(
    scheme: _scheme,
    host: host,
    port: port,
    queryParameters: {'c': code.formatted},
  );

  static PairingInfo? tryParse(String input) {
    final Uri uri;
    try {
      uri = Uri.parse(input);
    } on FormatException {
      return null;
    }
    if (uri.scheme != _scheme || uri.host.isEmpty || !uri.hasPort) return null;
    final codeStr = uri.queryParameters['c'];
    if (codeStr == null) return null;
    final code = PairingCode.tryParse(codeStr);
    if (code == null) return null;
    return PairingInfo(host: uri.host, port: uri.port, code: code);
  }
}

/// Every state a transfer can be in, mirrored between the receiver (source
/// of truth) and the sender (learns it by polling `GET /status/{sessionId}`).
enum TransferStatus {
  pendingConfirmation1,
  declined1,
  acceptedAwaitingUpload,
  uploading,
  pendingConfirmation2,
  declined2,
  importing,
  done,
  error,
}

/// Summary of a decoded-but-not-yet-applied backup, shown to the user for
/// Confirmation #2 before anything is written to the local database.
class BackupPreview {
  final DateTime? exportedAt;
  final int tableCount;
  final int rowCount;
  final int mediaCount;

  const BackupPreview({
    this.exportedAt,
    required this.tableCount,
    required this.rowCount,
    required this.mediaCount,
  });

  Map<String, dynamic> toJson() => {
    'exportedAt': exportedAt?.toIso8601String(),
    'tableCount': tableCount,
    'rowCount': rowCount,
    'mediaCount': mediaCount,
  };

  factory BackupPreview.fromJson(Map<String, dynamic> json) => BackupPreview(
    exportedAt: json['exportedAt'] != null
        ? DateTime.tryParse(json['exportedAt'] as String)
        : null,
    tableCount: json['tableCount'] as int,
    rowCount: json['rowCount'] as int,
    mediaCount: json['mediaCount'] as int,
  );
}

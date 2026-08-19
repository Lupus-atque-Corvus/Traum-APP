import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'backup_transfer_models.dart';

/// Derives a 256-bit AES key from a pairing secret and the session it
/// belongs to. Including [sessionId] in the HKDF `info` binds the key to one
/// specific pairing — two transfers can never accidentally reuse a key even
/// if (astronomically unlikely) they shared the same [PairingCode].
Future<Uint8List> deriveTransferKey(PairingCode secret, String sessionId) async {
  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final secretKey = await hkdf.deriveKey(
    secretKey: SecretKey(secret.bytes),
    nonce: utf8.encode('traum-transfer-v1'),
    info: utf8.encode(sessionId),
  );
  return Uint8List.fromList(await secretKey.extractBytes());
}

final _aesGcm = AesGcm.with256bits();

/// Encrypts [plaintext] with AES-256-GCM under [key]. Output layout is
/// `nonce(12) || ciphertext || tag(16)` — a self-contained blob that
/// [decryptPayload] can consume with no side-channel needed.
Future<Uint8List> encryptPayload(Uint8List plaintext, Uint8List key) async {
  final secretBox = await _aesGcm.encrypt(
    plaintext,
    secretKey: SecretKey(key),
  );
  return Uint8List.fromList(secretBox.concatenation());
}

/// Reverses [encryptPayload]. Throws if [key] is wrong or [encrypted] was
/// tampered with (the GCM authentication tag won't verify) or is too short
/// to even contain a nonce+tag.
Future<Uint8List> decryptPayload(Uint8List encrypted, Uint8List key) async {
  final secretBox = SecretBox.fromConcatenation(
    encrypted,
    nonceLength: _aesGcm.nonceLength,
    macLength: _aesGcm.macAlgorithm.macLength,
  );
  final plaintext = await _aesGcm.decrypt(secretBox, secretKey: SecretKey(key));
  return Uint8List.fromList(plaintext);
}

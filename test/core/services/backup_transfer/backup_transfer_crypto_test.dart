import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/services/backup_transfer/backup_transfer_crypto.dart';
import 'package:traum/core/services/backup_transfer/backup_transfer_models.dart';

void main() {
  group('deriveTransferKey', () {
    test('is deterministic for the same secret and sessionId', () async {
      final secret = PairingCode.generate();
      final keyA = await deriveTransferKey(secret, 'session-1');
      final keyB = await deriveTransferKey(secret, 'session-1');
      expect(keyA, equals(keyB));
    });

    test('differs for a different sessionId (same secret)', () async {
      final secret = PairingCode.generate();
      final keyA = await deriveTransferKey(secret, 'session-1');
      final keyB = await deriveTransferKey(secret, 'session-2');
      expect(keyA, isNot(equals(keyB)));
    });

    test('differs for a different secret (same sessionId)', () async {
      final keyA = await deriveTransferKey(PairingCode.generate(), 'session-1');
      final keyB = await deriveTransferKey(PairingCode.generate(), 'session-1');
      expect(keyA, isNot(equals(keyB)));
    });

    test('produces a 256-bit (32 byte) key', () async {
      final key = await deriveTransferKey(PairingCode.generate(), 'session-1');
      expect(key, hasLength(32));
    });
  });

  group('encryptPayload / decryptPayload', () {
    test('round-trips arbitrary bytes', () async {
      final key = await deriveTransferKey(PairingCode.generate(), 'session-1');
      final plaintext = Uint8List.fromList(utf8.encode('hello, backup!'));
      final encrypted = await encryptPayload(plaintext, key);
      final decrypted = await decryptPayload(encrypted, key);
      expect(decrypted, equals(plaintext));
    });

    test('round-trips a large binary payload', () async {
      final key = await deriveTransferKey(PairingCode.generate(), 'session-1');
      final plaintext = Uint8List.fromList(
        List.generate(500000, (i) => i % 256),
      );
      final encrypted = await encryptPayload(plaintext, key);
      final decrypted = await decryptPayload(encrypted, key);
      expect(decrypted, equals(plaintext));
    });

    test('ciphertext is not the same as the plaintext', () async {
      final key = await deriveTransferKey(PairingCode.generate(), 'session-1');
      final plaintext = Uint8List.fromList(utf8.encode('not encrypted yet'));
      final encrypted = await encryptPayload(plaintext, key);
      expect(encrypted, isNot(equals(plaintext)));
    });

    test('encrypting the same plaintext twice yields different ciphertext (random nonce)', () async {
      final key = await deriveTransferKey(PairingCode.generate(), 'session-1');
      final plaintext = Uint8List.fromList(utf8.encode('same input'));
      final a = await encryptPayload(plaintext, key);
      final b = await encryptPayload(plaintext, key);
      expect(a, isNot(equals(b)));
    });

    test('decrypting with the wrong key throws', () async {
      final keyA = await deriveTransferKey(PairingCode.generate(), 'session-1');
      final keyB = await deriveTransferKey(PairingCode.generate(), 'session-1');
      final plaintext = Uint8List.fromList(utf8.encode('secret data'));
      final encrypted = await encryptPayload(plaintext, keyA);
      expect(() => decryptPayload(encrypted, keyB), throwsA(anything));
    });

    test('decrypting tampered ciphertext throws (GCM tag check fails)', () async {
      final key = await deriveTransferKey(PairingCode.generate(), 'session-1');
      final plaintext = Uint8List.fromList(utf8.encode('untampered'));
      final encrypted = await encryptPayload(plaintext, key);
      final tampered = Uint8List.fromList(encrypted);
      // Flip a bit well past the nonce (first 12 bytes), inside the ciphertext.
      tampered[tampered.length - 1] ^= 0xFF;
      expect(() => decryptPayload(tampered, key), throwsA(anything));
    });

    test('decrypting too-short input throws instead of crashing oddly', () async {
      final key = await deriveTransferKey(PairingCode.generate(), 'session-1');
      expect(
        () => decryptPayload(Uint8List.fromList([1, 2, 3]), key),
        throwsA(anything),
      );
    });
  });
}

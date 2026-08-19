import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/services/backup_transfer/backup_transfer_models.dart';

void main() {
  group('PairingCode', () {
    test('generate() produces 5 random bytes', () {
      final code = PairingCode.generate();
      expect(code.bytes, hasLength(5));
    });

    test('generate() produces different bytes each time', () {
      final a = PairingCode.generate();
      final b = PairingCode.generate();
      expect(a.bytes, isNot(equals(b.bytes)));
    });

    test('formatted renders as XXXX-XXXX (uppercase, dash at index 4)', () {
      final code = PairingCode.generate();
      final formatted = code.formatted;
      expect(formatted, hasLength(9));
      expect(formatted[4], '-');
      expect(formatted, equals(formatted.toUpperCase()));
    });

    test('Crockford encoding matches a known vector', () {
      // 5 bytes of all zero -> 8 Crockford '0' characters.
      final code = PairingCode(Uint8List.fromList([0, 0, 0, 0, 0]));
      expect(code.formatted, '0000-0000');
    });

    test('Crockford encoding matches a second known vector', () {
      // 0xFF x5 = all bits set -> every 5-bit group is 11111 = 31 = 'Z'.
      final code = PairingCode(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF]));
      expect(code.formatted, 'ZZZZ-ZZZZ');
    });

    test('tryParse round-trips generate()', () {
      final original = PairingCode.generate();
      final parsed = PairingCode.tryParse(original.formatted);
      expect(parsed, isNotNull);
      expect(parsed!.bytes, equals(original.bytes));
    });

    test('tryParse accepts lowercase input', () {
      final original = PairingCode.generate();
      final parsed = PairingCode.tryParse(original.formatted.toLowerCase());
      expect(parsed!.bytes, equals(original.bytes));
    });

    test('tryParse accepts input without the dash', () {
      final original = PairingCode.generate();
      final noDash = original.formatted.replaceAll('-', '');
      final parsed = PairingCode.tryParse(noDash);
      expect(parsed!.bytes, equals(original.bytes));
    });

    test('tryParse rejects wrong length', () {
      expect(PairingCode.tryParse('ABCD-ABC'), isNull);
      expect(PairingCode.tryParse('ABCD-ABCDE'), isNull);
    });

    test('tryParse rejects characters outside the Crockford alphabet', () {
      // I, L, O, U are deliberately excluded from Crockford Base32.
      expect(PairingCode.tryParse('IIII-IIII'), isNull);
      expect(PairingCode.tryParse('OOOO-OOOO'), isNull);
    });

    test('== compares by byte content, not identity', () {
      final a = PairingCode(Uint8List.fromList([1, 2, 3, 4, 5]));
      final b = PairingCode(Uint8List.fromList([1, 2, 3, 4, 5]));
      final c = PairingCode(Uint8List.fromList([1, 2, 3, 4, 6]));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('PairingSession', () {
    test('is not expired immediately after creation', () {
      final session = PairingSession(
        PairingCode.generate(),
        validFor: const Duration(minutes: 2),
      );
      expect(session.isExpired, isFalse);
    });

    test('expires after the configured duration', () {
      fakeAsync((async) {
        final session = PairingSession(
          PairingCode.generate(),
          validFor: const Duration(minutes: 2),
        );
        async.elapse(const Duration(minutes: 1, seconds: 59));
        expect(session.isExpired, isFalse);
        async.elapse(const Duration(seconds: 2));
        expect(session.isExpired, isTrue);
      });
    });

    test('registerFailedAttempt() locks out after 5 failures', () {
      final session = PairingSession(
        PairingCode.generate(),
        validFor: const Duration(minutes: 2),
      );
      for (var i = 0; i < 4; i++) {
        expect(session.registerFailedAttempt(), isFalse);
      }
      expect(session.registerFailedAttempt(), isTrue);
      expect(session.isLockedOut, isTrue);
    });

    test('a successful match is not possible once locked out', () {
      final code = PairingCode.generate();
      final session = PairingSession(code, validFor: const Duration(minutes: 2));
      for (var i = 0; i < 5; i++) {
        session.registerFailedAttempt();
      }
      expect(session.isLockedOut, isTrue);
      expect(session.accepts(code), isFalse);
    });

    test('accepts() matches the right code and rejects a wrong one', () {
      final code = PairingCode.generate();
      final session = PairingSession(code, validFor: const Duration(minutes: 2));
      expect(session.accepts(PairingCode.generate()), isFalse);
      expect(session.accepts(code), isTrue);
    });
  });

  group('PairingInfo', () {
    test('toUri() / tryParse() round-trip', () {
      final info = PairingInfo(
        host: '192.168.1.23',
        port: 41234,
        code: PairingCode.generate(),
      );
      final uriString = info.toUri().toString();
      final parsed = PairingInfo.tryParse(uriString);
      expect(parsed, isNotNull);
      expect(parsed!.host, info.host);
      expect(parsed.port, info.port);
      expect(parsed.code, info.code);
    });

    test('tryParse rejects a URI with the wrong scheme', () {
      expect(PairingInfo.tryParse('https://192.168.1.23:41234?c=ABCD-EFGH'), isNull);
    });

    test('tryParse rejects garbage input', () {
      expect(PairingInfo.tryParse('not a uri at all'), isNull);
      expect(PairingInfo.tryParse(''), isNull);
    });
  });
}

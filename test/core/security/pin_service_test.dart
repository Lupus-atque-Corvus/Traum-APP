import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/security/pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, String> store;

  setUp(() {
    store = {};
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          return store[call.arguments['key'] as String];
        case 'write':
          store[call.arguments['key'] as String] =
              call.arguments['value'] as String;
          return null;
        case 'delete':
          store.remove(call.arguments['key'] as String);
          return null;
        case 'deleteAll':
          store.clear();
          return null;
        case 'containsKey':
          return store.containsKey(call.arguments['key'] as String);
        case 'readAll':
          return store;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('isSet is false before a PIN is saved, true after', () async {
    expect(await PinService.isSet(), isFalse);
    await PinService.save('1234');
    expect(await PinService.isSet(), isTrue);
  });

  test('verify returns true for the correct PIN and false otherwise', () async {
    await PinService.save('1234');
    expect(await PinService.verify('1234'), isTrue);
    expect(await PinService.verify('0000'), isFalse);
  });

  test('first 3 wrong attempts do not trigger a lockout', () async {
    await PinService.save('1234');
    for (var i = 0; i < 3; i++) {
      expect(await PinService.verify('0000'), isFalse);
    }
    expect(await PinService.getLockedUntil(), isNull);
  });

  test('4th consecutive wrong attempt locks the PIN entry for ~30s', () async {
    await PinService.save('1234');
    for (var i = 0; i < 4; i++) {
      await PinService.verify('0000');
    }
    final until = await PinService.getLockedUntil();
    expect(until, isNotNull);
    final remaining = until!.difference(DateTime.now()).inSeconds;
    expect(remaining, inInclusiveRange(28, 30));
  });

  test('further verify() calls while already locked do not consume a new '
      'attempt or change the lockout duration', () async {
    await PinService.save('1234');
    for (var i = 0; i < 4; i++) {
      await PinService.verify('0000');
    }
    final firstUntil = await PinService.getLockedUntil();
    expect(firstUntil, isNotNull);

    // Hammering the entry while locked must not push the unlock time out
    // further — the failure counter is only allowed to advance once the
    // lockout has actually expired.
    for (var i = 0; i < 5; i++) {
      expect(await PinService.verify('0000'), isFalse);
    }
    final secondUntil = await PinService.getLockedUntil();
    expect(secondUntil, firstUntil);
  });

  test('correct PIN is rejected while locked out, without consuming it as '
      'a fresh attempt', () async {
    await PinService.save('1234');
    for (var i = 0; i < 4; i++) {
      await PinService.verify('0000');
    }
    expect(await PinService.getLockedUntil(), isNotNull);
    // Even the correct PIN must not unlock early.
    expect(await PinService.verify('1234'), isFalse);
  });

  test(
    'a successful verify resets the failure count and lockout state',
    () async {
      await PinService.save('1234');
      await PinService.verify('0000');
      await PinService.verify('0000');
      await PinService.verify('1234'); // correct -> resets counter
      // Three more wrong attempts should not lock again (counter restarted).
      for (var i = 0; i < 3; i++) {
        expect(await PinService.verify('0000'), isFalse);
      }
      expect(await PinService.getLockedUntil(), isNull);
    },
  );

  test('save() resets any prior lockout state (e.g. PIN changed in '
      'Settings)', () async {
    await PinService.save('1234');
    for (var i = 0; i < 4; i++) {
      await PinService.verify('0000');
    }
    expect(await PinService.getLockedUntil(), isNotNull);
    await PinService.save('5678');
    expect(await PinService.getLockedUntil(), isNull);
  });

  test('clear() removes the PIN and resets lockout state', () async {
    await PinService.save('1234');
    for (var i = 0; i < 4; i++) {
      await PinService.verify('0000');
    }
    await PinService.clear();
    expect(await PinService.isSet(), isFalse);
    expect(await PinService.getLockedUntil(), isNull);
  });
}

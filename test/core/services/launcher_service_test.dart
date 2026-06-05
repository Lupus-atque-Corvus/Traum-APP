import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/services/launcher_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('traum/launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = LauncherService();

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('isDefaultLauncher returns native true', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'isDefaultLauncher');
      return true;
    });
    expect(await service.isDefaultLauncher(), isTrue);
  });

  test('isDefaultLauncher returns false on platform error', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'LAUNCHER_ERROR');
    });
    expect(await service.isDefaultLauncher(), isFalse);
  });

  test('requestSetDefault invokes native method', () async {
    String? called;
    messenger.setMockMethodCallHandler(channel, (call) async {
      called = call.method;
      return null;
    });
    await service.requestSetDefault();
    expect(called, 'requestSetDefaultLauncher');
  });
}

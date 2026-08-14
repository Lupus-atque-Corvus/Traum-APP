import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/security/pin_service.dart';
import 'package:traum/features/lock/pin_lock_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap() => MaterialApp(
  locale: const Locale('de'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const PinLockScreen(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, String> store;

  setUp(() {
    // The default test surface (800x600 logical px) is far shorter than any
    // real phone in portrait — this screen's centered Column overflows at
    // that height even though it fits comfortably on a real device.
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1080,
      2340,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);

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

  Future<void> tapDigits(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).first);
      await tester.pump();
    }
  }

  testWidgets('entering the wrong PIN shows an error and clears the input', (
    tester,
  ) async {
    await PinService.save('1234');

    await tester.pumpWidget(_wrap());
    await tester.pump();

    await tapDigits(tester, '0000');
    await tester.pump(); // start async verify
    await tester.pump(const Duration(milliseconds: 500)); // shake animation

    expect(find.text('Falscher PIN'), findsOneWidget);
  });
}

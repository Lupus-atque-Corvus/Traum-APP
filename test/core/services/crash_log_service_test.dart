import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:traum/core/services/crash_log_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.dir);
  final Directory dir;

  @override
  Future<String?> getApplicationSupportPath() async => dir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('crash_log_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
    CrashLogService.debugResetForTest();
  });
  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('readForExport returns null when no log has been written', () async {
    expect(await CrashLogService.readForExport(), isNull);
  });

  test(
    'a logged error is readable for export with source tag and message',
    () async {
      await CrashLogService.logForTest('ZONE', 'boom', StackTrace.current);

      final bytes = await CrashLogService.readForExport();
      expect(bytes, isNotNull);
      final text = utf8.decode(bytes!);
      expect(text, contains('[ZONE]'));
      expect(text, contains('boom'));
    },
  );

  test('multiple entries append rather than overwrite', () async {
    await CrashLogService.logForTest('FLUTTER', 'first error');
    await CrashLogService.logForTest('PLATFORM', 'second error');

    final text = utf8.decode((await CrashLogService.readForExport())!);
    expect(text, contains('first error'));
    expect(text, contains('second error'));
  });

  test(
    'log rotates instead of growing unboundedly past the size cap',
    () async {
      // Write comfortably past the 1 MB cap so rotation is guaranteed to
      // trigger, without depending on the exact internal threshold.
      final big = 'x' * (600 * 1024);
      await CrashLogService.logForTest('ZONE', big);
      await CrashLogService.logForTest('ZONE', big);
      await CrashLogService.logForTest('ZONE', 'after rotation marker');

      final text = utf8.decode((await CrashLogService.readForExport())!);
      expect(text, contains('after rotation marker'));
      expect(text.length, lessThan(1024 * 1024));
    },
  );
}

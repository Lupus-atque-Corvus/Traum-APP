import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/data/repositories/substance_reference_db_copier.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory dir;
  _FakePathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('substance_copier_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('copies the bundled fixture asset to app storage and sets the flag', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await SubstanceReferenceDbCopier.copyIfNeeded(prefs);

    final target = File(await SubstanceReferenceDbCopier.targetPath());
    expect(target.existsSync(), isTrue);
    expect(target.lengthSync(), greaterThan(0));
    expect(prefs.getBool('substance_reference_db_copied_v2'), isTrue);
  });

  test('is idempotent — second call does not re-copy', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await SubstanceReferenceDbCopier.copyIfNeeded(prefs);
    final target = File(await SubstanceReferenceDbCopier.targetPath());
    final firstModified = target.statSync().modified;

    await Future.delayed(const Duration(milliseconds: 5));
    await SubstanceReferenceDbCopier.copyIfNeeded(prefs);

    expect(target.statSync().modified, firstModified);
  });

  test('leaves the flag unset if copying fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Point the fake documents dir at a path that doesn't exist and can't be
    // created, forcing the write to fail.
    final badDir = Directory('${tempDir.path}/does/not/exist/at/all');
    PathProviderPlatform.instance = _FakePathProvider(badDir);

    await SubstanceReferenceDbCopier.copyIfNeeded(prefs);

    expect(prefs.getBool('substance_reference_db_copied_v2'), isNull);
  });
}

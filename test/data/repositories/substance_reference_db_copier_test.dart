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

  test(
    'copies the bundled fixture asset to app storage and sets the flag',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await SubstanceReferenceDbCopier.copyIfNeeded(prefs);

      final target = File(await SubstanceReferenceDbCopier.targetPath());
      expect(target.existsSync(), isTrue);
      expect(target.lengthSync(), greaterThan(0));
      expect(prefs.getBool('substance_reference_db_copied_v2'), isTrue);
    },
  );

  // NOTE: this test is currently VACUOUS. The real asset
  // (assets/substances_reference.sqlite3) is not bundled yet — both
  // copyIfNeeded() calls below fail identically on rootBundle.load(), the
  // flag never gets set, and File.statSync() on a never-created file
  // returns a stable "notFound" FileStat (epoch timestamp) rather than
  // throwing — so this assertion trivially passes regardless of whether the
  // early-return-if-already-copied branch works. This test provides ZERO
  // real coverage until the asset is bundled (a later task) and this suite
  // is re-run — at that point, verify this test actually exercises the
  // early-return path (e.g. assert the file's real modified-time is
  // unchanged after a successful first copy, or that the flag stays `true`
  // across both calls with an explicit check after the FIRST call already
  // succeeded — not just "still notFound").
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
    // Create a FILE at the path where the copier needs a directory, so that
    // `target.parent.create(recursive: true)` genuinely fails with a real
    // filesystem error ("not a directory" / "already exists as a file").
    // This forces a real write failure regardless of whether
    // rootBundle.load('assets/substances_reference.sqlite3') succeeds or
    // fails first — unlike a merely-nonexistent-but-creatable nested path,
    // which `create(recursive: true)` would happily create.
    final blockingFilePath = '${tempDir.path}/blocked_dir';
    File(blockingFilePath).writeAsStringSync('not a directory');
    // 'blocked_dir' exists as a FILE, so creating 'blocked_dir/nested' fails.
    final badDir = Directory('$blockingFilePath/nested');
    PathProviderPlatform.instance = _FakePathProvider(badDir);

    await SubstanceReferenceDbCopier.copyIfNeeded(prefs);

    expect(prefs.getBool('substance_reference_db_copied_v2'), isNull);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/core/providers/preferences_provider.dart';
import 'package:traum/data/preferences/preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  group('PreferencesRepository app launcher', () {
    test('defaults: disabled and empty favorites', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PreferencesRepository(prefs);
      expect(repo.appLauncherEnabled, isFalse);
      expect(repo.appLauncherFavorites, '[]');
    });

    test('persists enabled flag and favorites json', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PreferencesRepository(prefs);
      await repo.setAppLauncherEnabled(true);
      await repo.setAppLauncherFavorites('["com.a","com.b"]');
      expect(repo.appLauncherEnabled, isTrue);
      expect(repo.appLauncherFavorites, '["com.a","com.b"]');
    });
  });

  group('appLauncherEnabledProvider', () {
    test('toggles and persists', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      expect(container.read(appLauncherEnabledProvider), isFalse);
      await container.read(appLauncherEnabledProvider.notifier).set(true);
      expect(container.read(appLauncherEnabledProvider), isTrue);
    });
  });

  group('appLauncherFavoritesProvider', () {
    test('add avoids duplicates and preserves order', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appLauncherFavoritesProvider.notifier);

      await notifier.add('com.whatsapp');
      await notifier.add('com.instagram');
      await notifier.add('com.whatsapp'); // duplicate ignored

      expect(container.read(appLauncherFavoritesProvider),
          ['com.whatsapp', 'com.instagram']);
    });

    test('remove drops the package', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appLauncherFavoritesProvider.notifier);
      await notifier.add('com.a');
      await notifier.add('com.b');
      await notifier.remove('com.a');
      expect(container.read(appLauncherFavoritesProvider), ['com.b']);
    });

    test('toggle adds then removes', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appLauncherFavoritesProvider.notifier);
      await notifier.toggle('com.x');
      expect(container.read(appLauncherFavoritesProvider), ['com.x']);
      await notifier.toggle('com.x');
      expect(container.read(appLauncherFavoritesProvider), isEmpty);
    });

    test('reorder moves item', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appLauncherFavoritesProvider.notifier);
      await notifier.add('com.a');
      await notifier.add('com.b');
      await notifier.add('com.c');
      await notifier.reorder(0, 3); // move 'a' to end
      expect(container.read(appLauncherFavoritesProvider),
          ['com.b', 'com.c', 'com.a']);
    });
  });
}

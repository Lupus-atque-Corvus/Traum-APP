import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/core/providers/preferences_provider.dart';

// Regression test for a Phase 7 finding: settings_screen.dart used to read
// these reminder times via `ref.read(preferencesRepositoryProvider)` inside
// build(), so a saved time change never triggered a rebuild. These notifiers
// mirror the on/off toggle notifiers so `ref.watch(...)` picks up changes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  test('notifWorkoutTimeProvider defaults, persists, and notifies listeners',
      () async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    expect(container.read(notifWorkoutTimeProvider), '18:00');

    var notifyCount = 0;
    container.listen(notifWorkoutTimeProvider, (_, _) => notifyCount++);

    await container.read(notifWorkoutTimeProvider.notifier).set('07:30');
    expect(container.read(notifWorkoutTimeProvider), '07:30');
    expect(notifyCount, 1);

    // Persisted through the repository, not just in-memory notifier state.
    final repo = container.read(preferencesRepositoryProvider);
    expect(repo.notifWorkoutTime, '07:30');
  });

  test('notifHabitTimeProvider and notifTodoTimeProvider are independent',
      () async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    await container.read(notifHabitTimeProvider.notifier).set('21:00');
    await container.read(notifTodoTimeProvider.notifier).set('06:15');

    expect(container.read(notifHabitTimeProvider), '21:00');
    expect(container.read(notifTodoTimeProvider), '06:15');
  });
}

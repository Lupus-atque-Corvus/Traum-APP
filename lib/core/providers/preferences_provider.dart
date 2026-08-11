import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/preferences/preferences_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(ref.watch(sharedPreferencesProvider));
});

// Locale
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final repo = ref.watch(preferencesRepositoryProvider);
    final code = repo.appLocale;
    return code != null ? Locale(code) : null;
  }

  Future<void> setLocale(Locale? locale) async {
    final repo = ref.read(preferencesRepositoryProvider);
    await repo.setAppLocale(locale?.languageCode);
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

// NavSlots
class NavSlotsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final repo = ref.watch(preferencesRepositoryProvider);
    try {
      final list = jsonDecode(repo.navSlots) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return ['training', 'health', 'nutrition', 'budget'];
    }
  }

  Future<void> setSlots(List<String> slots) async {
    final repo = ref.read(preferencesRepositoryProvider);
    await repo.setNavSlots(jsonEncode(slots));
    state = slots;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = List<String>.from(state);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await setSlots(list);
  }

  Future<void> add(String module) async {
    if (state.length >= 4 || state.contains(module)) return;
    await setSlots([...state, module]);
  }

  Future<void> remove(String module) async {
    if (state.length <= 1) return;
    await setSlots(state.where((m) => m != module).toList());
  }
}

final navSlotsProvider = NotifierProvider<NavSlotsNotifier, List<String>>(
  NavSlotsNotifier.new,
);

// Unit system
class UnitSystemNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(preferencesRepositoryProvider).unitSystem;
  }

  Future<void> set(String value) async {
    await ref.read(preferencesRepositoryProvider).setUnitSystem(value);
    state = value;
  }
}

final unitSystemProvider = NotifierProvider<UnitSystemNotifier, String>(
  UnitSystemNotifier.new,
);

// Biometric
class BiometricLockNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(preferencesRepositoryProvider).biometricLock;
  }

  Future<void> set(bool value) async {
    await ref.read(preferencesRepositoryProvider).setBiometricLock(value);
    state = value;
  }
}

final biometricLockProvider = NotifierProvider<BiometricLockNotifier, bool>(
  BiometricLockNotifier.new,
);

// PIN lock
class PinLockNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(preferencesRepositoryProvider).pinLock;
  }

  Future<void> set(bool value) async {
    await ref.read(preferencesRepositoryProvider).setPinLock(value);
    state = value;
  }
}

final pinLockProvider = NotifierProvider<PinLockNotifier, bool>(
  PinLockNotifier.new,
);

// Period tracking
class PeriodTrackingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(preferencesRepositoryProvider).periodTrackingEnabled;
  }

  Future<void> set(bool value) async {
    await ref.read(preferencesRepositoryProvider).setPeriodTrackingEnabled(value);
    state = value;
  }
}

final isPeriodTrackingEnabledProvider =
    NotifierProvider<PeriodTrackingNotifier, bool>(PeriodTrackingNotifier.new);

// App-Launcher (experimentell)
class AppLauncherEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesRepositoryProvider).appLauncherEnabled;

  Future<void> set(bool value) async {
    await ref.read(preferencesRepositoryProvider).setAppLauncherEnabled(value);
    state = value;
  }
}

final appLauncherEnabledProvider =
    NotifierProvider<AppLauncherEnabledNotifier, bool>(
        AppLauncherEnabledNotifier.new);

class AppLauncherFavoritesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final repo = ref.watch(preferencesRepositoryProvider);
    try {
      final list = jsonDecode(repo.appLauncherFavorites) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> _save(List<String> list) async {
    await ref
        .read(preferencesRepositoryProvider)
        .setAppLauncherFavorites(jsonEncode(list));
    state = list;
  }

  Future<void> add(String packageName) async {
    if (state.contains(packageName)) return;
    await _save([...state, packageName]);
  }

  Future<void> remove(String packageName) async {
    await _save(state.where((p) => p != packageName).toList());
  }

  Future<void> toggle(String packageName) async {
    if (state.contains(packageName)) {
      await remove(packageName);
    } else {
      await add(packageName);
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = List<String>.from(state);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await _save(list);
  }
}

final appLauncherFavoritesProvider =
    NotifierProvider<AppLauncherFavoritesNotifier, List<String>>(
        AppLauncherFavoritesNotifier.new);

// Simple derived providers
final userNameProvider = Provider<String>((ref) {
  return ref.watch(preferencesRepositoryProvider).userName;
});

final userBiologicalSexProvider = Provider<String>((ref) {
  return ref.watch(preferencesRepositoryProvider).userBiologicalSex;
});

final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(preferencesRepositoryProvider).onboardingComplete;
});

final substancesDisclaimerAcceptedProvider = Provider<bool>((ref) {
  return ref.watch(preferencesRepositoryProvider).substancesDisclaimerAccepted;
});

final stepsGoalProvider = Provider<int>((ref) {
  return ref.watch(preferencesRepositoryProvider).stepsGoal;
});

final kcalGoalProvider = Provider<int>((ref) {
  return ref.watch(preferencesRepositoryProvider).kcalGoal;
});

final waterGoalMlProvider = Provider<int>((ref) {
  return ref.watch(preferencesRepositoryProvider).waterGoalMl;
});

final waterMinMlProvider = Provider<int>((ref) {
  return ref.watch(preferencesRepositoryProvider).waterMinMl;
});

final waterMaxMlProvider = Provider<int>((ref) {
  return ref.watch(preferencesRepositoryProvider).waterMaxMl;
});

final proteinGoalGProvider = Provider<int>((ref) {
  return ref.watch(preferencesRepositoryProvider).proteinGoalG;
});

class CurrencySymbolNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(preferencesRepositoryProvider).currencySymbol;
  Future<void> set(String v) async {
    await ref.read(preferencesRepositoryProvider).setCurrencySymbol(v);
    state = v;
  }
}

final currencySymbolProvider =
    NotifierProvider<CurrencySymbolNotifier, String>(CurrencySymbolNotifier.new);

class UsdaApiKeyNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(preferencesRepositoryProvider).usdaApiKey;
  Future<void> set(String v) async {
    final trimmed = v.trim();
    await ref.read(preferencesRepositoryProvider).setUsdaApiKey(trimmed);
    // Getter maps '' → 'DEMO_KEY' (see PreferencesRepository.usdaApiKey).
    state = ref.read(preferencesRepositoryProvider).usdaApiKey;
  }
}

final usdaApiKeyProvider =
    NotifierProvider<UsdaApiKeyNotifier, String>(UsdaApiKeyNotifier.new);

class KcalGoalNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(preferencesRepositoryProvider).kcalGoal;
  Future<void> set(int v) async {
    await ref.read(preferencesRepositoryProvider).setKcalGoal(v);
    state = v;
  }
}

final kcalGoalNotifierProvider =
    NotifierProvider<KcalGoalNotifier, int>(KcalGoalNotifier.new);

/// Zuletzt gewähltes Tagebuch — bleibt über App-Neustarts erhalten (anders
/// als der In-Memory-`activeCollectionProvider` der Graffiti-Map).
class ActiveDiaryNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(preferencesRepositoryProvider).activeDiaryId;
  Future<void> set(int v) async {
    await ref.read(preferencesRepositoryProvider).setActiveDiaryId(v);
    state = v;
  }
}

final activeDiaryProvider =
    NotifierProvider<ActiveDiaryNotifier, int>(ActiveDiaryNotifier.new);

class ProteinGoalNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(preferencesRepositoryProvider).proteinGoalG;
  Future<void> set(int v) async {
    await ref.read(preferencesRepositoryProvider).setProteinGoalG(v);
    state = v;
  }
}

final proteinGoalNotifierProvider =
    NotifierProvider<ProteinGoalNotifier, int>(ProteinGoalNotifier.new);

class StepsGoalNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(preferencesRepositoryProvider).stepsGoal;
  Future<void> set(int v) async {
    await ref.read(preferencesRepositoryProvider).setStepsGoal(v);
    state = v;
  }
}

final stepsGoalNotifierProvider =
    NotifierProvider<StepsGoalNotifier, int>(StepsGoalNotifier.new);

class HeightCmNotifier extends Notifier<double> {
  @override
  double build() => ref.watch(preferencesRepositoryProvider).heightCm;
  Future<void> set(double v) async {
    await ref.read(preferencesRepositoryProvider).setHeightCm(v);
    state = v;
  }
}

final heightCmNotifierProvider =
    NotifierProvider<HeightCmNotifier, double>(HeightCmNotifier.new);

class WeightGoalNotifier extends Notifier<double> {
  @override
  double build() => ref.watch(preferencesRepositoryProvider).weightGoalKg;
  Future<void> set(double v) async {
    await ref.read(preferencesRepositoryProvider).setWeightGoalKg(v);
    state = v;
  }
}

final weightGoalNotifierProvider =
    NotifierProvider<WeightGoalNotifier, double>(WeightGoalNotifier.new);

// Notification providers
//
// There are deliberately no generic "Medikamente"/"Supplements" toggles
// here: unlike Workout/Habit/Todo/Water/Period (one shared daily/periodic
// reminder each), medications and supplements are reminded individually —
// every medication/supplement carries its own configured intake times from
// when it was added (see `my_substances_tab.dart` /
// `NotificationService.medicationReminderId`/`supplementReminderId`). A
// blanket on/off-plus-single-time toggle here would be redundant with — and
// confusingly disconnected from — those per-item times.
class NotifWorkoutNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesRepositoryProvider).notifWorkout;
  Future<void> set(bool v) async {
    await ref.read(preferencesRepositoryProvider).setNotifWorkout(v);
    state = v;
  }
}

final notifWorkoutProvider =
    NotifierProvider<NotifWorkoutNotifier, bool>(NotifWorkoutNotifier.new);

class NotifWaterNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesRepositoryProvider).notifWater;
  Future<void> set(bool v) async {
    await ref.read(preferencesRepositoryProvider).setNotifWater(v);
    state = v;
  }
}

final notifWaterProvider =
    NotifierProvider<NotifWaterNotifier, bool>(NotifWaterNotifier.new);

class NotifHabitNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesRepositoryProvider).notifHabit;
  Future<void> set(bool v) async {
    await ref.read(preferencesRepositoryProvider).setNotifHabit(v);
    state = v;
  }
}

final notifHabitProvider =
    NotifierProvider<NotifHabitNotifier, bool>(NotifHabitNotifier.new);

class NotifTodoNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesRepositoryProvider).notifTodo;
  Future<void> set(bool v) async {
    await ref.read(preferencesRepositoryProvider).setNotifTodo(v);
    state = v;
  }
}

final notifTodoProvider =
    NotifierProvider<NotifTodoNotifier, bool>(NotifTodoNotifier.new);

// Notification times ("HH:mm" strings) — same watch/set-through-Notifier
// pattern as the on/off toggles above. Without this, a screen reading
// `preferencesRepositoryProvider.notifWorkoutTime` directly via `ref.read()`
// in `build()` never rebuilds when the time is changed, since the plain
// `Provider<PreferencesRepository>` itself never notifies.
class NotifWorkoutTimeNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(preferencesRepositoryProvider).notifWorkoutTime;
  Future<void> set(String v) async {
    await ref.read(preferencesRepositoryProvider).setNotifWorkoutTime(v);
    state = v;
  }
}

final notifWorkoutTimeProvider =
    NotifierProvider<NotifWorkoutTimeNotifier, String>(
        NotifWorkoutTimeNotifier.new);

class NotifHabitTimeNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(preferencesRepositoryProvider).notifHabitTime;
  Future<void> set(String v) async {
    await ref.read(preferencesRepositoryProvider).setNotifHabitTime(v);
    state = v;
  }
}

final notifHabitTimeProvider = NotifierProvider<NotifHabitTimeNotifier, String>(
    NotifHabitTimeNotifier.new);

class NotifTodoTimeNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(preferencesRepositoryProvider).notifTodoTime;
  Future<void> set(String v) async {
    await ref.read(preferencesRepositoryProvider).setNotifTodoTime(v);
    state = v;
  }
}

final notifTodoTimeProvider = NotifierProvider<NotifTodoTimeNotifier, String>(
    NotifTodoTimeNotifier.new);

class NotifPeriodNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesRepositoryProvider).notifPeriod;
  Future<void> set(bool v) async {
    await ref.read(preferencesRepositoryProvider).setNotifPeriod(v);
    state = v;
  }
}

final notifPeriodProvider =
    NotifierProvider<NotifPeriodNotifier, bool>(NotifPeriodNotifier.new);

class NotifBudgetNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesRepositoryProvider).notifBudget;
  Future<void> set(bool v) async {
    await ref.read(preferencesRepositoryProvider).setNotifBudget(v);
    state = v;
  }
}

final notifBudgetProvider =
    NotifierProvider<NotifBudgetNotifier, bool>(NotifBudgetNotifier.new);

final selectedCalendarIdProvider = Provider<String?>((ref) {
  return ref.watch(preferencesRepositoryProvider).selectedCalendarId;
});

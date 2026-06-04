import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepository {
  final SharedPreferences _prefs;

  PreferencesRepository(this._prefs);

  // User
  String get userName => _prefs.getString('user_name') ?? '';
  Future<void> setUserName(String v) => _prefs.setString('user_name', v);

  String get userBirthDate => _prefs.getString('user_birth_date') ?? '';
  Future<void> setUserBirthDate(String v) =>
      _prefs.setString('user_birth_date', v);

  String get userBiologicalSex =>
      _prefs.getString('user_biological_sex') ?? 'other';
  Future<void> setUserBiologicalSex(String v) =>
      _prefs.setString('user_biological_sex', v);

  String get unitSystem => _prefs.getString('unit_system') ?? 'metric';
  Future<void> setUnitSystem(String v) => _prefs.setString('unit_system', v);

  String get appTheme => _prefs.getString('app_theme') ?? 'dark';

  String? get appLocale => _prefs.getString('app_locale');
  Future<void> setAppLocale(String? v) =>
      v != null ? _prefs.setString('app_locale', v) : _prefs.remove('app_locale');

  String get navSlots =>
      _prefs.getString('nav_slots') ??
      '["training","health","nutrition","budget"]';
  Future<void> setNavSlots(String v) => _prefs.setString('nav_slots', v);

  // Legacy single-ID — kept for migration only
  String? get selectedCalendarId => _prefs.getString('calendar_sync_id');

  List<String> get selectedCalendarIds {
    final stored = _prefs.getString('calendar_sync_ids');
    if (stored != null) {
      try {
        return (jsonDecode(stored) as List<dynamic>).cast<String>();
      } catch (_) {}
    }
    // Migrate from old single-ID key
    final single = selectedCalendarId;
    if (single != null) return [single];
    return [];
  }

  Future<void> setSelectedCalendarIds(List<String> ids) async {
    await _prefs.setString('calendar_sync_ids', jsonEncode(ids));
  }

  bool get onboardingComplete =>
      _prefs.getBool('onboarding_complete') ?? false;
  Future<void> setOnboardingComplete(bool v) =>
      _prefs.setBool('onboarding_complete', v);

  bool get trainingSetupComplete =>
      _prefs.getBool('training_setup_complete') ?? false;
  Future<void> setTrainingSetupComplete(bool v) =>
      _prefs.setBool('training_setup_complete', v);

  // Goals
  int get stepsGoal => _prefs.getInt('steps_goal') ?? 10000;
  Future<void> setStepsGoal(int v) => _prefs.setInt('steps_goal', v);

  double get weightGoalKg => _prefs.getDouble('weight_goal_kg') ?? 75.0;
  Future<void> setWeightGoalKg(double v) =>
      _prefs.setDouble('weight_goal_kg', v);

  double get heightCm => _prefs.getDouble('height_cm') ?? 175.0;
  Future<void> setHeightCm(double v) => _prefs.setDouble('height_cm', v);

  int get kcalGoal => _prefs.getInt('kcal_goal') ?? 2000;
  Future<void> setKcalGoal(int v) => _prefs.setInt('kcal_goal', v);

  int get workoutGoalPerWeek => _prefs.getInt('workout_goal_per_week') ?? 3;
  Future<void> setWorkoutGoalPerWeek(int v) => _prefs.setInt('workout_goal_per_week', v);

  int get proteinGoalG => _prefs.getInt('protein_goal_g') ?? 150;
  Future<void> setProteinGoalG(int v) => _prefs.setInt('protein_goal_g', v);

  // Water (evidenzbasiert)
  int get waterGoalMl => _prefs.getInt('water_goal_ml') ?? 2500;
  Future<void> setWaterGoalMl(int v) => _prefs.setInt('water_goal_ml', v);

  int get waterMinMl => _prefs.getInt('water_min_ml') ?? 1800;
  Future<void> setWaterMinMl(int v) => _prefs.setInt('water_min_ml', v);

  int get waterMaxMl => _prefs.getInt('water_max_ml') ?? 4000;
  Future<void> setWaterMaxMl(int v) => _prefs.setInt('water_max_ml', v);

  // Period
  bool get periodTrackingEnabled =>
      _prefs.getBool('period_tracking_enabled') ?? false;
  Future<void> setPeriodTrackingEnabled(bool v) =>
      _prefs.setBool('period_tracking_enabled', v);

  int get avgCycleLength => _prefs.getInt('avg_cycle_length') ?? 28;
  Future<void> setAvgCycleLength(int v) => _prefs.setInt('avg_cycle_length', v);

  int get avgPeriodLength => _prefs.getInt('avg_period_length') ?? 5;
  Future<void> setAvgPeriodLength(int v) =>
      _prefs.setInt('avg_period_length', v);

  // Weather
  double? get weatherLat => _prefs.getDouble('weather_lat');
  Future<void> setWeatherLat(double v) => _prefs.setDouble('weather_lat', v);

  double? get weatherLon => _prefs.getDouble('weather_lon');
  Future<void> setWeatherLon(double v) => _prefs.setDouble('weather_lon', v);

  // Security
  bool get biometricLock => _prefs.getBool('biometric_lock') ?? false;
  Future<void> setBiometricLock(bool v) => _prefs.setBool('biometric_lock', v);

  bool get pinLock => _prefs.getBool('pin_lock') ?? false;
  Future<void> setPinLock(bool v) => _prefs.setBool('pin_lock', v);

  // Budget
  String get currencySymbol => _prefs.getString('currency_symbol') ?? '€';
  Future<void> setCurrencySymbol(String v) =>
      _prefs.setString('currency_symbol', v);

  double get monthlyBudget => _prefs.getDouble('monthly_budget') ?? 1500.0;
  Future<void> setMonthlyBudget(double v) =>
      _prefs.setDouble('monthly_budget', v);

  // Notifications
  bool get notifMedication => _prefs.getBool('notif_medication') ?? true;
  Future<void> setNotifMedication(bool v) =>
      _prefs.setBool('notif_medication', v);

  bool get notifSupplement => _prefs.getBool('notif_supplement') ?? true;
  Future<void> setNotifSupplement(bool v) =>
      _prefs.setBool('notif_supplement', v);

  bool get notifWorkout => _prefs.getBool('notif_workout') ?? true;
  Future<void> setNotifWorkout(bool v) => _prefs.setBool('notif_workout', v);

  bool get notifWater => _prefs.getBool('notif_water') ?? true;
  Future<void> setNotifWater(bool v) => _prefs.setBool('notif_water', v);

  bool get notifTodo => _prefs.getBool('notif_todo') ?? true;
  Future<void> setNotifTodo(bool v) => _prefs.setBool('notif_todo', v);

  bool get notifHabit => _prefs.getBool('notif_habit') ?? true;
  Future<void> setNotifHabit(bool v) => _prefs.setBool('notif_habit', v);

  bool get notifPeriod => _prefs.getBool('notif_period') ?? true;
  Future<void> setNotifPeriod(bool v) => _prefs.setBool('notif_period', v);

  bool get notifBudget => _prefs.getBool('notif_budget') ?? false;
  Future<void> setNotifBudget(bool v) => _prefs.setBool('notif_budget', v);

  // Notification times
  String get notifMedicationTime =>
      _prefs.getString('notif_medication_time') ?? '08:00';
  Future<void> setNotifMedicationTime(String v) =>
      _prefs.setString('notif_medication_time', v);

  String get notifSupplementTime =>
      _prefs.getString('notif_supplement_time') ?? '09:00';
  Future<void> setNotifSupplementTime(String v) =>
      _prefs.setString('notif_supplement_time', v);

  String get notifWorkoutTime =>
      _prefs.getString('notif_workout_time') ?? '18:00';
  Future<void> setNotifWorkoutTime(String v) =>
      _prefs.setString('notif_workout_time', v);

  int get notifWaterInterval =>
      _prefs.getInt('notif_water_interval') ?? 90;
  Future<void> setNotifWaterInterval(int v) =>
      _prefs.setInt('notif_water_interval', v);

  String get notifHabitTime =>
      _prefs.getString('notif_habit_time') ?? '20:00';
  Future<void> setNotifHabitTime(String v) =>
      _prefs.setString('notif_habit_time', v);

  String get notifTodoTime =>
      _prefs.getString('notif_todo_time') ?? '07:00';
  Future<void> setNotifTodoTime(String v) =>
      _prefs.setString('notif_todo_time', v);

  int get notifPeriodDays => _prefs.getInt('notif_period_days') ?? 3;
  Future<void> setNotifPeriodDays(int v) =>
      _prefs.setInt('notif_period_days', v);

  double get notifBudgetThreshold =>
      _prefs.getDouble('notif_budget_threshold') ?? 0.9;
  Future<void> setNotifBudgetThreshold(double v) =>
      _prefs.setDouble('notif_budget_threshold', v);

  // Cache
  int get lastHeartRate => _prefs.getInt('last_heart_rate') ?? 0;
  Future<void> setLastHeartRate(int v) => _prefs.setInt('last_heart_rate', v);

  int get stepsToday => _prefs.getInt('steps_today') ?? 0;
  Future<void> setStepsToday(int v) => _prefs.setInt('steps_today', v);

  String get weatherCache => _prefs.getString('weather_cache') ?? '';
  Future<void> setWeatherCache(String v) =>
      _prefs.setString('weather_cache', v);

  int get weatherCacheTs => _prefs.getInt('weather_cache_ts') ?? 0;
  Future<void> setWeatherCacheTs(int v) => _prefs.setInt('weather_cache_ts', v);

  int get lockTimestamp => _prefs.getInt('lock_timestamp') ?? 0;
  Future<void> setLockTimestamp(int v) => _prefs.setInt('lock_timestamp', v);

  // App-Launcher (experimentell)
  bool get appLauncherEnabled =>
      _prefs.getBool('app_launcher_enabled') ?? false;
  Future<void> setAppLauncherEnabled(bool v) =>
      _prefs.setBool('app_launcher_enabled', v);

  String get appLauncherFavorites =>
      _prefs.getString('app_launcher_favorites') ?? '[]';
  Future<void> setAppLauncherFavorites(String v) =>
      _prefs.setString('app_launcher_favorites', v);

  // Seeder flags
  bool get exercisesSeeded => _prefs.getBool('exercises_seeded') ?? false;
  Future<void> setExercisesSeeded(bool v) =>
      _prefs.setBool('exercises_seeded', v);

  bool get supplementsSeeded => _prefs.getBool('supplements_seeded') ?? false;
  Future<void> setSupplementsSeeded(bool v) =>
      _prefs.setBool('supplements_seeded', v);

  bool get medicationsSeeded => _prefs.getBool('medications_seeded') ?? false;
  Future<void> setMedicationsSeeded(bool v) =>
      _prefs.setBool('medications_seeded', v);

  Future<void> clearAll() => _prefs.clear();
}

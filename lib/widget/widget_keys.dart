/// Namespaced Schlüssel für den Shared-Group-Store der Homescreen-Widgets.
/// Schema: `<gruppe>.<feld>`. Werte werden immer als String geschrieben,
/// damit Android (SharedPreferences) und iOS (UserDefaults) identisch lesen.
class WidgetKeys {
  static const String appGroupId = 'group.de.traum.widgets';

  // health
  static const String steps = 'health.steps';
  static const String stepsGoal = 'health.stepsGoal';
  static const String sleepHours = 'health.sleepHours';
  static const String heartRate = 'health.heartRate';
  static const String mood = 'health.mood';

  // nutrition
  static const String kcal = 'nutrition.kcal';
  static const String kcalGoal = 'nutrition.kcalGoal';
  static const String waterMl = 'nutrition.waterMl';
  static const String waterGoalMl = 'nutrition.waterGoalMl';
  static const String protein = 'nutrition.protein';
  static const String proteinGoal = 'nutrition.proteinGoal';

  // planning
  static const String nextTodo = 'planning.nextTodo';

  /// Schlüssel des zuletzt geschriebenen Snapshots (ISO-8601), für Debug/Tests.
  static const String updatedAt = 'meta.updatedAt';
}

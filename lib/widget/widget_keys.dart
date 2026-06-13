/// Namespaced Schlüssel für den Shared-Group-Store der Homescreen-Widgets.
/// Schema: `<gruppe>.<feld>`. Werte werden immer als String geschrieben,
/// damit Android (SharedPreferences) und iOS (UserDefaults) identisch lesen.
class WidgetKeys {
  static const String appGroupId = 'group.de.traum.widgets';

  // ── health ──────────────────────────────────────────────────────────────
  static const String steps = 'health.steps';
  static const String stepsGoal = 'health.stepsGoal';
  static const String sleepHours = 'health.sleepHours';
  static const String heartRate = 'health.heartRate';
  static const String mood = 'health.mood';
  static const String healthScore = 'health.score';
  static const String weightKg = 'health.weightKg';
  static const String activeMinutes = 'health.activeMinutes';

  // ── nutrition ────────────────────────────────────────────────────────────
  static const String kcal = 'nutrition.kcal';
  static const String kcalGoal = 'nutrition.kcalGoal';
  static const String waterMl = 'nutrition.waterMl';
  static const String waterGoalMl = 'nutrition.waterGoalMl';
  static const String protein = 'nutrition.protein';
  static const String proteinGoal = 'nutrition.proteinGoal';
  static const String carbs = 'nutrition.carbs';
  static const String fat = 'nutrition.fat';
  static const String lastMeal = 'nutrition.lastMeal';

  // ── training ─────────────────────────────────────────────────────────────
  static const String nextWorkout = 'training.nextWorkout';
  static const String weeklyVolume = 'training.weeklyVolume';
  static const String trainingStreak = 'training.streak';

  // ── planning ─────────────────────────────────────────────────────────────
  static const String nextTodo = 'planning.nextTodo';
  static const String openTodos = 'planning.openTodos';
  static const String nextAppointment = 'planning.nextAppointment';
  static const String habitsDone = 'planning.habitsDone';
  static const String habitsTotal = 'planning.habitsTotal';
  static const String medsDone = 'planning.medsDone';
  static const String medsTotal = 'planning.medsTotal';

  // ── budget ───────────────────────────────────────────────────────────────
  static const String balanceMonth = 'budget.balanceMonth';
  static const String income = 'budget.income';
  static const String expense = 'budget.expense';
  static const String budgetSpent = 'budget.spent';
  static const String budgetLimit = 'budget.limit';
  static const String topCategory = 'budget.topCategory';

  // ── diary ─────────────────────────────────────────────────────────────────
  static const String writeStreak = 'diary.writeStreak';
  static const String lastEntry = 'diary.lastEntry';
  static const String entriesThisMonth = 'diary.entriesThisMonth';

  // ── abstinence ───────────────────────────────────────────────────────────
  static const String abstinenceTitle = 'abstinence.title';
  static const String abstinenceDuration = 'abstinence.duration';
  static const String moneySaved = 'abstinence.moneySaved';

  // ── substances ───────────────────────────────────────────────────────────
  static const String lastIntake = 'substances.lastIntake';
  static const String takenToday = 'substances.takenToday';

  // ── period ───────────────────────────────────────────────────────────────
  static const String cycleDay = 'period.cycleDay';
  static const String periodPhase = 'period.phase';
  static const String nextPeriodDays = 'period.nextDays';

  // ── notes ─────────────────────────────────────────────────────────────────
  static const String notesCount = 'notes.count';
  static const String lastNote = 'notes.lastNote';

  // ── map ───────────────────────────────────────────────────────────────────
  static const String placesCount = 'map.placesCount';
  static const String lastPhoto = 'map.lastPhoto';

  /// Schlüssel des zuletzt geschriebenen Snapshots (ISO-8601), für Debug/Tests.
  static const String updatedAt = 'meta.updatedAt';
}

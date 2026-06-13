import 'widget_keys.dart';

/// Vollständiger Datenstand für die Homescreen-Widgets.
class WidgetSnapshot {
  // ── health (Phase 1) ─────────────────────────────────────────────────────
  final int steps;
  final int stepsGoal;
  final double sleepHours;
  final int heartRate;
  final int mood;

  // ── nutrition (Phase 1) ──────────────────────────────────────────────────
  final int kcal;
  final int kcalGoal;
  final int waterMl;
  final int waterGoalMl;
  final int protein;
  final int proteinGoal;

  // ── planning (Phase 1) ───────────────────────────────────────────────────
  final String nextTodo;

  // ── health (Phase 2) ─────────────────────────────────────────────────────
  final int healthScore;
  final double weightKg;
  final int activeMinutes;

  // ── nutrition (Phase 2) ──────────────────────────────────────────────────
  final int carbs;
  final int fat;
  final String lastMeal;

  // ── training ─────────────────────────────────────────────────────────────
  final String nextWorkout;
  final int weeklyVolume;
  final int trainingStreak;

  // ── planning (Phase 2) ───────────────────────────────────────────────────
  final int openTodos;
  final String nextAppointment;
  final int habitsDone;
  final int habitsTotal;
  final int medsDone;
  final int medsTotal;

  // ── budget ───────────────────────────────────────────────────────────────
  final double balanceMonth;
  final double income;
  final double expense;
  final double budgetSpent;
  final double budgetLimit;
  final String topCategory;

  // ── diary ─────────────────────────────────────────────────────────────────
  final int writeStreak;
  final String lastEntry;
  final int entriesThisMonth;

  // ── abstinence ───────────────────────────────────────────────────────────
  final String abstinenceTitle;
  final String abstinenceDuration;
  final double moneySaved;

  // ── substances ───────────────────────────────────────────────────────────
  final String lastIntake;
  final int takenToday;

  // ── period ───────────────────────────────────────────────────────────────
  final int cycleDay;
  final String periodPhase;
  final int nextPeriodDays;

  // ── notes ─────────────────────────────────────────────────────────────────
  final int notesCount;
  final String lastNote;

  // ── map ───────────────────────────────────────────────────────────────────
  final int placesCount;
  final String lastPhoto;

  const WidgetSnapshot({
    // Phase 1 — required (no default) to preserve existing call sites
    required this.steps,
    required this.stepsGoal,
    required this.sleepHours,
    required this.heartRate,
    required this.mood,
    required this.kcal,
    required this.kcalGoal,
    required this.waterMl,
    required this.waterGoalMl,
    required this.protein,
    required this.proteinGoal,
    required this.nextTodo,
    // Phase 2 — optional with sensible defaults so old call sites compile
    this.healthScore = 0,
    this.weightKg = 0.0,
    this.activeMinutes = 0,
    this.carbs = 0,
    this.fat = 0,
    this.lastMeal = '',
    this.nextWorkout = '',
    this.weeklyVolume = 0,
    this.trainingStreak = 0,
    this.openTodos = 0,
    this.nextAppointment = '',
    this.habitsDone = 0,
    this.habitsTotal = 0,
    this.medsDone = 0,
    this.medsTotal = 0,
    this.balanceMonth = 0.0,
    this.income = 0.0,
    this.expense = 0.0,
    this.budgetSpent = 0.0,
    this.budgetLimit = 0.0,
    this.topCategory = '',
    this.writeStreak = 0,
    this.lastEntry = '',
    this.entriesThisMonth = 0,
    this.abstinenceTitle = '',
    this.abstinenceDuration = '',
    this.moneySaved = 0.0,
    this.lastIntake = '',
    this.takenToday = 0,
    this.cycleDay = 0,
    this.periodPhase = '',
    this.nextPeriodDays = 0,
    this.notesCount = 0,
    this.lastNote = '',
    this.placesCount = 0,
    this.lastPhoto = '',
  });

  factory WidgetSnapshot.empty() => const WidgetSnapshot(
        steps: 0,
        stepsGoal: 10000,
        sleepHours: 0,
        heartRate: 0,
        mood: 0,
        kcal: 0,
        kcalGoal: 2200,
        waterMl: 0,
        waterGoalMl: 2500,
        protein: 0,
        proteinGoal: 150,
        nextTodo: '',
      );

  /// Flache String-Map fürs Schreiben in den Group-Store.
  Map<String, String> toStringMap() => {
        // ── health (Phase 1) ───────────────────────────────────────────────
        WidgetKeys.steps: '$steps',
        WidgetKeys.stepsGoal: '$stepsGoal',
        WidgetKeys.sleepHours: _trimDouble(sleepHours),
        WidgetKeys.heartRate: '$heartRate',
        WidgetKeys.mood: '$mood',
        // ── nutrition (Phase 1) ────────────────────────────────────────────
        WidgetKeys.kcal: '$kcal',
        WidgetKeys.kcalGoal: '$kcalGoal',
        WidgetKeys.waterMl: '$waterMl',
        WidgetKeys.waterGoalMl: '$waterGoalMl',
        WidgetKeys.protein: '$protein',
        WidgetKeys.proteinGoal: '$proteinGoal',
        // ── planning (Phase 1) ─────────────────────────────────────────────
        WidgetKeys.nextTodo: nextTodo,
        // ── health (Phase 2) ───────────────────────────────────────────────
        WidgetKeys.healthScore: '$healthScore',
        WidgetKeys.weightKg: _trimDouble(weightKg),
        WidgetKeys.activeMinutes: '$activeMinutes',
        // ── nutrition (Phase 2) ────────────────────────────────────────────
        WidgetKeys.carbs: '$carbs',
        WidgetKeys.fat: '$fat',
        WidgetKeys.lastMeal: lastMeal,
        // ── training ──────────────────────────────────────────────────────
        WidgetKeys.nextWorkout: nextWorkout,
        WidgetKeys.weeklyVolume: '$weeklyVolume',
        WidgetKeys.trainingStreak: '$trainingStreak',
        // ── planning (Phase 2) ─────────────────────────────────────────────
        WidgetKeys.openTodos: '$openTodos',
        WidgetKeys.nextAppointment: nextAppointment,
        WidgetKeys.habitsDone: '$habitsDone',
        WidgetKeys.habitsTotal: '$habitsTotal',
        WidgetKeys.medsDone: '$medsDone',
        WidgetKeys.medsTotal: '$medsTotal',
        // ── budget ────────────────────────────────────────────────────────
        WidgetKeys.balanceMonth: _trimDouble(balanceMonth),
        WidgetKeys.income: _trimDouble(income),
        WidgetKeys.expense: _trimDouble(expense),
        WidgetKeys.budgetSpent: _trimDouble(budgetSpent),
        WidgetKeys.budgetLimit: _trimDouble(budgetLimit),
        WidgetKeys.topCategory: topCategory,
        // ── diary ─────────────────────────────────────────────────────────
        WidgetKeys.writeStreak: '$writeStreak',
        WidgetKeys.lastEntry: lastEntry,
        WidgetKeys.entriesThisMonth: '$entriesThisMonth',
        // ── abstinence ────────────────────────────────────────────────────
        WidgetKeys.abstinenceTitle: abstinenceTitle,
        WidgetKeys.abstinenceDuration: abstinenceDuration,
        WidgetKeys.moneySaved: _trimDouble(moneySaved),
        // ── substances ────────────────────────────────────────────────────
        WidgetKeys.lastIntake: lastIntake,
        WidgetKeys.takenToday: '$takenToday',
        // ── period ────────────────────────────────────────────────────────
        WidgetKeys.cycleDay: '$cycleDay',
        WidgetKeys.periodPhase: periodPhase,
        WidgetKeys.nextPeriodDays: '$nextPeriodDays',
        // ── notes ─────────────────────────────────────────────────────────
        WidgetKeys.notesCount: '$notesCount',
        WidgetKeys.lastNote: lastNote,
        // ── map ───────────────────────────────────────────────────────────
        WidgetKeys.placesCount: '$placesCount',
        WidgetKeys.lastPhoto: lastPhoto,
      };

  static String _trimDouble(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

import 'widget_keys.dart';

/// Vollständiger Datenstand für die Homescreen-Widgets.
class WidgetSnapshot {
  /// Kodiert eine Zahlenreihe als CSV-String ("4200,5100,…") für den Group-Store.
  static String encodeSeries(List<num> values) =>
      values.map((v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v').join(',');

  /// Kodiert Labels als ";"-getrennte Liste ("Apfel;Reis").
  static String encodeLabels(List<String> labels) => labels.join(';');

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
  final int mapPreview;

  // ── general (Phase 3) ────────────────────────────────────────────────────
  final String clockDate;
  final String weatherTemp;
  final String weatherForecast;
  final int appFavorites;
  final String quickActions;

  // ── health (Phase 3) ─────────────────────────────────────────────────────
  final int caloriesBurned;
  final int stepsWeekAvg;

  // ── nutrition (Phase 3) ──────────────────────────────────────────────────
  final int supplementsToday;
  final int mealsToday;

  // ── training (Phase 3) ───────────────────────────────────────────────────
  final int muscleHeatmap;
  final String lastWorkout;
  final int weeklyWorkouts;
  final int personalRecords;
  final String restTimer;

  // ── planning (Phase 3) ───────────────────────────────────────────────────
  final int overdueTodos;
  final int bestHabitStreak;

  // ── budget (Phase 3) ─────────────────────────────────────────────────────
  final String accountsOverview;
  final String recentTransaction;
  final String savingsGoal;
  final int recurringDue;
  final String monthTrend;

  // ── diary (Phase 3) ──────────────────────────────────────────────────────
  final int yearHeatmap;
  final int moodCalendar;

  // ── abstinence (Phase 3) ─────────────────────────────────────────────────
  final int longestStreak;
  final int allCounters;

  // ── notes (Phase 3) ──────────────────────────────────────────────────────
  final String pinnedNote;

  // ── v2 series (CSV / labels), Default '' ──────────────────────────────────
  final String stepsWeek;
  final String sleepWeek;
  final String weightHistory;
  final String moodWeek;
  final String macroSplit;
  final String mealsTodayList;
  final String volumeWeek;
  final String todayAgenda;
  final String habitWeek;
  final String categorySplit;
  final String monthTrendSeries;
  final String counters;
  final String quote;
  final String countdownLabel;
  final String countdownDays;

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
    // Phase 3 — map
    this.mapPreview = 0,
    // Phase 3 — general
    this.clockDate = '',
    this.weatherTemp = '',
    this.weatherForecast = '',
    this.appFavorites = 0,
    this.quickActions = '',
    // Phase 3 — health
    this.caloriesBurned = 0,
    this.stepsWeekAvg = 0,
    // Phase 3 — nutrition
    this.supplementsToday = 0,
    this.mealsToday = 0,
    // Phase 3 — training
    this.muscleHeatmap = 0,
    this.lastWorkout = '',
    this.weeklyWorkouts = 0,
    this.personalRecords = 0,
    this.restTimer = '',
    // Phase 3 — planning
    this.overdueTodos = 0,
    this.bestHabitStreak = 0,
    // Phase 3 — budget
    this.accountsOverview = '',
    this.recentTransaction = '',
    this.savingsGoal = '',
    this.recurringDue = 0,
    this.monthTrend = '',
    // Phase 3 — diary
    this.yearHeatmap = 0,
    this.moodCalendar = 0,
    // Phase 3 — abstinence
    this.longestStreak = 0,
    this.allCounters = 0,
    // Phase 3 — notes
    this.pinnedNote = '',
    // v2 series
    this.stepsWeek = '',
    this.sleepWeek = '',
    this.weightHistory = '',
    this.moodWeek = '',
    this.macroSplit = '',
    this.mealsTodayList = '',
    this.volumeWeek = '',
    this.todayAgenda = '',
    this.habitWeek = '',
    this.categorySplit = '',
    this.monthTrendSeries = '',
    this.counters = '',
    this.quote = '',
    this.countdownLabel = '',
    this.countdownDays = '',
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
        WidgetKeys.mapPreview: '$mapPreview',
        // ── general (Phase 3) ─────────────────────────────────────────────
        WidgetKeys.clockDate: clockDate,
        WidgetKeys.weatherTemp: weatherTemp,
        WidgetKeys.weatherForecast: weatherForecast,
        WidgetKeys.appFavorites: '$appFavorites',
        WidgetKeys.quickActions: quickActions,
        // ── health (Phase 3) ──────────────────────────────────────────────
        WidgetKeys.caloriesBurned: '$caloriesBurned',
        WidgetKeys.stepsWeekAvg: '$stepsWeekAvg',
        // ── nutrition (Phase 3) ───────────────────────────────────────────
        WidgetKeys.supplementsToday: '$supplementsToday',
        WidgetKeys.mealsToday: '$mealsToday',
        // ── training (Phase 3) ────────────────────────────────────────────
        WidgetKeys.muscleHeatmap: '$muscleHeatmap',
        WidgetKeys.lastWorkout: lastWorkout,
        WidgetKeys.weeklyWorkouts: '$weeklyWorkouts',
        WidgetKeys.personalRecords: '$personalRecords',
        WidgetKeys.restTimer: restTimer,
        // ── planning (Phase 3) ────────────────────────────────────────────
        WidgetKeys.overdueTodos: '$overdueTodos',
        WidgetKeys.bestHabitStreak: '$bestHabitStreak',
        // ── budget (Phase 3) ──────────────────────────────────────────────
        WidgetKeys.accountsOverview: accountsOverview,
        WidgetKeys.recentTransaction: recentTransaction,
        WidgetKeys.savingsGoal: savingsGoal,
        WidgetKeys.recurringDue: '$recurringDue',
        WidgetKeys.monthTrend: monthTrend,
        // ── diary (Phase 3) ───────────────────────────────────────────────
        WidgetKeys.yearHeatmap: '$yearHeatmap',
        WidgetKeys.moodCalendar: '$moodCalendar',
        // ── abstinence (Phase 3) ──────────────────────────────────────────
        WidgetKeys.longestStreak: '$longestStreak',
        WidgetKeys.allCounters: '$allCounters',
        // ── notes (Phase 3) ───────────────────────────────────────────────
        WidgetKeys.pinnedNote: pinnedNote,
        // ── v2 series ─────────────────────────────────────────────────────
        WidgetKeys.stepsWeek: stepsWeek,
        WidgetKeys.sleepWeek: sleepWeek,
        WidgetKeys.weightHistory: weightHistory,
        WidgetKeys.moodWeek: moodWeek,
        WidgetKeys.macroSplit: macroSplit,
        WidgetKeys.mealsTodayList: mealsTodayList,
        WidgetKeys.volumeWeek: volumeWeek,
        WidgetKeys.todayAgenda: todayAgenda,
        WidgetKeys.habitWeek: habitWeek,
        WidgetKeys.categorySplit: categorySplit,
        WidgetKeys.monthTrendSeries: monthTrendSeries,
        WidgetKeys.counters: counters,
        WidgetKeys.quote: quote,
        WidgetKeys.countdownLabel: countdownLabel,
        WidgetKeys.countdownDays: countdownDays,
        // ── v2 fixed-goal constants (rings with a fixed target) ───────────
        WidgetKeys.sleepGoalH: '8',
        WidgetKeys.activeGoalMin: '30',
        WidgetKeys.cycleLenDays: '28',
      };

  static String _trimDouble(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

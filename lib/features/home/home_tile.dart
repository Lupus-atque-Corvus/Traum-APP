import 'dart:convert';

enum HomeTileSize { small, wide, large }

enum HomeWidgetGroup {
  general, health, nutrition, training, planning,
  budget, diary, abstinence, substances, period, notes, map,
}

enum HomeWidgetType {
  // general
  clockDate, weatherNow, weatherForecast, appFavorites, quickActions, dailyScore, miniCalendar,
  // health
  steps, sleep, heartRate, moodToday, weightTrend, healthScore, healthSnapshot,
  activeMinutes, caloriesBurned, stepsWeekChart, weightChart,
  // nutrition
  caloriesRing, macros, water, lastMeal, remainingCalories, supplementsToday, mealsToday,
  // training
  nextWorkout, weeklyVolume, muscleHeatmap, lastWorkout, trainingStreak, weeklyWorkouts,
  personalRecords, restTimerQuick,
  // planning
  openTodos, todayAppointments, habitsToday, medicationsToday, nextAppointmentCountdown,
  overdueTodos, bestHabitStreak,
  // budget
  balanceMonth, incomeExpense, budgetProgress, accountsOverview, topCategory,
  recentTransactions, savingsGoal, recurringDue, monthTrend,
  // diary
  writeStreak, lastEntry, yearHeatmap, moodCalendar, entriesThisMonth,
  // abstinence
  currentStreak, longestStreak, moneySaved, allCounters,
  // substances
  lastIntake, takenToday,
  // period
  cycleDay, nextPeriod,
  // notes
  notesCount, lastNote, pinnedNote,
  // map
  placesCount, lastPhoto, mapPreview,
}

class HomeTile {
  final HomeWidgetType type;
  final HomeTileSize size;
  const HomeTile({required this.type, required this.size});

  Map<String, dynamic> toJson() => {'type': type.name, 'size': size.name};

  static HomeTile? tryFromJson(Map<String, dynamic> j) {
    HomeWidgetType? type;
    for (final e in HomeWidgetType.values) {
      if (e.name == j['type']) { type = e; break; }
    }
    if (type == null) return null;
    final size = HomeTileSize.values.firstWhere(
      (e) => e.name == j['size'],
      orElse: () => HomeTileSize.small,
    );
    return HomeTile(type: type, size: size);
  }

  factory HomeTile.fromJson(Map<String, dynamic> j) => tryFromJson(j)!;
}

String encodeHomeLayout(List<HomeTile> tiles) =>
    jsonEncode(tiles.map((t) => t.toJson()).toList());

List<HomeTile> decodeHomeLayout(String raw) {
  try {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => HomeTile.tryFromJson(e as Map<String, dynamic>))
        .whereType<HomeTile>()
        .toList();
  } catch (_) {
    return [];
  }
}

/// Standard-Layout für neue/leere Installationen (entspricht dem bisherigen Home).
List<HomeTile> defaultHomeLayout() => const [
      HomeTile(type: HomeWidgetType.clockDate, size: HomeTileSize.wide),
      HomeTile(type: HomeWidgetType.steps, size: HomeTileSize.small),
      HomeTile(type: HomeWidgetType.caloriesRing, size: HomeTileSize.small),
      HomeTile(type: HomeWidgetType.water, size: HomeTileSize.wide),
      HomeTile(type: HomeWidgetType.openTodos, size: HomeTileSize.wide),
      HomeTile(type: HomeWidgetType.medicationsToday, size: HomeTileSize.small),
      HomeTile(type: HomeWidgetType.habitsToday, size: HomeTileSize.wide),
      HomeTile(type: HomeWidgetType.incomeExpense, size: HomeTileSize.wide),
      HomeTile(type: HomeWidgetType.lastEntry, size: HomeTileSize.wide),
      HomeTile(type: HomeWidgetType.healthSnapshot, size: HomeTileSize.large),
    ];

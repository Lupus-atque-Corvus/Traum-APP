import 'widget_keys.dart';

/// Render-Vorlage eines Widgets. Wird in Kotlin/Swift gespiegelt.
enum WidgetTemplate { stat, progress, dualStat, list, overview, ring, ringTrio, barChart, sparkline, donut, dashboard, motivation }

/// Eine Kennzahl-Zelle eines Widgets: Label + Wert-Schlüssel
/// (+ optionales Ziel für Fortschritt).
class WidgetSlot {
  final String label;
  final String valueKey;
  final String? goalKey;
  const WidgetSlot({
    required this.label,
    required this.valueKey,
    this.goalKey,
  });
}

/// Ein nativer Widget-Typ (Single Source of Truth, gespiegelt nach Kotlin/Swift).
class WidgetCatalogEntry {
  final String key;
  final String title;
  final String accentHex;
  final WidgetTemplate template;
  final String route;
  final List<WidgetSlot> slots;

  const WidgetCatalogEntry({
    required this.key,
    required this.title,
    required this.accentHex,
    required this.template,
    required this.route,
    required this.slots,
  });

  /// Alle Datenschlüssel, die dieses Widget benötigt (Wert + optionales Ziel).
  List<String> get dataKeys => [
        for (final s in slots) ...[
          s.valueKey,
          if (s.goalKey != null) s.goalKey!,
        ],
      ];
}

/// Vollständiger nativer Katalog. Reihenfolge = Anzeige-Reihenfolge im Picker.
const List<WidgetCatalogEntry> widgetCatalog = [
  // ── 1. Übersicht ─────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'overview',
    title: 'Übersicht',
    accentHex: '#FF6B3D',
    template: WidgetTemplate.overview,
    route: '/home',
    slots: [
      WidgetSlot(label: 'Schritte',  valueKey: WidgetKeys.steps,    goalKey: WidgetKeys.stepsGoal),
      WidgetSlot(label: 'Kalorien',  valueKey: WidgetKeys.kcal,     goalKey: WidgetKeys.kcalGoal),
      WidgetSlot(label: 'Wasser',    valueKey: WidgetKeys.waterMl,  goalKey: WidgetKeys.waterGoalMl),
      WidgetSlot(label: 'Aufgabe',   valueKey: WidgetKeys.nextTodo),
    ],
  ),
  // ── 2. Gesundheit ─────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'health',
    title: 'Gesundheit',
    accentHex: '#F43F5E',
    template: WidgetTemplate.overview,
    route: '/health',
    slots: [
      WidgetSlot(label: 'Score',  valueKey: WidgetKeys.healthScore),
      WidgetSlot(label: 'Schlaf', valueKey: WidgetKeys.sleepHours),
      WidgetSlot(label: 'Puls',   valueKey: WidgetKeys.heartRate),
      WidgetSlot(label: 'Aktiv',  valueKey: WidgetKeys.activeMinutes),
    ],
  ),
  // ── 3. Ernährung ──────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'nutrition',
    title: 'Ernährung',
    accentHex: '#3DD68C',
    template: WidgetTemplate.overview,
    route: '/nutrition',
    slots: [
      WidgetSlot(label: 'Kalorien', valueKey: WidgetKeys.kcal,     goalKey: WidgetKeys.kcalGoal),
      WidgetSlot(label: 'Protein',  valueKey: WidgetKeys.protein,  goalKey: WidgetKeys.proteinGoal),
      WidgetSlot(label: 'Wasser',   valueKey: WidgetKeys.waterMl,  goalKey: WidgetKeys.waterGoalMl),
      WidgetSlot(label: 'Mahlzeit', valueKey: WidgetKeys.lastMeal),
    ],
  ),
  // ── 4. Training ───────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'training',
    title: 'Training',
    accentHex: '#5B6CF9',
    template: WidgetTemplate.overview,
    route: '/training',
    slots: [
      WidgetSlot(label: 'Nächstes', valueKey: WidgetKeys.nextWorkout),
      WidgetSlot(label: 'Volumen',  valueKey: WidgetKeys.weeklyVolume),
      WidgetSlot(label: 'Streak',   valueKey: WidgetKeys.trainingStreak),
    ],
  ),
  // ── 5. Planung ────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'planning',
    title: 'Planung',
    accentHex: '#F5A623',
    template: WidgetTemplate.overview,
    route: '/planning',
    slots: [
      WidgetSlot(label: 'Offen',   valueKey: WidgetKeys.openTodos),
      WidgetSlot(label: 'Termin',  valueKey: WidgetKeys.nextAppointment),
      WidgetSlot(label: 'Habits',  valueKey: WidgetKeys.habitsDone,  goalKey: WidgetKeys.habitsTotal),
      WidgetSlot(label: 'Medis',   valueKey: WidgetKeys.medsDone,    goalKey: WidgetKeys.medsTotal),
    ],
  ),
  // ── 6. Budget ─────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'budget',
    title: 'Budget',
    accentHex: '#00D4D4',
    template: WidgetTemplate.overview,
    route: '/budget',
    slots: [
      WidgetSlot(label: 'Saldo',    valueKey: WidgetKeys.balanceMonth),
      WidgetSlot(label: 'Ausgaben', valueKey: WidgetKeys.budgetSpent, goalKey: WidgetKeys.budgetLimit),
      WidgetSlot(label: 'Einnahmen',valueKey: WidgetKeys.income),
      WidgetSlot(label: 'Top',      valueKey: WidgetKeys.topCategory),
    ],
  ),
  // ── 7. Tagebuch ───────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'diary',
    title: 'Tagebuch',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.overview,
    route: '/diary',
    slots: [
      WidgetSlot(label: 'Streak',  valueKey: WidgetKeys.writeStreak),
      WidgetSlot(label: 'Letzter', valueKey: WidgetKeys.lastEntry),
      WidgetSlot(label: 'Monat',   valueKey: WidgetKeys.entriesThisMonth),
    ],
  ),
  // ── 8. Abstinenz ──────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'abstinence',
    title: 'Abstinenz',
    accentHex: '#FFAA55',
    template: WidgetTemplate.overview,
    route: '/abstinence',
    slots: [
      WidgetSlot(label: 'Titel',   valueKey: WidgetKeys.abstinenceTitle),
      WidgetSlot(label: 'Dauer',   valueKey: WidgetKeys.abstinenceDuration),
      WidgetSlot(label: 'Gespart', valueKey: WidgetKeys.moneySaved),
    ],
  ),
  // ── 9. Mittel ─────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'substances',
    title: 'Mittel',
    accentHex: '#0099BB',
    template: WidgetTemplate.overview,
    route: '/substances',
    slots: [
      WidgetSlot(label: 'Zuletzt', valueKey: WidgetKeys.lastIntake),
      WidgetSlot(label: 'Heute',   valueKey: WidgetKeys.takenToday),
    ],
  ),
  // ── 10. Zyklus ────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'period',
    title: 'Zyklus',
    accentHex: '#FF8FAB',
    template: WidgetTemplate.overview,
    route: '/period',
    slots: [
      WidgetSlot(label: 'Zyklustag', valueKey: WidgetKeys.cycleDay),
      WidgetSlot(label: 'Phase',     valueKey: WidgetKeys.periodPhase),
      WidgetSlot(label: 'Nächste',   valueKey: WidgetKeys.nextPeriodDays),
    ],
  ),
  // ── 11. Notizen ───────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'notes',
    title: 'Notizen',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.overview,
    route: '/notes',
    slots: [
      WidgetSlot(label: 'Notizen', valueKey: WidgetKeys.notesCount),
      WidgetSlot(label: 'Letzte',  valueKey: WidgetKeys.lastNote),
    ],
  ),
  // ── 12. Karte ─────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'map',
    title: 'Karte',
    accentHex: '#3DD68C',
    template: WidgetTemplate.overview,
    route: '/graffitimap',
    slots: [
      WidgetSlot(label: 'Orte', valueKey: WidgetKeys.placesCount),
      WidgetSlot(label: 'Foto', valueKey: WidgetKeys.lastPhoto),
    ],
  ),
];

/// Funktions-Katalog: ein Eintrag pro [HomeWidgetType].
/// Ermöglicht Coverage-Tests und dient als Mapping-Tabelle für
/// native Widget-Renderer auf Android/iOS.
const List<WidgetCatalogEntry> functionCatalog = [
  // ── general ───────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'clockDate',
    title: 'Uhr',
    accentHex: '#FF6B3D',
    template: WidgetTemplate.stat,
    route: '/home',
    slots: [WidgetSlot(label: 'Datum', valueKey: WidgetKeys.clockDate)],
  ),
  WidgetCatalogEntry(
    key: 'weatherNow',
    title: 'Wetter',
    accentHex: '#FF6B3D',
    template: WidgetTemplate.stat,
    route: '/home',
    slots: [WidgetSlot(label: 'Temperatur', valueKey: WidgetKeys.weatherTemp)],
  ),
  WidgetCatalogEntry(
    key: 'weatherForecast',
    title: 'Wetter',
    accentHex: '#FF6B3D',
    template: WidgetTemplate.stat,
    route: '/home',
    slots: [WidgetSlot(label: 'Vorhersage', valueKey: WidgetKeys.weatherForecast)],
  ),
  WidgetCatalogEntry(
    key: 'appFavorites',
    title: 'Apps',
    accentHex: '#FF6B3D',
    template: WidgetTemplate.list,
    route: '/home',
    slots: [WidgetSlot(label: 'Favoriten', valueKey: WidgetKeys.appFavorites)],
  ),
  WidgetCatalogEntry(
    key: 'quickActions',
    title: 'Schnellzugriff',
    accentHex: '#FF6B3D',
    template: WidgetTemplate.list,
    route: '/home',
    slots: [WidgetSlot(label: 'Aktionen', valueKey: WidgetKeys.quickActions)],
  ),
  WidgetCatalogEntry(
    key: 'dailyScore',
    title: 'Tagesübersicht',
    accentHex: '#FF6B3D',
    template: WidgetTemplate.stat,
    route: '/home',
    slots: [WidgetSlot(label: 'Score', valueKey: WidgetKeys.healthScore)],
  ),
  WidgetCatalogEntry(
    key: 'miniCalendar',
    title: 'Kalender',
    accentHex: '#FF6B3D',
    template: WidgetTemplate.list,
    route: '/home',
    slots: [WidgetSlot(label: 'Termin', valueKey: WidgetKeys.nextAppointment)],
  ),
  // ── health ────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'steps',
    title: 'Schritte',
    accentHex: '#F43F5E',
    template: WidgetTemplate.progress,
    route: '/health',
    slots: [
      WidgetSlot(label: 'Schritte', valueKey: WidgetKeys.steps, goalKey: WidgetKeys.stepsGoal),
    ],
  ),
  WidgetCatalogEntry(
    key: 'sleep',
    title: 'Schlaf',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'Stunden', valueKey: WidgetKeys.sleepHours)],
  ),
  WidgetCatalogEntry(
    key: 'heartRate',
    title: 'Herzfrequenz',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'Puls', valueKey: WidgetKeys.heartRate)],
  ),
  WidgetCatalogEntry(
    key: 'moodToday',
    title: 'Stimmung',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'Stimmung', valueKey: WidgetKeys.mood)],
  ),
  WidgetCatalogEntry(
    key: 'weightTrend',
    title: 'Gewicht',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'Gewicht', valueKey: WidgetKeys.weightKg)],
  ),
  WidgetCatalogEntry(
    key: 'healthScore',
    title: 'Score',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'Score', valueKey: WidgetKeys.healthScore)],
  ),
  WidgetCatalogEntry(
    key: 'healthSnapshot',
    title: 'Gesundheit',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'Score', valueKey: WidgetKeys.healthScore)],
  ),
  WidgetCatalogEntry(
    key: 'activeMinutes',
    title: 'Aktive Min.',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'Minuten', valueKey: WidgetKeys.activeMinutes)],
  ),
  WidgetCatalogEntry(
    key: 'caloriesBurned',
    title: 'Verbrannt',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'kcal', valueKey: WidgetKeys.caloriesBurned)],
  ),
  WidgetCatalogEntry(
    key: 'stepsWeekChart',
    title: 'Schritte-Woche',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'Ø Schritte', valueKey: WidgetKeys.stepsWeekAvg)],
  ),
  WidgetCatalogEntry(
    key: 'weightChart',
    title: 'Gewichtsverlauf',
    accentHex: '#F43F5E',
    template: WidgetTemplate.stat,
    route: '/health',
    slots: [WidgetSlot(label: 'Gewicht', valueKey: WidgetKeys.weightKg)],
  ),
  // ── nutrition ─────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'caloriesRing',
    title: 'Kalorien',
    accentHex: '#3DD68C',
    template: WidgetTemplate.progress,
    route: '/nutrition',
    slots: [
      WidgetSlot(label: 'Kalorien', valueKey: WidgetKeys.kcal, goalKey: WidgetKeys.kcalGoal),
    ],
  ),
  WidgetCatalogEntry(
    key: 'macros',
    title: 'Makros',
    accentHex: '#3DD68C',
    template: WidgetTemplate.dualStat,
    route: '/nutrition',
    slots: [
      WidgetSlot(label: 'Protein', valueKey: WidgetKeys.protein),
      WidgetSlot(label: 'Kohlenhydrate', valueKey: WidgetKeys.carbs),
    ],
  ),
  WidgetCatalogEntry(
    key: 'water',
    title: 'Wasser',
    accentHex: '#3DD68C',
    template: WidgetTemplate.progress,
    route: '/nutrition',
    slots: [
      WidgetSlot(label: 'Wasser', valueKey: WidgetKeys.waterMl, goalKey: WidgetKeys.waterGoalMl),
    ],
  ),
  WidgetCatalogEntry(
    key: 'lastMeal',
    title: 'Letzte Mahlzeit',
    accentHex: '#3DD68C',
    template: WidgetTemplate.stat,
    route: '/nutrition',
    slots: [WidgetSlot(label: 'Mahlzeit', valueKey: WidgetKeys.lastMeal)],
  ),
  WidgetCatalogEntry(
    key: 'remainingCalories',
    title: 'Rest-kcal',
    accentHex: '#3DD68C',
    template: WidgetTemplate.progress,
    route: '/nutrition',
    slots: [
      WidgetSlot(label: 'Rest', valueKey: WidgetKeys.kcal, goalKey: WidgetKeys.kcalGoal),
    ],
  ),
  WidgetCatalogEntry(
    key: 'supplementsToday',
    title: 'Supplements',
    accentHex: '#3DD68C',
    template: WidgetTemplate.stat,
    route: '/nutrition',
    slots: [WidgetSlot(label: 'Supplements', valueKey: WidgetKeys.supplementsToday)],
  ),
  WidgetCatalogEntry(
    key: 'mealsToday',
    title: 'Mahlzeiten',
    accentHex: '#3DD68C',
    template: WidgetTemplate.stat,
    route: '/nutrition',
    slots: [WidgetSlot(label: 'Mahlzeiten', valueKey: WidgetKeys.mealsToday)],
  ),
  // ── training ──────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'nextWorkout',
    title: 'Nächstes Workout',
    accentHex: '#5B6CF9',
    template: WidgetTemplate.stat,
    route: '/training',
    slots: [WidgetSlot(label: 'Workout', valueKey: WidgetKeys.nextWorkout)],
  ),
  WidgetCatalogEntry(
    key: 'weeklyVolume',
    title: 'Wochen-Volumen',
    accentHex: '#5B6CF9',
    template: WidgetTemplate.stat,
    route: '/training',
    slots: [WidgetSlot(label: 'Sets', valueKey: WidgetKeys.weeklyVolume)],
  ),
  WidgetCatalogEntry(
    key: 'muscleHeatmap',
    title: 'Muskeln',
    accentHex: '#5B6CF9',
    template: WidgetTemplate.stat,
    route: '/training',
    slots: [WidgetSlot(label: 'Muskeln', valueKey: WidgetKeys.muscleHeatmap)],
  ),
  WidgetCatalogEntry(
    key: 'lastWorkout',
    title: 'Letztes Workout',
    accentHex: '#5B6CF9',
    template: WidgetTemplate.stat,
    route: '/training',
    slots: [WidgetSlot(label: 'Workout', valueKey: WidgetKeys.lastWorkout)],
  ),
  WidgetCatalogEntry(
    key: 'trainingStreak',
    title: 'Trainings-Streak',
    accentHex: '#5B6CF9',
    template: WidgetTemplate.stat,
    route: '/training',
    slots: [WidgetSlot(label: 'Wochen', valueKey: WidgetKeys.trainingStreak)],
  ),
  WidgetCatalogEntry(
    key: 'weeklyWorkouts',
    title: 'Wochen-Workouts',
    accentHex: '#5B6CF9',
    template: WidgetTemplate.stat,
    route: '/training',
    slots: [WidgetSlot(label: 'Workouts', valueKey: WidgetKeys.weeklyWorkouts)],
  ),
  WidgetCatalogEntry(
    key: 'personalRecords',
    title: 'Rekorde',
    accentHex: '#5B6CF9',
    template: WidgetTemplate.stat,
    route: '/training',
    slots: [WidgetSlot(label: 'Rekorde', valueKey: WidgetKeys.personalRecords)],
  ),
  WidgetCatalogEntry(
    key: 'restTimerQuick',
    title: 'Rest-Timer',
    accentHex: '#5B6CF9',
    template: WidgetTemplate.stat,
    route: '/training',
    slots: [WidgetSlot(label: 'Timer', valueKey: WidgetKeys.restTimer)],
  ),
  // ── planning ──────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'openTodos',
    title: 'Offene Todos',
    accentHex: '#F5A623',
    template: WidgetTemplate.stat,
    route: '/planning',
    slots: [WidgetSlot(label: 'Offen', valueKey: WidgetKeys.openTodos)],
  ),
  WidgetCatalogEntry(
    key: 'todayAppointments',
    title: 'Heute',
    accentHex: '#F5A623',
    template: WidgetTemplate.list,
    route: '/planning',
    slots: [WidgetSlot(label: 'Termin', valueKey: WidgetKeys.nextAppointment)],
  ),
  WidgetCatalogEntry(
    key: 'habitsToday',
    title: 'Gewohnheiten',
    accentHex: '#F5A623',
    template: WidgetTemplate.progress,
    route: '/planning',
    slots: [
      WidgetSlot(label: 'Habits', valueKey: WidgetKeys.habitsDone, goalKey: WidgetKeys.habitsTotal),
    ],
  ),
  WidgetCatalogEntry(
    key: 'medicationsToday',
    title: 'Medikamente',
    accentHex: '#F5A623',
    template: WidgetTemplate.progress,
    route: '/planning',
    slots: [
      WidgetSlot(label: 'Medis', valueKey: WidgetKeys.medsDone, goalKey: WidgetKeys.medsTotal),
    ],
  ),
  WidgetCatalogEntry(
    key: 'nextAppointmentCountdown',
    title: 'Nächster Termin',
    accentHex: '#F5A623',
    template: WidgetTemplate.stat,
    route: '/planning',
    slots: [WidgetSlot(label: 'Termin', valueKey: WidgetKeys.nextAppointment)],
  ),
  WidgetCatalogEntry(
    key: 'overdueTodos',
    title: 'Überfällig',
    accentHex: '#F5A623',
    template: WidgetTemplate.stat,
    route: '/planning',
    slots: [WidgetSlot(label: 'Überfällig', valueKey: WidgetKeys.overdueTodos)],
  ),
  WidgetCatalogEntry(
    key: 'bestHabitStreak',
    title: 'Beste Serie',
    accentHex: '#F5A623',
    template: WidgetTemplate.stat,
    route: '/planning',
    slots: [WidgetSlot(label: 'Tage', valueKey: WidgetKeys.bestHabitStreak)],
  ),
  // ── budget ────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'balanceMonth',
    title: 'Saldo',
    accentHex: '#00D4D4',
    template: WidgetTemplate.stat,
    route: '/budget',
    slots: [WidgetSlot(label: 'Saldo', valueKey: WidgetKeys.balanceMonth)],
  ),
  WidgetCatalogEntry(
    key: 'incomeExpense',
    title: 'Ein/Aus',
    accentHex: '#00D4D4',
    template: WidgetTemplate.dualStat,
    route: '/budget',
    slots: [
      WidgetSlot(label: 'Einnahmen', valueKey: WidgetKeys.income),
      WidgetSlot(label: 'Ausgaben', valueKey: WidgetKeys.expense),
    ],
  ),
  WidgetCatalogEntry(
    key: 'budgetProgress',
    title: 'Budget',
    accentHex: '#00D4D4',
    template: WidgetTemplate.progress,
    route: '/budget',
    slots: [
      WidgetSlot(label: 'Budget', valueKey: WidgetKeys.budgetSpent, goalKey: WidgetKeys.budgetLimit),
    ],
  ),
  WidgetCatalogEntry(
    key: 'accountsOverview',
    title: 'Konten',
    accentHex: '#00D4D4',
    template: WidgetTemplate.stat,
    route: '/budget',
    slots: [WidgetSlot(label: 'Konten', valueKey: WidgetKeys.accountsOverview)],
  ),
  WidgetCatalogEntry(
    key: 'topCategory',
    title: 'Top-Ausgabe',
    accentHex: '#00D4D4',
    template: WidgetTemplate.stat,
    route: '/budget',
    slots: [WidgetSlot(label: 'Kategorie', valueKey: WidgetKeys.topCategory)],
  ),
  WidgetCatalogEntry(
    key: 'recentTransactions',
    title: 'Letzte',
    accentHex: '#00D4D4',
    template: WidgetTemplate.stat,
    route: '/budget',
    slots: [WidgetSlot(label: 'Transaktion', valueKey: WidgetKeys.recentTransaction)],
  ),
  WidgetCatalogEntry(
    key: 'savingsGoal',
    title: 'Sparziel',
    accentHex: '#00D4D4',
    template: WidgetTemplate.stat,
    route: '/budget',
    slots: [WidgetSlot(label: 'Ziel', valueKey: WidgetKeys.savingsGoal)],
  ),
  WidgetCatalogEntry(
    key: 'recurringDue',
    title: 'Wiederkehrend',
    accentHex: '#00D4D4',
    template: WidgetTemplate.stat,
    route: '/budget',
    slots: [WidgetSlot(label: 'Fällig', valueKey: WidgetKeys.recurringDue)],
  ),
  WidgetCatalogEntry(
    key: 'monthTrend',
    title: 'Monats-Trend',
    accentHex: '#00D4D4',
    template: WidgetTemplate.stat,
    route: '/budget',
    slots: [WidgetSlot(label: 'Trend', valueKey: WidgetKeys.monthTrend)],
  ),
  // ── diary ─────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'writeStreak',
    title: 'Schreib-Streak',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.stat,
    route: '/diary',
    slots: [WidgetSlot(label: 'Tage', valueKey: WidgetKeys.writeStreak)],
  ),
  WidgetCatalogEntry(
    key: 'lastEntry',
    title: 'Letzter Eintrag',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.stat,
    route: '/diary',
    slots: [WidgetSlot(label: 'Eintrag', valueKey: WidgetKeys.lastEntry)],
  ),
  WidgetCatalogEntry(
    key: 'yearHeatmap',
    title: 'Jahres-Heatmap',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.stat,
    route: '/diary',
    slots: [WidgetSlot(label: 'Einträge', valueKey: WidgetKeys.yearHeatmap)],
  ),
  WidgetCatalogEntry(
    key: 'moodCalendar',
    title: 'Stimmungs-Kalender',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.stat,
    route: '/diary',
    slots: [WidgetSlot(label: 'Stimmung', valueKey: WidgetKeys.moodCalendar)],
  ),
  WidgetCatalogEntry(
    key: 'entriesThisMonth',
    title: 'Einträge/Monat',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.stat,
    route: '/diary',
    slots: [WidgetSlot(label: 'Einträge', valueKey: WidgetKeys.entriesThisMonth)],
  ),
  // ── abstinence ────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'currentStreak',
    title: 'Aktueller Streak',
    accentHex: '#FFAA55',
    template: WidgetTemplate.stat,
    route: '/abstinence',
    slots: [WidgetSlot(label: 'Dauer', valueKey: WidgetKeys.abstinenceDuration)],
  ),
  WidgetCatalogEntry(
    key: 'longestStreak',
    title: 'Längster Streak',
    accentHex: '#FFAA55',
    template: WidgetTemplate.stat,
    route: '/abstinence',
    slots: [WidgetSlot(label: 'Tage', valueKey: WidgetKeys.longestStreak)],
  ),
  WidgetCatalogEntry(
    key: 'moneySaved',
    title: 'Gespart',
    accentHex: '#FFAA55',
    template: WidgetTemplate.stat,
    route: '/abstinence',
    slots: [WidgetSlot(label: 'Gespart', valueKey: WidgetKeys.moneySaved)],
  ),
  WidgetCatalogEntry(
    key: 'allCounters',
    title: 'Alle Counter',
    accentHex: '#FFAA55',
    template: WidgetTemplate.stat,
    route: '/abstinence',
    slots: [WidgetSlot(label: 'Counter', valueKey: WidgetKeys.allCounters)],
  ),
  // ── substances ────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'lastIntake',
    title: 'Letzte Einnahme',
    accentHex: '#0099BB',
    template: WidgetTemplate.stat,
    route: '/substances',
    slots: [WidgetSlot(label: 'Zuletzt', valueKey: WidgetKeys.lastIntake)],
  ),
  WidgetCatalogEntry(
    key: 'takenToday',
    title: 'Heute',
    accentHex: '#0099BB',
    template: WidgetTemplate.stat,
    route: '/substances',
    slots: [WidgetSlot(label: 'Heute', valueKey: WidgetKeys.takenToday)],
  ),
  // ── period ────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'cycleDay',
    title: 'Zyklustag',
    accentHex: '#FF8FAB',
    template: WidgetTemplate.stat,
    route: '/period',
    slots: [WidgetSlot(label: 'Tag', valueKey: WidgetKeys.cycleDay)],
  ),
  WidgetCatalogEntry(
    key: 'nextPeriod',
    title: 'Nächste Periode',
    accentHex: '#FF8FAB',
    template: WidgetTemplate.stat,
    route: '/period',
    slots: [WidgetSlot(label: 'Tage', valueKey: WidgetKeys.nextPeriodDays)],
  ),
  // ── notes ─────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'notesCount',
    title: 'Notizen',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.stat,
    route: '/notes',
    slots: [WidgetSlot(label: 'Notizen', valueKey: WidgetKeys.notesCount)],
  ),
  WidgetCatalogEntry(
    key: 'lastNote',
    title: 'Letzte Notiz',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.stat,
    route: '/notes',
    slots: [WidgetSlot(label: 'Notiz', valueKey: WidgetKeys.lastNote)],
  ),
  WidgetCatalogEntry(
    key: 'pinnedNote',
    title: 'Angepinnt',
    accentHex: '#9B8EC4',
    template: WidgetTemplate.stat,
    route: '/notes',
    slots: [WidgetSlot(label: 'Notiz', valueKey: WidgetKeys.pinnedNote)],
  ),
  // ── map ───────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'placesCount',
    title: 'Orte',
    accentHex: '#3DD68C',
    template: WidgetTemplate.stat,
    route: '/graffitimap',
    slots: [WidgetSlot(label: 'Orte', valueKey: WidgetKeys.placesCount)],
  ),
  WidgetCatalogEntry(
    key: 'lastPhoto',
    title: 'Letztes Foto',
    accentHex: '#3DD68C',
    template: WidgetTemplate.stat,
    route: '/graffitimap',
    slots: [WidgetSlot(label: 'Foto', valueKey: WidgetKeys.lastPhoto)],
  ),
  WidgetCatalogEntry(
    key: 'mapPreview',
    title: 'Karte',
    accentHex: '#3DD68C',
    template: WidgetTemplate.stat,
    route: '/graffitimap',
    slots: [WidgetSlot(label: 'Orte', valueKey: WidgetKeys.mapPreview)],
  ),

  // ══ v2 visual widgets (native-only; nicht in HomeWidgetType) ═══════════════
  // ── general ───────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'dailyGoals', title: 'Tagesziele', accentHex: '#FF6B3D',
    template: WidgetTemplate.ringTrio, route: '/home',
    slots: [
      WidgetSlot(label: 'Schritte', valueKey: WidgetKeys.steps, goalKey: WidgetKeys.stepsGoal),
      WidgetSlot(label: 'Kalorien', valueKey: WidgetKeys.kcal, goalKey: WidgetKeys.kcalGoal),
      WidgetSlot(label: 'Wasser', valueKey: WidgetKeys.waterMl, goalKey: WidgetKeys.waterGoalMl),
    ],
  ),
  WidgetCatalogEntry(
    key: 'morningRoutine', title: 'Morgenroutine', accentHex: '#FF6B3D',
    template: WidgetTemplate.dashboard, route: '/home',
    slots: [
      WidgetSlot(label: 'Wetter', valueKey: WidgetKeys.weatherTemp),
      WidgetSlot(label: 'Termin', valueKey: WidgetKeys.nextAppointment),
      WidgetSlot(label: 'Habits', valueKey: WidgetKeys.habitsDone, goalKey: WidgetKeys.habitsTotal),
      WidgetSlot(label: 'Wasser', valueKey: WidgetKeys.waterMl, goalKey: WidgetKeys.waterGoalMl),
    ],
  ),
  WidgetCatalogEntry(
    key: 'quoteOfDay', title: 'Spruch des Tages', accentHex: '#FF6B3D',
    template: WidgetTemplate.motivation, route: '/home',
    slots: [WidgetSlot(label: 'Spruch', valueKey: WidgetKeys.quote)],
  ),
  WidgetCatalogEntry(
    key: 'celebrate', title: 'Tagesziel', accentHex: '#FF6B3D',
    template: WidgetTemplate.motivation, route: '/home',
    slots: [WidgetSlot(label: 'Ziel', valueKey: WidgetKeys.healthScore)],
  ),
  WidgetCatalogEntry(
    key: 'countdown', title: 'Countdown', accentHex: '#FF6B3D',
    template: WidgetTemplate.motivation, route: '/home',
    slots: [WidgetSlot(label: 'Countdown', valueKey: WidgetKeys.countdownLabel)],
  ),
  // ── health ────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'stepsWeek', title: 'Schritte Woche', accentHex: '#F43F5E',
    template: WidgetTemplate.barChart, route: '/health',
    slots: [WidgetSlot(label: '7 Tage', valueKey: WidgetKeys.stepsWeek)],
  ),
  WidgetCatalogEntry(
    key: 'weightTrendChart', title: 'Gewichtsverlauf', accentHex: '#F43F5E',
    template: WidgetTemplate.sparkline, route: '/health',
    slots: [WidgetSlot(label: 'Gewicht', valueKey: WidgetKeys.weightHistory)],
  ),
  WidgetCatalogEntry(
    key: 'moodWeek', title: 'Stimmung Woche', accentHex: '#F43F5E',
    template: WidgetTemplate.barChart, route: '/health',
    slots: [WidgetSlot(label: 'Stimmung', valueKey: WidgetKeys.moodWeek)],
  ),
  WidgetCatalogEntry(
    key: 'healthRings', title: 'Gesundheitsringe', accentHex: '#F43F5E',
    template: WidgetTemplate.ringTrio, route: '/health',
    slots: [
      WidgetSlot(label: 'Schlaf', valueKey: WidgetKeys.sleepHours, goalKey: WidgetKeys.sleepGoalH),
      WidgetSlot(label: 'Puls', valueKey: WidgetKeys.heartRate),
      WidgetSlot(label: 'Aktiv', valueKey: WidgetKeys.activeMinutes, goalKey: WidgetKeys.activeGoalMin),
    ],
  ),
  WidgetCatalogEntry(
    key: 'sleepWeek', title: 'Schlaf Woche', accentHex: '#F43F5E',
    template: WidgetTemplate.barChart, route: '/health',
    slots: [WidgetSlot(label: 'Schlaf', valueKey: WidgetKeys.sleepWeek)],
  ),
  // ── nutrition ─────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'macroDonut', title: 'Makros', accentHex: '#3DD68C',
    template: WidgetTemplate.donut, route: '/nutrition',
    slots: [WidgetSlot(label: 'P/K/F', valueKey: WidgetKeys.macroSplit)],
  ),
  WidgetCatalogEntry(
    key: 'waterBottle', title: 'Wasser', accentHex: '#3DD68C',
    template: WidgetTemplate.ring, route: '/nutrition',
    slots: [WidgetSlot(label: 'Wasser', valueKey: WidgetKeys.waterMl, goalKey: WidgetKeys.waterGoalMl)],
  ),
  WidgetCatalogEntry(
    key: 'nutritionDash', title: 'Ernährung', accentHex: '#3DD68C',
    template: WidgetTemplate.dashboard, route: '/nutrition',
    slots: [
      WidgetSlot(label: 'kcal', valueKey: WidgetKeys.kcal, goalKey: WidgetKeys.kcalGoal),
      WidgetSlot(label: 'Protein', valueKey: WidgetKeys.protein),
      WidgetSlot(label: 'Wasser', valueKey: WidgetKeys.waterMl),
      WidgetSlot(label: 'Mahlzeit', valueKey: WidgetKeys.lastMeal),
    ],
  ),
  WidgetCatalogEntry(
    key: 'mealsTodayList', title: 'Mahlzeiten', accentHex: '#3DD68C',
    template: WidgetTemplate.list, route: '/nutrition',
    slots: [WidgetSlot(label: 'Mahlzeiten', valueKey: WidgetKeys.mealsTodayList)],
  ),
  // ── training ──────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'trainingDash', title: 'Training', accentHex: '#5B6CF9',
    template: WidgetTemplate.dashboard, route: '/training',
    slots: [
      WidgetSlot(label: 'Nächstes', valueKey: WidgetKeys.nextWorkout),
      WidgetSlot(label: 'Volumen', valueKey: WidgetKeys.weeklyVolume),
      WidgetSlot(label: 'Streak', valueKey: WidgetKeys.trainingStreak),
    ],
  ),
  WidgetCatalogEntry(
    key: 'volumeWeek', title: 'Volumen Woche', accentHex: '#5B6CF9',
    template: WidgetTemplate.barChart, route: '/training',
    slots: [WidgetSlot(label: 'Volumen', valueKey: WidgetKeys.volumeWeek)],
  ),
  // ── planning ──────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'habitWeek', title: 'Habit-Woche', accentHex: '#F5A623',
    template: WidgetTemplate.barChart, route: '/planning',
    slots: [WidgetSlot(label: 'Woche', valueKey: WidgetKeys.habitWeek)],
  ),
  WidgetCatalogEntry(
    key: 'todayAgenda', title: 'Heute', accentHex: '#F5A623',
    template: WidgetTemplate.list, route: '/planning',
    slots: [WidgetSlot(label: 'Heute', valueKey: WidgetKeys.todayAgenda)],
  ),
  // ── budget ────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'budgetDash', title: 'Budget-Übersicht', accentHex: '#00D4D4',
    template: WidgetTemplate.dashboard, route: '/budget',
    slots: [
      WidgetSlot(label: 'Saldo', valueKey: WidgetKeys.balanceMonth),
      WidgetSlot(label: 'Ausgaben', valueKey: WidgetKeys.budgetSpent, goalKey: WidgetKeys.budgetLimit),
      WidgetSlot(label: 'Einnahmen', valueKey: WidgetKeys.income),
      WidgetSlot(label: 'Top', valueKey: WidgetKeys.topCategory),
    ],
  ),
  WidgetCatalogEntry(
    key: 'monthTrendChart', title: 'Monats-Trend', accentHex: '#00D4D4',
    template: WidgetTemplate.sparkline, route: '/budget',
    slots: [WidgetSlot(label: 'Monat', valueKey: WidgetKeys.monthTrendSeries)],
  ),
  WidgetCatalogEntry(
    key: 'categoryDonut', title: 'Kategorien', accentHex: '#00D4D4',
    template: WidgetTemplate.donut, route: '/budget',
    slots: [WidgetSlot(label: 'Kategorien', valueKey: WidgetKeys.categorySplit)],
  ),
  // ── diary ─────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'diaryDash', title: 'Tagebuch', accentHex: '#9B8EC4',
    template: WidgetTemplate.dashboard, route: '/diary',
    slots: [
      WidgetSlot(label: 'Streak', valueKey: WidgetKeys.writeStreak),
      WidgetSlot(label: 'Letzter', valueKey: WidgetKeys.lastEntry),
      WidgetSlot(label: 'Monat', valueKey: WidgetKeys.entriesThisMonth),
    ],
  ),
  // ── abstinence ────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'abstinenceDash', title: 'Counter', accentHex: '#FFAA55',
    template: WidgetTemplate.list, route: '/abstinence',
    slots: [WidgetSlot(label: 'Counter', valueKey: WidgetKeys.counters)],
  ),
  // ── substances ────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'substancesDash', title: 'Mittel', accentHex: '#0099BB',
    template: WidgetTemplate.dashboard, route: '/substances',
    slots: [
      WidgetSlot(label: 'Zuletzt', valueKey: WidgetKeys.lastIntake),
      WidgetSlot(label: 'Heute', valueKey: WidgetKeys.takenToday),
    ],
  ),
  // ── period ────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'cycleRing', title: 'Zyklus', accentHex: '#FF8FAB',
    template: WidgetTemplate.ring, route: '/period',
    slots: [WidgetSlot(label: 'Zyklustag', valueKey: WidgetKeys.cycleDay, goalKey: WidgetKeys.cycleLenDays)],
  ),
  // ── notes ─────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'pinnedNoteCard', title: 'Angepinnt', accentHex: '#9B8EC4',
    template: WidgetTemplate.motivation, route: '/notes',
    slots: [WidgetSlot(label: 'Notiz', valueKey: WidgetKeys.pinnedNote)],
  ),
  // ── map ───────────────────────────────────────────────────────────────────
  WidgetCatalogEntry(
    key: 'mapDash', title: 'Karte', accentHex: '#3DD68C',
    template: WidgetTemplate.dashboard, route: '/graffitimap',
    slots: [
      WidgetSlot(label: 'Orte', valueKey: WidgetKeys.placesCount),
      WidgetSlot(label: 'Foto', valueKey: WidgetKeys.lastPhoto),
    ],
  ),
];

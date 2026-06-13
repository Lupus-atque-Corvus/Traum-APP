import 'widget_keys.dart';

/// Render-Vorlage eines Widgets. Wird in Kotlin/Swift gespiegelt.
enum WidgetTemplate { stat, progress, dualStat, list, overview }

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

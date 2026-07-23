import 'home_tile.dart';

/// Signatur-Widgets je Modul, die beim Onboarding ins Start-Home-Layout
/// aufgenommen werden, wenn der Nutzer das Modul als Interesse wählt.
const Map<String, List<HomeWidgetType>> _kModuleSignatureWidgets = {
  'health': [HomeWidgetType.healthSnapshot],
  'nutrition': [HomeWidgetType.caloriesRing, HomeWidgetType.water],
  'training': [HomeWidgetType.nextWorkout],
  'substances': [HomeWidgetType.takenToday],
  'planning': [HomeWidgetType.openTodos, HomeWidgetType.habitsToday],
  'abstinence': [HomeWidgetType.currentStreak],
  'budget': [HomeWidgetType.incomeExpense],
  'diary': [HomeWidgetType.lastEntry],
  'notes': [HomeWidgetType.lastNote],
  'graffitiMap': [HomeWidgetType.mapPreview],
  'period': [HomeWidgetType.cycleDay],
};

/// Standardgröße je Widget-Typ; unbekannte → small.
HomeTileSize _sizeFor(HomeWidgetType t) {
  switch (t) {
    case HomeWidgetType.healthSnapshot:
    case HomeWidgetType.incomeExpense:
    case HomeWidgetType.openTodos:
    case HomeWidgetType.habitsToday:
    case HomeWidgetType.lastEntry:
    case HomeWidgetType.lastNote:
    case HomeWidgetType.mapPreview:
      return HomeTileSize.wide;
    default:
      return HomeTileSize.small;
  }
}

/// Baut ein an die gewählten Module angepasstes Start-Home-Layout.
/// Leere Auswahl → bestehendes [defaultHomeLayout].
List<HomeTile> seededLayoutForModules(Set<String> modules) {
  if (modules.isEmpty) return defaultHomeLayout();
  final tiles = <HomeTile>[
    const HomeTile(type: HomeWidgetType.clockDate, size: HomeTileSize.wide),
    const HomeTile(type: HomeWidgetType.dailyScore, size: HomeTileSize.small),
  ];
  final seen = <HomeWidgetType>{
    HomeWidgetType.clockDate,
    HomeWidgetType.dailyScore,
  };
  for (final module in modules) {
    final widgets = _kModuleSignatureWidgets[module];
    if (widgets == null) continue;
    for (final w in widgets) {
      if (seen.add(w)) tiles.add(HomeTile(type: w, size: _sizeFor(w)));
    }
  }
  return tiles;
}

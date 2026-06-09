import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_tile.dart';
import 'widgets/general_widgets.dart';
import 'widgets/health_widgets.dart';
import 'widgets/nutrition_widgets.dart';
import 'widgets/training_widgets.dart';
import 'widgets/planning_widgets.dart';
import 'widgets/budget_widgets.dart';
import 'widgets/diary_widgets.dart';
import 'widgets/misc_widgets.dart';

/// Baut den Inhalt eines Widgets für die gegebene Größe.
typedef HomeWidgetBuilder = Widget Function(
    BuildContext context, WidgetRef ref, HomeTileSize size);

class HomeWidgetDescriptor {
  final String title;
  final HomeWidgetGroup group;
  final Color accent;
  final HomeTileSize defaultSize;
  final Set<HomeTileSize> sizes;
  final String? route;
  final HomeWidgetBuilder builder;

  const HomeWidgetDescriptor({
    required this.title,
    required this.group,
    required this.accent,
    required this.defaultSize,
    required this.sizes,
    required this.route,
    required this.builder,
  });
}

final Map<HomeWidgetType, HomeWidgetDescriptor> homeWidgetRegistry = {
  ...generalHomeWidgets,
  ...healthHomeWidgets,
  ...nutritionHomeWidgets,
  ...trainingHomeWidgets,
  ...planningHomeWidgets,
  ...budgetHomeWidgets,
  ...diaryHomeWidgets,
  ...miscHomeWidgets,
};

HomeWidgetDescriptor? descriptorFor(HomeWidgetType type) =>
    homeWidgetRegistry[type];

/// Nächste erlaubte Größe (zyklisch) für den Resize-Button.
HomeTileSize nextSize(HomeWidgetType type, HomeTileSize current) {
  final d = homeWidgetRegistry[type];
  if (d == null || d.sizes.isEmpty) return current;
  final ordered = HomeTileSize.values.where(d.sizes.contains).toList();
  final i = ordered.indexOf(current);
  return ordered[(i + 1) % ordered.length];
}

const List<HomeWidgetGroup> homeWidgetGroupOrder = HomeWidgetGroup.values;

String homeWidgetGroupLabel(HomeWidgetGroup g) => switch (g) {
      HomeWidgetGroup.general => 'Allgemein',
      HomeWidgetGroup.health => 'Gesundheit',
      HomeWidgetGroup.nutrition => 'Ernährung',
      HomeWidgetGroup.training => 'Training',
      HomeWidgetGroup.planning => 'Planung',
      HomeWidgetGroup.budget => 'Budget',
      HomeWidgetGroup.diary => 'Tagebuch',
      HomeWidgetGroup.abstinence => 'Abstinenz',
      HomeWidgetGroup.substances => 'Substanzen',
      HomeWidgetGroup.period => 'Periode',
      HomeWidgetGroup.notes => 'Notizen',
      HomeWidgetGroup.map => 'Graffiti Map',
    };

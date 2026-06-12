import 'widget_keys.dart';

/// Vollständiger Datenstand für die Homescreen-Widgets.
class WidgetSnapshot {
  final int steps;
  final int stepsGoal;
  final double sleepHours;
  final int heartRate;
  final int mood;
  final int kcal;
  final int kcalGoal;
  final int waterMl;
  final int waterGoalMl;
  final int protein;
  final int proteinGoal;
  final String nextTodo;

  const WidgetSnapshot({
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
  });

  factory WidgetSnapshot.empty() => const WidgetSnapshot(
        steps: 0, stepsGoal: 10000,
        sleepHours: 0, heartRate: 0, mood: 0,
        kcal: 0, kcalGoal: 2200,
        waterMl: 0, waterGoalMl: 2500,
        protein: 0, proteinGoal: 150,
        nextTodo: '',
      );

  /// Flache String-Map fürs Schreiben in den Group-Store.
  Map<String, String> toStringMap() => {
        WidgetKeys.steps: '$steps',
        WidgetKeys.stepsGoal: '$stepsGoal',
        WidgetKeys.sleepHours: _trimDouble(sleepHours),
        WidgetKeys.heartRate: '$heartRate',
        WidgetKeys.mood: '$mood',
        WidgetKeys.kcal: '$kcal',
        WidgetKeys.kcalGoal: '$kcalGoal',
        WidgetKeys.waterMl: '$waterMl',
        WidgetKeys.waterGoalMl: '$waterGoalMl',
        WidgetKeys.protein: '$protein',
        WidgetKeys.proteinGoal: '$proteinGoal',
        WidgetKeys.nextTodo: nextTodo,
      };

  static String _trimDouble(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

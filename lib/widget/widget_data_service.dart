import 'package:home_widget/home_widget.dart';

class WidgetDataService {
  static const String _appGroupId = 'group.de.traum.widgets';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateAll({
    int steps = 0,
    int stepsGoal = 10000,
    double calories = 0,
    int caloriesGoal = 2000,
    int waterMl = 0,
    int waterGoalMl = 2500,
    double protein = 0,
    int proteinGoal = 150,
    double sleepHours = 0,
    String nextTodo = '',
    String abstinenceTitle = '',
    String abstinenceDuration = '',
    String periodDaysLabel = '',
    double budgetSpent = 0,
    double budgetLimit = 1500,
    int habitsCompleted = 0,
    int habitsTotal = 0,
    int medsTaken = 0,
    int medsTotal = 0,
    String nextAppointment = '',
    int heartRate = 0,
    int mood = 0,
  }) async {
    final data = {
      'steps': steps,
      'stepsGoal': stepsGoal,
      'calories': calories,
      'caloriesGoal': caloriesGoal,
      'waterMl': waterMl,
      'waterGoalMl': waterGoalMl,
      'protein': protein,
      'proteinGoal': proteinGoal,
      'sleepHours': sleepHours,
      'nextTodo': nextTodo,
      'abstinenceTitle': abstinenceTitle,
      'abstinenceDuration': abstinenceDuration,
      'periodDaysLabel': periodDaysLabel,
      'budgetSpent': budgetSpent,
      'budgetLimit': budgetLimit,
      'habitsCompleted': habitsCompleted,
      'habitsTotal': habitsTotal,
      'medsTaken': medsTaken,
      'medsTotal': medsTotal,
      'nextAppointment': nextAppointment,
      'heartRate': heartRate,
      'mood': mood,
    };

    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData(entry.key, entry.value);
    }

    await HomeWidget.updateWidget(
      androidName: 'TraumOverviewWidgetProvider',
      iOSName: 'TraumOverviewWidget',
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/traum_database.dart';

final databaseProvider = Provider<TraumDatabase>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final planningDaoProvider = Provider<PlanningDao>((ref) {
  return ref.watch(databaseProvider).planningDao;
});

final trainingDaoProvider = Provider<TrainingDao>((ref) {
  return ref.watch(databaseProvider).trainingDao;
});

final healthDaoProvider = Provider<HealthDao>((ref) {
  return ref.watch(databaseProvider).healthDao;
});

final nutritionDaoProvider = Provider<NutritionDao>((ref) {
  return ref.watch(databaseProvider).nutritionDao;
});

final supplementDaoProvider = Provider<SupplementDao>((ref) {
  return ref.watch(databaseProvider).supplementDao;
});

final medicationDaoProvider = Provider<MedicationDao>((ref) {
  return ref.watch(databaseProvider).medicationDao;
});

final abstinenceDaoProvider = Provider<AbstinenceDao>((ref) {
  return ref.watch(databaseProvider).abstinenceDao;
});

final budgetDaoProvider = Provider<BudgetDao>((ref) {
  return ref.watch(databaseProvider).budgetDao;
});

final periodDaoProvider = Provider<PeriodDao>((ref) {
  return ref.watch(databaseProvider).periodDao;
});

// ─── Supplement ───────────────────────────────────────────────────────────────
final supplementsStreamProvider = StreamProvider.autoDispose<List<Supplement>>((ref) =>
    ref.watch(supplementDaoProvider).watchAllSupplements());

// ─── Abstinence ───────────────────────────────────────────────────────────────
final abstinenceTrackersStreamProvider = StreamProvider.autoDispose<List<AbstinenceTracker>>((ref) =>
    ref.watch(abstinenceDaoProvider).watchAllTrackers());

// ─── Medication ───────────────────────────────────────────────────────────────
final allMedicationsStreamProvider = StreamProvider.autoDispose<List<Medication>>((ref) =>
    ref.watch(medicationDaoProvider).watchAllMedications());

final medicationLogsForDateProvider = StreamProvider.autoDispose.family<List<MedicationLog>, DateTime>((ref, date) =>
    ref.watch(medicationDaoProvider).watchLogsForDate(date));

// ─── Planning ─────────────────────────────────────────────────────────────────
final allAppointmentsStreamProvider = StreamProvider.autoDispose<List<Appointment>>((ref) =>
    ref.watch(planningDaoProvider).watchAllAppointments());

final appointmentsForDateProvider = StreamProvider.autoDispose.family<List<Appointment>, DateTime>((ref, date) =>
    ref.watch(planningDaoProvider).watchAppointmentsForDate(date));

final allTodosStreamProvider = StreamProvider.autoDispose<List<Todo>>((ref) =>
    ref.watch(planningDaoProvider).watchAllTodos());

final allGoalsStreamProvider = StreamProvider.autoDispose<List<Goal>>((ref) =>
    ref.watch(planningDaoProvider).watchAllGoals());

final allHabitsStreamProvider = StreamProvider.autoDispose<List<Habit>>((ref) =>
    ref.watch(planningDaoProvider).watchAllHabits());

final habitLogsForDateProvider = StreamProvider.autoDispose.family<List<HabitLog>, DateTime>((ref, date) =>
    ref.watch(planningDaoProvider).watchHabitLogsForDate(date));

final habitLogsLast7DaysProvider = FutureProvider.autoDispose.family<List<HabitLog>, int>((ref, habitId) =>
    ref.watch(planningDaoProvider).getHabitLogsForLast7Days(habitId));

// ─── Budget ───────────────────────────────────────────────────────────────────
final allBudgetCategoriesStreamProvider = StreamProvider.autoDispose<List<BudgetCategory>>((ref) =>
    ref.watch(budgetDaoProvider).watchAllCategories());

final transactionsForMonthProvider = StreamProvider.autoDispose.family<List<Transaction>, (int, int)>((ref, ym) =>
    ref.watch(budgetDaoProvider).watchTransactionsForMonth(ym.$1, ym.$2));

// ─── Nutrition ────────────────────────────────────────────────────────────────
final nutritionLogsForDateProvider = StreamProvider.autoDispose.family<List<NutritionLog>, DateTime>((ref, date) =>
    ref.watch(nutritionDaoProvider).watchLogsForDate(date));

final waterForDateProvider = StreamProvider.autoDispose.family<List<WaterLog>, DateTime>((ref, date) =>
    ref.watch(nutritionDaoProvider).watchWaterForDate(date));

// ─── Profile / Health ─────────────────────────────────────────────────────────
final latestWeightProvider = FutureProvider.autoDispose<WeightLog?>((ref) =>
    ref.watch(healthDaoProvider).getLatestWeight());

final recentSleepLogsProvider = FutureProvider.autoDispose.family<List<SleepLog>, int>((ref, days) =>
    ref.watch(healthDaoProvider).getRecentSleepLogs(days));

final latestMoodProvider = FutureProvider.autoDispose<MoodLog?>((ref) =>
    ref.watch(healthDaoProvider).getLatestMood());

final recentTrainingSetsProvider = FutureProvider.autoDispose.family<List<WorkoutSet>, int>((ref, days) =>
    ref.watch(trainingDaoProvider).getRecentSets(Duration(days: days)));

final trainingSessionsThisWeekProvider = FutureProvider.autoDispose<List<WorkoutSession>>((ref) =>
    ref.watch(trainingDaoProvider).getSessionsThisWeek());

final allWeightLogsStreamProvider = StreamProvider.autoDispose<List<WeightLog>>((ref) =>
    ref.watch(healthDaoProvider).watchAllWeightLogs());

final allSleepLogsStreamProvider = StreamProvider.autoDispose<List<SleepLog>>((ref) =>
    ref.watch(healthDaoProvider).watchAllSleepLogs());

final allMeasurementsStreamProvider = StreamProvider.autoDispose<List<BodyMeasurement>>((ref) =>
    ref.watch(healthDaoProvider).watchAllMeasurements());

final allMoodLogsStreamProvider = StreamProvider.autoDispose<List<MoodLog>>((ref) =>
    ref.watch(healthDaoProvider).watchAllMoodLogs());

// ─── Training ─────────────────────────────────────────────────────────────────
final allExercisesStreamProvider = StreamProvider.autoDispose<List<Exercise>>((ref) =>
    ref.watch(trainingDaoProvider).watchAllExercises());

final allWorkoutPlansStreamProvider = StreamProvider.autoDispose<List<WorkoutPlan>>((ref) =>
    ref.watch(trainingDaoProvider).watchAllPlans());

final workoutDaysForPlanProvider = StreamProvider.autoDispose.family<List<WorkoutDay>, int>((ref, planId) =>
    ref.watch(trainingDaoProvider).watchDaysForPlan(planId));

final setsForSessionProvider = StreamProvider.autoDispose.family<List<WorkoutSet>, int>((ref, sessionId) =>
    ref.watch(trainingDaoProvider).watchSetsForSession(sessionId));

final dayExercisesProvider = StreamProvider.autoDispose
    .family<List<WorkoutDayExercise>, int>((ref, dayId) =>
        ref.watch(trainingDaoProvider).watchDayExercises(dayId));

final activePlanProvider = FutureProvider.autoDispose<WorkoutPlan?>((ref) =>
    ref.watch(trainingDaoProvider).getActivePlan());

// ─── Nutrition extras ─────────────────────────────────────────────────────────
final allMealTemplatesStreamProvider = StreamProvider.autoDispose<List<MealTemplate>>((ref) =>
    ref.watch(nutritionDaoProvider).watchAllTemplates());

final allShoppingItemsStreamProvider = StreamProvider.autoDispose<List<ShoppingListItem>>((ref) =>
    ref.watch(nutritionDaoProvider).watchAllShoppingItems());

// ─── Period ───────────────────────────────────────────────────────────────────
final allPeriodEntriesStreamProvider = StreamProvider.autoDispose<List<PeriodEntry>>((ref) =>
    ref.watch(periodDaoProvider).watchAllPeriodEntries());

final allPeriodSymptomsStreamProvider = StreamProvider.autoDispose<List<PeriodSymptom>>((ref) =>
    ref.watch(periodDaoProvider).watchAllSymptoms());

// ─── Budget extras ────────────────────────────────────────────────────────────
final allTransactionsStreamProvider = StreamProvider.autoDispose<List<Transaction>>((ref) =>
    ref.watch(budgetDaoProvider).watchAllTransactions());

final allSavingsGoalsStreamProvider = StreamProvider.autoDispose<List<SavingsGoal>>((ref) =>
    ref.watch(budgetDaoProvider).watchAllSavingsGoals());

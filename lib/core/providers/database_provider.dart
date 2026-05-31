import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/traum_database.dart';
import '../../data/models/substance_info.dart';
import '../../data/repositories/substance_repository.dart';
import '../../data/services/substance_api_service.dart';
import '../services/calendar_sync_service.dart';
import '../services/interaction_service.dart';
import '../services/substance_download_service.dart';
import 'preferences_provider.dart';

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

final accountsDaoProvider = Provider<AccountsDao>((ref) {
  return ref.watch(databaseProvider).accountsDao;
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

// ─── Muscle groups for a routine plan (for body map preview) ─────────────────
final planMuscleGroupsProvider = FutureProvider.autoDispose.family<List<String>, int>((ref, planId) async {
  final dao = ref.watch(trainingDaoProvider);
  final days = await dao.getDaysForPlan(planId);
  final allExercises = ref.watch(allExercisesStreamProvider).valueOrNull ?? [];
  final exerciseById = {for (final e in allExercises) e.id: e};
  final Set<String> groups = {};
  for (final day in days) {
    final dayExercises = await dao.getDayExercises(day.id);
    for (final de in dayExercises) {
      final ex = exerciseById[de.exerciseId];
      if (ex != null) groups.add(ex.muscleGroup);
    }
  }
  return groups.toList();
});

// ─── Sessions last 72 h (for muscle heat map) ────────────────────────────────
final sessionsLast72hProvider = FutureProvider.autoDispose<List<WorkoutSession>>((ref) =>
    ref.watch(trainingDaoProvider).getSessionsAfter(
      DateTime.now().subtract(const Duration(hours: 72))
    ));

// ─── Workout streak ───────────────────────────────────────────────────────────
final workoutStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final cutoff = DateTime.now().subtract(const Duration(days: 365));
  final sessions = await ref.watch(trainingDaoProvider).getSessionsAfter(cutoff);
  final trainedDays = sessions
      .where((s) => s.completedAt != null)
      .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
      .toSet();

  int streak = 0;
  var day = DateTime.now();
  day = DateTime(day.year, day.month, day.day);
  while (trainedDays.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
});

final allSavingsGoalsStreamProvider = StreamProvider.autoDispose<List<SavingsGoal>>((ref) =>
    ref.watch(budgetDaoProvider).watchAllSavingsGoals());

final exerciseSetCountsProvider = FutureProvider.autoDispose<Map<int, int>>((ref) =>
    ref.watch(trainingDaoProvider).getExerciseSetCounts());

final exerciseSessionHistoryProvider = FutureProvider.autoDispose
    .family<List<(WorkoutSession, List<WorkoutSet>)>, int>((ref, exerciseId) =>
        ref.watch(trainingDaoProvider).getSessionsWithSetsForExercise(exerciseId));

// ─── Substance ────────────────────────────────────────────────────────────────
final substanceDaoProvider = Provider<SubstanceDao>((ref) =>
    ref.watch(databaseProvider).substanceDao);

final substanceApiServiceProvider = Provider<SubstanceApiService>((_) =>
    SubstanceApiService());

final substanceDatabaseDaoProvider = Provider<SubstanceDatabaseDao>((ref) {
  return ref.watch(databaseProvider).substanceDatabaseDao;
});

final substanceDownloadServiceProvider =
    Provider<SubstanceDownloadService>((ref) {
  return SubstanceDownloadService(ref.watch(substanceDatabaseDaoProvider));
});

final substanceDbAvailableProvider = FutureProvider<bool>((ref) async {
  final count = await ref.watch(substanceDbCountProvider.future);
  return count > 0;
});

final substanceDbCountProvider = FutureProvider<int>((ref) {
  return ref.watch(substanceDatabaseDaoProvider).count();
});

final substanceRepositoryProvider = Provider<SubstanceRepository>((ref) {
  return SubstanceRepository(
    ref.watch(substanceDaoProvider),
    ref.watch(substanceDatabaseDaoProvider),
    ref.watch(substanceApiServiceProvider),
  );
});

final substanceSearchProvider =
    FutureProvider.autoDispose.family<List<SubstanceInfo>, String>((ref, q) =>
        ref.watch(substanceRepositoryProvider).search(q));

final interactionServiceProvider = Provider<InteractionService>((ref) =>
    InteractionService(ref.watch(substanceRepositoryProvider)));

final interactionAlertsProvider =
    FutureProvider.autoDispose<List<InteractionAlert>>((ref) async {
  final supps = ref.watch(supplementsStreamProvider).valueOrNull ?? [];
  final meds = ref.watch(allMedicationsStreamProvider).valueOrNull ?? [];
  final activeNames = [
    ...supps.where((s) => s.isActive).map((s) => s.name),
    ...meds.where((m) => m.isActive).map((m) => m.name),
  ];
  return ref.read(interactionServiceProvider).checkSubstances(activeNames);
});

// ─── Accounts ─────────────────────────────────────────────────────────────────
final accountsStreamProvider = StreamProvider.autoDispose<List<Account>>((ref) =>
    ref.watch(accountsDaoProvider).watchAll());

// ─── Diary ────────────────────────────────────────────────────────────────────
final diaryDaoProvider = Provider<DiaryDao>((ref) {
  return ref.watch(databaseProvider).diaryDao;
});

final foodProductsDaoProvider = Provider<FoodProductsDao>((ref) {
  return ref.watch(databaseProvider).foodProductsDao;
});

final mealEntriesDaoProvider = Provider<MealEntriesDao>((ref) {
  return ref.watch(databaseProvider).mealEntriesDao;
});

// ─── Calendar Sync ────────────────────────────────────────────────────────────
final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  return CalendarSyncService(
    ref.watch(planningDaoProvider),
    ref.watch(preferencesRepositoryProvider),
  );
});

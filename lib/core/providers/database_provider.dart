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

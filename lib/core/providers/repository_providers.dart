import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/planning_repository.dart';
import '../../data/repositories/weather_repository.dart';
import '../../data/repositories/training_repository.dart';
import '../../data/repositories/health_repository.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/supplement_repository.dart';
import '../../data/repositories/medication_repository.dart';
import '../../data/repositories/abstinence_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/period_repository.dart';
import 'database_provider.dart';

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  return PlanningRepository(ref.watch(planningDaoProvider));
});

final trainingRepositoryProvider = Provider<TrainingRepository>((ref) {
  return TrainingRepository(ref.watch(trainingDaoProvider));
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ref.watch(healthDaoProvider));
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(nutritionDaoProvider));
});

final supplementRepositoryProvider = Provider<SupplementRepository>((ref) {
  return SupplementRepository(ref.watch(supplementDaoProvider));
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(ref.watch(medicationDaoProvider));
});

final abstinenceRepositoryProvider = Provider<AbstinenceRepository>((ref) {
  return AbstinenceRepository(ref.watch(abstinenceDaoProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(budgetDaoProvider));
});

final periodRepositoryProvider = Provider<PeriodRepository>((ref) {
  return PeriodRepository(ref.watch(periodDaoProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository();
});

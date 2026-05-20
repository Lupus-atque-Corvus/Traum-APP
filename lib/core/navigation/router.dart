import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/preferences_provider.dart';
import 'routes.dart';
import 'traum_scaffold.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/training/training_screen.dart';
import '../../features/training/active_workout_screen.dart';
import '../../features/training/exercise_library_screen.dart';
import '../../features/training/workout_session_detail_screen.dart';
import '../../features/training/exercise_progress_screen.dart';
import '../../features/training/workout_plan_detail_screen.dart';
import '../../features/training/routines_screen.dart';
import '../../features/training/new_routine_screen.dart';
import '../../features/training/muscle_heatmap_screen.dart';
import '../../features/training/training_wizard_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/health/health_score_detail_screen.dart';
import '../../features/nutrition/nutrition_screen.dart';
import '../../features/nutrition/meal_log_screen.dart';
import '../../features/nutrition/food_search_screen.dart';
import '../../features/nutrition/shopping_list_screen.dart';
import '../../features/supplements/supplement_screen.dart';
import '../../features/planning/planning_screen.dart';
import '../../features/medication/medication_screen.dart';
import '../../features/abstinence/abstinence_screen.dart';
import '../../features/budget/budget_screen.dart';
import '../../features/budget/add_transaction_screen.dart';
import '../../features/budget/transaction_list_screen.dart';
import '../../features/budget/budget_stats_screen.dart';
import '../../features/budget/savings_screen.dart';
import '../../features/period_tracking/period_screen.dart';
import '../../features/period_tracking/period_calendar_screen.dart';
import '../../features/period_tracking/cycle_history_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/lock/biometric_lock_screen.dart';
import '../../features/lock/pin_lock_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(preferencesRepositoryProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      final onboarded = prefs.onboardingComplete;
      final goingToOnboarding = state.matchedLocation == Routes.onboarding;

      if (!onboarded && !goingToOnboarding) return Routes.onboarding;
      if (onboarded && goingToOnboarding) return Routes.home;

      // If onboarded but training setup not done, redirect /training to /training/setup
      final trainingSetupDone = prefs.trainingSetupComplete;
      if (onboarded &&
          !trainingSetupDone &&
          state.matchedLocation == Routes.training) {
        return Routes.trainingSetup;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.biometricLock,
        builder: (_, __) => const BiometricLockScreen(),
      ),
      GoRoute(
        path: Routes.pinEntry,
        builder: (_, __) => const PinLockScreen(),
      ),
      GoRoute(
        path: Routes.trainingSetup,
        builder: (_, __) => const TrainingWizardScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => TraumScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.training,
            builder: (_, __) => const TrainingScreen(),
            routes: [
              GoRoute(
                path: 'active',
                builder: (_, __) => const ActiveWorkoutScreen(),
              ),
              GoRoute(
                path: 'exercises',
                builder: (_, __) => const ExerciseLibraryScreen(),
              ),
              GoRoute(
                path: 'session/:id',
                builder: (_, state) => WorkoutSessionDetailScreen(
                  sessionId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'exercise/:id/progress',
                builder: (_, state) => ExerciseProgressScreen(
                  exerciseId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'plan/:id',
                builder: (_, state) => WorkoutPlanDetailScreen(
                  planId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'routines',
                builder: (_, __) => const RoutinesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const NewRoutineScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: 'heatmap',
                builder: (_, __) => const MuscleHeatmapScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.health,
            builder: (_, __) => const HealthScreen(),
            routes: [
              GoRoute(
                path: 'score-detail',
                builder: (_, __) => const HealthScoreDetailScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.nutrition,
            builder: (_, __) => const NutritionScreen(),
            routes: [
              GoRoute(
                path: 'log',
                builder: (_, __) => const MealLogScreen(),
              ),
              GoRoute(
                path: 'search',
                builder: (_, __) => const FoodSearchScreen(),
              ),
              GoRoute(
                path: 'shopping',
                builder: (_, __) => const ShoppingListScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.supplements,
            builder: (_, __) => const SupplementScreen(),
          ),
          GoRoute(
            path: Routes.planning,
            builder: (_, __) => const PlanningScreen(),
          ),
          GoRoute(
            path: Routes.medication,
            builder: (_, __) => const MedicationScreen(),
          ),
          GoRoute(
            path: Routes.abstinence,
            builder: (_, __) => const AbstinenceScreen(),
          ),
          GoRoute(
            path: Routes.budget,
            builder: (_, __) => const BudgetScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, __) => const AddTransactionScreen(),
              ),
              GoRoute(
                path: 'transactions',
                builder: (_, __) => const TransactionListScreen(),
              ),
              GoRoute(
                path: 'stats',
                builder: (_, __) => const BudgetStatsScreen(),
              ),
              GoRoute(
                path: 'savings',
                builder: (_, __) => const SavingsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.period,
            builder: (_, __) => const PeriodScreen(),
            routes: [
              GoRoute(
                path: 'calendar',
                builder: (_, __) => const PeriodCalendarScreen(),
              ),
              GoRoute(
                path: 'history',
                builder: (_, __) => const CycleHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

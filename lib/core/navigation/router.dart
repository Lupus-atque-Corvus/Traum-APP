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
import '../../features/training/workout_history_screen.dart';
import '../../features/training/training_wizard_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/health/health_score_detail_screen.dart';
import '../../features/nutrition/nutrition_screen.dart';
import '../../features/substances/substances_screen.dart';
import '../../features/planning/planning_screen.dart';
import '../../features/abstinence/abstinence_screen.dart';
import '../../features/budget/budget_categories_screen.dart';
import '../../features/budget/budget_scale.dart';
import '../../features/budget/budget_screen.dart';
import '../../features/budget/transaction_list_screen.dart';
import '../../features/budget/transaction_detail_screen.dart';
import '../../features/budget/budget_stats_screen.dart';
import '../../features/budget/savings_screen.dart';
import '../../features/budget/debts_screen.dart';
import '../../features/budget/recurring_screen.dart';
import '../../features/period_tracking/period_screen.dart';
import '../../features/period_tracking/period_calendar_screen.dart';
import '../../features/period_tracking/cycle_history_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/lock/biometric_lock_screen.dart';
import '../../features/lock/pin_lock_screen.dart';
import '../../features/diary/diary_screen.dart';
import '../../features/diary/diary_entry_screen.dart';
import '../../features/diary/diary_slideshow_screen.dart';
import '../../features/graffiti_map/graffiti_map_screen.dart';
import '../../features/graffiti_map/map_gallery_screen.dart';
import '../../features/graffiti_map/marker_detail_screen.dart';
import '../../features/graffiti_map/create_collection_screen.dart';
import '../../features/graffiti_map/edit_collection_screen.dart';
import '../../features/graffiti_map/edit_location_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/notes/note_detail_screen.dart';
import '../../features/notes/notes_graph_screen.dart';
import '../../features/notes/notes_tags_screen.dart';
import '../../features/notes/notes_search_screen.dart';
import '../../features/notes/notes_daily_screen.dart';
import '../../features/notes/notes_templates_screen.dart';
import '../../features/notes/notes_trash_screen.dart';

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
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.biometricLock,
        builder: (_, _) => const BiometricLockScreen(),
      ),
      GoRoute(path: Routes.pinEntry, builder: (_, _) => const PinLockScreen()),
      GoRoute(
        path: Routes.trainingSetup,
        builder: (_, _) => const TrainingWizardScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => TraumScaffold(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: Routes.notifications,
            builder: (_, _) => const NotificationCenterScreen(),
          ),
          GoRoute(
            path: Routes.training,
            builder: (_, _) => const TrainingScreen(),
            routes: [
              GoRoute(
                path: 'active',
                builder: (_, state) {
                  final dayIdStr = state.uri.queryParameters['dayId'];
                  final dayId = dayIdStr != null ? int.tryParse(dayIdStr) : null;
                  return ActiveWorkoutScreen(dayId: dayId);
                },
              ),
              GoRoute(
                path: 'exercises',
                builder: (_, _) => const ExerciseLibraryScreen(),
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
                builder: (_, _) => const RoutinesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, state) => NewRoutineScreen(
                      initialPlanType: state.uri.queryParameters['type'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'heatmap',
                builder: (_, _) => const MuscleHeatmapScreen(),
              ),
              GoRoute(
                path: 'history',
                builder: (_, _) => const WorkoutHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.health,
            builder: (_, _) => const HealthScreen(),
            routes: [
              GoRoute(
                path: 'score-detail',
                builder: (_, _) => const HealthScoreDetailScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.nutrition,
            builder: (_, _) => const NutritionScreen(),
          ),
          GoRoute(
            path: Routes.substances,
            builder: (_, _) => const SubstancesScreen(),
          ),
          GoRoute(
            path: Routes.supplements,
            redirect: (_, _) => Routes.substances,
          ),
          GoRoute(
            path: Routes.medication,
            redirect: (_, _) => Routes.substances,
          ),
          GoRoute(
            path: Routes.planning,
            builder: (_, _) => const PlanningScreen(),
          ),
          GoRoute(
            path: Routes.abstinence,
            builder: (_, _) => const AbstinenceScreen(),
          ),
          GoRoute(
            path: Routes.budget,
            builder: (_, _) => const BudgetScreen(),
            routes: [
              GoRoute(
                path: 'categories',
                builder: (_, _) =>
                    const BudgetTextScale(child: BudgetCategoriesScreen()),
              ),
              GoRoute(
                path: 'transaction/:id',
                builder: (_, state) => BudgetTextScale(
                  child: TransactionDetailScreen(
                    transactionId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ),
              GoRoute(
                path: 'transactions',
                builder: (_, _) =>
                    const BudgetTextScale(child: TransactionListScreen()),
              ),
              GoRoute(
                path: 'stats',
                builder: (_, _) =>
                    const BudgetTextScale(child: BudgetStatsScreen()),
              ),
              GoRoute(
                path: 'savings',
                builder: (_, _) =>
                    const BudgetTextScale(child: SavingsScreen()),
              ),
              GoRoute(
                path: 'debts',
                builder: (_, _) => const BudgetTextScale(child: DebtsScreen()),
              ),
              GoRoute(
                path: 'recurring',
                builder: (_, _) =>
                    const BudgetTextScale(child: RecurringScreen()),
              ),
            ],
          ),
          GoRoute(
            path: Routes.diary,
            builder: (_, _) => const DiaryScreen(),
            routes: [
              GoRoute(
                path: 'entry/:date',
                builder: (_, state) =>
                    DiaryEntryScreen(date: state.pathParameters['date']!),
              ),
              GoRoute(
                path: 'slideshow',
                builder: (_, _) => const DiarySlideShowScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.period,
            builder: (_, _) => const PeriodScreen(),
            routes: [
              GoRoute(
                path: 'calendar',
                builder: (_, _) => const PeriodCalendarScreen(),
              ),
              GoRoute(
                path: 'history',
                builder: (_, _) => const CycleHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.graffitiMap,
            builder: (_, _) => const GraffitiMapScreen(),
            routes: [
              GoRoute(
                path: 'marker/:id',
                builder: (_, state) => MarkerDetailScreen(
                  markerId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'marker/:id/location',
                builder: (_, state) => EditLocationScreen(
                  markerId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'gallery',
                builder: (_, _) => const MapGalleryScreen(),
              ),
              GoRoute(
                path: 'create',
                builder: (_, _) => const CreateCollectionScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (_, state) => EditCollectionScreen(
                  collectionId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.notes,
            builder: (_, _) => const NotesScreen(),
            routes: [
              GoRoute(
                path: 'note/:id',
                builder: (_, state) => NoteDetailScreen(
                  noteId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'graph',
                builder: (_, _) => const NotesGraphScreen(),
              ),
              GoRoute(path: 'tags', builder: (_, _) => const NotesTagsScreen()),
              GoRoute(
                path: 'search',
                builder: (_, _) => const NotesSearchScreen(),
              ),
              GoRoute(
                path: 'daily',
                builder: (_, _) => const NotesDailyScreen(),
              ),
              GoRoute(
                path: 'templates',
                builder: (_, _) => const NotesTemplatesScreen(),
              ),
              GoRoute(
                path: 'trash',
                builder: (_, _) => const NotesTrashScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

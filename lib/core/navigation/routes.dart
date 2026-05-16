class Routes {
  Routes._();

  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String training = '/training';
  static const String activeWorkout = '/training/active';
  static const String exerciseLibrary = '/training/exercises';
  static const String workoutDetail = '/training/session/:id';
  static const String exerciseProgress = '/training/exercise/:id/progress';
  static const String workoutPlan = '/training/plan/:id';
  static const String routines = '/training/routines';
  static const String newRoutine = '/training/routines/new';
  static const String muscleHeatmap = '/training/heatmap';
  static const String health = '/health';
  static const String healthScoreDetail = '/health/score-detail';
  static const String nutrition = '/nutrition';
  static const String mealLog = '/nutrition/log';
  static const String foodSearch = '/nutrition/search';
  static const String shoppingList = '/nutrition/shopping';
  static const String supplements = '/supplements';
  static const String planning = '/planning';
  static const String medication = '/medication';
  static const String abstinence = '/abstinence';
  static const String budget = '/budget';
  static const String transactionList = '/budget/transactions';
  static const String addTransaction = '/budget/add';
  static const String budgetStats = '/budget/stats';
  static const String savings = '/budget/savings';
  static const String period = '/period';
  static const String periodCalendar = '/period/calendar';
  static const String cycleHistory = '/period/history';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String biometricLock = '/biometric-lock';
  static const String pinEntry = '/pin-entry';

  static String workoutDetailPath(int id) => '/training/session/$id';
  static String exerciseProgressPath(int id) => '/training/exercise/$id/progress';
  static String workoutPlanPath(int id) => '/training/plan/$id';

  static const Map<String, String> moduleRoutes = {
    'home': home,
    'training': training,
    'health': health,
    'nutrition': nutrition,
    'supplements': supplements,
    'planning': planning,
    'medication': medication,
    'abstinence': abstinence,
    'budget': budget,
    'period': period,
    'profile': profile,
    'settings': settings,
  };

  static const Map<String, String> moduleLabels = {
    'home': 'Home',
    'training': 'Training',
    'health': 'Gesundheit',
    'nutrition': 'Ernährung',
    'supplements': 'Supplements',
    'planning': 'Planung',
    'medication': 'Medikamente',
    'abstinence': 'Abstinenz',
    'budget': 'Budget',
    'period': 'Zyklus',
    'profile': 'Profil',
    'settings': 'Einstellungen',
  };
}

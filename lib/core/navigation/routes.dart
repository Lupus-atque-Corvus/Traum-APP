import '../../l10n/app_localizations.dart';

class Routes {
  Routes._();

  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String training = '/training';
  static const String trainingSetup = '/training/setup';
  static const String activeWorkout = '/training/active';
  static const String exerciseLibrary = '/training/exercises';
  static const String workoutDetail = '/training/session/:id';
  static const String exerciseProgress = '/training/exercise/:id/progress';
  static const String workoutPlan = '/training/plan/:id';
  static const String routines = '/training/routines';
  static const String newRoutine = '/training/routines/new';
  static const String muscleHeatmap = '/training/heatmap';
  static const String workoutHistory = '/training/history';
  static const String health = '/health';
  static const String healthScoreDetail = '/health/score-detail';
  static const String nutrition = '/nutrition';
  static const String mealLog = '/nutrition/log';
  static const String foodSearch = '/nutrition/search';
  static const String shoppingList = '/nutrition/shopping';
  static const String substances = '/substances';
  static const String supplements = '/supplements';
  static const String planning = '/planning';
  static const String medication = '/medication';
  static const String abstinence = '/abstinence';
  static const String budget = '/budget';
  static const String diary = '/diary';
  static const String budgetCategories = '/budget/categories';
  static const String transactionList = '/budget/transactions';
  static const String budgetStats = '/budget/stats';
  static const String savings = '/budget/savings';
  static const String debts = '/budget/debts';
  static const String recurring = '/budget/recurring';
  static const String period = '/period';
  static const String periodCalendar = '/period/calendar';
  static const String cycleHistory = '/period/history';
  static const String graffitiMap = '/graffitimap';
  static const String notes = '/notes';
  static const String noteDetail = '/notes/note/:id';
  static const String notesGraph = '/notes/graph';
  static const String notesTags = '/notes/tags';
  static const String notesSearch = '/notes/search';
  static const String notesDaily = '/notes/daily';
  static const String notesTemplates = '/notes/templates';
  static const String notesTrash = '/notes/trash';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String biometricLock = '/biometric-lock';
  static const String pinEntry = '/pin-entry';

  static String noteDetailPath(int id) => '/notes/note/$id';
  static String workoutDetailPath(int id) => '/training/session/$id';
  static String exerciseProgressPath(int id) => '/training/exercise/$id/progress';
  static String workoutPlanPath(int id) => '/training/plan/$id';

  static const Map<String, String> moduleRoutes = {
    'home': home,
    'training': training,
    'health': health,
    'nutrition': nutrition,
    'substances': substances,
    'planning': planning,
    'abstinence': abstinence,
    'budget': budget,
    'diary': diary,
    'graffitiMap': graffitiMap,
    'notes': notes,
    'period': period,
    'profile': profile,
    'settings': settings,
  };

  static String labelFor(String module, AppLocalizations l10n) {
    switch (module) {
      case 'home':
        return l10n.home;
      case 'training':
        return l10n.training;
      case 'health':
        return l10n.health;
      case 'nutrition':
        return l10n.nutrition;
      case 'substances':
        return 'Mittel';
      case 'planning':
        return l10n.planning;
      case 'abstinence':
        return 'Fortschritt';
      case 'budget':
        return l10n.budget;
      case 'diary':
        return l10n.diaryModuleLabel;
      case 'graffitiMap':
        return 'Graffiti Map';
      case 'notes':
        return l10n.notes_title;
      case 'period':
        return l10n.period;
      case 'profile':
        return l10n.profile;
      case 'settings':
        return l10n.settings;
      default:
        return module;
    }
  }
}

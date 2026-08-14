// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get training => 'Training';

  @override
  String get health => 'Health';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get supplements => 'Supplements';

  @override
  String get planning => 'Planning';

  @override
  String get medication => 'Medication';

  @override
  String get abstinence => 'Abstinence';

  @override
  String get budget => 'Budget';

  @override
  String get period => 'Cycle';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get a11yToggleFavorite => 'Toggle favorite';

  @override
  String get a11yAddSet => 'Add set';

  @override
  String get a11yToggleTorch => 'Toggle flashlight';

  @override
  String get a11yScanBarcode => 'Scan barcode';

  @override
  String get a11yWorkoutHistory => 'Workout history';

  @override
  String get a11ySwitchCamera => 'Switch camera';

  @override
  String get a11yPreviousMonth => 'Previous month';

  @override
  String get a11yNextMonth => 'Next month';

  @override
  String get a11yReceiptPhoto => 'Receipt photo';

  @override
  String get a11yMoreInfo => 'More info';

  @override
  String get a11yToggleCheck => 'Toggle checkbox';

  @override
  String a11yStarRating(int count) {
    return 'Rating: $count stars';
  }

  @override
  String get a11yMapMarker => 'Map marker';

  @override
  String a11yViewPhoto(int index, int total) {
    return 'Photo $index of $total';
  }

  @override
  String get a11yDiaryDayHasEntry => 'Has entry';

  @override
  String get confirm => 'Confirm';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get share => 'Share';

  @override
  String get deleteQuestion => 'Delete?';

  @override
  String errorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get fieldTypeText => 'Text';

  @override
  String get fieldTypeSelect => 'Selection';

  @override
  String get fieldTypeToggle => 'Toggle';

  @override
  String get fieldTypeNumber => 'Number';

  @override
  String get mapEnterName => 'Please enter a name';

  @override
  String get mapStarRating => 'Star rating';

  @override
  String get mapMultiplePhotos => 'Multiple photos per point';

  @override
  String get mapAutoGroupPhotos => 'Group photos automatically';

  @override
  String get mapAddCustomField => 'Add custom field';

  @override
  String get mapCustomField => 'Custom field';

  @override
  String get mapNewEntry => 'New entry';

  @override
  String get mapNotFound => 'Map not found';

  @override
  String get mapEntryNotFound => 'Entry not found';

  @override
  String get mapDeleteEntryConfirm => 'Delete this entry and all its photos?';

  @override
  String get mapAddPhoto => 'Add photo';

  @override
  String get mapEditLocation => 'Adjust location';

  @override
  String get mapSetHere => 'Set here';

  @override
  String get mapStartNavigation => 'Start navigation';

  @override
  String get mapLocationPermissionMissing => 'Location permission missing';

  @override
  String get mapLocationUnavailable => 'Location unavailable';

  @override
  String get mapSearchHashtag => 'Search by #hashtag…';

  @override
  String get mapAddedToExisting => 'Added to existing place';

  @override
  String get workoutAddExercise => 'Add exercise';

  @override
  String get workoutNoExercisesYet => 'No exercises in the workout yet';

  @override
  String get workoutDiscard => 'Discard workout';

  @override
  String get workoutDeleteSet => 'Delete set';

  @override
  String get exerciseInfoTitle => 'Exercise info';

  @override
  String get workoutAddNote => 'Add a note';

  @override
  String get workoutRemoveExercise => 'Remove exercise';

  @override
  String get workoutAddNoteHint => 'Add a note...';

  @override
  String get exerciseSearchHint => 'Search exercises...';

  @override
  String get supersetLabel => 'Superset';

  @override
  String get exerciseFeedbackTitle => 'Feedback on this exercise';

  @override
  String get exerciseNotFound => 'Exercise not found';

  @override
  String get trainingVolume => 'Training volume';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get exerciseTrainToSeeProgress =>
      'Train this exercise to see your progress';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get calendarSyncTitle => 'Calendar sync';

  @override
  String get searchSubstanceHint => 'Search substance…';

  @override
  String noResultsForQuery(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get substanceMedications => 'Medications';

  @override
  String get substanceSupplements => 'Supplements';

  @override
  String get whatToAdd => 'What would you like to add?';

  @override
  String get noSubstancesYet => 'No substances yet';

  @override
  String get addSubstanceHint => 'Tap + to add supplements or\nmedications.';

  @override
  String get unitLabel => 'Unit';

  @override
  String get nutrientForNutrition => 'Nutrient (for nutrition)';

  @override
  String get none => 'none';

  @override
  String get form => 'Form';

  @override
  String get reminderTimes => 'Reminder times';

  @override
  String get logConsumption => 'Log consumption';

  @override
  String get timePoint => 'Time';

  @override
  String get pleaseEnterSubstance => 'Please enter a substance';

  @override
  String get substancesTabMyMeds => 'My Meds';

  @override
  String get substancesTabDatabase => 'Database';

  @override
  String get substancesDisclaimerTitle => 'Before you begin';

  @override
  String get substancesDisclaimerAccept => 'I understand';

  @override
  String get substanceFilterAll => 'All';

  @override
  String get substanceFilterPflanzlich => 'Herbal';

  @override
  String get substanceKlasseMed => 'MED';

  @override
  String get substanceKlasseSupp => 'SUPP';

  @override
  String get substancePflanzlich => 'herbal';

  @override
  String get substanceStatusVollstaendig => 'complete';

  @override
  String get substanceStatusTeilweise => 'partial';

  @override
  String get substanceStatusNurChemie => 'chemistry only';

  @override
  String get substanceSectionEffekt => 'Effect';

  @override
  String get substanceSectionWechselwirkungen => 'Interactions';

  @override
  String get substanceSectionDosierung => 'Dosage';

  @override
  String get substanceSectionChemie => 'Chemistry';

  @override
  String get substanceSectionTopNebenwirkungen => 'Most common side effects';

  @override
  String get substanceFieldBeschreibung => 'Description';

  @override
  String get substanceFieldEffekt => 'Effect / What it\'s for';

  @override
  String get substanceFieldIndikation => 'Indication';

  @override
  String get substanceFieldWarnungen => 'Warnings';

  @override
  String get substanceFieldKontraindikationen => 'Contraindications';

  @override
  String get substanceFieldSpeziellePopulationen => 'Special populations';

  @override
  String get substanceDosisErwachsene => 'Adults';

  @override
  String get substanceDosisKinder => 'Children';

  @override
  String get substanceDosisSenioren => 'Seniors';

  @override
  String get substanceDosisSchwangerschaft => 'Pregnancy/Nursing';

  @override
  String get substanceChemieSummenformel => 'Molecular formula';

  @override
  String get substanceChemieMolekulargewicht => 'Molecular weight';

  @override
  String get substanceKeineAngabe => 'not available';

  @override
  String get substanceWikipediaAttribution =>
      'Contains material from Wikipedia/Wikidata, licensed under CC BY-SA.';

  @override
  String get substanceAddToMyMeds => 'Add to My Meds';

  @override
  String get substanceAddedToMyMeds => 'Added to My Meds';

  @override
  String get substanceAddedShow => 'Show';

  @override
  String get settingsSubstanceDbInfo => 'Substance database';

  @override
  String get substanceTypeMed => 'Medication';

  @override
  String get substanceTypeSupp => 'Supplement';

  @override
  String get substanceLogIntake => 'Log intake';

  @override
  String get substanceDeactivate => 'Deactivate';

  @override
  String get substanceDelete => 'Delete';

  @override
  String get substanceConfirmDeleteTitle => 'Really delete?';

  @override
  String substanceConfirmDeleteBody(String name) {
    return '$name will be permanently removed.';
  }

  @override
  String get substanceSaving => 'Saving…';

  @override
  String get substanceLogIntakeAction => 'Log';

  @override
  String get substanceHintVitaminD3 => 'e.g. Vitamin D3';

  @override
  String get substanceHintIbuprofen => 'e.g. Ibuprofen 400mg';

  @override
  String get substanceHintDosageExample => 'e.g. 400 mg';

  @override
  String get substanceLabelSubstance => 'Substance';

  @override
  String get substanceLabelDosis => 'Dose';

  @override
  String get productNotFound => 'Product not found';

  @override
  String get searchFoodHint => 'Search food...';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get waterUpper => 'WATER';

  @override
  String get weeklyTrend => 'Weekly trend';

  @override
  String get createCustomProduct => 'Create custom product';

  @override
  String get saveFailed => 'Failed to save';

  @override
  String get urgent => 'Urgent';

  @override
  String get bookedAsExpense => 'Booked as expense in Finances ✓';

  @override
  String get bookingFailed => 'Booking failed';

  @override
  String get totalPaidUpper => 'TOTAL PAID';

  @override
  String get shoppingListEmpty => 'Shopping list empty';

  @override
  String get doneUpper => 'DONE';

  @override
  String get deleteCompleted => 'Delete completed';

  @override
  String get estimatedUpper => 'ESTIMATED';

  @override
  String get inStore => 'In store 🛒';

  @override
  String inCartStatus(int inCart, int total) {
    return 'IN CART · REAL · $inCart/$total';
  }

  @override
  String get completeShoppingLabel => '✓  Complete shopping';

  @override
  String estimatedBudgetLabel(String amount) {
    return 'Budget (estimated): $amount';
  }

  @override
  String get listEmpty => 'List is empty';

  @override
  String get saveTemplate => 'Save template';

  @override
  String get templateNameHint => 'e.g. Weekly shopping';

  @override
  String get templates => 'Templates';

  @override
  String get noTemplatesSaved => 'No templates saved yet.';

  @override
  String get nothingLogged => 'Nothing logged yet';

  @override
  String get microNutrientsSupplements => 'Micronutrients & supplements';

  @override
  String get supplementsToday => 'SUPPLEMENTS TODAY';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get noData => 'No data';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingDay => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String get steps => 'Steps';

  @override
  String get calories => 'Calories';

  @override
  String get protein => 'Protein';

  @override
  String get water => 'Water';

  @override
  String get sleep => 'Sleep';

  @override
  String get weight => 'Weight';

  @override
  String get workout => 'Workout';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisMonth => 'This month';

  @override
  String get goal => 'Goal';

  @override
  String get minimum => 'Minimum';

  @override
  String get maximum => 'Maximum';

  @override
  String get streak => 'Streak';

  @override
  String get days => 'Days';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get seconds => 'Seconds';

  @override
  String get allDataOnDevice => 'All data stays on your device.';

  @override
  String get startWorkout => 'Start workout';

  @override
  String get newWorkoutTitle => 'New Workout';

  @override
  String get setTypeNormal => 'Normal set';

  @override
  String get setTypeWarmup => 'Warm-up set';

  @override
  String get setTypeDrop => 'Drop set';

  @override
  String get setTypeFailure => 'Failure set';

  @override
  String lastWorkoutMinutesAgo(int minutes) {
    return 'Last workout $minutes min ago';
  }

  @override
  String lastWorkoutHoursAgo(int hours) {
    return 'Last workout ${hours}h ago';
  }

  @override
  String get lastWorkoutYesterday => 'Last workout yesterday';

  @override
  String lastWorkoutDaysAgo(int days) {
    return 'Last workout $days days ago';
  }

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get ovulation => 'Ovulation';

  @override
  String get cycle_length => 'Cycle length';

  @override
  String get period_length => 'Period length';

  @override
  String get metric => 'Metric';

  @override
  String get imperial => 'Imperial';

  @override
  String get biometric_lock => 'Biometric lock';

  @override
  String get notifications => 'Notifications';

  @override
  String get export_data => 'Export data';

  @override
  String get delete_all_data => 'Delete all data';

  @override
  String get reset_onboarding => 'Repeat onboarding';

  @override
  String get version => 'Version';

  @override
  String get legal => 'Legal';

  @override
  String get privacy_policy => 'Privacy policy';

  @override
  String get terms_of_service => 'Terms of service';

  @override
  String get medical_disclaimer => 'Medical disclaimer';

  @override
  String get open_source_licenses => 'Open source licenses';

  @override
  String get onboarding_privacy_title => 'Privacy & Consent';

  @override
  String get onboarding_body_title => 'Body & Fitness';

  @override
  String get lets_go => 'Let\'s go';

  @override
  String get healthScoreTitle => 'Your Health Score';

  @override
  String get healthScoreDetail => 'What influences your score?';

  @override
  String get healthScoreLabelSehrGut => 'Excellent';

  @override
  String get healthScoreLabelGut => 'Good';

  @override
  String get healthScoreLabelMittel => 'Average';

  @override
  String get healthScoreLabelVerbesserung => 'Needs improvement';

  @override
  String get healthScoreLabelKritisch => 'Critical';

  @override
  String get healthScoreInfluenceFactors => 'Influence Factors';

  @override
  String get healthScoreTodayFocus => 'Today\'s Focus';

  @override
  String get healthScoreDailySummary => 'Daily Summary';

  @override
  String get healthScoreFactorDetails => 'Factor Details';

  @override
  String get healthScoreInsights => 'Insights & Recommendations';

  @override
  String get healthScorePotential => 'Improvement potential';

  @override
  String get healthScoreBalance => 'Overall balance';

  @override
  String get healthScoreBewertungOptimal => 'Optimal';

  @override
  String get healthScoreBewertungGut => 'Good';

  @override
  String get healthScoreBewertungMittel => 'Average';

  @override
  String get healthScoreBewertungSchwach => 'Poor';

  @override
  String get allModulesInNav => 'All modules in navigation';

  @override
  String get adjustNav => 'Customize navigation';

  @override
  String get activeModules => 'Active modules';

  @override
  String get noModulesYet => 'No modules';

  @override
  String get otherModules => 'More modules';

  @override
  String get maxModulesReached => 'Maximum reached';

  @override
  String get exitDialogTitle => 'Exit app?';

  @override
  String get exitDialogContent => 'Do you really want to exit the app?';

  @override
  String get more => 'More';

  @override
  String get customize => 'Customize';

  @override
  String get exit => 'Exit';

  @override
  String relapseAt(String name) {
    return 'Relapse: $name';
  }

  @override
  String get relapseDescription => 'Are you sure you want to report a relapse?';

  @override
  String get confirmRelapse => 'Confirm relapse';

  @override
  String get relapse => 'Relapse';

  @override
  String get daysShort => 'd';

  @override
  String get hoursShort => 'h';

  @override
  String get minutesShort => 'min';

  @override
  String get secondsShort => 's';

  @override
  String get noTrackers => 'No trackers';

  @override
  String get tapToStartTracker => 'Tap to start a tracker';

  @override
  String get startTracker => 'Start tracker';

  @override
  String get whatToAvoid => 'What do you want to avoid?';

  @override
  String get emoji => 'Emoji';

  @override
  String get motivationOptional => 'Motivation (optional)';

  @override
  String get starting => 'Starting...';

  @override
  String get startTrackerButton => 'Start tracker';

  @override
  String get nameRequired => 'Name required';

  @override
  String get startDate => 'Start date';

  @override
  String milestoneProgressCaption(int percent, String milestone) {
    return '$percent% until $milestone';
  }

  @override
  String get allMilestonesReached => 'All milestones reached';

  @override
  String get fieldDescription => 'Description';

  @override
  String get dateLabel => 'Date';

  @override
  String get fieldNoteOptional => 'Note (optional)';

  @override
  String get saving => 'Saving...';

  @override
  String get all => 'All';

  @override
  String get categoryOther => 'Other';

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String get monthShortJan => 'Jan';

  @override
  String get monthShortFeb => 'Feb';

  @override
  String get monthShortMar => 'Mar';

  @override
  String get monthShortApr => 'Apr';

  @override
  String get monthShortMay => 'May';

  @override
  String get monthShortJun => 'Jun';

  @override
  String get monthShortJul => 'Jul';

  @override
  String get monthShortAug => 'Aug';

  @override
  String get monthShortSep => 'Sep';

  @override
  String get monthShortOct => 'Oct';

  @override
  String get monthShortNov => 'Nov';

  @override
  String get monthShortDec => 'Dec';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get statistics => 'Statistics';

  @override
  String get savingsGoals => 'Savings goals';

  @override
  String get totalIncome => 'Total income';

  @override
  String get totalExpense => 'Total expenses';

  @override
  String get last6Months => 'Last 6 months';

  @override
  String get topExpenseCategories => 'Top expense categories';

  @override
  String get reached => 'Reached';

  @override
  String remainingAmount(String remaining, String currency) {
    return '$remaining $currency remaining';
  }

  @override
  String targetDate(String date) {
    return 'Target date: $date';
  }

  @override
  String get deposit => 'Deposit';

  @override
  String get depositAmount => 'Deposit amount';

  @override
  String get fieldName => 'Name';

  @override
  String get createSavingsGoal => 'Create savings goal';

  @override
  String get savingsGoalNameHint => 'e.g. Vacation';

  @override
  String get targetAmountLabel => 'Target amount';

  @override
  String get alreadySaved => 'Already saved';

  @override
  String get targetDateOptional => 'Target date (optional)';

  @override
  String get noDate => 'No date';

  @override
  String get whatSavingFor => 'What are you saving for?';

  @override
  String get pleaseEnterValidTargetAmount =>
      'Please enter a valid target amount';

  @override
  String get allTransactions => 'All transactions';

  @override
  String get noSavingsGoals => 'No savings goals';

  @override
  String get tapToCreateSavingsGoal => 'Tap to create a savings goal';

  @override
  String get motivationExcellent => 'Excellent! Your body is in top shape.';

  @override
  String get motivationGood => 'Great! You\'re on a good track.';

  @override
  String get motivationSolid =>
      'Solid! Small adjustments will get you further.';

  @override
  String get motivationImprove => 'There\'s room for improvement. Start today!';

  @override
  String get motivationAttention =>
      'Your body needs attention. Take action now!';

  @override
  String get hintTraining => 'Plan your next workout and stay active.';

  @override
  String get hintNutrition => 'Focus on balanced meals and enough protein.';

  @override
  String get hintRegeneration => 'Give your body enough sleep and recovery.';

  @override
  String get hintSupplements =>
      'Supplement your diet with targeted supplements.';

  @override
  String get hintMedication => 'Don\'t forget to take your medication.';

  @override
  String get hintMentalStress =>
      'Take time for relaxation and stress reduction.';

  @override
  String get hintDefault => 'Stay consistent and track your goals daily.';

  @override
  String get score => 'Score';

  @override
  String get overview => 'Overview';

  @override
  String get sleepTab => 'Sleep';

  @override
  String get weightTab => 'Weight';

  @override
  String get measurementsTab => 'Measurements';

  @override
  String get moreLabel => 'More';

  @override
  String get tapOnArea => 'Tap on an area';

  @override
  String get strength => 'Strength';

  @override
  String get details => 'Details';

  @override
  String get improve => 'Improve';

  @override
  String get trendLabel => 'Trend';

  @override
  String get noTrendData => 'No trend data';

  @override
  String trendBetter(int diff) {
    return '+$diff pts better';
  }

  @override
  String trendWorse(int diff) {
    return '-$diff pts worse';
  }

  @override
  String balanceDiff(int diff, String best, String worst) {
    return '$diff pts gap between $best and $worst';
  }

  @override
  String get analyze => 'Analyze';

  @override
  String get weekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get noSleepData => 'No sleep data';

  @override
  String get sleepLast7Nights => 'Sleep (last 7 nights)';

  @override
  String avgHours(String hours) {
    return 'Ø $hours h';
  }

  @override
  String entriesRecorded(int n) {
    return '$n entries';
  }

  @override
  String get currentWeight => 'Current weight';

  @override
  String get noEntry => 'No entry';

  @override
  String get moodLastEntry => 'Last mood entry';

  @override
  String get moodVeryBad => 'Very bad';

  @override
  String get moodBad => 'Bad';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodGood => 'Good';

  @override
  String get moodExcellent => 'Excellent';

  @override
  String get weightHistory => 'Weight history';

  @override
  String get entries => 'Entries';

  @override
  String get noWeightEntries => 'No weight entries';

  @override
  String get logWeight => 'Log weight';

  @override
  String get noBodyMeasurements => 'No body measurements';

  @override
  String get currentMeasurements => 'Current measurements';

  @override
  String get editMeasurements => 'Edit measurements';

  @override
  String get chest => 'Chest';

  @override
  String get waist => 'Waist';

  @override
  String get hips => 'Hips';

  @override
  String get thigh => 'Thigh';

  @override
  String get bicep => 'Bicep';

  @override
  String get shoulders => 'Shoulders';

  @override
  String get calf => 'Calf';

  @override
  String get neck => 'Neck';

  @override
  String get bodyFat => 'Body fat';

  @override
  String get logBodyMeasurements => 'Log body measurements';

  @override
  String get logSleep => 'Log sleep';

  @override
  String get fallingAsleep => 'Falling asleep';

  @override
  String get wakingUp => 'Waking up';

  @override
  String get sleepQuality => 'Sleep quality';

  @override
  String waterMin(int ml) {
    return 'Min $ml ml';
  }

  @override
  String get permissionNotifications => 'Notifications';

  @override
  String get permissionLocation => 'Location';

  @override
  String get todos => 'Tasks';

  @override
  String get missingPermissions => 'Missing permissions';

  @override
  String get habits => 'Habits';

  @override
  String permissionsContent(String items) {
    return '$items';
  }

  @override
  String get heartRate => 'Heart rate';

  @override
  String get mood => 'Mood';

  @override
  String get later => 'Later';

  @override
  String get openSettings => 'Open settings';

  @override
  String get documentCouldNotLoad => 'Document could not be loaded';

  @override
  String get appIsLocked => 'App locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get usePin => 'Use PIN';

  @override
  String get unlockReason => 'Unlock TRAUM';

  @override
  String get authFailedTryAgain => 'Authentication failed. Please try again.';

  @override
  String get biometricNotAvailable => 'Biometrics not available';

  @override
  String get biometricNotEnrolled => 'No biometric data enrolled';

  @override
  String get biometricLockedOut => 'Biometrics locked. Please try again later.';

  @override
  String biometricError(String msg) {
    return 'Biometric error: $msg';
  }

  @override
  String get biometricNotAvailableUsePin =>
      'Biometrics not available. Please use PIN.';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String pinLocked(int seconds) {
    return 'Too many failed attempts. Try again in ${seconds}s.';
  }

  @override
  String get activeLabel => 'Active';

  @override
  String get addMedication => 'Add medication';

  @override
  String get editMedication => 'Edit medication';

  @override
  String get dosage => 'Dosage';

  @override
  String timeForMedication(String name) {
    return 'Time for $name';
  }

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get snack => 'Snack';

  @override
  String get searchHint => 'Search...';

  @override
  String get mealType => 'Meal type';

  @override
  String get amountGrams => 'Amount (g)';

  @override
  String get proteinG => 'Protein (g)';

  @override
  String get completed => 'Completed';

  @override
  String get addProduct => 'Add product';

  @override
  String get quantity => 'Quantity';

  @override
  String get kcalPer100g => 'kcal/100g';

  @override
  String get proteinPer100g => 'Protein (g/100g)';

  @override
  String get carbsPer100g => 'Carbs (g/100g)';

  @override
  String get fatPer100g => 'Fat (g/100g)';

  @override
  String get noResults => 'No results';

  @override
  String get search => 'Search';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get welcomeToTraum => 'Welcome to TRAUM';

  @override
  String get startNow => 'Start now';

  @override
  String get yourLifeYourData => 'Your life. Your data.';

  @override
  String get traumDescription =>
      'TRAUM is your personal health dashboard. All data stays on your device.';

  @override
  String get consentReadLeading => 'I have read the';

  @override
  String get consentReadTrailing => 'read and accepted';

  @override
  String get healthDataConsent => 'Health data consent';

  @override
  String get consentAcceptLeading => 'I accept the';

  @override
  String get consentDot => '·';

  @override
  String get consentConfirmLeading => 'I confirm that I';

  @override
  String get ageConsent => 'I am at least 16 years old';

  @override
  String get profileTitle => 'Your Profile';

  @override
  String get yourName => 'Your name';

  @override
  String get sex => 'Sex';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get unitsLabel => 'Units';

  @override
  String get pleaseFillProfile => 'Please fill in your profile';

  @override
  String get heightLabelOnboarding => 'Height (cm)';

  @override
  String get weightLabelOnboarding => 'Weight (kg)';

  @override
  String get weightGoalLabelOnboarding => 'Target weight (kg)';

  @override
  String get dailyStepsGoal => 'Daily step goal';

  @override
  String stepsLabelText(int steps) {
    return '$steps steps';
  }

  @override
  String get yourWaterGoal => 'Your water goal';

  @override
  String waterGoalSummary(int goal, int min, int max) {
    return 'Goal: $goal ml (Min: $min ml, Max: $max ml)';
  }

  @override
  String get nutritionTitleOb => 'Nutrition goals';

  @override
  String get caloriesGoalLabel => 'Calorie goal (kcal)';

  @override
  String get proteinGoalLabelOb => 'Protein goal (g)';

  @override
  String get budgetTitleOb => 'Budget';

  @override
  String get wantToKeepBudget => 'Do you want to manage your budget?';

  @override
  String get monthlyBudget => 'Monthly budget (€)';

  @override
  String get cycleTitleOb => 'Your Cycle';

  @override
  String get cycleLengthLabel => 'Cycle length (days)';

  @override
  String get periodLengthLabel => 'Period length (days)';

  @override
  String get weatherTitleOb => 'Weather location';

  @override
  String get weatherDescription =>
      'TRAUM shows you the current weather on the home screen.';

  @override
  String get requestingLocation => 'Requesting location...';

  @override
  String get allowLocation => 'Allow location';

  @override
  String get notificationsTitleOb => 'Notifications';

  @override
  String get notificationsDescription =>
      'Receive reminders for medication, supplements and more.';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String get notNow => 'Not now';

  @override
  String get healthTitleOb => 'Fitness data';

  @override
  String get healthDescription =>
      'Connect TRAUM to your health app for automatic steps, sleep and heart rate.';

  @override
  String get connecting => 'Connecting...';

  @override
  String get allowAccessImport => 'Allow access & import';

  @override
  String get doneTitleOb => 'All set!';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name!';
  }

  @override
  String summaryGoals(int kcal, int water) {
    return 'Goals: $kcal kcal · $water ml water';
  }

  @override
  String get faceIdActivate => 'Activate Face ID';

  @override
  String get fingerprintActivate => 'Activate fingerprint';

  @override
  String get biometricSetupReason => 'Protect TRAUM with biometrics';

  @override
  String get authFailedShort => 'Authentication failed';

  @override
  String get biometricCouldNotSet => 'Biometrics could not be set up';

  @override
  String get pinsDoNotMatch => 'PINs do not match';

  @override
  String get appSecurity => 'App security';

  @override
  String get protectDataWith => 'Protect your data with';

  @override
  String get unlockAppFastSecure => 'Fast & secure unlock';

  @override
  String get pinSet => 'Set PIN';

  @override
  String get pin4Digit => '4-digit PIN';

  @override
  String get continueWithoutLock => 'Continue without lock';

  @override
  String get pinSetTitle => 'Set PIN';

  @override
  String get pinConfirmTitle => 'Confirm PIN';

  @override
  String get enterPin4Digits => 'Enter 4-digit PIN';

  @override
  String get enterPinAgainConfirm => 'Enter PIN again';

  @override
  String get backToSelection => 'Back to selection';

  @override
  String get addSupplement => 'Add supplement';

  @override
  String get editSupplement => 'Edit supplement';

  @override
  String get category => 'Category';

  @override
  String get fieldUnit => 'Unit';

  @override
  String avgCycleDays(int days) {
    return 'Ø $days d.';
  }

  @override
  String avgDurationDays(int days) {
    return 'Ø $days d.';
  }

  @override
  String get entriesLabel => 'Entries';

  @override
  String get irregularCycle => 'Irregular';

  @override
  String get cycleLengths => 'Cycle lengths';

  @override
  String get periods => 'Periods';

  @override
  String get cycle => 'Cycle';

  @override
  String get tDayUnit => 'd.';

  @override
  String get cycleHistory => 'Cycle history';

  @override
  String get noHistory => 'No history';

  @override
  String get logPeriodsToSeeStats => 'Log periods to see statistics';

  @override
  String get flowLight => 'Light';

  @override
  String get flowMedium => 'Medium';

  @override
  String get flowStrong => 'Heavy';

  @override
  String get flowVeryStrong => 'Very heavy';

  @override
  String get periodBleed => 'Period';

  @override
  String get predictedOvulation => 'Predicted ovulation';

  @override
  String get fertileWindow2 => 'Fertile window';

  @override
  String get predictedPeriodStart => 'Predicted period start';

  @override
  String get noSpecialEvent => 'No special event';

  @override
  String get periodCalendar => 'Cycle calendar';

  @override
  String get symptomsToday => 'Symptoms today';

  @override
  String pregnancyProbabilityToday(int pct) {
    return '$pct% pregnancy probability';
  }

  @override
  String get calendarTooltip => 'Calendar';

  @override
  String get historyTooltip => 'History';

  @override
  String get endPeriod => 'End period';

  @override
  String get startPeriod => 'Start period';

  @override
  String get flowIntensity => 'Intensity';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get savingPeriod => 'Saving...';

  @override
  String get startPeriodButton => 'Start period';

  @override
  String get symptomCramps => 'Cramps';

  @override
  String get symptomHeadache => 'Headache';

  @override
  String get symptomBackPain => 'Back pain';

  @override
  String get symptomBreastTension => 'Breast tenderness';

  @override
  String get symptomBloating => 'Bloating';

  @override
  String get symptomNausea => 'Nausea';

  @override
  String get symptomMoodSwings => 'Mood swings';

  @override
  String get symptomTiredness => 'Fatigue';

  @override
  String get symptomAcne => 'Acne';

  @override
  String get symptomSleepIssues => 'Sleep issues';

  @override
  String get orCustomSymptom => 'or enter custom symptom';

  @override
  String get intensityLabel => 'Intensity';

  @override
  String get intensityLight => 'Light';

  @override
  String get intensityMedium => 'Medium';

  @override
  String get intensityStrong => 'Strong';

  @override
  String get fertileLegend => 'Fertile';

  @override
  String get ovulationLegend => 'Ovulation';

  @override
  String get periodLegend => 'Period';

  @override
  String noAppointmentsOnDate(String date) {
    return 'No appointments on $date';
  }

  @override
  String get addAppointment => 'Add appointment';

  @override
  String get addTodo => 'Add task';

  @override
  String get titleRequiredField => 'Title';

  @override
  String get location => 'Location';

  @override
  String get optional => '(optional)';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'End';

  @override
  String get titleRequired => 'Title required';

  @override
  String get endBeforeStartError => 'End time must be after the start time';

  @override
  String get noTasks => 'No tasks';

  @override
  String get tapToAddTask => 'Tap to add a task';

  @override
  String get open => 'Open';

  @override
  String get finished => 'Done';

  @override
  String dueDateLabel(String date) {
    return 'Due: $date';
  }

  @override
  String get addTask => 'Add task';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldPriority => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get dueDate => 'Due date';

  @override
  String get noGoals => 'No goals';

  @override
  String get addGoal => 'Add goal';

  @override
  String get addTracker => 'Add tracker';

  @override
  String get addSubstance => 'Add substance';

  @override
  String get targetValue => 'Target value';

  @override
  String get unitHintKgKm => 'e.g. kg, km';

  @override
  String get deadline => 'Deadline';

  @override
  String get noHabits => 'No habits';

  @override
  String get tapToAddHabit => 'Tap to add a habit';

  @override
  String get addHabit => 'Add habit';

  @override
  String get frequency => 'Frequency';

  @override
  String get frequencyDaily => 'Daily';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get calendar => 'Calendar';

  @override
  String get todosTab => 'Tasks';

  @override
  String get goalsTab => 'Goals';

  @override
  String get habitsTab => 'Habits';

  @override
  String get habitsCompletedTodayLabel => 'done today';

  @override
  String habitStreakDays(int count) {
    return '$count-day streak';
  }

  @override
  String habitStreakWeeks(int count) {
    return '$count-week streak';
  }

  @override
  String get bmi => 'BMI';

  @override
  String get weightGoalLabel => 'Target weight';

  @override
  String get loseAction => 'lose';

  @override
  String get gainAction => 'gain';

  @override
  String weightDiff(String diff, String action) {
    return '$diff kg to $action';
  }

  @override
  String sleepDays(int days) {
    return 'Last $days days';
  }

  @override
  String get avgSleepDuration => 'Ø sleep duration';

  @override
  String get avgQuality => 'Ø quality';

  @override
  String get trainingThisWeek => 'Training this week';

  @override
  String get workoutsLabel => 'Workouts';

  @override
  String get setsLabel => 'Sets';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get nutritionGoals => 'Nutrition goals';

  @override
  String get kcalGoal => 'kcal goal';

  @override
  String get proteinGoal => 'Protein goal';

  @override
  String get stepsGoal => 'Steps goal';

  @override
  String get moodLabel => 'Mood';

  @override
  String get noMoodData => 'No mood data';

  @override
  String moodLast(int score) {
    return 'Last value: $score/5';
  }

  @override
  String get bmiUnderweight => 'Underweight';

  @override
  String get bmiNormal => 'Normal weight';

  @override
  String get bmiOverweight => 'Overweight';

  @override
  String get bmiObese => 'Obese';

  @override
  String get myProfile => 'My profile';

  @override
  String get myDashboard => 'My dashboard';

  @override
  String get body => 'Body';

  @override
  String get height => 'Height';

  @override
  String get exportSelected => 'Export selected';

  @override
  String get supportSection => 'Support';

  @override
  String get appSection => 'App';

  @override
  String get repeatOnboardingSubtitle => 'Repeat the onboarding process';

  @override
  String get navigationSection => 'Navigation';

  @override
  String get adjustNavSubtitle => 'Choose your modules';

  @override
  String get units => 'Units';

  @override
  String get metricSwitch => 'Metric';

  @override
  String get metricSwitchSubtitle => 'kg, cm, km';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get notificationCenterEmpty => 'All done — nothing open';

  @override
  String get notificationCenterMedsToday => 'Medications today';

  @override
  String notificationCenterMedsStatus(int taken, int active) {
    return '$taken taken · $active active';
  }

  @override
  String get notificationCenterNextAppointment => 'Next appointment';

  @override
  String get notificationCenterOpenTodos => 'Open tasks';

  @override
  String notificationCenterTodosStatus(int count, String title) {
    return '$count open · $title';
  }

  @override
  String get notifMedicationHint =>
      'Set medication and supplement reminders directly on each one under \"My substances\" — not centrally here.';

  @override
  String get notifTraining => 'Training';

  @override
  String get notifWater => 'Water';

  @override
  String get notifHabits => 'Habits';

  @override
  String get notifTodos => 'Tasks';

  @override
  String get notifCycle => 'Cycle';

  @override
  String notifDailyAt(String time) {
    return 'Daily at $time';
  }

  @override
  String get notifPermissionDeniedTitle => 'Notifications disabled';

  @override
  String get notifPermissionDeniedMessage =>
      'Reminders won\'t show up until Traum has notification permission in your system settings.';

  @override
  String get goals => 'Goals';

  @override
  String get kcalGoalLabel => 'Calorie goal';

  @override
  String get proteinGoalLabel => 'Protein goal (g)';

  @override
  String get stepsGoalLabel => 'Step goal';

  @override
  String get stepsGoalSuffix => 'steps';

  @override
  String get heightLabel => 'Height';

  @override
  String get heightCm => 'cm';

  @override
  String get weightGoalCm => 'kg';

  @override
  String get waterGoal => 'Water goal';

  @override
  String waterGoalAutomatic(int ml) {
    return 'Automatic ($ml ml)';
  }

  @override
  String get currency => 'Currency';

  @override
  String get currencySymbol => 'Currency symbol';

  @override
  String get chooseCurrency => 'Choose currency';

  @override
  String get periodTracking => 'Cycle tracking';

  @override
  String get enablePeriodTracking => 'Enable cycle tracking';

  @override
  String get periodTrackingSubtitle => 'Track your cycle';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get biometricLockSubtitle => 'Use biometrics';

  @override
  String get biometricLockUnavailable => 'Biometrics not available';

  @override
  String get pinLock => 'PIN lock';

  @override
  String get pinLockSubtitle => '4-digit PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get languageSection => 'Language';

  @override
  String get appLanguage => 'App language';

  @override
  String get deleteAllConfirmTitle => 'Delete all data?';

  @override
  String get deleteAllConfirmContent => 'This action cannot be undone.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get reallyDeleteAllTitle => 'Really delete everything?';

  @override
  String get reallyDeleteAllContent =>
      'All your data will be permanently deleted.';

  @override
  String get deleteEverything => 'Delete everything';

  @override
  String get exportAll => 'Export all';

  @override
  String get exportSelection => 'Export selection';

  @override
  String get importData => 'Import data';

  @override
  String get backupRunning => 'Creating backup…';

  @override
  String get backupProgressTitle => 'Creating backup…';

  @override
  String get backupProgressBody =>
      'This can take a moment with many photos/videos. Afterwards you\'ll choose where to save it (e.g. Files app, Google Drive, email).';

  @override
  String get importProgressTitle => 'Reading backup…';

  @override
  String get importProgressBody => 'This can take a moment for a large file.';

  @override
  String get backupProgressPhaseTables => 'Reading data…';

  @override
  String get backupProgressPhaseMedia => 'Reading photos/videos…';

  @override
  String get backupProgressPhaseEncoding => 'Packing…';

  @override
  String backupCreated(int rows, int media) {
    return 'Backup created: $rows entries, $media media files';
  }

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get nutritionReport => 'Nutrition report (PDF)';

  @override
  String get nutritionReportRange7 => 'Last 7 days';

  @override
  String get nutritionReportRange30 => 'Last 30 days';

  @override
  String get nutritionReportRangeCustom => 'Choose a date range';

  @override
  String get nutritionReportEmpty => 'No nutrition data in this range';

  @override
  String importDone(int rows, int media) {
    return '$rows entries imported, $media media files restored';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get exercise => 'Exercise';

  @override
  String get muscleBrust => 'Chest';

  @override
  String get muscleRuecken => 'Back';

  @override
  String get muscleSchulter => 'Shoulders';

  @override
  String get muscleBizeps => 'Biceps';

  @override
  String get muscleTrizeps => 'Triceps';

  @override
  String get muscleBauch => 'Abs';

  @override
  String get muscleBeine => 'Legs';

  @override
  String get muscleGesaess => 'Glutes';

  @override
  String get muscleWaden => 'Calves';

  @override
  String get muscleGanzkoerper => 'Full body';

  @override
  String get muscleForearms => 'Forearms';

  @override
  String get muscleCardio => 'Cardio';

  @override
  String get myRoutines => 'My routines';

  @override
  String trainingDayName(String letter) {
    return 'Day $letter';
  }

  @override
  String get trainingDayA => 'Day A';

  @override
  String get newRoutine => 'New routine';

  @override
  String get routineName => 'Routine name';

  @override
  String get routineNameHint => 'e.g. Push Day';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get descriptionHint => 'e.g. Chest & Shoulders';

  @override
  String get setAsActive => 'Set as active';

  @override
  String get trainingDays => 'Training days';

  @override
  String get addDay => 'Add day';

  @override
  String get createRoutineButton => 'Create routine';

  @override
  String get trainingRoutines => 'Training routines';

  @override
  String get noRoutines => 'No routines';

  @override
  String get tapToCreateRoutine => 'Tap to create a routine';

  @override
  String get dailyRoutines => 'Daily Routines';

  @override
  String get morningRoutine => 'Morning Routine';

  @override
  String get eveningRoutine => 'Evening Routine';

  @override
  String get routineTypeWorkout => 'Workout';

  @override
  String get startRoutine => 'Start';

  @override
  String get noRoutinesYet =>
      'No routines yet — create your first morning or evening routine.';

  @override
  String get pickExercisesAfterSave =>
      'After saving you\'ll pick the exercises for this routine right away.';

  @override
  String get activate => 'Activate';

  @override
  String get active => 'Active';

  @override
  String get trainingPlan => 'Training plan';

  @override
  String get noTrainingDays => 'No training days';

  @override
  String get workoutDetails => 'Workout details';

  @override
  String get noSetsRecorded => 'No sets recorded';

  @override
  String setLabel(int n) {
    return 'Set $n';
  }

  @override
  String repsCount(int n) {
    return '$n reps';
  }

  @override
  String setCount(int n) {
    return '$n sets';
  }

  @override
  String get addExercise => 'Add exercise';

  @override
  String get exerciseLibrary => 'Exercise library';

  @override
  String get exerciseHint => 'Exercise name';

  @override
  String get equipmentOptional => 'Equipment (optional)';

  @override
  String get equipmentHint => 'e.g. Dumbbell';

  @override
  String get instructionsOptional => 'Instructions (optional)';

  @override
  String get instructionExecution => 'Execution instruction';

  @override
  String get noExercisesYet => 'No exercises yet';

  @override
  String get muscleGroup => 'Muscle group';

  @override
  String get muscleHeatmapTitle => 'Muscle heatmap';

  @override
  String get recentSets => 'Recent sets';

  @override
  String get much => 'Much';

  @override
  String get restTimerLabel => 'Rest';

  @override
  String get notTrained => 'Not trained';

  @override
  String get progress => 'Progress';

  @override
  String get reps => 'Reps';

  @override
  String get finishing => 'Finishing...';

  @override
  String get exercises => 'Exercises';

  @override
  String get volumeKg => 'Volume (kg)';

  @override
  String get createExercise => 'Create exercise';

  @override
  String get deleteExercise => 'Delete exercise';

  @override
  String get similarExercises => 'Similar exercises';

  @override
  String get timesPerformed => 'Times performed';

  @override
  String get totalDurationLabel => 'Total duration';

  @override
  String get totalVolumeLabel => 'Total volume';

  @override
  String get mostRecent => 'Most recent';

  @override
  String get average => 'Average';

  @override
  String get removeBookmarkAction => 'Remove bookmark';

  @override
  String get addBookmarkAction => 'Add bookmark';

  @override
  String get exerciseFeedbackPrompt => 'Got tips for this exercise?';

  @override
  String get selectCalendars => 'Select calendars';

  @override
  String get noCalendarsFoundHint =>
      'No calendars found.\nPlease close the planner and reopen it.';

  @override
  String get iconLabel => 'Icon';

  @override
  String get homeWidgetClock => 'Clock';

  @override
  String get homeWidgetWeather => 'Weather';

  @override
  String get homeWidgetApps => 'Apps';

  @override
  String get homeWidgetQuickAccess => 'Quick access';

  @override
  String get homeWidgetDailyOverview => 'Daily overview';

  @override
  String get homeWidgetCalendar => 'Calendar';

  @override
  String get addWidgetTitle => 'Add widget';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherFoggy => 'Foggy';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherShowers => 'Showers';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get noFavoriteApps => 'No favorites';

  @override
  String get appSingular => 'app';

  @override
  String get appPlural => 'apps';

  @override
  String get quickActionNote => 'Note';

  @override
  String get quickActionPhoto => 'Photo';

  @override
  String get quickActionExpense => 'Expense';

  @override
  String get waterLogFailed => 'Couldn\'t save water intake';

  @override
  String get cameraCaptureFailed => 'Couldn\'t take photo';

  @override
  String get cameraRecordingFailed => 'Couldn\'t start recording';

  @override
  String get pointCameraAtBarcode => 'Point the camera at the barcode';

  @override
  String get fetchingProduct => 'Looking up product...';

  @override
  String get manualEntry => 'Manual';

  @override
  String get newCustomProductTitle => 'Add new product';

  @override
  String get productNameLabel => 'Name *';

  @override
  String get productNameHint => 'e.g. Homemade Bolognese';

  @override
  String get brandOptionalLabel => 'Brand (optional)';

  @override
  String get brandOptionalHint => 'e.g. Homemade';

  @override
  String get nutrientsPer100g => 'Nutrients per 100g';

  @override
  String get caloriesKcalLabel => 'Calories (kcal)';

  @override
  String get proteinGramLabel => 'Protein (g)';

  @override
  String get carbsGramLabel => 'Carbs (g)';

  @override
  String get fatGramLabel => 'Fat (g)';

  @override
  String get loadingCalendars => 'Loading calendars…';

  @override
  String get noCalendarSelected => 'No calendar selected';

  @override
  String calendarsSelectedCount(int count) {
    return '$count calendars selected';
  }

  @override
  String get syncedCalendarsTitle => 'Synced calendars';

  @override
  String get noModulesSelectedError => 'No modules selected';

  @override
  String get sendFeedbackTitle => 'Send feedback';

  @override
  String get feedbackHelpText => 'Your feedback helps make TRAUM better.';

  @override
  String get feedbackTypeLabel => 'TYPE';

  @override
  String get shortTitleLabel => 'SHORT TITLE';

  @override
  String get feedbackTitleHintBug => 'e.g. \"Water tracking doesn\'t update\"';

  @override
  String get feedbackTitleHintFeature => 'e.g. \"Dark mode for widgets\"';

  @override
  String get feedbackTitleHintImprovement => 'e.g. \"Typo in onboarding\"';

  @override
  String get descriptionSectionLabel => 'DESCRIPTION';

  @override
  String get feedbackDescHintBug =>
      'Describe what happened and how to reproduce it...';

  @override
  String get feedbackDescHintOther =>
      'Describe your idea or suggested improvement...';

  @override
  String get feedbackSystemInfoDisclaimer =>
      'System info (app version, Android version, device) is attached automatically.';

  @override
  String get openGitHubAndSubmit => 'Open GitHub & submit';

  @override
  String get githubSubmitFooter =>
      'Opens GitHub in the browser. A GitHub account is required to submit.';

  @override
  String get feedbackTypeBug => 'Bug';

  @override
  String get feedbackTypeFeature => 'Feature';

  @override
  String get feedbackTypeImprovement => 'Improvement';

  @override
  String get weatherLocationNeededTitle => 'Location access needed';

  @override
  String get weatherLocationNeededContent =>
      'TRAUM needs your location to show the current weather on the home screen.\n\nPlease allow location access in the system settings.';

  @override
  String get continueWithoutWeather => 'Continue without weather';

  @override
  String get medium => 'Medium';

  @override
  String get noExercises => 'No exercises yet';

  @override
  String get wizardSkip => 'Skip';

  @override
  String get wizardNext => 'Next';

  @override
  String get wizardFinish => 'Done';

  @override
  String wizardStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get templateSelectTitle => 'Choose template';

  @override
  String get templateSelectSubtitle =>
      'Choose a proven plan or build your own.';

  @override
  String get daysSelectTitle => 'Training days';

  @override
  String get daysSelectSubtitle => 'Select days and customize the names.';

  @override
  String get exercisesReviewTitle => 'Review exercises';

  @override
  String get exercisesReviewSubtitle => 'Adjust exercises per training day.';

  @override
  String get searchExercise => 'Search exercise...';

  @override
  String get restDay => 'Rest day';

  @override
  String get freeTraining => 'Free workout';

  @override
  String get completedThisWeek => 'Completed';

  @override
  String get plannedThisWeek => 'Planned';

  @override
  String get weeklyVolume => 'Volume';

  @override
  String exercisesToday(int count) {
    return '$count exercises · today';
  }

  @override
  String get sessionNamesLabel => 'Session names';

  @override
  String get bookmarked => 'Bookmarked';

  @override
  String get notTrainedHeatmap => 'Not trained';

  @override
  String get heatmapDays7 => '7 days';

  @override
  String get heatmapDays14 => '14 days';

  @override
  String get heatmapDays30 => '30 days';

  @override
  String get heatmapExercisesIn => 'Exercises in period';

  @override
  String get restTimer => 'Rest';

  @override
  String get restTimerSkip => 'Skip';

  @override
  String get workoutStreak => 'Day streak';

  @override
  String get restDuration => 'Rest duration';

  @override
  String get instructionsLabel => 'Instructions';

  @override
  String get equipmentLabel => 'Equipment';

  @override
  String get difficultyLabel => 'Difficulty';

  @override
  String get detailsLabel => 'Details';

  @override
  String get settingsFeedback => 'Feedback & bug reports';

  @override
  String get settingsFeedbackSubtitle => 'Bug · Feature · Improvement';

  @override
  String get budgetMoreLink => 'More ›';

  @override
  String get budgetScanningReceipt => 'Analysing receipt...';

  @override
  String get budgetSaveAsTemplate => 'Save as template';

  @override
  String get budgetSplitTransaction => 'Split amount';

  @override
  String budgetSplitRemaining(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get budgetTrend => 'Trend';

  @override
  String get budgetIncome => 'Income';

  @override
  String get budgetExpenses => 'Expenses';

  @override
  String get budgetCategories => 'Categories';

  @override
  String get budgetTransactions => 'Transactions';

  @override
  String get budgetSavingGoals => 'Savings goals';

  @override
  String get budgetDebts => 'Debts';

  @override
  String get addDebtItem => 'Add item';

  @override
  String get editDebtItem => 'Edit item';

  @override
  String get debtItemDescription => 'Description';

  @override
  String get debtItemPrice => 'Price';

  @override
  String debtTotalFromItems(int count) {
    return 'Total from $count items';
  }

  @override
  String get budgetAccounts => 'Accounts';

  @override
  String get budgetRecentTransactions => 'Recent transactions';

  @override
  String get budgetTemplateNameHint => 'Template name';

  @override
  String get budgetTemplateSaved => 'Saved as template';

  @override
  String get budgetDeleteTransactionConfirm => 'Delete transaction?';

  @override
  String budgetSplitOriginalAmount(String amount) {
    return 'Original amount: $amount';
  }

  @override
  String get budgetSplitAddPart => 'Add another part';

  @override
  String get budgetSplitConfirm => 'Split';

  @override
  String get budgetTransactionSplitDone => 'Transaction split';

  @override
  String get budgetTransactionNotFound => 'Transaction not found';

  @override
  String get budgetTransferLabel => 'Transfer';

  @override
  String get budgetNoteLabel => 'Note';

  @override
  String get budgetNoteEditHint => 'Tap to edit...';

  @override
  String get budgetPhotoUnavailable => 'Photo unavailable';

  @override
  String get budgetCamera => 'Camera';

  @override
  String get budgetGallery => 'Gallery';

  @override
  String get budgetTransferAccountsRequired =>
      'Select from and to accounts (must differ)';

  @override
  String get budgetInvalidAmount => 'Please enter a valid amount';

  @override
  String amountExceedsMax(String max) {
    return 'Amount must be at most $max';
  }

  @override
  String get budgetDefaultDescriptionExpense => 'Expense';

  @override
  String get budgetDefaultDescriptionIncome => 'Income';

  @override
  String get budgetAmountLabel => 'Amount';

  @override
  String get budgetNoAccount => 'No account';

  @override
  String get budgetFromAccount => 'From';

  @override
  String get budgetToAccount => 'To';

  @override
  String get budgetDayBeforeYesterday => 'Day before yesterday';

  @override
  String get budgetOtherDate => 'Other ▼';

  @override
  String get budgetDescriptionHint => 'Description...';

  @override
  String get budgetReceiptAttachedHint => 'Receipt attached';

  @override
  String get budgetNoteOptionalHint => 'Note (optional)...';

  @override
  String get budgetTemplateNameFieldHint => 'Template name...';

  @override
  String get budgetMonthlyRecurring => 'Monthly recurring';

  @override
  String get budgetRecurringDayLabel => 'On day of the month:';

  @override
  String get budgetNewCategoryTile => 'New';

  @override
  String get budgetTypeExpense => 'Expense';

  @override
  String get budgetTypeIncome => 'Income';

  @override
  String get budgetTypeTransfer => 'Transfer';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get addDebt => 'Add debt';

  @override
  String get debtsScreenTitle => 'Debts';

  @override
  String get noDebtsRecorded => 'No debts recorded';

  @override
  String get creditorLabel => 'Creditor *';

  @override
  String get creditorHint => 'e.g. Bank';

  @override
  String get totalOpenDebts => 'Total open debts';

  @override
  String get payInstallment => 'Pay installment';

  @override
  String get ok => 'OK';

  @override
  String get primaryAccount => 'Primary account';

  @override
  String returnRateLabel(String rate) {
    return 'Return: $rate%';
  }

  @override
  String get deleteAccountConfirmTitle => 'Delete account?';

  @override
  String deleteAccountConfirmContent(String name) {
    return '\"$name\" will be removed. Existing transactions remain.';
  }

  @override
  String get editAccount => 'Edit account';

  @override
  String get addAccount => 'Add account';

  @override
  String get accountTypeChecking => 'Checking account';

  @override
  String get accountTypeSavings => 'Savings account';

  @override
  String get accountTypeCredit => 'Credit card';

  @override
  String get accountTypeInvestment => 'Investment';

  @override
  String get accountNameLabel => 'Name *';

  @override
  String get accountNameHint => 'e.g. Checking';

  @override
  String get bankInstitutionLabel => 'Bank / Institution';

  @override
  String get bankInstitutionHint => 'e.g. Chase';

  @override
  String get accountBalanceLabel => 'Balance *';

  @override
  String get lastFourDigitsLabel => 'Last 4 digits';

  @override
  String get returnRatePercentLabel => 'Return %';

  @override
  String get markAsPrimaryAccount => 'Mark as primary account';

  @override
  String get deleteAccountButton => 'Delete account';

  @override
  String get recurringScreenTitle => 'Recurring';

  @override
  String get noRecurringTransactions => 'No recurring transactions';

  @override
  String get monthlyIncome => 'Monthly income';

  @override
  String get monthlyExpenses => 'Monthly expenses';

  @override
  String recurringDayOfMonth(int day) {
    return 'Every $day of the month';
  }

  @override
  String get editRecurringTitle => 'Edit recurring';

  @override
  String budgetAmountWithCurrencyLabel(String currency) {
    return 'Amount ($currency)';
  }

  @override
  String get descriptionLabel => 'Description';

  @override
  String get budgetOtherCategory => 'Other';

  @override
  String expensesByCategoryLabel(String month) {
    return 'Expenses by category · $month';
  }

  @override
  String get total => 'Total';

  @override
  String get monthlyOverview => 'Monthly overview';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get undo => 'Undo';

  @override
  String get budgetCategoriesScreenTitle => 'Budget categories';

  @override
  String get budgetNoCategoriesHint =>
      'No categories yet.\nTap + to create one.';

  @override
  String get budgetDeleteCategoryConfirm => 'Delete category?';

  @override
  String budgetDeleteCategoryContent(String name) {
    return '\"$name\" will be removed. Existing transactions remain and appear as \"Other\".';
  }

  @override
  String get deleteGoalConfirmTitle => 'Delete goal?';

  @override
  String deleteGoalConfirmContent(String name) {
    return '\"$name\" will be permanently deleted.';
  }

  @override
  String get deleteHabitConfirmTitle => 'Delete habit?';

  @override
  String deleteHabitConfirmContent(String name) {
    return '\"$name\" and its history will be permanently deleted.';
  }

  @override
  String get deleteTrackerConfirmTitle => 'Delete tracker?';

  @override
  String deleteTrackerConfirmContent(String name) {
    return '\"$name\" and its history will be permanently deleted.';
  }

  @override
  String get deleteAppointmentConfirmTitle => 'Delete appointment?';

  @override
  String deleteAppointmentConfirmContent(String name) {
    return '\"$name\" will be permanently deleted.';
  }

  @override
  String get deleteTodoConfirmTitle => 'Delete task?';

  @override
  String deleteTodoConfirmContent(String name) {
    return '\"$name\" will be permanently deleted.';
  }

  @override
  String budgetCategoryLimitLabel(String amount) {
    return 'Limit: $amount / mo.';
  }

  @override
  String get budgetNewCategoryButton => '+ New category';

  @override
  String get budgetEditCategoryTitle => 'Edit category';

  @override
  String get budgetCreateCategoryTitle => 'Create category';

  @override
  String get budgetCategoryNameLabel => 'Name *';

  @override
  String get budgetCategoryNameHint => 'e.g. Groceries';

  @override
  String get budgetMonthlyLimitLabel => 'Monthly limit (optional)';

  @override
  String get budgetTypeLabel => 'Type:';

  @override
  String get budgetAvailableThisMonth => 'Available this month';

  @override
  String get budgetHideAmountAction => 'Hide';

  @override
  String get budgetShowAmountAction => 'Show';

  @override
  String get budgetSavingsRate => 'Savings rate';

  @override
  String budgetDayOfMonth(int day, int daysInMonth) {
    return 'Day $day of $daysInMonth';
  }

  @override
  String budgetDayOfMonthForecast(int day, int daysInMonth) {
    return 'Day $day of $daysInMonth · forecast ';
  }

  @override
  String budgetForecastRemaining(String amount) {
    return '~$amount left';
  }

  @override
  String get budgetTotalBalanceAllAccounts => 'Total balance · all accounts';

  @override
  String get budgetRecurringLabel => 'Recurring';

  @override
  String get budgetSeeAll => 'All ›';

  @override
  String get budgetNoTransactionsYet => 'No transactions yet';

  @override
  String get budgetNoTransactionsHint => 'Tap + New to add one';

  @override
  String get diaryTitle => 'Diary';

  @override
  String get diarySlideshow => 'Slideshow';

  @override
  String get diaryNoteHint => 'Write something about this moment... (optional)';

  @override
  String get diaryRetake => 'Retake';

  @override
  String diaryTotalEntries(int count) {
    return '$count entries';
  }

  @override
  String get diaryRecentEntries => 'Recent entries';

  @override
  String get diaryYearOverview => 'Year overview';

  @override
  String get diaryDeleteTitle => 'Delete entry?';

  @override
  String get diaryDeleteMessage =>
      'The entry and media file will be permanently deleted.';

  @override
  String get diaryModuleLabel => 'Diary';

  @override
  String get diarySwitcherTitle => 'Choose diary';

  @override
  String get diaryNewDiary => 'New diary';

  @override
  String get diaryEditCreateTitle => 'New diary';

  @override
  String get diaryEditEditTitle => 'Edit diary';

  @override
  String get diaryNameLabel => 'Name';

  @override
  String get diaryNameHint => 'e.g. \"Portugal trip\"';

  @override
  String get diaryIconLabel => 'Icon';

  @override
  String get diaryColorLabel => 'Color';

  @override
  String get diaryEnterName => 'Please enter a name';

  @override
  String get diaryDeleteDiaryButton => 'Delete diary';

  @override
  String get diaryDeleteDiaryTitle => 'Delete diary?';

  @override
  String get diaryDeleteDiaryMessage =>
      'The diary and all its entries will be permanently deleted.';

  @override
  String get diaryCannotDeleteLast => 'The last diary can\'t be deleted.';

  @override
  String get cameraOverlayAlignHint => 'Align with the last photo';

  @override
  String get cameraOverlayRefOff => 'No overlay';

  @override
  String get cameraOverlayRefLastPhoto => 'Last photo';

  @override
  String get cameraOverlayRefBodyFull => 'Full body';

  @override
  String get cameraOverlayRefFaceSingle => 'Face';

  @override
  String get cameraOverlayRefFacesTwo => 'Two faces';

  @override
  String get cameraOverlayRefFood => 'Food';

  @override
  String get cameraOverlayRefGenericHint => 'Align with the guide';

  @override
  String get cameraOverlayPermissionDeniedTitle => 'Camera access needed';

  @override
  String get cameraOverlayPermissionDeniedMessage =>
      'Please allow camera and microphone access to take photos and videos.';

  @override
  String get cameraOverlayOpenSettings => 'Open settings';

  @override
  String get cameraOverlayGrantAccess => 'Grant access';

  @override
  String get cameraOverlayModePhoto => 'Photo';

  @override
  String get cameraOverlayModeVideo => 'Video';

  @override
  String get cameraOverlayNoCameraFound => 'No camera found';

  @override
  String get nutritionTitle => 'Nutrition';

  @override
  String get myFoodsSection => 'My foods';

  @override
  String get searchOnlineSection => 'Found online';

  @override
  String get sourceMerged => 'Combined';

  @override
  String get searchOffline => 'Offline — local results only';

  @override
  String get usdaApiKeyLabel => 'USDA API key';

  @override
  String get usdaApiKeyHint => 'Empty = DEMO_KEY (limited rate)';

  @override
  String get notes_title => 'Notes';

  @override
  String get notes_new_folder => 'New folder';

  @override
  String get notes_new_note => 'New note';

  @override
  String get notes_new_template => 'New template';

  @override
  String get notes_toggle_preview => 'Toggle preview';

  @override
  String get notes_toggle_bookmark => 'Toggle bookmark';

  @override
  String get notes_toggle_panel => 'Expand/collapse panel';

  @override
  String get notes_recent => 'Recently edited';

  @override
  String get notes_bookmarks => 'Bookmarks';

  @override
  String get notes_graph => 'Graph';

  @override
  String get notes_tags => 'Tags';

  @override
  String get notes_search => 'Search';

  @override
  String get notes_daily => 'Daily notes';

  @override
  String get notes_templates => 'Templates';

  @override
  String get notes_trash => 'Trash';

  @override
  String get notes_edit_mode => 'Edit';

  @override
  String get notes_reading_mode => 'Read';

  @override
  String get notes_backlinks => 'Backlinks';

  @override
  String get notes_outgoing_links => 'Outgoing links';

  @override
  String get notes_outline => 'Outline';

  @override
  String get notes_unresolved_links => 'Unresolved links';

  @override
  String get notes_no_backlinks => 'No backlinks';

  @override
  String get notes_no_outgoing_links => 'No outgoing links';

  @override
  String get notes_no_outline => 'No headings';

  @override
  String get notes_move_to_folder => 'Move to folder';

  @override
  String get notes_delete => 'Delete';

  @override
  String get notes_restore => 'Restore';

  @override
  String get notes_delete_permanently => 'Delete permanently';

  @override
  String get notes_word_count => 'words';

  @override
  String get notes_insert_template => 'Insert template';

  @override
  String get notes_export_md => 'Export as .md';

  @override
  String notes_create_note_named(String title) {
    return 'Create \"$title\"';
  }

  @override
  String get notes_rename => 'Rename';

  @override
  String get notes_pin => 'Pin';

  @override
  String get notes_unpin => 'Unpin';

  @override
  String get notes_no_notes => 'No notes yet';

  @override
  String get notes_root => 'Root';

  @override
  String get notes_folder_name => 'Folder name';

  @override
  String get notes_note_title => 'Title';

  @override
  String get notes_template_name => 'Template name';

  @override
  String get notes_no_tags => 'No tags';

  @override
  String get notes_no_templates => 'No templates';

  @override
  String get notes_search_hint => 'Search notes…';

  @override
  String get notes_quick_switcher_hint => 'Find or create note…';

  @override
  String get notes_untitled => 'Untitled';

  @override
  String get notes_import_vault => 'Import vault';

  @override
  String get notes_export_vault => 'Export vault';

  @override
  String get notes_local_graph => 'Local graph';

  @override
  String get notes_full_graph => 'Full graph';

  @override
  String get notes_neighbor_depth => 'Neighbor depth';

  @override
  String get notes_no_daily => 'No daily note for this day';

  @override
  String get notes_cancel => 'Cancel';

  @override
  String get notes_save => 'Save';

  @override
  String get notes_create => 'Create';

  @override
  String get notes_no_results => 'No results';

  @override
  String get notes_confirm_delete_permanently =>
      'Delete note permanently? This cannot be undone.';

  @override
  String get notes_no_trash => 'Trash is empty';

  @override
  String get notes_empty_note_hint => 'Write something in Markdown…';

  @override
  String notes_import_done(int count) {
    return 'Vault imported: $count notes';
  }

  @override
  String get experimentalSection => 'Experimental';

  @override
  String get appLauncher => 'App Launcher';

  @override
  String get appLauncherSubtitle =>
      'Launch favorite apps as tiles in the More menu';

  @override
  String get experimentalBadge => 'EXPERIMENTAL';

  @override
  String get appsSectionTitle => 'Apps';

  @override
  String get addApp => 'Add';

  @override
  String get selectApps => 'Select apps';

  @override
  String get searchApps => 'Search apps…';

  @override
  String get noAppsInstalled => 'No apps found';

  @override
  String get appNotFound => 'App not found';

  @override
  String get removeFromLauncher => 'Remove from launcher';

  @override
  String get setAsLauncher => 'Set as default launcher';

  @override
  String get setAsLauncherActive => 'TRAUM is your default home app';

  @override
  String get setAsLauncherInactive => 'Tap to set TRAUM as your home screen';

  @override
  String get setAsLauncherFailed => 'Couldn\'t open launcher settings';

  @override
  String get graffitiMapChooseMap => 'Choose map';

  @override
  String get graffitiMapNewMap => 'Create new map';

  @override
  String get graffitiMapSinglePhotos => 'Single photos';

  @override
  String get graffitiMapWithRating => 'With rating · multiple photos';

  @override
  String get graffitiMapNote => 'Add note...';

  @override
  String get graffitiMapHashtag => 'Enter hashtag';

  @override
  String get graffitiMapSave => 'Save';

  @override
  String get graffitiMapOverview => 'Overview';

  @override
  String get graffitiMapNoLocation => 'No location';

  @override
  String get mapFieldTowerType => 'Tower type';

  @override
  String get mapFieldTowerHeight => 'Height (m)';

  @override
  String get mapFieldTowerOperator => 'Operator';

  @override
  String get mapOptionDecayed => 'Decayed';

  @override
  String get mapOptionPartiallyPreserved => 'Partially preserved';

  @override
  String get mapOptionWellPreserved => 'Well preserved';

  @override
  String get mapOptionFreelyAccessible => 'Freely accessible';

  @override
  String get mapOptionFence => 'Fence';

  @override
  String get mapOptionLocked => 'Locked';

  @override
  String get mapOptionDangerous => 'Dangerous';

  @override
  String get mapOptionPlanned => 'Planned';

  @override
  String get mapOptionVisited => 'Visited';

  @override
  String get mapOptionRadioMast => 'Radio mast';

  @override
  String get mapOptionTransmissionMast => 'Transmission mast';

  @override
  String get mapOptionOtherType => 'Other';

  @override
  String get mapEditCollectionTitle => 'Edit map';

  @override
  String get mapIconLabel => 'Icon';

  @override
  String get mapColorLabel => 'Color';

  @override
  String get mapGroupRadiusLabel => 'Grouping radius';

  @override
  String get mapAutoGroupDescription =>
      'Nearby photos are grouped into one location';

  @override
  String get mapNameHint => 'Map name…';

  @override
  String get mapLabelHint => 'Label';

  @override
  String get mapOptionsCommaHint => 'Options, comma-separated';

  @override
  String get mapPhotoLabel => 'Photo';

  @override
  String get mapImportLabel => 'Import';

  @override
  String get mapUndoAction => 'Undo';

  @override
  String get mapUnnamedPoint => 'Point';

  @override
  String get mapNameFieldHint => 'Name…';

  @override
  String get mapEnterHint => 'Enter…';

  @override
  String get mapNoEntriesYet => 'No entries yet';

  @override
  String get mapEntryLabel => 'Entry';

  @override
  String get mapNoteLabel => 'Note';

  @override
  String get mapHashtagsLabel => 'Hashtags';

  @override
  String get mapCreateTitle => 'Create new map';

  @override
  String get mapTemplate => 'Choose template';

  @override
  String get mapTemplateGraffiti => 'Graffiti';

  @override
  String get mapTemplateTowers => 'Towers';

  @override
  String get mapTemplateLostPlaces => 'Lost Places';

  @override
  String get mapTemplateCustom => 'Custom map';

  @override
  String get mapFunctions => 'Functions';

  @override
  String get mapFields => 'Fields';

  @override
  String get mapFieldCondition => 'Condition';

  @override
  String get mapFieldAccess => 'Accessibility';

  @override
  String get mapFieldVisited => 'Visit status';

  @override
  String get mapFieldDanger => 'Danger warning';

  @override
  String get mapFieldHidden => 'Private marker';

  @override
  String get mapCreateButton => 'Create map';

  @override
  String mapDistanceFromYou(String distance) {
    return '$distance from you';
  }

  @override
  String get mapTowerName => 'Name';

  @override
  String get mapRating => 'Rating';

  @override
  String get obInterestsTitle => 'Which areas interest you?';

  @override
  String get obInterestsSubtitle =>
      'Pick what you want to use. You can change everything later.';

  @override
  String obInterestsSelected(int count) {
    return '$count selected';
  }

  @override
  String get obTabsTitle => 'Your 4 tabs';

  @override
  String get obTabsSubtitle =>
      'These modules appear in the bottom bar. Home is always on the left.';

  @override
  String get obTabsHint => 'You can change the bar anytime in settings.';

  @override
  String get obTrainingTitle => 'Training';

  @override
  String get obTrainingSubtitle =>
      'Tell us a bit about you – you\'ll build the plan yourself later.';

  @override
  String get obTrainingLevel => 'Experience';

  @override
  String get obLevelBeginner => 'Beginner';

  @override
  String get obLevelIntermediate => 'Intermediate';

  @override
  String get obLevelAdvanced => 'Advanced';

  @override
  String get obTrainingGoalLabel => 'Main goal';

  @override
  String get obGoalMuscle => 'Build muscle';

  @override
  String get obGoalLose => 'Lose weight';

  @override
  String get obGoalFitness => 'Stay fit';

  @override
  String get obTrainingPerWeek => 'Training days per week';

  @override
  String get obAbstinenceTitle => 'Abstinence';

  @override
  String get obAbstinenceSubtitle => 'Track streaks and time or money saved.';

  @override
  String get obAbstinenceFeature1 => 'Live streak since your start date';

  @override
  String get obAbstinenceFeature2 => 'Money saved & time gained';

  @override
  String get obAbstinenceFeature3 => 'Track multiple at once';

  @override
  String get obAbstinenceQuickAdd => 'What do you want to give up? (optional)';

  @override
  String get obAbstinenceHint => 'e.g. smoking, alcohol, sugar';

  @override
  String get obAbstinenceStart => 'Start date';

  @override
  String get obSubstancesTitle => 'Substances';

  @override
  String get obSubstancesSubtitle => 'Keep an eye on intake and interactions.';

  @override
  String get obSubstancesFeature1 => 'Log intake';

  @override
  String get obSubstancesFeature2 => 'Interaction check between substances';

  @override
  String get obSubstancesFeature3 => 'History & frequency';

  @override
  String get obPlanningTitle => 'Planning';

  @override
  String get obPlanningSubtitle =>
      'Tasks, habits and appointments in one place.';

  @override
  String get obPlanningFeature1 => 'To-dos with due dates';

  @override
  String get obPlanningFeature2 => 'Habits in the tracker';

  @override
  String get obPlanningFeature3 => 'Appointments & calendar sync';

  @override
  String get obDiaryTitle => 'Diary';

  @override
  String get obDiarySubtitle => 'Capture moments in photo & video.';

  @override
  String get obDiaryFeature1 => 'One entry per day';

  @override
  String get obDiaryFeature2 => 'Calendar & year heatmap';

  @override
  String get obDiaryFeature3 => 'Look back as a slideshow';

  @override
  String get obNotesTitle => 'Notes';

  @override
  String get obNotesSubtitle => 'Capture and link your thoughts.';

  @override
  String get obNotesFeature1 => 'Markdown with tags';

  @override
  String get obNotesFeature2 => 'Links & graph';

  @override
  String get obNotesFeature3 => 'Daily notes & templates';

  @override
  String get obMapTitle => 'Graffiti map';

  @override
  String get obMapSubtitle => 'Pin places with photos on the map.';

  @override
  String get obMapFeature1 => 'Drop your own places';

  @override
  String get obMapFeature2 => 'Collect photos per place';

  @override
  String get obMapFeature3 => 'Collections & tours';

  @override
  String get obHealthScoreTitle => 'Health score';

  @override
  String get obHealthScoreSubtitle => 'A daily value from all your data.';

  @override
  String get obHealthScoreFeature1 => 'Score from sleep, steps & more';

  @override
  String get obHealthScoreFeature2 => 'Personal insights';

  @override
  String get obHealthScoreFeature3 => 'Radar & history';

  @override
  String get obDashboardTitle => 'Your dashboard';

  @override
  String get obDashboardSubtitle => 'Your home screen is yours.';

  @override
  String get obDashboardFeature1 => 'Add & remove widgets';

  @override
  String get obDashboardFeature2 => 'Move freely in edit mode';

  @override
  String get obDashboardFeature3 => 'Five sizes per tile';

  @override
  String get obDashboardSeeded =>
      'We\'ve already tailored your dashboard to your interests.';

  @override
  String get obUnderstood => 'Got it';

  @override
  String get obBirthDate => 'Date of birth';

  @override
  String get obBirthDatePick => 'Pick date';

  @override
  String get phaseMenstrual => 'Menstruation';

  @override
  String get phaseFollicular => 'Follicular phase';

  @override
  String get phaseFertile => 'Fertile window';

  @override
  String get phaseOvulation => 'Ovulation';

  @override
  String get phaseLuteal => 'Luteal phase';

  @override
  String get logPeriodShort => 'Period';

  @override
  String get logSymptomShort => 'Symptom';

  @override
  String get logTempShort => 'Temp';

  @override
  String get logMore => 'More';

  @override
  String nextPeriodIn(int days) {
    return 'Period in $days days';
  }

  @override
  String predictedRange(Object start, Object end) {
    return 'Likely $start–$end';
  }

  @override
  String get fertileWindowLabel => 'Fertile window';

  @override
  String get ovulationEstimatedLabel => 'Ovulation (estimated)';

  @override
  String get ovulationConfirmedLabel => 'Ovulation (confirmed)';

  @override
  String get loggedToday => 'Logged today';

  @override
  String get nothingLoggedToday => 'Nothing logged yet';

  @override
  String get cycleLengthsTitle => 'Cycle lengths';

  @override
  String cycleLengthsSubtitle(int avg) {
    return 'Avg $avg d · normal 21–35';
  }

  @override
  String get bbtCurveTitle => 'Basal body temperature';

  @override
  String get cycleAnalysisTitle => 'Cycle analysis';

  @override
  String get regularityRegular => 'Regular';

  @override
  String get regularitySlightly => 'Slightly irregular';

  @override
  String get regularityIrregular => 'Irregular';

  @override
  String get regularityUnknown => 'Not enough data';

  @override
  String variabilityDays(int days) {
    return 'Variation ±$days days';
  }

  @override
  String gynAgeYears(int years) {
    return 'Gyn. age: $years y since menarche';
  }

  @override
  String get symptomPatternsTitle => 'Patterns across cycles';

  @override
  String get healthFlagConsistentlyLong =>
      'Several cycles longer than 35 days.';

  @override
  String get healthFlagConsistentlyShort =>
      'Several cycles shorter than 21 days.';

  @override
  String get healthFlagLongPeriod => 'Your period lasts unusually long.';

  @override
  String get healthFlagHighVariability => 'Your cycle length varies a lot.';

  @override
  String get healthAllNormal => 'Everything within normal range.';

  @override
  String get menarcheTitle => 'First period (menarche)';

  @override
  String get menarcheNotSet => 'Not set';

  @override
  String get lutealPhaseTitle => 'Luteal phase length';

  @override
  String get cycleSettingsTitle => 'Cycle settings';

  @override
  String get energyLabel => 'Energy';

  @override
  String get bbtInputLabel => 'Basal body temperature (°C)';

  @override
  String get cervicalMucusLabel => 'Cervical mucus';

  @override
  String get mucusDry => 'Dry';

  @override
  String get mucusSticky => 'Sticky';

  @override
  String get mucusCreamy => 'Creamy';

  @override
  String get mucusWatery => 'Watery';

  @override
  String get mucusEggWhite => 'Egg-white';

  @override
  String get sexLabel => 'Sex';

  @override
  String get sexNone => 'None';

  @override
  String get sexProtected => 'Protected';

  @override
  String get sexUnprotected => 'Unprotected';

  @override
  String get logTodayTitle => 'Log today';

  @override
  String get saveLog => 'Save';

  @override
  String get periodMedicalDisclaimer =>
      'Not medical advice and not a contraceptive guarantee.';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodSixMonths => '6 months';

  @override
  String get periodYear => 'Year';

  @override
  String get moduleSubstances => 'Substances';

  @override
  String get moduleProgress => 'Progress';

  @override
  String get moduleGraffitiMap => 'Graffiti Map';

  @override
  String get calendarAccessDeniedSyncOff =>
      'Calendar access denied — sync disabled';

  @override
  String get editAppointment => 'Edit appointment';

  @override
  String syncDone(int synced, int errors) {
    return '$synced synced, $errors errors';
  }

  @override
  String updateAvailableTitle(String version) {
    return 'Update available — v$version';
  }

  @override
  String get updateNow => 'Update now';

  @override
  String get updatePreparing => 'Preparing…';

  @override
  String get updateDownloadFailed => 'Download failed';

  @override
  String get updateInstallPermissionMissing =>
      'Permission missing. Enable \"Install unknown apps\" in settings and try again.';

  @override
  String updateInstallLaunchFailed(String reason) {
    return 'Could not start the installer ($reason). Open the file traum-update.apk manually from the downloads/cache folder.';
  }

  @override
  String diaryStreakDays(int days) {
    return 'Streak: $days days';
  }

  @override
  String get diaryCaptureMomentHint => 'Capture this moment.';

  @override
  String get diaryPhotoLabel => 'Photo';

  @override
  String get diaryVideoLabel => 'Video';

  @override
  String get weekdaysFull =>
      'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';

  @override
  String get diaryEntryNotFound => 'Entry not found';

  @override
  String get diaryShareLabel => 'Share';

  @override
  String diaryShareText(String date) {
    return 'Diary entry $date';
  }

  @override
  String diaryHeatmapStats(int count, String percent) {
    return '$count entries · $percent% of days';
  }
}

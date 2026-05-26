import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In de, this message translates to:
  /// **'TRAUM'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In de, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @training.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @health.
  ///
  /// In de, this message translates to:
  /// **'Gesundheit'**
  String get health;

  /// No description provided for @nutrition.
  ///
  /// In de, this message translates to:
  /// **'Ernährung'**
  String get nutrition;

  /// No description provided for @supplements.
  ///
  /// In de, this message translates to:
  /// **'Supplements'**
  String get supplements;

  /// No description provided for @planning.
  ///
  /// In de, this message translates to:
  /// **'Planung'**
  String get planning;

  /// No description provided for @medication.
  ///
  /// In de, this message translates to:
  /// **'Medikamente'**
  String get medication;

  /// No description provided for @abstinence.
  ///
  /// In de, this message translates to:
  /// **'Abstinenz'**
  String get abstinence;

  /// No description provided for @budget.
  ///
  /// In de, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @period.
  ///
  /// In de, this message translates to:
  /// **'Zyklus'**
  String get period;

  /// No description provided for @profile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get add;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirm;

  /// No description provided for @skip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get no;

  /// No description provided for @loading.
  ///
  /// In de, this message translates to:
  /// **'Lädt...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In de, this message translates to:
  /// **'Fehler'**
  String get error;

  /// No description provided for @noData.
  ///
  /// In de, this message translates to:
  /// **'Keine Daten'**
  String get noData;

  /// No description provided for @greetingMorning.
  ///
  /// In de, this message translates to:
  /// **'Guten Morgen'**
  String get greetingMorning;

  /// No description provided for @greetingDay.
  ///
  /// In de, this message translates to:
  /// **'Guten Tag'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In de, this message translates to:
  /// **'Guten Abend'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In de, this message translates to:
  /// **'Gute Nacht'**
  String get greetingNight;

  /// No description provided for @steps.
  ///
  /// In de, this message translates to:
  /// **'Schritte'**
  String get steps;

  /// No description provided for @calories.
  ///
  /// In de, this message translates to:
  /// **'Kalorien'**
  String get calories;

  /// No description provided for @protein.
  ///
  /// In de, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @water.
  ///
  /// In de, this message translates to:
  /// **'Wasser'**
  String get water;

  /// No description provided for @sleep.
  ///
  /// In de, this message translates to:
  /// **'Schlaf'**
  String get sleep;

  /// No description provided for @weight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get weight;

  /// No description provided for @workout.
  ///
  /// In de, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In de, this message translates to:
  /// **'Diesen Monat'**
  String get thisMonth;

  /// No description provided for @goal.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get goal;

  /// No description provided for @minimum.
  ///
  /// In de, this message translates to:
  /// **'Minimum'**
  String get minimum;

  /// No description provided for @maximum.
  ///
  /// In de, this message translates to:
  /// **'Maximum'**
  String get maximum;

  /// No description provided for @streak.
  ///
  /// In de, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @days.
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In de, this message translates to:
  /// **'Stunden'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In de, this message translates to:
  /// **'Minuten'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In de, this message translates to:
  /// **'Sekunden'**
  String get seconds;

  /// No description provided for @noEntriesYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge'**
  String get noEntriesYet;

  /// No description provided for @allDataOnDevice.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten bleiben auf deinem Gerät.'**
  String get allDataOnDevice;

  /// No description provided for @medicalDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Diese App ersetzt keine ärztliche Beratung.'**
  String get medicalDisclaimer;

  /// No description provided for @startWorkout.
  ///
  /// In de, this message translates to:
  /// **'Workout starten'**
  String get startWorkout;

  /// No description provided for @workoutComplete.
  ///
  /// In de, this message translates to:
  /// **'Workout abgeschlossen'**
  String get workoutComplete;

  /// No description provided for @addEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag hinzufügen'**
  String get addEntry;

  /// No description provided for @income.
  ///
  /// In de, this message translates to:
  /// **'Einnahmen'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben'**
  String get expense;

  /// No description provided for @balance.
  ///
  /// In de, this message translates to:
  /// **'Saldo'**
  String get balance;

  /// No description provided for @monthly.
  ///
  /// In de, this message translates to:
  /// **'Monatlich'**
  String get monthly;

  /// No description provided for @daily.
  ///
  /// In de, this message translates to:
  /// **'Täglich'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In de, this message translates to:
  /// **'Wöchentlich'**
  String get weekly;

  /// No description provided for @period_days_label.
  ///
  /// In de, this message translates to:
  /// **'Tage bis zur nächsten Periode'**
  String get period_days_label;

  /// No description provided for @ovulation.
  ///
  /// In de, this message translates to:
  /// **'Eisprung'**
  String get ovulation;

  /// No description provided for @fertile_window.
  ///
  /// In de, this message translates to:
  /// **'Fruchtbares Fenster'**
  String get fertile_window;

  /// No description provided for @cycle_length.
  ///
  /// In de, this message translates to:
  /// **'Zykluslänge'**
  String get cycle_length;

  /// No description provided for @period_length.
  ///
  /// In de, this message translates to:
  /// **'Periodenlänge'**
  String get period_length;

  /// No description provided for @next_period.
  ///
  /// In de, this message translates to:
  /// **'Nächste Periode'**
  String get next_period;

  /// No description provided for @no_period_data.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Zyklusdaten. Trage deine erste Periode ein.'**
  String get no_period_data;

  /// No description provided for @language_de.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get language_de;

  /// No description provided for @language_en.
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get language_en;

  /// No description provided for @metric.
  ///
  /// In de, this message translates to:
  /// **'Metrisch'**
  String get metric;

  /// No description provided for @imperial.
  ///
  /// In de, this message translates to:
  /// **'Imperial'**
  String get imperial;

  /// No description provided for @dark_mode.
  ///
  /// In de, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @biometric_lock.
  ///
  /// In de, this message translates to:
  /// **'Biometrische Sperre'**
  String get biometric_lock;

  /// No description provided for @notifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notifications;

  /// No description provided for @export_data.
  ///
  /// In de, this message translates to:
  /// **'Daten exportieren'**
  String get export_data;

  /// No description provided for @delete_all_data.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten löschen'**
  String get delete_all_data;

  /// No description provided for @delete_confirm.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher? Diese Aktion kann nicht rückgängig gemacht werden.'**
  String get delete_confirm;

  /// No description provided for @reset_onboarding.
  ///
  /// In de, this message translates to:
  /// **'Onboarding wiederholen'**
  String get reset_onboarding;

  /// No description provided for @report_bug.
  ///
  /// In de, this message translates to:
  /// **'Fehler melden'**
  String get report_bug;

  /// No description provided for @version.
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @legal.
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get legal;

  /// No description provided for @privacy_policy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get privacy_policy;

  /// No description provided for @terms_of_service.
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen'**
  String get terms_of_service;

  /// No description provided for @medical_disclaimer.
  ///
  /// In de, this message translates to:
  /// **'Medizinischer Haftungsausschluss'**
  String get medical_disclaimer;

  /// No description provided for @open_source_licenses.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get open_source_licenses;

  /// No description provided for @onboarding_welcome_title.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei TRAUM'**
  String get onboarding_welcome_title;

  /// No description provided for @onboarding_welcome_subtitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Leben. Deine Daten. Dein System.'**
  String get onboarding_welcome_subtitle;

  /// No description provided for @onboarding_privacy_title.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz & Einwilligung'**
  String get onboarding_privacy_title;

  /// No description provided for @onboarding_profile_title.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil'**
  String get onboarding_profile_title;

  /// No description provided for @onboarding_body_title.
  ///
  /// In de, this message translates to:
  /// **'Körper & Fitness'**
  String get onboarding_body_title;

  /// No description provided for @onboarding_nutrition_title.
  ///
  /// In de, this message translates to:
  /// **'Ernährung'**
  String get onboarding_nutrition_title;

  /// No description provided for @onboarding_supplements_title.
  ///
  /// In de, this message translates to:
  /// **'Supplements'**
  String get onboarding_supplements_title;

  /// No description provided for @onboarding_medication_title.
  ///
  /// In de, this message translates to:
  /// **'Medikamente'**
  String get onboarding_medication_title;

  /// No description provided for @onboarding_budget_title.
  ///
  /// In de, this message translates to:
  /// **'Budget'**
  String get onboarding_budget_title;

  /// No description provided for @onboarding_cycle_title.
  ///
  /// In de, this message translates to:
  /// **'Dein Zyklus'**
  String get onboarding_cycle_title;

  /// No description provided for @onboarding_nav_title.
  ///
  /// In de, this message translates to:
  /// **'Navigation anpassen'**
  String get onboarding_nav_title;

  /// No description provided for @onboarding_weather_title.
  ///
  /// In de, this message translates to:
  /// **'Wetter-Standort'**
  String get onboarding_weather_title;

  /// No description provided for @onboarding_notifications_title.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get onboarding_notifications_title;

  /// No description provided for @onboarding_health_title.
  ///
  /// In de, this message translates to:
  /// **'Fitness-Daten verbinden'**
  String get onboarding_health_title;

  /// No description provided for @onboarding_done_title.
  ///
  /// In de, this message translates to:
  /// **'Alles bereit!'**
  String get onboarding_done_title;

  /// No description provided for @lets_go.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get lets_go;

  /// No description provided for @healthScoreTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Gesundheitsscore'**
  String get healthScoreTitle;

  /// No description provided for @healthScoreDetail.
  ///
  /// In de, this message translates to:
  /// **'Was beeinflusst deinen Score?'**
  String get healthScoreDetail;

  /// No description provided for @healthScoreLabelSehrGut.
  ///
  /// In de, this message translates to:
  /// **'Sehr gut'**
  String get healthScoreLabelSehrGut;

  /// No description provided for @healthScoreLabelGut.
  ///
  /// In de, this message translates to:
  /// **'Gut'**
  String get healthScoreLabelGut;

  /// No description provided for @healthScoreLabelMittel.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get healthScoreLabelMittel;

  /// No description provided for @healthScoreLabelVerbesserung.
  ///
  /// In de, this message translates to:
  /// **'Verbesserungsbedarf'**
  String get healthScoreLabelVerbesserung;

  /// No description provided for @healthScoreLabelKritisch.
  ///
  /// In de, this message translates to:
  /// **'Kritisch'**
  String get healthScoreLabelKritisch;

  /// No description provided for @healthScoreInfluenceFactors.
  ///
  /// In de, this message translates to:
  /// **'Einflussfaktoren'**
  String get healthScoreInfluenceFactors;

  /// No description provided for @healthScoreTodayFocus.
  ///
  /// In de, this message translates to:
  /// **'Heute im Fokus'**
  String get healthScoreTodayFocus;

  /// No description provided for @healthScoreDailySummary.
  ///
  /// In de, this message translates to:
  /// **'Tageszusammenfassung'**
  String get healthScoreDailySummary;

  /// No description provided for @healthScoreFactorDetails.
  ///
  /// In de, this message translates to:
  /// **'Einflussfaktor Details'**
  String get healthScoreFactorDetails;

  /// No description provided for @healthScoreInsights.
  ///
  /// In de, this message translates to:
  /// **'Insights & Empfehlungen'**
  String get healthScoreInsights;

  /// No description provided for @healthScoreStrength.
  ///
  /// In de, this message translates to:
  /// **'Stärke'**
  String get healthScoreStrength;

  /// No description provided for @healthScorePotential.
  ///
  /// In de, this message translates to:
  /// **'Verbesserungspotenzial'**
  String get healthScorePotential;

  /// No description provided for @healthScoreTrend.
  ///
  /// In de, this message translates to:
  /// **'Trend'**
  String get healthScoreTrend;

  /// No description provided for @healthScoreBalance.
  ///
  /// In de, this message translates to:
  /// **'Gesamtbalance'**
  String get healthScoreBalance;

  /// No description provided for @healthScoreFactorTraining.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get healthScoreFactorTraining;

  /// No description provided for @healthScoreFactorNutrition.
  ///
  /// In de, this message translates to:
  /// **'Ernährung'**
  String get healthScoreFactorNutrition;

  /// No description provided for @healthScoreFactorRegeneration.
  ///
  /// In de, this message translates to:
  /// **'Regeneration'**
  String get healthScoreFactorRegeneration;

  /// No description provided for @healthScoreFactorSupplements.
  ///
  /// In de, this message translates to:
  /// **'Supplemente'**
  String get healthScoreFactorSupplements;

  /// No description provided for @healthScoreFactorMedication.
  ///
  /// In de, this message translates to:
  /// **'Medikamente'**
  String get healthScoreFactorMedication;

  /// No description provided for @healthScoreFactorMental.
  ///
  /// In de, this message translates to:
  /// **'Stress & Mental'**
  String get healthScoreFactorMental;

  /// No description provided for @healthScoreBewertungOptimal.
  ///
  /// In de, this message translates to:
  /// **'Optimal'**
  String get healthScoreBewertungOptimal;

  /// No description provided for @healthScoreBewertungGut.
  ///
  /// In de, this message translates to:
  /// **'Gut'**
  String get healthScoreBewertungGut;

  /// No description provided for @healthScoreBewertungMittel.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get healthScoreBewertungMittel;

  /// No description provided for @healthScoreBewertungSchwach.
  ///
  /// In de, this message translates to:
  /// **'Schwach'**
  String get healthScoreBewertungSchwach;

  /// No description provided for @allModulesInNav.
  ///
  /// In de, this message translates to:
  /// **'Alle Module in Navigation'**
  String get allModulesInNav;

  /// No description provided for @adjustNav.
  ///
  /// In de, this message translates to:
  /// **'Navigation anpassen'**
  String get adjustNav;

  /// No description provided for @activeModules.
  ///
  /// In de, this message translates to:
  /// **'Aktive Module'**
  String get activeModules;

  /// No description provided for @noModulesYet.
  ///
  /// In de, this message translates to:
  /// **'Keine Module'**
  String get noModulesYet;

  /// No description provided for @otherModules.
  ///
  /// In de, this message translates to:
  /// **'Weitere Module'**
  String get otherModules;

  /// No description provided for @maxModulesReached.
  ///
  /// In de, this message translates to:
  /// **'Maximum erreicht'**
  String get maxModulesReached;

  /// No description provided for @exitDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'App verlassen?'**
  String get exitDialogTitle;

  /// No description provided for @exitDialogContent.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du die App wirklich beenden?'**
  String get exitDialogContent;

  /// No description provided for @more.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get more;

  /// No description provided for @customize.
  ///
  /// In de, this message translates to:
  /// **'Anpassen'**
  String get customize;

  /// No description provided for @exit.
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get exit;

  /// No description provided for @relapseAt.
  ///
  /// In de, this message translates to:
  /// **'Rückfall: {name}'**
  String relapseAt(String name);

  /// No description provided for @relapseDescription.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher, dass du einen Rückfall melden möchtest?'**
  String get relapseDescription;

  /// No description provided for @confirmRelapse.
  ///
  /// In de, this message translates to:
  /// **'Rückfall bestätigen'**
  String get confirmRelapse;

  /// No description provided for @relapse.
  ///
  /// In de, this message translates to:
  /// **'Rückfall'**
  String get relapse;

  /// No description provided for @daysShort.
  ///
  /// In de, this message translates to:
  /// **'T.'**
  String get daysShort;

  /// No description provided for @hoursShort.
  ///
  /// In de, this message translates to:
  /// **'Std.'**
  String get hoursShort;

  /// No description provided for @minutesShort.
  ///
  /// In de, this message translates to:
  /// **'Min.'**
  String get minutesShort;

  /// No description provided for @secondsShort.
  ///
  /// In de, this message translates to:
  /// **'Sek.'**
  String get secondsShort;

  /// No description provided for @noTrackers.
  ///
  /// In de, this message translates to:
  /// **'Keine Tracker'**
  String get noTrackers;

  /// No description provided for @tapToStartTracker.
  ///
  /// In de, this message translates to:
  /// **'Tippe, um einen Tracker zu starten'**
  String get tapToStartTracker;

  /// No description provided for @startTracker.
  ///
  /// In de, this message translates to:
  /// **'Tracker starten'**
  String get startTracker;

  /// No description provided for @whatToAvoid.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du vermeiden?'**
  String get whatToAvoid;

  /// No description provided for @emoji.
  ///
  /// In de, this message translates to:
  /// **'Emoji'**
  String get emoji;

  /// No description provided for @motivationOptional.
  ///
  /// In de, this message translates to:
  /// **'Motivation (optional)'**
  String get motivationOptional;

  /// No description provided for @starting.
  ///
  /// In de, this message translates to:
  /// **'Wird gestartet...'**
  String get starting;

  /// No description provided for @startTrackerButton.
  ///
  /// In de, this message translates to:
  /// **'Tracker starten'**
  String get startTrackerButton;

  /// No description provided for @nameRequired.
  ///
  /// In de, this message translates to:
  /// **'Name erforderlich'**
  String get nameRequired;

  /// No description provided for @startDate.
  ///
  /// In de, this message translates to:
  /// **'Startdatum'**
  String get startDate;

  /// No description provided for @addTransaction.
  ///
  /// In de, this message translates to:
  /// **'Transaktion hinzufügen'**
  String get addTransaction;

  /// No description provided for @expenseLabel.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe'**
  String get expenseLabel;

  /// No description provided for @incomeLabel.
  ///
  /// In de, this message translates to:
  /// **'Einnahme'**
  String get incomeLabel;

  /// No description provided for @amountWithCurrency.
  ///
  /// In de, this message translates to:
  /// **'Betrag ({currency})'**
  String amountWithCurrency(String currency);

  /// No description provided for @fieldDescription.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get fieldDescription;

  /// No description provided for @transactionDescriptionHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Supermarkt'**
  String get transactionDescriptionHint;

  /// No description provided for @dateLabel.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get dateLabel;

  /// No description provided for @categoryOptional.
  ///
  /// In de, this message translates to:
  /// **'Kategorie (optional)'**
  String get categoryOptional;

  /// No description provided for @noCategories.
  ///
  /// In de, this message translates to:
  /// **'Keine Kategorien'**
  String get noCategories;

  /// No description provided for @noCategory.
  ///
  /// In de, this message translates to:
  /// **'Keine Kategorie'**
  String get noCategory;

  /// No description provided for @fieldNoteOptional.
  ///
  /// In de, this message translates to:
  /// **'Notiz (optional)'**
  String get fieldNoteOptional;

  /// No description provided for @noteHint.
  ///
  /// In de, this message translates to:
  /// **'Notiz...'**
  String get noteHint;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen gültigen Betrag ein'**
  String get pleaseEnterValidAmount;

  /// No description provided for @descriptionRequired.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung erforderlich'**
  String get descriptionRequired;

  /// No description provided for @saving.
  ///
  /// In de, this message translates to:
  /// **'Wird gespeichert...'**
  String get saving;

  /// No description provided for @latestTransactions.
  ///
  /// In de, this message translates to:
  /// **'Neueste Transaktionen'**
  String get latestTransactions;

  /// No description provided for @all.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get all;

  /// No description provided for @balanceThisMonth.
  ///
  /// In de, this message translates to:
  /// **'Saldo diesen Monat'**
  String get balanceThisMonth;

  /// No description provided for @categoryOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get categoryOther;

  /// No description provided for @budgetsLabel.
  ///
  /// In de, this message translates to:
  /// **'Budgets'**
  String get budgetsLabel;

  /// No description provided for @monthJan.
  ///
  /// In de, this message translates to:
  /// **'Januar'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In de, this message translates to:
  /// **'Februar'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In de, this message translates to:
  /// **'März'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In de, this message translates to:
  /// **'April'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In de, this message translates to:
  /// **'Mai'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In de, this message translates to:
  /// **'Juni'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In de, this message translates to:
  /// **'Juli'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In de, this message translates to:
  /// **'August'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In de, this message translates to:
  /// **'September'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In de, this message translates to:
  /// **'Oktober'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In de, this message translates to:
  /// **'November'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In de, this message translates to:
  /// **'Dezember'**
  String get monthDec;

  /// No description provided for @monthShortJan.
  ///
  /// In de, this message translates to:
  /// **'Jan'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In de, this message translates to:
  /// **'Feb'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In de, this message translates to:
  /// **'Mär'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In de, this message translates to:
  /// **'Apr'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In de, this message translates to:
  /// **'Mai'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In de, this message translates to:
  /// **'Jun'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In de, this message translates to:
  /// **'Jul'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In de, this message translates to:
  /// **'Aug'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In de, this message translates to:
  /// **'Sep'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In de, this message translates to:
  /// **'Okt'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In de, this message translates to:
  /// **'Nov'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In de, this message translates to:
  /// **'Dez'**
  String get monthShortDec;

  /// No description provided for @noTransactions.
  ///
  /// In de, this message translates to:
  /// **'Keine Transaktionen'**
  String get noTransactions;

  /// No description provided for @tapPlusToAdd.
  ///
  /// In de, this message translates to:
  /// **'Tippe + um hinzuzufügen'**
  String get tapPlusToAdd;

  /// No description provided for @statistics.
  ///
  /// In de, this message translates to:
  /// **'Statistiken'**
  String get statistics;

  /// No description provided for @savingsGoals.
  ///
  /// In de, this message translates to:
  /// **'Sparziele'**
  String get savingsGoals;

  /// No description provided for @totalIncome.
  ///
  /// In de, this message translates to:
  /// **'Gesamteinnahmen'**
  String get totalIncome;

  /// No description provided for @totalExpense.
  ///
  /// In de, this message translates to:
  /// **'Gesamtausgaben'**
  String get totalExpense;

  /// No description provided for @last6Months.
  ///
  /// In de, this message translates to:
  /// **'Letzte 6 Monate'**
  String get last6Months;

  /// No description provided for @topExpenseCategories.
  ///
  /// In de, this message translates to:
  /// **'Top Ausgabenkategorien'**
  String get topExpenseCategories;

  /// No description provided for @reached.
  ///
  /// In de, this message translates to:
  /// **'Erreicht'**
  String get reached;

  /// No description provided for @remainingAmount.
  ///
  /// In de, this message translates to:
  /// **'Noch {remaining} {currency}'**
  String remainingAmount(String remaining, String currency);

  /// No description provided for @targetDate.
  ///
  /// In de, this message translates to:
  /// **'Zieldatum: {date}'**
  String targetDate(String date);

  /// No description provided for @deposit.
  ///
  /// In de, this message translates to:
  /// **'Einzahlung'**
  String get deposit;

  /// No description provided for @depositAmount.
  ///
  /// In de, this message translates to:
  /// **'Einzahlungsbetrag'**
  String get depositAmount;

  /// No description provided for @fieldName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @createSavingsGoal.
  ///
  /// In de, this message translates to:
  /// **'Sparziel erstellen'**
  String get createSavingsGoal;

  /// No description provided for @savingsGoalNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Urlaub'**
  String get savingsGoalNameHint;

  /// No description provided for @targetAmountLabel.
  ///
  /// In de, this message translates to:
  /// **'Zielbetrag'**
  String get targetAmountLabel;

  /// No description provided for @alreadySaved.
  ///
  /// In de, this message translates to:
  /// **'Bereits gespart'**
  String get alreadySaved;

  /// No description provided for @targetDateOptional.
  ///
  /// In de, this message translates to:
  /// **'Zieldatum (optional)'**
  String get targetDateOptional;

  /// No description provided for @noDate.
  ///
  /// In de, this message translates to:
  /// **'Kein Datum'**
  String get noDate;

  /// No description provided for @whatSavingFor.
  ///
  /// In de, this message translates to:
  /// **'Wofür sparst du?'**
  String get whatSavingFor;

  /// No description provided for @pleaseEnterValidTargetAmount.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen gültigen Zielbetrag ein'**
  String get pleaseEnterValidTargetAmount;

  /// No description provided for @allTransactions.
  ///
  /// In de, this message translates to:
  /// **'Alle Transaktionen'**
  String get allTransactions;

  /// No description provided for @noSavingsGoals.
  ///
  /// In de, this message translates to:
  /// **'Keine Sparziele'**
  String get noSavingsGoals;

  /// No description provided for @tapToCreateSavingsGoal.
  ///
  /// In de, this message translates to:
  /// **'Tippe, um ein Sparziel zu erstellen'**
  String get tapToCreateSavingsGoal;

  /// No description provided for @motivationExcellent.
  ///
  /// In de, this message translates to:
  /// **'Ausgezeichnet! Dein Körper ist in Topform.'**
  String get motivationExcellent;

  /// No description provided for @motivationGood.
  ///
  /// In de, this message translates to:
  /// **'Super! Du bist auf einem guten Weg.'**
  String get motivationGood;

  /// No description provided for @motivationSolid.
  ///
  /// In de, this message translates to:
  /// **'Solide! Mit kleinen Anpassungen erreichst du mehr.'**
  String get motivationSolid;

  /// No description provided for @motivationImprove.
  ///
  /// In de, this message translates to:
  /// **'Es gibt noch Luft nach oben. Fang heute an!'**
  String get motivationImprove;

  /// No description provided for @motivationAttention.
  ///
  /// In de, this message translates to:
  /// **'Dein Körper braucht Aufmerksamkeit. Jetzt handeln!'**
  String get motivationAttention;

  /// No description provided for @hintTraining.
  ///
  /// In de, this message translates to:
  /// **'Plane dein nächstes Workout und bleib aktiv.'**
  String get hintTraining;

  /// No description provided for @hintNutrition.
  ///
  /// In de, this message translates to:
  /// **'Achte auf ausgewogene Mahlzeiten und ausreichend Protein.'**
  String get hintNutrition;

  /// No description provided for @hintRegeneration.
  ///
  /// In de, this message translates to:
  /// **'Gönne deinem Körper ausreichend Schlaf und Erholung.'**
  String get hintRegeneration;

  /// No description provided for @hintSupplements.
  ///
  /// In de, this message translates to:
  /// **'Ergänze deine Ernährung mit gezielten Supplements.'**
  String get hintSupplements;

  /// No description provided for @hintMedication.
  ///
  /// In de, this message translates to:
  /// **'Vergiss nicht, deine Medikamente einzunehmen.'**
  String get hintMedication;

  /// No description provided for @hintMentalStress.
  ///
  /// In de, this message translates to:
  /// **'Nimm dir Zeit für Entspannung und Stressabbau.'**
  String get hintMentalStress;

  /// No description provided for @hintDefault.
  ///
  /// In de, this message translates to:
  /// **'Bleib konsistent und verfolge deine Ziele täglich.'**
  String get hintDefault;

  /// No description provided for @score.
  ///
  /// In de, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @overview.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get overview;

  /// No description provided for @sleepTab.
  ///
  /// In de, this message translates to:
  /// **'Schlaf'**
  String get sleepTab;

  /// No description provided for @weightTab.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get weightTab;

  /// No description provided for @measurementsTab.
  ///
  /// In de, this message translates to:
  /// **'Maße'**
  String get measurementsTab;

  /// No description provided for @moreLabel.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get moreLabel;

  /// No description provided for @tapOnArea.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf einen Bereich'**
  String get tapOnArea;

  /// No description provided for @strength.
  ///
  /// In de, this message translates to:
  /// **'Stärke'**
  String get strength;

  /// No description provided for @details.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @improve.
  ///
  /// In de, this message translates to:
  /// **'Verbessern'**
  String get improve;

  /// No description provided for @trendLabel.
  ///
  /// In de, this message translates to:
  /// **'Trend'**
  String get trendLabel;

  /// No description provided for @noTrendData.
  ///
  /// In de, this message translates to:
  /// **'Keine Trenddaten'**
  String get noTrendData;

  /// No description provided for @trendBetter.
  ///
  /// In de, this message translates to:
  /// **'+{diff} Pkt. besser'**
  String trendBetter(int diff);

  /// No description provided for @trendWorse.
  ///
  /// In de, this message translates to:
  /// **'-{diff} Pkt. schlechter'**
  String trendWorse(int diff);

  /// No description provided for @balanceDiff.
  ///
  /// In de, this message translates to:
  /// **'{diff} Pkt. Abstand zwischen {best} und {worst}'**
  String balanceDiff(int diff, String best, String worst);

  /// No description provided for @analyze.
  ///
  /// In de, this message translates to:
  /// **'Analysieren'**
  String get analyze;

  /// No description provided for @weekdaysShort.
  ///
  /// In de, this message translates to:
  /// **'Mo,Di,Mi,Do,Fr,Sa,So'**
  String get weekdaysShort;

  /// No description provided for @noSleepData.
  ///
  /// In de, this message translates to:
  /// **'Keine Schlafdaten'**
  String get noSleepData;

  /// No description provided for @sleepLast7Nights.
  ///
  /// In de, this message translates to:
  /// **'Schlaf (letzte 7 Nächte)'**
  String get sleepLast7Nights;

  /// No description provided for @avgHours.
  ///
  /// In de, this message translates to:
  /// **'Ø {hours} h'**
  String avgHours(String hours);

  /// No description provided for @entriesRecorded.
  ///
  /// In de, this message translates to:
  /// **'{n} Einträge'**
  String entriesRecorded(int n);

  /// No description provided for @currentWeight.
  ///
  /// In de, this message translates to:
  /// **'Aktuelles Gewicht'**
  String get currentWeight;

  /// No description provided for @noEntry.
  ///
  /// In de, this message translates to:
  /// **'Kein Eintrag'**
  String get noEntry;

  /// No description provided for @moodLastEntry.
  ///
  /// In de, this message translates to:
  /// **'Letzter Stimmungseintrag'**
  String get moodLastEntry;

  /// No description provided for @moodVeryBad.
  ///
  /// In de, this message translates to:
  /// **'Sehr schlecht'**
  String get moodVeryBad;

  /// No description provided for @moodBad.
  ///
  /// In de, this message translates to:
  /// **'Schlecht'**
  String get moodBad;

  /// No description provided for @moodNeutral.
  ///
  /// In de, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @moodGood.
  ///
  /// In de, this message translates to:
  /// **'Gut'**
  String get moodGood;

  /// No description provided for @moodExcellent.
  ///
  /// In de, this message translates to:
  /// **'Ausgezeichnet'**
  String get moodExcellent;

  /// No description provided for @weightHistory.
  ///
  /// In de, this message translates to:
  /// **'Gewichtsverlauf'**
  String get weightHistory;

  /// No description provided for @entries.
  ///
  /// In de, this message translates to:
  /// **'Einträge'**
  String get entries;

  /// No description provided for @noWeightEntries.
  ///
  /// In de, this message translates to:
  /// **'Keine Gewichtseinträge'**
  String get noWeightEntries;

  /// No description provided for @logWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht eintragen'**
  String get logWeight;

  /// No description provided for @noBodyMeasurements.
  ///
  /// In de, this message translates to:
  /// **'Keine Körpermaße'**
  String get noBodyMeasurements;

  /// No description provided for @currentMeasurements.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Maße'**
  String get currentMeasurements;

  /// No description provided for @chest.
  ///
  /// In de, this message translates to:
  /// **'Brust'**
  String get chest;

  /// No description provided for @waist.
  ///
  /// In de, this message translates to:
  /// **'Taille'**
  String get waist;

  /// No description provided for @hips.
  ///
  /// In de, this message translates to:
  /// **'Hüfte'**
  String get hips;

  /// No description provided for @thigh.
  ///
  /// In de, this message translates to:
  /// **'Oberschenkel'**
  String get thigh;

  /// No description provided for @bicep.
  ///
  /// In de, this message translates to:
  /// **'Bizeps'**
  String get bicep;

  /// No description provided for @shoulders.
  ///
  /// In de, this message translates to:
  /// **'Schultern'**
  String get shoulders;

  /// No description provided for @calf.
  ///
  /// In de, this message translates to:
  /// **'Wade'**
  String get calf;

  /// No description provided for @neck.
  ///
  /// In de, this message translates to:
  /// **'Hals'**
  String get neck;

  /// No description provided for @bodyFat.
  ///
  /// In de, this message translates to:
  /// **'Körperfett'**
  String get bodyFat;

  /// No description provided for @logBodyMeasurements.
  ///
  /// In de, this message translates to:
  /// **'Körpermaße eintragen'**
  String get logBodyMeasurements;

  /// No description provided for @logSleep.
  ///
  /// In de, this message translates to:
  /// **'Schlaf eintragen'**
  String get logSleep;

  /// No description provided for @fallingAsleep.
  ///
  /// In de, this message translates to:
  /// **'Einschlafen'**
  String get fallingAsleep;

  /// No description provided for @wakingUp.
  ///
  /// In de, this message translates to:
  /// **'Aufwachen'**
  String get wakingUp;

  /// No description provided for @sleepQuality.
  ///
  /// In de, this message translates to:
  /// **'Schlafqualität'**
  String get sleepQuality;

  /// No description provided for @weatherClear.
  ///
  /// In de, this message translates to:
  /// **'Klar'**
  String get weatherClear;

  /// No description provided for @weatherCloudy.
  ///
  /// In de, this message translates to:
  /// **'Bewölkt'**
  String get weatherCloudy;

  /// No description provided for @weatherFoggy.
  ///
  /// In de, this message translates to:
  /// **'Neblig'**
  String get weatherFoggy;

  /// No description provided for @weatherRain.
  ///
  /// In de, this message translates to:
  /// **'Regen'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In de, this message translates to:
  /// **'Schnee'**
  String get weatherSnow;

  /// No description provided for @weatherShowers.
  ///
  /// In de, this message translates to:
  /// **'Schauer'**
  String get weatherShowers;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In de, this message translates to:
  /// **'Gewitter'**
  String get weatherThunderstorm;

  /// No description provided for @goalShort.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get goalShort;

  /// No description provided for @stepsProgress.
  ///
  /// In de, this message translates to:
  /// **'{current} / {goal}'**
  String stepsProgress(int current, int goal);

  /// No description provided for @macroProgress.
  ///
  /// In de, this message translates to:
  /// **'{val} / {goal} {unit}'**
  String macroProgress(String val, int goal, String unit);

  /// No description provided for @dailyLimitReached.
  ///
  /// In de, this message translates to:
  /// **'Tageslimit erreicht'**
  String get dailyLimitReached;

  /// No description provided for @waterMin.
  ///
  /// In de, this message translates to:
  /// **'Min {ml} ml'**
  String waterMin(int ml);

  /// No description provided for @permissionNotifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get permissionNotifications;

  /// No description provided for @waterTotal.
  ///
  /// In de, this message translates to:
  /// **'{ml} ml'**
  String waterTotal(int ml);

  /// No description provided for @waterGoalAndMax.
  ///
  /// In de, this message translates to:
  /// **'Ziel: {goal} ml · Max: {max} ml'**
  String waterGoalAndMax(int goal, int max);

  /// No description provided for @permissionLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort'**
  String get permissionLocation;

  /// No description provided for @waterButton.
  ///
  /// In de, this message translates to:
  /// **'+{ml} ml'**
  String waterButton(int ml);

  /// No description provided for @todos.
  ///
  /// In de, this message translates to:
  /// **'Aufgaben'**
  String get todos;

  /// No description provided for @allLabel.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get allLabel;

  /// No description provided for @noOpenTodos.
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Aufgaben'**
  String get noOpenTodos;

  /// No description provided for @medicationsTitle.
  ///
  /// In de, this message translates to:
  /// **'Medikamente'**
  String get medicationsTitle;

  /// No description provided for @noMedications.
  ///
  /// In de, this message translates to:
  /// **'Keine Medikamente'**
  String get noMedications;

  /// No description provided for @missingPermissions.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Berechtigungen'**
  String get missingPermissions;

  /// No description provided for @habits.
  ///
  /// In de, this message translates to:
  /// **'Gewohnheiten'**
  String get habits;

  /// No description provided for @noHabitsTapToAdd.
  ///
  /// In de, this message translates to:
  /// **'Keine Gewohnheiten – Tippe zum Hinzufügen'**
  String get noHabitsTapToAdd;

  /// No description provided for @noTransactionsThisMonth.
  ///
  /// In de, this message translates to:
  /// **'Keine Transaktionen diesen Monat'**
  String get noTransactionsThisMonth;

  /// No description provided for @permissionsContent.
  ///
  /// In de, this message translates to:
  /// **'{items}'**
  String permissionsContent(String items);

  /// No description provided for @tapForCycleInfo.
  ///
  /// In de, this message translates to:
  /// **'Tippe für Zyklusinfos'**
  String get tapForCycleInfo;

  /// No description provided for @healthLabel.
  ///
  /// In de, this message translates to:
  /// **'Gesundheit'**
  String get healthLabel;

  /// No description provided for @heartRate.
  ///
  /// In de, this message translates to:
  /// **'Herzrate'**
  String get heartRate;

  /// No description provided for @mood.
  ///
  /// In de, this message translates to:
  /// **'Stimmung'**
  String get mood;

  /// No description provided for @later.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get later;

  /// No description provided for @openSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get openSettings;

  /// No description provided for @documentCouldNotLoad.
  ///
  /// In de, this message translates to:
  /// **'Dokument konnte nicht geladen werden'**
  String get documentCouldNotLoad;

  /// No description provided for @appIsLocked.
  ///
  /// In de, this message translates to:
  /// **'App gesperrt'**
  String get appIsLocked;

  /// No description provided for @unlock.
  ///
  /// In de, this message translates to:
  /// **'Entsperren'**
  String get unlock;

  /// No description provided for @usePin.
  ///
  /// In de, this message translates to:
  /// **'PIN verwenden'**
  String get usePin;

  /// No description provided for @unlockReason.
  ///
  /// In de, this message translates to:
  /// **'TRAUM entsperren'**
  String get unlockReason;

  /// No description provided for @authFailedTryAgain.
  ///
  /// In de, this message translates to:
  /// **'Authentifizierung fehlgeschlagen. Bitte erneut versuchen.'**
  String get authFailedTryAgain;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Biometrie nicht verfügbar'**
  String get biometricNotAvailable;

  /// No description provided for @biometricNotEnrolled.
  ///
  /// In de, this message translates to:
  /// **'Keine biometrischen Daten registriert'**
  String get biometricNotEnrolled;

  /// No description provided for @biometricLockedOut.
  ///
  /// In de, this message translates to:
  /// **'Biometrie gesperrt. Bitte versuche es später erneut.'**
  String get biometricLockedOut;

  /// No description provided for @biometricError.
  ///
  /// In de, this message translates to:
  /// **'Biometriefehler: {msg}'**
  String biometricError(String msg);

  /// No description provided for @biometricNotAvailableUsePin.
  ///
  /// In de, this message translates to:
  /// **'Biometrie nicht verfügbar. Bitte PIN verwenden.'**
  String get biometricNotAvailableUsePin;

  /// No description provided for @enterPin.
  ///
  /// In de, this message translates to:
  /// **'PIN eingeben'**
  String get enterPin;

  /// No description provided for @wrongPin.
  ///
  /// In de, this message translates to:
  /// **'Falscher PIN'**
  String get wrongPin;

  /// No description provided for @formTablet.
  ///
  /// In de, this message translates to:
  /// **'Tablette'**
  String get formTablet;

  /// No description provided for @formCapsule.
  ///
  /// In de, this message translates to:
  /// **'Kapsel'**
  String get formCapsule;

  /// No description provided for @formDrops.
  ///
  /// In de, this message translates to:
  /// **'Tropfen'**
  String get formDrops;

  /// No description provided for @formInjection.
  ///
  /// In de, this message translates to:
  /// **'Injektion'**
  String get formInjection;

  /// No description provided for @formOintment.
  ///
  /// In de, this message translates to:
  /// **'Salbe'**
  String get formOintment;

  /// No description provided for @formSpray.
  ///
  /// In de, this message translates to:
  /// **'Spray'**
  String get formSpray;

  /// No description provided for @formOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get formOther;

  /// No description provided for @inactive.
  ///
  /// In de, this message translates to:
  /// **'Inaktiv'**
  String get inactive;

  /// No description provided for @activeLabel.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get activeLabel;

  /// No description provided for @noMedicationsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Medikamente'**
  String get noMedicationsYet;

  /// No description provided for @tapToAddMedication.
  ///
  /// In de, this message translates to:
  /// **'Tippe, um ein Medikament hinzuzufügen'**
  String get tapToAddMedication;

  /// No description provided for @addMedication.
  ///
  /// In de, this message translates to:
  /// **'Medikament hinzufügen'**
  String get addMedication;

  /// No description provided for @medicationNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Ibuprofen'**
  String get medicationNameHint;

  /// No description provided for @dosageHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. 400mg'**
  String get dosageHint;

  /// No description provided for @dosage.
  ///
  /// In de, this message translates to:
  /// **'Dosierung'**
  String get dosage;

  /// No description provided for @formLabel.
  ///
  /// In de, this message translates to:
  /// **'Form'**
  String get formLabel;

  /// No description provided for @reminderTimes.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungszeiten'**
  String get reminderTimes;

  /// No description provided for @allMedications.
  ///
  /// In de, this message translates to:
  /// **'Alle Medikamente'**
  String get allMedications;

  /// No description provided for @timeForMedication.
  ///
  /// In de, this message translates to:
  /// **'Zeit für {name}'**
  String timeForMedication(String name);

  /// No description provided for @remindersTimes.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen: {times}'**
  String remindersTimes(String times);

  /// No description provided for @breakfast.
  ///
  /// In de, this message translates to:
  /// **'Frühstück'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In de, this message translates to:
  /// **'Mittagessen'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In de, this message translates to:
  /// **'Abendessen'**
  String get dinner;

  /// No description provided for @snack.
  ///
  /// In de, this message translates to:
  /// **'Snack'**
  String get snack;

  /// No description provided for @searchOrCreate.
  ///
  /// In de, this message translates to:
  /// **'Suchen oder erstellen'**
  String get searchOrCreate;

  /// No description provided for @noResultsLabel.
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse gefunden'**
  String get noResultsLabel;

  /// No description provided for @createFood.
  ///
  /// In de, this message translates to:
  /// **'Lebensmittel erstellen'**
  String get createFood;

  /// No description provided for @amountG.
  ///
  /// In de, this message translates to:
  /// **'Menge (g)'**
  String get amountG;

  /// No description provided for @logEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag speichern'**
  String get logEntry;

  /// No description provided for @searchFood.
  ///
  /// In de, this message translates to:
  /// **'Essen suchen'**
  String get searchFood;

  /// No description provided for @plusNew.
  ///
  /// In de, this message translates to:
  /// **'+ Neu'**
  String get plusNew;

  /// No description provided for @searchHint.
  ///
  /// In de, this message translates to:
  /// **'Suchen...'**
  String get searchHint;

  /// No description provided for @mealType.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit-Typ'**
  String get mealType;

  /// No description provided for @foodHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Haferflocken'**
  String get foodHint;

  /// No description provided for @foodLabel.
  ///
  /// In de, this message translates to:
  /// **'Lebensmittel'**
  String get foodLabel;

  /// No description provided for @amountGrams.
  ///
  /// In de, this message translates to:
  /// **'Menge (g)'**
  String get amountGrams;

  /// No description provided for @caloriesKcal.
  ///
  /// In de, this message translates to:
  /// **'Kalorien (kcal)'**
  String get caloriesKcal;

  /// No description provided for @proteinG.
  ///
  /// In de, this message translates to:
  /// **'Protein (g)'**
  String get proteinG;

  /// No description provided for @carbsG.
  ///
  /// In de, this message translates to:
  /// **'Kohlenhydrate (g)'**
  String get carbsG;

  /// No description provided for @fatG.
  ///
  /// In de, this message translates to:
  /// **'Fett (g)'**
  String get fatG;

  /// No description provided for @logMeal.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit eintragen'**
  String get logMeal;

  /// No description provided for @quickSelect.
  ///
  /// In de, this message translates to:
  /// **'Schnellauswahl'**
  String get quickSelect;

  /// No description provided for @addWater.
  ///
  /// In de, this message translates to:
  /// **'Wasser hinzufügen'**
  String get addWater;

  /// No description provided for @positiveAmountRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine positive Menge eingeben'**
  String get positiveAmountRequired;

  /// No description provided for @waterGoal2000.
  ///
  /// In de, this message translates to:
  /// **'Ziel: 2000 ml'**
  String get waterGoal2000;

  /// No description provided for @nothingLogged.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts eingetragen'**
  String get nothingLogged;

  /// No description provided for @shoppingListTooltip.
  ///
  /// In de, this message translates to:
  /// **'Einkaufsliste'**
  String get shoppingListTooltip;

  /// No description provided for @completed.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get completed;

  /// No description provided for @shoppingList.
  ///
  /// In de, this message translates to:
  /// **'Einkaufsliste'**
  String get shoppingList;

  /// No description provided for @addProduct.
  ///
  /// In de, this message translates to:
  /// **'Produkt hinzufügen'**
  String get addProduct;

  /// No description provided for @itemHint.
  ///
  /// In de, this message translates to:
  /// **'Eintrag...'**
  String get itemHint;

  /// No description provided for @quantity.
  ///
  /// In de, this message translates to:
  /// **'Menge'**
  String get quantity;

  /// No description provided for @unitHint.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get unitHint;

  /// No description provided for @deleteCompletedTooltip.
  ///
  /// In de, this message translates to:
  /// **'Erledigte löschen'**
  String get deleteCompletedTooltip;

  /// No description provided for @shoppingListEmpty.
  ///
  /// In de, this message translates to:
  /// **'Einkaufsliste leer'**
  String get shoppingListEmpty;

  /// No description provided for @tapToAddProduct.
  ///
  /// In de, this message translates to:
  /// **'Tippe, um ein Produkt hinzuzufügen'**
  String get tapToAddProduct;

  /// No description provided for @servingSize.
  ///
  /// In de, this message translates to:
  /// **'Portionsgröße'**
  String get servingSize;

  /// No description provided for @kcalPer100g.
  ///
  /// In de, this message translates to:
  /// **'kcal/100g'**
  String get kcalPer100g;

  /// No description provided for @proteinPer100g.
  ///
  /// In de, this message translates to:
  /// **'Protein (g/100g)'**
  String get proteinPer100g;

  /// No description provided for @carbsPer100g.
  ///
  /// In de, this message translates to:
  /// **'Kohlenhydrate (g/100g)'**
  String get carbsPer100g;

  /// No description provided for @fatPer100g.
  ///
  /// In de, this message translates to:
  /// **'Fett (g/100g)'**
  String get fatPer100g;

  /// No description provided for @createButton.
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get createButton;

  /// No description provided for @caloriesRequired.
  ///
  /// In de, this message translates to:
  /// **'Kalorien erforderlich'**
  String get caloriesRequired;

  /// No description provided for @noResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse'**
  String get noResults;

  /// No description provided for @search.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get search;

  /// No description provided for @weightKg.
  ///
  /// In de, this message translates to:
  /// **'Gewicht (kg)'**
  String get weightKg;

  /// No description provided for @weightLbs.
  ///
  /// In de, this message translates to:
  /// **'Gewicht (lbs)'**
  String get weightLbs;

  /// No description provided for @welcomeToTraum.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei TRAUM'**
  String get welcomeToTraum;

  /// No description provided for @startNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt starten'**
  String get startNow;

  /// No description provided for @yourLifeYourData.
  ///
  /// In de, this message translates to:
  /// **'Dein Leben. Deine Daten.'**
  String get yourLifeYourData;

  /// No description provided for @traumDescription.
  ///
  /// In de, this message translates to:
  /// **'TRAUM ist dein persönliches Gesundheits-Dashboard. Alle Daten bleiben auf deinem Gerät.'**
  String get traumDescription;

  /// No description provided for @consentReadLeading.
  ///
  /// In de, this message translates to:
  /// **'Ich habe die'**
  String get consentReadLeading;

  /// No description provided for @consentReadTrailing.
  ///
  /// In de, this message translates to:
  /// **'gelesen und akzeptiert'**
  String get consentReadTrailing;

  /// No description provided for @healthDataConsent.
  ///
  /// In de, this message translates to:
  /// **'Gesundheitsdaten-Einwilligung'**
  String get healthDataConsent;

  /// No description provided for @consentAcceptLeading.
  ///
  /// In de, this message translates to:
  /// **'Ich akzeptiere die'**
  String get consentAcceptLeading;

  /// No description provided for @consentDot.
  ///
  /// In de, this message translates to:
  /// **'·'**
  String get consentDot;

  /// No description provided for @consentConfirmLeading.
  ///
  /// In de, this message translates to:
  /// **'Ich bestätige, dass ich'**
  String get consentConfirmLeading;

  /// No description provided for @ageConsent.
  ///
  /// In de, this message translates to:
  /// **'Ich bin mindestens 16 Jahre alt'**
  String get ageConsent;

  /// No description provided for @profileTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil'**
  String get profileTitle;

  /// No description provided for @yourName.
  ///
  /// In de, this message translates to:
  /// **'Dein Name'**
  String get yourName;

  /// No description provided for @sex.
  ///
  /// In de, this message translates to:
  /// **'Geschlecht'**
  String get sex;

  /// No description provided for @sexMale.
  ///
  /// In de, this message translates to:
  /// **'Männlich'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In de, this message translates to:
  /// **'Weiblich'**
  String get sexFemale;

  /// No description provided for @unitsLabel.
  ///
  /// In de, this message translates to:
  /// **'Einheiten'**
  String get unitsLabel;

  /// No description provided for @pleaseFillProfile.
  ///
  /// In de, this message translates to:
  /// **'Bitte fülle dein Profil aus'**
  String get pleaseFillProfile;

  /// No description provided for @heightLabelOnboarding.
  ///
  /// In de, this message translates to:
  /// **'Körpergröße (cm)'**
  String get heightLabelOnboarding;

  /// No description provided for @weightLabelOnboarding.
  ///
  /// In de, this message translates to:
  /// **'Gewicht (kg)'**
  String get weightLabelOnboarding;

  /// No description provided for @weightGoalLabelOnboarding.
  ///
  /// In de, this message translates to:
  /// **'Zielgewicht (kg)'**
  String get weightGoalLabelOnboarding;

  /// No description provided for @dailyStepsGoal.
  ///
  /// In de, this message translates to:
  /// **'Tägliches Schrittziel'**
  String get dailyStepsGoal;

  /// No description provided for @stepsLabelText.
  ///
  /// In de, this message translates to:
  /// **'{steps} Schritte'**
  String stepsLabelText(int steps);

  /// No description provided for @yourWaterGoal.
  ///
  /// In de, this message translates to:
  /// **'Dein Wasserziel'**
  String get yourWaterGoal;

  /// No description provided for @waterGoalSummary.
  ///
  /// In de, this message translates to:
  /// **'Ziel: {goal} ml (Min: {min} ml, Max: {max} ml)'**
  String waterGoalSummary(int goal, int min, int max);

  /// No description provided for @nutritionTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Ernährungsziele'**
  String get nutritionTitleOb;

  /// No description provided for @caloriesGoalLabel.
  ///
  /// In de, this message translates to:
  /// **'Kalorienziel (kcal)'**
  String get caloriesGoalLabel;

  /// No description provided for @proteinGoalLabelOb.
  ///
  /// In de, this message translates to:
  /// **'Proteinziel (g)'**
  String get proteinGoalLabelOb;

  /// No description provided for @supplementsTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Supplements'**
  String get supplementsTitleOb;

  /// No description provided for @takeSupplementsRegularly.
  ///
  /// In de, this message translates to:
  /// **'Nimmst du regelmäßig Supplements?'**
  String get takeSupplementsRegularly;

  /// No description provided for @addSupplementButton.
  ///
  /// In de, this message translates to:
  /// **'Supplement hinzufügen'**
  String get addSupplementButton;

  /// No description provided for @noSupplementsAddedYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Supplements hinzugefügt'**
  String get noSupplementsAddedYet;

  /// No description provided for @medicationTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Medikamente'**
  String get medicationTitleOb;

  /// No description provided for @medicalDisclaimerOb.
  ///
  /// In de, this message translates to:
  /// **'TRAUM ersetzt keine ärztliche Beratung.'**
  String get medicalDisclaimerOb;

  /// No description provided for @takeMedicationRegularly.
  ///
  /// In de, this message translates to:
  /// **'Nimmst du regelmäßig Medikamente?'**
  String get takeMedicationRegularly;

  /// No description provided for @addMedicationButton.
  ///
  /// In de, this message translates to:
  /// **'Medikament hinzufügen'**
  String get addMedicationButton;

  /// No description provided for @noMedicationsAddedYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Medikamente hinzugefügt'**
  String get noMedicationsAddedYet;

  /// No description provided for @budgetTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Budget'**
  String get budgetTitleOb;

  /// No description provided for @wantToKeepBudget.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du dein Budget verwalten?'**
  String get wantToKeepBudget;

  /// No description provided for @monthlyBudget.
  ///
  /// In de, this message translates to:
  /// **'Monatliches Budget (€)'**
  String get monthlyBudget;

  /// No description provided for @cycleTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Dein Zyklus'**
  String get cycleTitleOb;

  /// No description provided for @cycleLengthLabel.
  ///
  /// In de, this message translates to:
  /// **'Zykluslänge (Tage)'**
  String get cycleLengthLabel;

  /// No description provided for @periodLengthLabel.
  ///
  /// In de, this message translates to:
  /// **'Periodenlänge (Tage)'**
  String get periodLengthLabel;

  /// No description provided for @navTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Navigation anpassen'**
  String get navTitleOb;

  /// No description provided for @homeAlwaysLeft.
  ///
  /// In de, this message translates to:
  /// **'Home ist immer links'**
  String get homeAlwaysLeft;

  /// No description provided for @slotsSelected.
  ///
  /// In de, this message translates to:
  /// **'{n} Slots ausgewählt'**
  String slotsSelected(int n);

  /// No description provided for @adjustNavLater.
  ///
  /// In de, this message translates to:
  /// **'Später anpassen'**
  String get adjustNavLater;

  /// No description provided for @weatherTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Wetter-Standort'**
  String get weatherTitleOb;

  /// No description provided for @weatherDescription.
  ///
  /// In de, this message translates to:
  /// **'TRAUM zeigt dir das aktuelle Wetter auf der Startseite.'**
  String get weatherDescription;

  /// No description provided for @requestingLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort anfragen...'**
  String get requestingLocation;

  /// No description provided for @allowLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort erlauben'**
  String get allowLocation;

  /// No description provided for @notificationsTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notificationsTitleOb;

  /// No description provided for @notificationsDescription.
  ///
  /// In de, this message translates to:
  /// **'Erhalte Erinnerungen für Medikamente, Supplements und mehr.'**
  String get notificationsDescription;

  /// No description provided for @allowNotifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen erlauben'**
  String get allowNotifications;

  /// No description provided for @notNow.
  ///
  /// In de, this message translates to:
  /// **'Nicht jetzt'**
  String get notNow;

  /// No description provided for @healthTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Fitness-Daten'**
  String get healthTitleOb;

  /// No description provided for @healthDescription.
  ///
  /// In de, this message translates to:
  /// **'Verbinde TRAUM mit deiner Gesundheits-App für automatische Schritte, Schlaf und Herzrate.'**
  String get healthDescription;

  /// No description provided for @connecting.
  ///
  /// In de, this message translates to:
  /// **'Verbindet...'**
  String get connecting;

  /// No description provided for @allowAccessImport.
  ///
  /// In de, this message translates to:
  /// **'Zugang erlauben & importieren'**
  String get allowAccessImport;

  /// No description provided for @doneTitleOb.
  ///
  /// In de, this message translates to:
  /// **'Alles bereit!'**
  String get doneTitleOb;

  /// No description provided for @welcomeName.
  ///
  /// In de, this message translates to:
  /// **'Willkommen, {name}!'**
  String welcomeName(String name);

  /// No description provided for @summaryGoals.
  ///
  /// In de, this message translates to:
  /// **'Ziele: {kcal} kcal · {water} ml Wasser'**
  String summaryGoals(int kcal, int water);

  /// No description provided for @faceIdActivate.
  ///
  /// In de, this message translates to:
  /// **'Face ID aktivieren'**
  String get faceIdActivate;

  /// No description provided for @fingerprintActivate.
  ///
  /// In de, this message translates to:
  /// **'Fingerabdruck aktivieren'**
  String get fingerprintActivate;

  /// No description provided for @biometricSetupReason.
  ///
  /// In de, this message translates to:
  /// **'TRAUM mit Biometrie schützen'**
  String get biometricSetupReason;

  /// No description provided for @authFailedShort.
  ///
  /// In de, this message translates to:
  /// **'Authentifizierung fehlgeschlagen'**
  String get authFailedShort;

  /// No description provided for @biometricCouldNotSet.
  ///
  /// In de, this message translates to:
  /// **'Biometrie konnte nicht eingerichtet werden'**
  String get biometricCouldNotSet;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In de, this message translates to:
  /// **'PINs stimmen nicht überein'**
  String get pinsDoNotMatch;

  /// No description provided for @appSecurity.
  ///
  /// In de, this message translates to:
  /// **'App-Sicherheit'**
  String get appSecurity;

  /// No description provided for @protectDataWith.
  ///
  /// In de, this message translates to:
  /// **'Schütze deine Daten mit'**
  String get protectDataWith;

  /// No description provided for @unlockAppFastSecure.
  ///
  /// In de, this message translates to:
  /// **'Schnell & sicher entsperren'**
  String get unlockAppFastSecure;

  /// No description provided for @pinSet.
  ///
  /// In de, this message translates to:
  /// **'PIN festlegen'**
  String get pinSet;

  /// No description provided for @pin4Digit.
  ///
  /// In de, this message translates to:
  /// **'4-stellige PIN'**
  String get pin4Digit;

  /// No description provided for @continueWithoutLock.
  ///
  /// In de, this message translates to:
  /// **'Ohne Sperre fortfahren'**
  String get continueWithoutLock;

  /// No description provided for @pinSetTitle.
  ///
  /// In de, this message translates to:
  /// **'PIN festlegen'**
  String get pinSetTitle;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'PIN bestätigen'**
  String get pinConfirmTitle;

  /// No description provided for @enterPin4Digits.
  ///
  /// In de, this message translates to:
  /// **'4-stellige PIN eingeben'**
  String get enterPin4Digits;

  /// No description provided for @enterPinAgainConfirm.
  ///
  /// In de, this message translates to:
  /// **'PIN erneut eingeben'**
  String get enterPinAgainConfirm;

  /// No description provided for @backToSelection.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Auswahl'**
  String get backToSelection;

  /// No description provided for @addSupplement.
  ///
  /// In de, this message translates to:
  /// **'Supplement hinzufügen'**
  String get addSupplement;

  /// No description provided for @supplementNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Vitamin D'**
  String get supplementNameHint;

  /// No description provided for @category.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get category;

  /// No description provided for @fieldAmount.
  ///
  /// In de, this message translates to:
  /// **'Menge'**
  String get fieldAmount;

  /// No description provided for @amountHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. 1000'**
  String get amountHint;

  /// No description provided for @fieldUnit.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get fieldUnit;

  /// No description provided for @categoryVitamins.
  ///
  /// In de, this message translates to:
  /// **'Vitamine'**
  String get categoryVitamins;

  /// No description provided for @categoryMinerals.
  ///
  /// In de, this message translates to:
  /// **'Mineralien'**
  String get categoryMinerals;

  /// No description provided for @categoryAminoAcids.
  ///
  /// In de, this message translates to:
  /// **'Aminosäuren'**
  String get categoryAminoAcids;

  /// No description provided for @categoryProtein.
  ///
  /// In de, this message translates to:
  /// **'Protein'**
  String get categoryProtein;

  /// No description provided for @categoryOmega3.
  ///
  /// In de, this message translates to:
  /// **'Omega-3'**
  String get categoryOmega3;

  /// No description provided for @categoryAdaptogens.
  ///
  /// In de, this message translates to:
  /// **'Adaptogene'**
  String get categoryAdaptogens;

  /// No description provided for @categoryPreWorkout.
  ///
  /// In de, this message translates to:
  /// **'Pre-Workout'**
  String get categoryPreWorkout;

  /// No description provided for @categoryGutHealth.
  ///
  /// In de, this message translates to:
  /// **'Darmgesundheit'**
  String get categoryGutHealth;

  /// No description provided for @categoryCreatine.
  ///
  /// In de, this message translates to:
  /// **'Creatin'**
  String get categoryCreatine;

  /// No description provided for @unitCapsules.
  ///
  /// In de, this message translates to:
  /// **'Kapseln'**
  String get unitCapsules;

  /// No description provided for @unitTablets.
  ///
  /// In de, this message translates to:
  /// **'Tabletten'**
  String get unitTablets;

  /// No description provided for @unitScoop.
  ///
  /// In de, this message translates to:
  /// **'Messbecher'**
  String get unitScoop;

  /// No description provided for @noSupplements.
  ///
  /// In de, this message translates to:
  /// **'Keine Supplements'**
  String get noSupplements;

  /// No description provided for @tapToAddSupplement.
  ///
  /// In de, this message translates to:
  /// **'Tippe, um ein Supplement hinzuzufügen'**
  String get tapToAddSupplement;

  /// No description provided for @avgCycleDaysShort.
  ///
  /// In de, this message translates to:
  /// **'Ø {n} T.'**
  String avgCycleDaysShort(int n);

  /// No description provided for @avgCycleDays.
  ///
  /// In de, this message translates to:
  /// **'Ø {days} T.'**
  String avgCycleDays(int days);

  /// No description provided for @avgDurationDays.
  ///
  /// In de, this message translates to:
  /// **'Ø {days} T.'**
  String avgDurationDays(int days);

  /// No description provided for @entriesLabel.
  ///
  /// In de, this message translates to:
  /// **'Einträge'**
  String get entriesLabel;

  /// No description provided for @irregularCycle.
  ///
  /// In de, this message translates to:
  /// **'Unregelmäßig'**
  String get irregularCycle;

  /// No description provided for @cycleLengths.
  ///
  /// In de, this message translates to:
  /// **'Zykluslängen'**
  String get cycleLengths;

  /// No description provided for @periods.
  ///
  /// In de, this message translates to:
  /// **'Perioden'**
  String get periods;

  /// No description provided for @cycle.
  ///
  /// In de, this message translates to:
  /// **'Zyklus'**
  String get cycle;

  /// No description provided for @tDayUnit.
  ///
  /// In de, this message translates to:
  /// **'T.'**
  String get tDayUnit;

  /// No description provided for @cycleHistory.
  ///
  /// In de, this message translates to:
  /// **'Zyklus-Verlauf'**
  String get cycleHistory;

  /// No description provided for @noHistory.
  ///
  /// In de, this message translates to:
  /// **'Kein Verlauf'**
  String get noHistory;

  /// No description provided for @logPeriodsToSeeStats.
  ///
  /// In de, this message translates to:
  /// **'Trage Perioden ein, um Statistiken zu sehen'**
  String get logPeriodsToSeeStats;

  /// No description provided for @flowLight.
  ///
  /// In de, this message translates to:
  /// **'Leicht'**
  String get flowLight;

  /// No description provided for @flowMedium.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get flowMedium;

  /// No description provided for @flowStrong.
  ///
  /// In de, this message translates to:
  /// **'Stark'**
  String get flowStrong;

  /// No description provided for @flowVeryStrong.
  ///
  /// In de, this message translates to:
  /// **'Sehr stark'**
  String get flowVeryStrong;

  /// No description provided for @periodBleed.
  ///
  /// In de, this message translates to:
  /// **'Periode'**
  String get periodBleed;

  /// No description provided for @predictedOvulation.
  ///
  /// In de, this message translates to:
  /// **'Voraussichtlicher Eisprung'**
  String get predictedOvulation;

  /// No description provided for @fertileWindow2.
  ///
  /// In de, this message translates to:
  /// **'Fruchtbares Fenster'**
  String get fertileWindow2;

  /// No description provided for @predictedPeriodStart.
  ///
  /// In de, this message translates to:
  /// **'Voraussichtlicher Periodenstart'**
  String get predictedPeriodStart;

  /// No description provided for @noSpecialEvent.
  ///
  /// In de, this message translates to:
  /// **'Kein besonderes Ereignis'**
  String get noSpecialEvent;

  /// No description provided for @periodCalendar.
  ///
  /// In de, this message translates to:
  /// **'Zykluskalender'**
  String get periodCalendar;

  /// No description provided for @symptomsToday.
  ///
  /// In de, this message translates to:
  /// **'Symptome heute'**
  String get symptomsToday;

  /// No description provided for @periodEntries.
  ///
  /// In de, this message translates to:
  /// **'Periodeneinträge'**
  String get periodEntries;

  /// No description provided for @tapToStartPeriod.
  ///
  /// In de, this message translates to:
  /// **'Tippe, um eine Periode zu starten'**
  String get tapToStartPeriod;

  /// No description provided for @follicularPhase.
  ///
  /// In de, this message translates to:
  /// **'Follikelphase'**
  String get follicularPhase;

  /// No description provided for @ovulationPhase.
  ///
  /// In de, this message translates to:
  /// **'Eisprungphase'**
  String get ovulationPhase;

  /// No description provided for @fertileWindowPhase.
  ///
  /// In de, this message translates to:
  /// **'Fruchtbares Fenster'**
  String get fertileWindowPhase;

  /// No description provided for @nextPeriodLabel.
  ///
  /// In de, this message translates to:
  /// **'Nächste Periode'**
  String get nextPeriodLabel;

  /// No description provided for @ovulationLabel.
  ///
  /// In de, this message translates to:
  /// **'Eisprung'**
  String get ovulationLabel;

  /// No description provided for @fertileLabel.
  ///
  /// In de, this message translates to:
  /// **'Fruchtbar'**
  String get fertileLabel;

  /// No description provided for @pregnancyProbabilityToday.
  ///
  /// In de, this message translates to:
  /// **'{pct}% Schwangerschaftswahrscheinlichkeit'**
  String pregnancyProbabilityToday(int pct);

  /// No description provided for @calendarTooltip.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get calendarTooltip;

  /// No description provided for @historyTooltip.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get historyTooltip;

  /// No description provided for @noSymptomsToday.
  ///
  /// In de, this message translates to:
  /// **'Keine Symptome heute'**
  String get noSymptomsToday;

  /// No description provided for @selectOrEnterSymptom.
  ///
  /// In de, this message translates to:
  /// **'Symptom auswählen oder eingeben'**
  String get selectOrEnterSymptom;

  /// No description provided for @endPeriod.
  ///
  /// In de, this message translates to:
  /// **'Periode beenden'**
  String get endPeriod;

  /// No description provided for @startPeriod.
  ///
  /// In de, this message translates to:
  /// **'Periode starten'**
  String get startPeriod;

  /// No description provided for @flowIntensity.
  ///
  /// In de, this message translates to:
  /// **'Stärke'**
  String get flowIntensity;

  /// No description provided for @noteOptional.
  ///
  /// In de, this message translates to:
  /// **'Notiz (optional)'**
  String get noteOptional;

  /// No description provided for @savingPeriod.
  ///
  /// In de, this message translates to:
  /// **'Wird gespeichert...'**
  String get savingPeriod;

  /// No description provided for @startPeriodButton.
  ///
  /// In de, this message translates to:
  /// **'Periode starten'**
  String get startPeriodButton;

  /// No description provided for @symptomCramps.
  ///
  /// In de, this message translates to:
  /// **'Krämpfe'**
  String get symptomCramps;

  /// No description provided for @symptomHeadache.
  ///
  /// In de, this message translates to:
  /// **'Kopfschmerzen'**
  String get symptomHeadache;

  /// No description provided for @symptomBackPain.
  ///
  /// In de, this message translates to:
  /// **'Rückenschmerzen'**
  String get symptomBackPain;

  /// No description provided for @symptomBreastTension.
  ///
  /// In de, this message translates to:
  /// **'Brustspannen'**
  String get symptomBreastTension;

  /// No description provided for @symptomBloating.
  ///
  /// In de, this message translates to:
  /// **'Blähungen'**
  String get symptomBloating;

  /// No description provided for @symptomNausea.
  ///
  /// In de, this message translates to:
  /// **'Übelkeit'**
  String get symptomNausea;

  /// No description provided for @symptomMoodSwings.
  ///
  /// In de, this message translates to:
  /// **'Stimmungsschwankungen'**
  String get symptomMoodSwings;

  /// No description provided for @symptomTiredness.
  ///
  /// In de, this message translates to:
  /// **'Müdigkeit'**
  String get symptomTiredness;

  /// No description provided for @symptomAcne.
  ///
  /// In de, this message translates to:
  /// **'Akne'**
  String get symptomAcne;

  /// No description provided for @symptomSleepIssues.
  ///
  /// In de, this message translates to:
  /// **'Schlafprobleme'**
  String get symptomSleepIssues;

  /// No description provided for @addSymptom.
  ///
  /// In de, this message translates to:
  /// **'Symptom hinzufügen'**
  String get addSymptom;

  /// No description provided for @orCustomSymptom.
  ///
  /// In de, this message translates to:
  /// **'oder eigenes Symptom eingeben'**
  String get orCustomSymptom;

  /// No description provided for @intensityLabel.
  ///
  /// In de, this message translates to:
  /// **'Intensität'**
  String get intensityLabel;

  /// No description provided for @intensityLight.
  ///
  /// In de, this message translates to:
  /// **'Leicht'**
  String get intensityLight;

  /// No description provided for @intensityMedium.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get intensityMedium;

  /// No description provided for @intensityStrong.
  ///
  /// In de, this message translates to:
  /// **'Stark'**
  String get intensityStrong;

  /// No description provided for @saveSymptom.
  ///
  /// In de, this message translates to:
  /// **'Symptom speichern'**
  String get saveSymptom;

  /// No description provided for @fertileLegend.
  ///
  /// In de, this message translates to:
  /// **'Fruchtbar'**
  String get fertileLegend;

  /// No description provided for @ovulationLegend.
  ///
  /// In de, this message translates to:
  /// **'Eisprung'**
  String get ovulationLegend;

  /// No description provided for @periodLegend.
  ///
  /// In de, this message translates to:
  /// **'Periode'**
  String get periodLegend;

  /// No description provided for @noAppointmentsOnDate.
  ///
  /// In de, this message translates to:
  /// **'Keine Termine am {date}'**
  String noAppointmentsOnDate(String date);

  /// No description provided for @addAppointment.
  ///
  /// In de, this message translates to:
  /// **'Termin hinzufügen'**
  String get addAppointment;

  /// No description provided for @titleRequiredField.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get titleRequiredField;

  /// No description provided for @location.
  ///
  /// In de, this message translates to:
  /// **'Ort'**
  String get location;

  /// No description provided for @optional.
  ///
  /// In de, this message translates to:
  /// **'(optional)'**
  String get optional;

  /// No description provided for @startLabel.
  ///
  /// In de, this message translates to:
  /// **'Beginn'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In de, this message translates to:
  /// **'Ende'**
  String get endLabel;

  /// No description provided for @titleRequired.
  ///
  /// In de, this message translates to:
  /// **'Titel erforderlich'**
  String get titleRequired;

  /// No description provided for @noTasks.
  ///
  /// In de, this message translates to:
  /// **'Keine Aufgaben'**
  String get noTasks;

  /// No description provided for @tapToAddTask.
  ///
  /// In de, this message translates to:
  /// **'Tippe, um eine Aufgabe hinzuzufügen'**
  String get tapToAddTask;

  /// No description provided for @open.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get open;

  /// No description provided for @finished.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get finished;

  /// No description provided for @dueDateLabel.
  ///
  /// In de, this message translates to:
  /// **'Fällig: {date}'**
  String dueDateLabel(String date);

  /// No description provided for @addTask.
  ///
  /// In de, this message translates to:
  /// **'Aufgabe hinzufügen'**
  String get addTask;

  /// No description provided for @fieldTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get fieldTitle;

  /// No description provided for @fieldPriority.
  ///
  /// In de, this message translates to:
  /// **'Priorität'**
  String get fieldPriority;

  /// No description provided for @priorityLow.
  ///
  /// In de, this message translates to:
  /// **'Niedrig'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In de, this message translates to:
  /// **'Hoch'**
  String get priorityHigh;

  /// No description provided for @dueDate.
  ///
  /// In de, this message translates to:
  /// **'Fälligkeitsdatum'**
  String get dueDate;

  /// No description provided for @noGoals.
  ///
  /// In de, this message translates to:
  /// **'Keine Ziele'**
  String get noGoals;

  /// No description provided for @addGoal.
  ///
  /// In de, this message translates to:
  /// **'Ziel hinzufügen'**
  String get addGoal;

  /// No description provided for @targetValue.
  ///
  /// In de, this message translates to:
  /// **'Zielwert'**
  String get targetValue;

  /// No description provided for @unitHintKgKm.
  ///
  /// In de, this message translates to:
  /// **'z.B. kg, km'**
  String get unitHintKgKm;

  /// No description provided for @deadline.
  ///
  /// In de, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @noHabits.
  ///
  /// In de, this message translates to:
  /// **'Keine Gewohnheiten'**
  String get noHabits;

  /// No description provided for @tapToAddHabit.
  ///
  /// In de, this message translates to:
  /// **'Tippe, um eine Gewohnheit hinzuzufügen'**
  String get tapToAddHabit;

  /// No description provided for @addHabit.
  ///
  /// In de, this message translates to:
  /// **'Gewohnheit hinzufügen'**
  String get addHabit;

  /// No description provided for @frequency.
  ///
  /// In de, this message translates to:
  /// **'Häufigkeit'**
  String get frequency;

  /// No description provided for @frequencyDaily.
  ///
  /// In de, this message translates to:
  /// **'Täglich'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In de, this message translates to:
  /// **'Wöchentlich'**
  String get frequencyWeekly;

  /// No description provided for @calendar.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get calendar;

  /// No description provided for @todosTab.
  ///
  /// In de, this message translates to:
  /// **'Aufgaben'**
  String get todosTab;

  /// No description provided for @goalsTab.
  ///
  /// In de, this message translates to:
  /// **'Ziele'**
  String get goalsTab;

  /// No description provided for @habitsTab.
  ///
  /// In de, this message translates to:
  /// **'Gewohnheiten'**
  String get habitsTab;

  /// No description provided for @bmi.
  ///
  /// In de, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @weightGoalLabel.
  ///
  /// In de, this message translates to:
  /// **'Zielgewicht'**
  String get weightGoalLabel;

  /// No description provided for @loseAction.
  ///
  /// In de, this message translates to:
  /// **'abnehmen'**
  String get loseAction;

  /// No description provided for @gainAction.
  ///
  /// In de, this message translates to:
  /// **'zunehmen'**
  String get gainAction;

  /// No description provided for @weightDiff.
  ///
  /// In de, this message translates to:
  /// **'{diff} kg {action}'**
  String weightDiff(String diff, String action);

  /// No description provided for @sleepDays.
  ///
  /// In de, this message translates to:
  /// **'Letzte {days} Tage'**
  String sleepDays(int days);

  /// No description provided for @avgSleepDuration.
  ///
  /// In de, this message translates to:
  /// **'Ø Schlafdauer'**
  String get avgSleepDuration;

  /// No description provided for @avgQuality.
  ///
  /// In de, this message translates to:
  /// **'Ø Qualität'**
  String get avgQuality;

  /// No description provided for @trainingThisWeek.
  ///
  /// In de, this message translates to:
  /// **'Training diese Woche'**
  String get trainingThisWeek;

  /// No description provided for @workoutsLabel.
  ///
  /// In de, this message translates to:
  /// **'Workouts'**
  String get workoutsLabel;

  /// No description provided for @setsLabel.
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get setsLabel;

  /// No description provided for @volumeLabel.
  ///
  /// In de, this message translates to:
  /// **'Volumen'**
  String get volumeLabel;

  /// No description provided for @nutritionGoals.
  ///
  /// In de, this message translates to:
  /// **'Ernährungsziele'**
  String get nutritionGoals;

  /// No description provided for @kcalGoal.
  ///
  /// In de, this message translates to:
  /// **'kcal-Ziel'**
  String get kcalGoal;

  /// No description provided for @proteinGoal.
  ///
  /// In de, this message translates to:
  /// **'Protein-Ziel'**
  String get proteinGoal;

  /// No description provided for @stepsGoal.
  ///
  /// In de, this message translates to:
  /// **'Schrittziel'**
  String get stepsGoal;

  /// No description provided for @moodLabel.
  ///
  /// In de, this message translates to:
  /// **'Stimmung'**
  String get moodLabel;

  /// No description provided for @noMoodData.
  ///
  /// In de, this message translates to:
  /// **'Keine Stimmungsdaten'**
  String get noMoodData;

  /// No description provided for @moodLast.
  ///
  /// In de, this message translates to:
  /// **'Letzter Wert: {score}/5'**
  String moodLast(int score);

  /// No description provided for @bmiUnderweight.
  ///
  /// In de, this message translates to:
  /// **'Untergewicht'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In de, this message translates to:
  /// **'Normalgewicht'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In de, this message translates to:
  /// **'Übergewicht'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In de, this message translates to:
  /// **'Adipositas'**
  String get bmiObese;

  /// No description provided for @myProfile.
  ///
  /// In de, this message translates to:
  /// **'Mein Profil'**
  String get myProfile;

  /// No description provided for @myDashboard.
  ///
  /// In de, this message translates to:
  /// **'Mein Dashboard'**
  String get myDashboard;

  /// No description provided for @body.
  ///
  /// In de, this message translates to:
  /// **'Körper'**
  String get body;

  /// No description provided for @height.
  ///
  /// In de, this message translates to:
  /// **'Körpergröße'**
  String get height;

  /// No description provided for @exportSelected.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählte exportieren'**
  String get exportSelected;

  /// No description provided for @exportPreparing.
  ///
  /// In de, this message translates to:
  /// **'Wird vorbereitet...'**
  String get exportPreparing;

  /// No description provided for @supportSection.
  ///
  /// In de, this message translates to:
  /// **'Support'**
  String get supportSection;

  /// No description provided for @bugReportDarkModeYes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get bugReportDarkModeYes;

  /// No description provided for @bugReportDevice.
  ///
  /// In de, this message translates to:
  /// **'Gerät: {device}'**
  String bugReportDevice(String device);

  /// No description provided for @bugReportSubject.
  ///
  /// In de, this message translates to:
  /// **'[TRAUM] Fehlerbericht'**
  String get bugReportSubject;

  /// No description provided for @bugReportBody.
  ///
  /// In de, this message translates to:
  /// **'Bitte beschreibe den Fehler:'**
  String get bugReportBody;

  /// No description provided for @appSection.
  ///
  /// In de, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @repeatOnboardingSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Onboarding erneut durchlaufen'**
  String get repeatOnboardingSubtitle;

  /// No description provided for @navigationSection.
  ///
  /// In de, this message translates to:
  /// **'Navigation'**
  String get navigationSection;

  /// No description provided for @adjustNavSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle deine Module'**
  String get adjustNavSubtitle;

  /// No description provided for @units.
  ///
  /// In de, this message translates to:
  /// **'Einheiten'**
  String get units;

  /// No description provided for @metricSwitch.
  ///
  /// In de, this message translates to:
  /// **'Metrisch'**
  String get metricSwitch;

  /// No description provided for @metricSwitchSubtitle.
  ///
  /// In de, this message translates to:
  /// **'kg, cm, km'**
  String get metricSwitchSubtitle;

  /// No description provided for @notificationsSection.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notificationsSection;

  /// No description provided for @notifMedication.
  ///
  /// In de, this message translates to:
  /// **'Medikamente'**
  String get notifMedication;

  /// No description provided for @notifSupplements.
  ///
  /// In de, this message translates to:
  /// **'Supplements'**
  String get notifSupplements;

  /// No description provided for @notifTraining.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get notifTraining;

  /// No description provided for @notifWater.
  ///
  /// In de, this message translates to:
  /// **'Wasser'**
  String get notifWater;

  /// No description provided for @notifHabits.
  ///
  /// In de, this message translates to:
  /// **'Gewohnheiten'**
  String get notifHabits;

  /// No description provided for @notifTodos.
  ///
  /// In de, this message translates to:
  /// **'Aufgaben'**
  String get notifTodos;

  /// No description provided for @notifCycle.
  ///
  /// In de, this message translates to:
  /// **'Zyklus'**
  String get notifCycle;

  /// No description provided for @notifDailyAt.
  ///
  /// In de, this message translates to:
  /// **'Täglich um {time}'**
  String notifDailyAt(String time);

  /// No description provided for @goals.
  ///
  /// In de, this message translates to:
  /// **'Ziele'**
  String get goals;

  /// No description provided for @kcalGoalLabel.
  ///
  /// In de, this message translates to:
  /// **'Kalorienziel'**
  String get kcalGoalLabel;

  /// No description provided for @proteinGoalLabel.
  ///
  /// In de, this message translates to:
  /// **'Proteinziel (g)'**
  String get proteinGoalLabel;

  /// No description provided for @stepsGoalLabel.
  ///
  /// In de, this message translates to:
  /// **'Schrittziel'**
  String get stepsGoalLabel;

  /// No description provided for @stepsGoalSuffix.
  ///
  /// In de, this message translates to:
  /// **'Schritte'**
  String get stepsGoalSuffix;

  /// No description provided for @heightLabel.
  ///
  /// In de, this message translates to:
  /// **'Körpergröße'**
  String get heightLabel;

  /// No description provided for @heightCm.
  ///
  /// In de, this message translates to:
  /// **'cm'**
  String get heightCm;

  /// No description provided for @weightGoalCm.
  ///
  /// In de, this message translates to:
  /// **'kg'**
  String get weightGoalCm;

  /// No description provided for @waterGoal.
  ///
  /// In de, this message translates to:
  /// **'Wasserziel'**
  String get waterGoal;

  /// No description provided for @waterGoalAutomatic.
  ///
  /// In de, this message translates to:
  /// **'Automatisch ({ml} ml)'**
  String waterGoalAutomatic(int ml);

  /// No description provided for @currency.
  ///
  /// In de, this message translates to:
  /// **'Währung'**
  String get currency;

  /// No description provided for @currencySymbol.
  ///
  /// In de, this message translates to:
  /// **'Währungssymbol'**
  String get currencySymbol;

  /// No description provided for @chooseCurrency.
  ///
  /// In de, this message translates to:
  /// **'Währung wählen'**
  String get chooseCurrency;

  /// No description provided for @periodTracking.
  ///
  /// In de, this message translates to:
  /// **'Zyklustracking'**
  String get periodTracking;

  /// No description provided for @enablePeriodTracking.
  ///
  /// In de, this message translates to:
  /// **'Zyklustracking aktivieren'**
  String get enablePeriodTracking;

  /// No description provided for @periodTrackingSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Verfolge deinen Zyklus'**
  String get periodTrackingSubtitle;

  /// No description provided for @privacySecurity.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz & Sicherheit'**
  String get privacySecurity;

  /// No description provided for @biometricLockSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Biometrie verwenden'**
  String get biometricLockSubtitle;

  /// No description provided for @biometricLockUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Biometrie nicht verfügbar'**
  String get biometricLockUnavailable;

  /// No description provided for @pinLock.
  ///
  /// In de, this message translates to:
  /// **'PIN-Sperre'**
  String get pinLock;

  /// No description provided for @pinLockSubtitle.
  ///
  /// In de, this message translates to:
  /// **'4-stellige PIN'**
  String get pinLockSubtitle;

  /// No description provided for @changePin.
  ///
  /// In de, this message translates to:
  /// **'PIN ändern'**
  String get changePin;

  /// No description provided for @languageSection.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get languageSection;

  /// No description provided for @appLanguage.
  ///
  /// In de, this message translates to:
  /// **'App-Sprache'**
  String get appLanguage;

  /// No description provided for @deleteAllConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten löschen?'**
  String get deleteAllConfirmTitle;

  /// No description provided for @deleteAllConfirmContent.
  ///
  /// In de, this message translates to:
  /// **'Diese Aktion kann nicht rückgängig gemacht werden.'**
  String get deleteAllConfirmContent;

  /// No description provided for @continueLabel.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get continueLabel;

  /// No description provided for @reallyDeleteAllTitle.
  ///
  /// In de, this message translates to:
  /// **'Wirklich alles löschen?'**
  String get reallyDeleteAllTitle;

  /// No description provided for @reallyDeleteAllContent.
  ///
  /// In de, this message translates to:
  /// **'Alle deine Daten werden permanent gelöscht.'**
  String get reallyDeleteAllContent;

  /// No description provided for @deleteEverything.
  ///
  /// In de, this message translates to:
  /// **'Alles löschen'**
  String get deleteEverything;

  /// No description provided for @exportAll.
  ///
  /// In de, this message translates to:
  /// **'Alles exportieren'**
  String get exportAll;

  /// No description provided for @exportSelection.
  ///
  /// In de, this message translates to:
  /// **'Auswahl exportieren'**
  String get exportSelection;

  /// No description provided for @chooseLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache wählen'**
  String get chooseLanguage;

  /// No description provided for @exercise.
  ///
  /// In de, this message translates to:
  /// **'Übung'**
  String get exercise;

  /// No description provided for @muscleBrust.
  ///
  /// In de, this message translates to:
  /// **'Brust'**
  String get muscleBrust;

  /// No description provided for @muscleRuecken.
  ///
  /// In de, this message translates to:
  /// **'Rücken'**
  String get muscleRuecken;

  /// No description provided for @muscleSchulter.
  ///
  /// In de, this message translates to:
  /// **'Schultern'**
  String get muscleSchulter;

  /// No description provided for @muscleBizeps.
  ///
  /// In de, this message translates to:
  /// **'Bizeps'**
  String get muscleBizeps;

  /// No description provided for @muscleTrizeps.
  ///
  /// In de, this message translates to:
  /// **'Trizeps'**
  String get muscleTrizeps;

  /// No description provided for @muscleBauch.
  ///
  /// In de, this message translates to:
  /// **'Bauch'**
  String get muscleBauch;

  /// No description provided for @muscleBeine.
  ///
  /// In de, this message translates to:
  /// **'Beine'**
  String get muscleBeine;

  /// No description provided for @muscleGesaess.
  ///
  /// In de, this message translates to:
  /// **'Gesäß'**
  String get muscleGesaess;

  /// No description provided for @muscleWaden.
  ///
  /// In de, this message translates to:
  /// **'Waden'**
  String get muscleWaden;

  /// No description provided for @muscleGanzkoerper.
  ///
  /// In de, this message translates to:
  /// **'Ganzkörper'**
  String get muscleGanzkoerper;

  /// No description provided for @noWorkoutPlanned.
  ///
  /// In de, this message translates to:
  /// **'Kein Workout geplant'**
  String get noWorkoutPlanned;

  /// No description provided for @weeklyProgress.
  ///
  /// In de, this message translates to:
  /// **'Wochenfortschritt'**
  String get weeklyProgress;

  /// No description provided for @createRoutine.
  ///
  /// In de, this message translates to:
  /// **'Routine erstellen'**
  String get createRoutine;

  /// No description provided for @muscleGroupsOverview.
  ///
  /// In de, this message translates to:
  /// **'Muskelgruppen-Übersicht'**
  String get muscleGroupsOverview;

  /// No description provided for @noTrainingSessionsRecorded.
  ///
  /// In de, this message translates to:
  /// **'Keine Trainingseinheiten aufgezeichnet'**
  String get noTrainingSessionsRecorded;

  /// No description provided for @myRoutines.
  ///
  /// In de, this message translates to:
  /// **'Meine Routinen'**
  String get myRoutines;

  /// No description provided for @noRoutinesCreated.
  ///
  /// In de, this message translates to:
  /// **'Keine Routinen erstellt'**
  String get noRoutinesCreated;

  /// No description provided for @trainingDayName.
  ///
  /// In de, this message translates to:
  /// **'Tag {letter}'**
  String trainingDayName(String letter);

  /// No description provided for @trainingDayA.
  ///
  /// In de, this message translates to:
  /// **'Tag A'**
  String get trainingDayA;

  /// No description provided for @newRoutine.
  ///
  /// In de, this message translates to:
  /// **'Neue Routine'**
  String get newRoutine;

  /// No description provided for @routineName.
  ///
  /// In de, this message translates to:
  /// **'Routinenname'**
  String get routineName;

  /// No description provided for @routineNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Push Day'**
  String get routineNameHint;

  /// No description provided for @descriptionOptional.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung (optional)'**
  String get descriptionOptional;

  /// No description provided for @descriptionHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Brust & Schultern'**
  String get descriptionHint;

  /// No description provided for @setAsActive.
  ///
  /// In de, this message translates to:
  /// **'Als aktiv setzen'**
  String get setAsActive;

  /// No description provided for @trainingDays.
  ///
  /// In de, this message translates to:
  /// **'Trainingstage'**
  String get trainingDays;

  /// No description provided for @addDay.
  ///
  /// In de, this message translates to:
  /// **'Tag hinzufügen'**
  String get addDay;

  /// No description provided for @createRoutineButton.
  ///
  /// In de, this message translates to:
  /// **'Routine erstellen'**
  String get createRoutineButton;

  /// No description provided for @trainingRoutines.
  ///
  /// In de, this message translates to:
  /// **'Trainingsroutinen'**
  String get trainingRoutines;

  /// No description provided for @noRoutines.
  ///
  /// In de, this message translates to:
  /// **'Keine Routinen'**
  String get noRoutines;

  /// No description provided for @tapToCreateRoutine.
  ///
  /// In de, this message translates to:
  /// **'Tippe, um eine Routine zu erstellen'**
  String get tapToCreateRoutine;

  /// No description provided for @activate.
  ///
  /// In de, this message translates to:
  /// **'Aktivieren'**
  String get activate;

  /// No description provided for @active.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get active;

  /// No description provided for @trainingPlan.
  ///
  /// In de, this message translates to:
  /// **'Trainingsplan'**
  String get trainingPlan;

  /// No description provided for @noTrainingDays.
  ///
  /// In de, this message translates to:
  /// **'Keine Trainingstage'**
  String get noTrainingDays;

  /// No description provided for @workoutDetails.
  ///
  /// In de, this message translates to:
  /// **'Workout-Details'**
  String get workoutDetails;

  /// No description provided for @noSetsRecorded.
  ///
  /// In de, this message translates to:
  /// **'Keine Sätze aufgezeichnet'**
  String get noSetsRecorded;

  /// No description provided for @setLabel.
  ///
  /// In de, this message translates to:
  /// **'Satz {n}'**
  String setLabel(int n);

  /// No description provided for @repsCount.
  ///
  /// In de, this message translates to:
  /// **'{n} Wdh.'**
  String repsCount(int n);

  /// No description provided for @setCount.
  ///
  /// In de, this message translates to:
  /// **'{n} Sätze'**
  String setCount(int n);

  /// No description provided for @addExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung hinzufügen'**
  String get addExercise;

  /// No description provided for @exerciseLibrary.
  ///
  /// In de, this message translates to:
  /// **'Übungsbibliothek'**
  String get exerciseLibrary;

  /// No description provided for @exerciseHint.
  ///
  /// In de, this message translates to:
  /// **'Übungsname'**
  String get exerciseHint;

  /// No description provided for @equipmentOptional.
  ///
  /// In de, this message translates to:
  /// **'Equipment (optional)'**
  String get equipmentOptional;

  /// No description provided for @equipmentHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Hantel'**
  String get equipmentHint;

  /// No description provided for @instructionsOptional.
  ///
  /// In de, this message translates to:
  /// **'Ausführung (optional)'**
  String get instructionsOptional;

  /// No description provided for @instructionExecution.
  ///
  /// In de, this message translates to:
  /// **'Ausführungshinweis'**
  String get instructionExecution;

  /// No description provided for @noExercisesInLibrary.
  ///
  /// In de, this message translates to:
  /// **'Keine Übungen in der Bibliothek'**
  String get noExercisesInLibrary;

  /// No description provided for @noExercisesYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Übungen'**
  String get noExercisesYet;

  /// No description provided for @muscleGroup.
  ///
  /// In de, this message translates to:
  /// **'Muskelgruppe'**
  String get muscleGroup;

  /// No description provided for @muscleHeatmapTitle.
  ///
  /// In de, this message translates to:
  /// **'Muskel-Heatmap'**
  String get muscleHeatmapTitle;

  /// No description provided for @recentSets.
  ///
  /// In de, this message translates to:
  /// **'Letzte Sätze'**
  String get recentSets;

  /// No description provided for @trainExerciseToSeeProgress.
  ///
  /// In de, this message translates to:
  /// **'Trainiere diese Übung, um Fortschritt zu sehen'**
  String get trainExerciseToSeeProgress;

  /// No description provided for @noProgressData.
  ///
  /// In de, this message translates to:
  /// **'Keine Fortschrittsdaten'**
  String get noProgressData;

  /// No description provided for @trainingVolumeLast7Days.
  ///
  /// In de, this message translates to:
  /// **'Trainingsvolumen (letzte 7 Tage)'**
  String get trainingVolumeLast7Days;

  /// No description provided for @volumeLast90Days.
  ///
  /// In de, this message translates to:
  /// **'Volumen (letzte 90 Tage)'**
  String get volumeLast90Days;

  /// No description provided for @maxWeight.
  ///
  /// In de, this message translates to:
  /// **'Max. Gewicht'**
  String get maxWeight;

  /// No description provided for @maxReps.
  ///
  /// In de, this message translates to:
  /// **'Max. Wdh.'**
  String get maxReps;

  /// No description provided for @little.
  ///
  /// In de, this message translates to:
  /// **'Wenig'**
  String get little;

  /// No description provided for @much.
  ///
  /// In de, this message translates to:
  /// **'Viel'**
  String get much;

  /// No description provided for @restTimerLabel.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get restTimerLabel;

  /// No description provided for @addSet.
  ///
  /// In de, this message translates to:
  /// **'Satz hinzufügen'**
  String get addSet;

  /// No description provided for @noTraining.
  ///
  /// In de, this message translates to:
  /// **'Kein Training'**
  String get noTraining;

  /// No description provided for @notTrained.
  ///
  /// In de, this message translates to:
  /// **'Nicht trainiert'**
  String get notTrained;

  /// No description provided for @progress.
  ///
  /// In de, this message translates to:
  /// **'Fortschritt'**
  String get progress;

  /// No description provided for @reps.
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen'**
  String get reps;

  /// No description provided for @finishing.
  ///
  /// In de, this message translates to:
  /// **'Wird beendet...'**
  String get finishing;

  /// No description provided for @noTrainingPlanned.
  ///
  /// In de, this message translates to:
  /// **'Kein Training geplant'**
  String get noTrainingPlanned;

  /// No description provided for @exercises.
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get exercises;

  /// No description provided for @volumeKg.
  ///
  /// In de, this message translates to:
  /// **'Volumen (kg)'**
  String get volumeKg;

  /// No description provided for @createExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung erstellen'**
  String get createExercise;

  /// No description provided for @medium.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get medium;

  /// No description provided for @noExercises.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Übungen'**
  String get noExercises;

  /// No description provided for @wizardSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get wizardSkip;

  /// No description provided for @wizardNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get wizardNext;

  /// No description provided for @wizardFinish.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get wizardFinish;

  /// No description provided for @wizardStepOf.
  ///
  /// In de, this message translates to:
  /// **'Schritt {current} von {total}'**
  String wizardStepOf(int current, int total);

  /// No description provided for @templateSelectTitle.
  ///
  /// In de, this message translates to:
  /// **'Vorlage wählen'**
  String get templateSelectTitle;

  /// No description provided for @templateSelectSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen bewährten Plan oder erstelle deinen eigenen.'**
  String get templateSelectSubtitle;

  /// No description provided for @daysSelectTitle.
  ///
  /// In de, this message translates to:
  /// **'Trainingstage'**
  String get daysSelectTitle;

  /// No description provided for @daysSelectSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle die Tage und passe die Namen an.'**
  String get daysSelectSubtitle;

  /// No description provided for @exercisesReviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Übungen prüfen'**
  String get exercisesReviewTitle;

  /// No description provided for @exercisesReviewSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Passe die Übungen je Trainingstag an.'**
  String get exercisesReviewSubtitle;

  /// No description provided for @searchExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung suchen...'**
  String get searchExercise;

  /// No description provided for @restDay.
  ///
  /// In de, this message translates to:
  /// **'Ruhetag'**
  String get restDay;

  /// No description provided for @freeTraining.
  ///
  /// In de, this message translates to:
  /// **'Freies Training'**
  String get freeTraining;

  /// No description provided for @completedThisWeek.
  ///
  /// In de, this message translates to:
  /// **'Absolviert'**
  String get completedThisWeek;

  /// No description provided for @plannedThisWeek.
  ///
  /// In de, this message translates to:
  /// **'Geplant'**
  String get plannedThisWeek;

  /// No description provided for @weeklyVolume.
  ///
  /// In de, this message translates to:
  /// **'Volumen'**
  String get weeklyVolume;

  /// No description provided for @exercisesToday.
  ///
  /// In de, this message translates to:
  /// **'{count} Übungen · heute'**
  String exercisesToday(int count);

  /// No description provided for @sessionNamesLabel.
  ///
  /// In de, this message translates to:
  /// **'Einheitennamen'**
  String get sessionNamesLabel;

  /// No description provided for @bookmarked.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert'**
  String get bookmarked;

  /// No description provided for @estimated1RM.
  ///
  /// In de, this message translates to:
  /// **'Geschätzter 1RM (Epley)'**
  String get estimated1RM;

  /// No description provided for @heavilyTrained.
  ///
  /// In de, this message translates to:
  /// **'Stark trainiert'**
  String get heavilyTrained;

  /// No description provided for @lightlyTrained.
  ///
  /// In de, this message translates to:
  /// **'Leicht trainiert'**
  String get lightlyTrained;

  /// No description provided for @notTrainedHeatmap.
  ///
  /// In de, this message translates to:
  /// **'Nicht trainiert'**
  String get notTrainedHeatmap;

  /// No description provided for @restTimer.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get restTimer;

  /// No description provided for @restTimerSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get restTimerSkip;

  /// No description provided for @bookmarkExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung speichern'**
  String get bookmarkExercise;

  /// No description provided for @warmupSet.
  ///
  /// In de, this message translates to:
  /// **'Aufwärm-Satz'**
  String get warmupSet;

  /// No description provided for @workoutStreak.
  ///
  /// In de, this message translates to:
  /// **'Tage in Folge'**
  String get workoutStreak;

  /// No description provided for @restDuration.
  ///
  /// In de, this message translates to:
  /// **'Pausenlänge'**
  String get restDuration;

  /// No description provided for @muscleGroupVolume.
  ///
  /// In de, this message translates to:
  /// **'Volumen pro Muskelgruppe'**
  String get muscleGroupVolume;

  /// No description provided for @noMuscleDataThisWeek.
  ///
  /// In de, this message translates to:
  /// **'Kein Trainingsvolumen diese Woche'**
  String get noMuscleDataThisWeek;

  /// No description provided for @lastPerformanceHint.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt: {info}'**
  String lastPerformanceHint(String info);

  /// No description provided for @noLastPerformance.
  ///
  /// In de, this message translates to:
  /// **'Keine früheren Daten'**
  String get noLastPerformance;

  /// No description provided for @instructionsLabel.
  ///
  /// In de, this message translates to:
  /// **'Ausführung'**
  String get instructionsLabel;

  /// No description provided for @equipmentLabel.
  ///
  /// In de, this message translates to:
  /// **'Equipment'**
  String get equipmentLabel;

  /// No description provided for @difficultyLabel.
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit'**
  String get difficultyLabel;

  /// No description provided for @detailsLabel.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @feedbackTitle.
  ///
  /// In de, this message translates to:
  /// **'Feedback senden'**
  String get feedbackTitle;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Feedback hilft TRAUM besser zu machen.'**
  String get feedbackSubtitle;

  /// No description provided for @feedbackTypeBug.
  ///
  /// In de, this message translates to:
  /// **'Bug'**
  String get feedbackTypeBug;

  /// No description provided for @feedbackTypeFeature.
  ///
  /// In de, this message translates to:
  /// **'Feature'**
  String get feedbackTypeFeature;

  /// No description provided for @feedbackTypeImprovement.
  ///
  /// In de, this message translates to:
  /// **'Verbesserung'**
  String get feedbackTypeImprovement;

  /// No description provided for @feedbackShortTitle.
  ///
  /// In de, this message translates to:
  /// **'Kurztitel'**
  String get feedbackShortTitle;

  /// No description provided for @feedbackDescription.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get feedbackDescription;

  /// No description provided for @feedbackSubmit.
  ///
  /// In de, this message translates to:
  /// **'GitHub öffnen & absenden'**
  String get feedbackSubmit;

  /// No description provided for @feedbackHint.
  ///
  /// In de, this message translates to:
  /// **'Öffnet GitHub im Browser. Ein GitHub-Account ist zum Absenden nötig.'**
  String get feedbackHint;

  /// No description provided for @feedbackSystemInfo.
  ///
  /// In de, this message translates to:
  /// **'Systemdaten werden automatisch angehängt.'**
  String get feedbackSystemInfo;

  /// No description provided for @settingsFeedback.
  ///
  /// In de, this message translates to:
  /// **'Feedback & Fehler melden'**
  String get settingsFeedback;

  /// No description provided for @settingsFeedbackSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Bug · Feature · Verbesserung'**
  String get settingsFeedbackSubtitle;

  /// No description provided for @newWorkout.
  ///
  /// In de, this message translates to:
  /// **'Neues Workout'**
  String get newWorkout;

  /// No description provided for @addFirstExercise.
  ///
  /// In de, this message translates to:
  /// **'Füge deine erste Übung hinzu'**
  String get addFirstExercise;

  /// No description provided for @discardWorkout.
  ///
  /// In de, this message translates to:
  /// **'Workout verwerfen'**
  String get discardWorkout;

  /// No description provided for @deleteSet.
  ///
  /// In de, this message translates to:
  /// **'Satz löschen'**
  String get deleteSet;

  /// No description provided for @exerciseInfo.
  ///
  /// In de, this message translates to:
  /// **'Übungsinfo'**
  String get exerciseInfo;

  /// No description provided for @addNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz hinzufügen'**
  String get addNote;

  /// No description provided for @addNoteHint.
  ///
  /// In de, this message translates to:
  /// **'Notiz hinzufügen...'**
  String get addNoteHint;

  /// No description provided for @removeExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung entfernen'**
  String get removeExercise;

  /// No description provided for @normalSet.
  ///
  /// In de, this message translates to:
  /// **'Normaler Satz'**
  String get normalSet;

  /// No description provided for @warmupSetLabel.
  ///
  /// In de, this message translates to:
  /// **'Aufwärm-Satz'**
  String get warmupSetLabel;

  /// No description provided for @dropSet.
  ///
  /// In de, this message translates to:
  /// **'Drop-Satz'**
  String get dropSet;

  /// No description provided for @failureSet.
  ///
  /// In de, this message translates to:
  /// **'Versagenssatz'**
  String get failureSet;

  /// No description provided for @exerciseNotFound.
  ///
  /// In de, this message translates to:
  /// **'Übung nicht gefunden'**
  String get exerciseNotFound;

  /// No description provided for @trainingVolume.
  ///
  /// In de, this message translates to:
  /// **'Trainingsvolumen'**
  String get trainingVolume;

  /// No description provided for @timesPerformed.
  ///
  /// In de, this message translates to:
  /// **'Mal durchgeführt'**
  String get timesPerformed;

  /// No description provided for @totalDuration.
  ///
  /// In de, this message translates to:
  /// **'Gesamtdauer'**
  String get totalDuration;

  /// No description provided for @totalVolume.
  ///
  /// In de, this message translates to:
  /// **'Gesamtvolumen'**
  String get totalVolume;

  /// No description provided for @noDataYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Daten'**
  String get noDataYet;

  /// No description provided for @mostRecent.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt'**
  String get mostRecent;

  /// No description provided for @average.
  ///
  /// In de, this message translates to:
  /// **'Durchschnitt'**
  String get average;

  /// No description provided for @noHistoryYet.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Verlauf'**
  String get noHistoryYet;

  /// No description provided for @superset.
  ///
  /// In de, this message translates to:
  /// **'Supersatz'**
  String get superset;

  /// No description provided for @infoTab.
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get infoTab;

  /// No description provided for @historyTab.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get historyTab;

  /// No description provided for @similarExercises.
  ///
  /// In de, this message translates to:
  /// **'Ähnliche Übungen'**
  String get similarExercises;

  /// No description provided for @addAllCount.
  ///
  /// In de, this message translates to:
  /// **'Alle hinzufügen ({n})'**
  String addAllCount(int n);

  /// No description provided for @timesPerformedValue.
  ///
  /// In de, this message translates to:
  /// **'{n}×'**
  String timesPerformedValue(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

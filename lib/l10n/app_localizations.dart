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

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

  /// No description provided for @a11yToggleFavorite.
  ///
  /// In de, this message translates to:
  /// **'Favorit umschalten'**
  String get a11yToggleFavorite;

  /// No description provided for @a11yAddSet.
  ///
  /// In de, this message translates to:
  /// **'Satz hinzufügen'**
  String get a11yAddSet;

  /// No description provided for @a11yToggleTorch.
  ///
  /// In de, this message translates to:
  /// **'Taschenlampe umschalten'**
  String get a11yToggleTorch;

  /// No description provided for @a11yScanBarcode.
  ///
  /// In de, this message translates to:
  /// **'Barcode scannen'**
  String get a11yScanBarcode;

  /// No description provided for @a11yWorkoutHistory.
  ///
  /// In de, this message translates to:
  /// **'Trainingsverlauf'**
  String get a11yWorkoutHistory;

  /// No description provided for @a11ySwitchCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera wechseln'**
  String get a11ySwitchCamera;

  /// No description provided for @a11yPreviousMonth.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Monat'**
  String get a11yPreviousMonth;

  /// No description provided for @a11yNextMonth.
  ///
  /// In de, this message translates to:
  /// **'Nächster Monat'**
  String get a11yNextMonth;

  /// No description provided for @a11yReceiptPhoto.
  ///
  /// In de, this message translates to:
  /// **'Beleg-Foto'**
  String get a11yReceiptPhoto;

  /// No description provided for @a11yMoreInfo.
  ///
  /// In de, this message translates to:
  /// **'Weitere Informationen'**
  String get a11yMoreInfo;

  /// No description provided for @a11yToggleCheck.
  ///
  /// In de, this message translates to:
  /// **'Häkchen umschalten'**
  String get a11yToggleCheck;

  /// No description provided for @a11yStarRating.
  ///
  /// In de, this message translates to:
  /// **'Bewertung: {count} Sterne'**
  String a11yStarRating(int count);

  /// No description provided for @a11yMapMarker.
  ///
  /// In de, this message translates to:
  /// **'Kartenmarker'**
  String get a11yMapMarker;

  /// No description provided for @a11yViewPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto {index} von {total}'**
  String a11yViewPhoto(int index, int total);

  /// No description provided for @a11yDiaryDayHasEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag vorhanden'**
  String get a11yDiaryDayHasEntry;

  /// No description provided for @a11yMedicationDoseTaken.
  ///
  /// In de, this message translates to:
  /// **'{name}, {time}, eingenommen'**
  String a11yMedicationDoseTaken(String name, String time);

  /// No description provided for @a11yMedicationDoseNotTaken.
  ///
  /// In de, this message translates to:
  /// **'{name}, {time}, nicht eingenommen'**
  String a11yMedicationDoseNotTaken(String name, String time);

  /// No description provided for @a11yHabitDoneToday.
  ///
  /// In de, this message translates to:
  /// **'{name}, heute erledigt'**
  String a11yHabitDoneToday(String name);

  /// No description provided for @a11yHabitNotDoneToday.
  ///
  /// In de, this message translates to:
  /// **'{name}, heute noch nicht erledigt'**
  String a11yHabitNotDoneToday(String name);

  /// No description provided for @a11yAddCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie hinzufügen'**
  String get a11yAddCategory;

  /// No description provided for @a11yColorOption.
  ///
  /// In de, this message translates to:
  /// **'Farbe {index}'**
  String a11yColorOption(int index);

  /// No description provided for @a11yVideoEntry.
  ///
  /// In de, this message translates to:
  /// **'Video'**
  String get a11yVideoEntry;

  /// No description provided for @confirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirm;

  /// No description provided for @camera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @share.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get share;

  /// No description provided for @deleteQuestion.
  ///
  /// In de, this message translates to:
  /// **'Löschen?'**
  String get deleteQuestion;

  /// No description provided for @errorWithDetail.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {error}'**
  String errorWithDetail(String error);

  /// No description provided for @fieldTypeText.
  ///
  /// In de, this message translates to:
  /// **'Text'**
  String get fieldTypeText;

  /// No description provided for @fieldTypeSelect.
  ///
  /// In de, this message translates to:
  /// **'Auswahl'**
  String get fieldTypeSelect;

  /// No description provided for @fieldTypeToggle.
  ///
  /// In de, this message translates to:
  /// **'Schalter'**
  String get fieldTypeToggle;

  /// No description provided for @fieldTypeNumber.
  ///
  /// In de, this message translates to:
  /// **'Zahl'**
  String get fieldTypeNumber;

  /// No description provided for @mapEnterName.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Namen eingeben'**
  String get mapEnterName;

  /// No description provided for @mapStarRating.
  ///
  /// In de, this message translates to:
  /// **'Sterne-Bewertung'**
  String get mapStarRating;

  /// No description provided for @mapMultiplePhotos.
  ///
  /// In de, this message translates to:
  /// **'Mehrere Fotos pro Punkt'**
  String get mapMultiplePhotos;

  /// No description provided for @mapAutoGroupPhotos.
  ///
  /// In de, this message translates to:
  /// **'Fotos automatisch gruppieren'**
  String get mapAutoGroupPhotos;

  /// No description provided for @mapAddCustomField.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Feld hinzufügen'**
  String get mapAddCustomField;

  /// No description provided for @mapCustomField.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Feld'**
  String get mapCustomField;

  /// No description provided for @mapNewEntry.
  ///
  /// In de, this message translates to:
  /// **'Neuer Eintrag'**
  String get mapNewEntry;

  /// No description provided for @mapNotFound.
  ///
  /// In de, this message translates to:
  /// **'Karte nicht gefunden'**
  String get mapNotFound;

  /// No description provided for @mapEntryNotFound.
  ///
  /// In de, this message translates to:
  /// **'Eintrag nicht gefunden'**
  String get mapEntryNotFound;

  /// No description provided for @mapDeleteEntryConfirm.
  ///
  /// In de, this message translates to:
  /// **'Diesen Eintrag mit allen Fotos löschen?'**
  String get mapDeleteEntryConfirm;

  /// No description provided for @mapAddPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzufügen'**
  String get mapAddPhoto;

  /// No description provided for @mapEditLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort anpassen'**
  String get mapEditLocation;

  /// No description provided for @mapSetHere.
  ///
  /// In de, this message translates to:
  /// **'Hier setzen'**
  String get mapSetHere;

  /// No description provided for @mapStartNavigation.
  ///
  /// In de, this message translates to:
  /// **'Navigation starten'**
  String get mapStartNavigation;

  /// No description provided for @mapLocationPermissionMissing.
  ///
  /// In de, this message translates to:
  /// **'Standortberechtigung fehlt'**
  String get mapLocationPermissionMissing;

  /// No description provided for @mapLocationUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Standort nicht verfügbar'**
  String get mapLocationUnavailable;

  /// No description provided for @mapSearchHashtag.
  ///
  /// In de, this message translates to:
  /// **'Nach #Hashtag suchen…'**
  String get mapSearchHashtag;

  /// No description provided for @mapAddedToExisting.
  ///
  /// In de, this message translates to:
  /// **'Zu vorhandenem Ort hinzugefügt'**
  String get mapAddedToExisting;

  /// No description provided for @workoutAddExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung hinzufügen'**
  String get workoutAddExercise;

  /// No description provided for @workoutNoExercisesYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Übungen im Workout'**
  String get workoutNoExercisesYet;

  /// No description provided for @workoutDiscard.
  ///
  /// In de, this message translates to:
  /// **'Workout verwerfen'**
  String get workoutDiscard;

  /// No description provided for @workoutDeleteSet.
  ///
  /// In de, this message translates to:
  /// **'Satz löschen'**
  String get workoutDeleteSet;

  /// No description provided for @exerciseInfoTitle.
  ///
  /// In de, this message translates to:
  /// **'Übungsinfo'**
  String get exerciseInfoTitle;

  /// No description provided for @workoutAddNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz hinzufügen'**
  String get workoutAddNote;

  /// No description provided for @workoutRemoveExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung entfernen'**
  String get workoutRemoveExercise;

  /// No description provided for @workoutAddNoteHint.
  ///
  /// In de, this message translates to:
  /// **'Notiz hinzufügen...'**
  String get workoutAddNoteHint;

  /// No description provided for @exerciseSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Übungen suchen...'**
  String get exerciseSearchHint;

  /// No description provided for @supersetLabel.
  ///
  /// In de, this message translates to:
  /// **'Superset'**
  String get supersetLabel;

  /// No description provided for @exerciseFeedbackTitle.
  ///
  /// In de, this message translates to:
  /// **'Feedback zu dieser Übung'**
  String get exerciseFeedbackTitle;

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

  /// No description provided for @noDataYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Daten'**
  String get noDataYet;

  /// No description provided for @exerciseTrainToSeeProgress.
  ///
  /// In de, this message translates to:
  /// **'Trainiere diese Übung, um deinen Fortschritt zu sehen'**
  String get exerciseTrainToSeeProgress;

  /// No description provided for @noHistoryYet.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Verlauf'**
  String get noHistoryYet;

  /// No description provided for @calendarSyncTitle.
  ///
  /// In de, this message translates to:
  /// **'Kalender-Sync'**
  String get calendarSyncTitle;

  /// No description provided for @searchSubstanceHint.
  ///
  /// In de, this message translates to:
  /// **'Substanz suchen…'**
  String get searchSubstanceHint;

  /// No description provided for @noResultsForQuery.
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse für \"{query}\"'**
  String noResultsForQuery(String query);

  /// No description provided for @substanceMedications.
  ///
  /// In de, this message translates to:
  /// **'Medikamente'**
  String get substanceMedications;

  /// No description provided for @substanceSupplements.
  ///
  /// In de, this message translates to:
  /// **'Supplements'**
  String get substanceSupplements;

  /// No description provided for @whatToAdd.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du hinzufügen?'**
  String get whatToAdd;

  /// No description provided for @noSubstancesYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Mittel'**
  String get noSubstancesYet;

  /// No description provided for @addSubstanceHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf + um Supplements oder\nMedikamente hinzuzufügen.'**
  String get addSubstanceHint;

  /// No description provided for @unitLabel.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get unitLabel;

  /// No description provided for @nutrientForNutrition.
  ///
  /// In de, this message translates to:
  /// **'Nährstoff (für Ernährung)'**
  String get nutrientForNutrition;

  /// No description provided for @none.
  ///
  /// In de, this message translates to:
  /// **'keiner'**
  String get none;

  /// No description provided for @form.
  ///
  /// In de, this message translates to:
  /// **'Form'**
  String get form;

  /// No description provided for @reminderTimes.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungszeiten'**
  String get reminderTimes;

  /// No description provided for @logConsumption.
  ///
  /// In de, this message translates to:
  /// **'Konsum erfassen'**
  String get logConsumption;

  /// No description provided for @timePoint.
  ///
  /// In de, this message translates to:
  /// **'Zeitpunkt'**
  String get timePoint;

  /// No description provided for @pleaseEnterSubstance.
  ///
  /// In de, this message translates to:
  /// **'Bitte Substanz angeben'**
  String get pleaseEnterSubstance;

  /// No description provided for @substancesTabMyMeds.
  ///
  /// In de, this message translates to:
  /// **'Meine Mittel'**
  String get substancesTabMyMeds;

  /// No description provided for @substancesTabDatabase.
  ///
  /// In de, this message translates to:
  /// **'Datenbank'**
  String get substancesTabDatabase;

  /// No description provided for @substancesDisclaimerTitle.
  ///
  /// In de, this message translates to:
  /// **'Bevor es losgeht'**
  String get substancesDisclaimerTitle;

  /// No description provided for @substancesDisclaimerAccept.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get substancesDisclaimerAccept;

  /// No description provided for @substanceFilterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get substanceFilterAll;

  /// No description provided for @substanceFilterPflanzlich.
  ///
  /// In de, this message translates to:
  /// **'Pflanzlich'**
  String get substanceFilterPflanzlich;

  /// No description provided for @substanceKlasseMed.
  ///
  /// In de, this message translates to:
  /// **'MED'**
  String get substanceKlasseMed;

  /// No description provided for @substanceKlasseSupp.
  ///
  /// In de, this message translates to:
  /// **'SUPP'**
  String get substanceKlasseSupp;

  /// No description provided for @substancePflanzlich.
  ///
  /// In de, this message translates to:
  /// **'pflanzlich'**
  String get substancePflanzlich;

  /// No description provided for @substanceStatusVollstaendig.
  ///
  /// In de, this message translates to:
  /// **'vollständig'**
  String get substanceStatusVollstaendig;

  /// No description provided for @substanceStatusTeilweise.
  ///
  /// In de, this message translates to:
  /// **'teilweise'**
  String get substanceStatusTeilweise;

  /// No description provided for @substanceStatusNurChemie.
  ///
  /// In de, this message translates to:
  /// **'nur Chemie'**
  String get substanceStatusNurChemie;

  /// No description provided for @substanceSectionEffekt.
  ///
  /// In de, this message translates to:
  /// **'Effekt'**
  String get substanceSectionEffekt;

  /// No description provided for @substanceSectionWechselwirkungen.
  ///
  /// In de, this message translates to:
  /// **'Wechselwirkungen'**
  String get substanceSectionWechselwirkungen;

  /// No description provided for @substanceSectionDosierung.
  ///
  /// In de, this message translates to:
  /// **'Dosierung'**
  String get substanceSectionDosierung;

  /// No description provided for @substanceSectionChemie.
  ///
  /// In de, this message translates to:
  /// **'Chemie'**
  String get substanceSectionChemie;

  /// No description provided for @substanceSectionTopNebenwirkungen.
  ///
  /// In de, this message translates to:
  /// **'Häufigste Nebenwirkungen'**
  String get substanceSectionTopNebenwirkungen;

  /// No description provided for @substanceFieldBeschreibung.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get substanceFieldBeschreibung;

  /// No description provided for @substanceFieldEffekt.
  ///
  /// In de, this message translates to:
  /// **'Effekt / Wofür'**
  String get substanceFieldEffekt;

  /// No description provided for @substanceFieldIndikation.
  ///
  /// In de, this message translates to:
  /// **'Indikation'**
  String get substanceFieldIndikation;

  /// No description provided for @substanceFieldWarnungen.
  ///
  /// In de, this message translates to:
  /// **'Warnungen'**
  String get substanceFieldWarnungen;

  /// No description provided for @substanceFieldKontraindikationen.
  ///
  /// In de, this message translates to:
  /// **'Kontraindikationen'**
  String get substanceFieldKontraindikationen;

  /// No description provided for @substanceFieldSpeziellePopulationen.
  ///
  /// In de, this message translates to:
  /// **'Spezielle Populationen'**
  String get substanceFieldSpeziellePopulationen;

  /// No description provided for @substanceDosisErwachsene.
  ///
  /// In de, this message translates to:
  /// **'Erwachsene'**
  String get substanceDosisErwachsene;

  /// No description provided for @substanceDosisKinder.
  ///
  /// In de, this message translates to:
  /// **'Kinder'**
  String get substanceDosisKinder;

  /// No description provided for @substanceDosisSenioren.
  ///
  /// In de, this message translates to:
  /// **'Senioren'**
  String get substanceDosisSenioren;

  /// No description provided for @substanceDosisSchwangerschaft.
  ///
  /// In de, this message translates to:
  /// **'Schwangerschaft/Stillzeit'**
  String get substanceDosisSchwangerschaft;

  /// No description provided for @substanceChemieSummenformel.
  ///
  /// In de, this message translates to:
  /// **'Summenformel'**
  String get substanceChemieSummenformel;

  /// No description provided for @substanceChemieMolekulargewicht.
  ///
  /// In de, this message translates to:
  /// **'Molekulargewicht'**
  String get substanceChemieMolekulargewicht;

  /// No description provided for @substanceKeineAngabe.
  ///
  /// In de, this message translates to:
  /// **'keine Angabe'**
  String get substanceKeineAngabe;

  /// No description provided for @substanceWikipediaAttribution.
  ///
  /// In de, this message translates to:
  /// **'Enthält Material aus Wikipedia/Wikidata, lizenziert unter CC BY-SA.'**
  String get substanceWikipediaAttribution;

  /// No description provided for @substanceAddToMyMeds.
  ///
  /// In de, this message translates to:
  /// **'Zu meinen Mitteln hinzufügen'**
  String get substanceAddToMyMeds;

  /// No description provided for @substanceAddedToMyMeds.
  ///
  /// In de, this message translates to:
  /// **'Zu Meine Mittel hinzugefügt'**
  String get substanceAddedToMyMeds;

  /// No description provided for @substanceAddedShow.
  ///
  /// In de, this message translates to:
  /// **'Anzeigen'**
  String get substanceAddedShow;

  /// No description provided for @settingsSubstanceDbInfo.
  ///
  /// In de, this message translates to:
  /// **'Substanzdatenbank'**
  String get settingsSubstanceDbInfo;

  /// No description provided for @substanceTypeMed.
  ///
  /// In de, this message translates to:
  /// **'Medikament'**
  String get substanceTypeMed;

  /// No description provided for @substanceTypeSupp.
  ///
  /// In de, this message translates to:
  /// **'Supplement'**
  String get substanceTypeSupp;

  /// No description provided for @substanceLogIntake.
  ///
  /// In de, this message translates to:
  /// **'Konsum erfassen'**
  String get substanceLogIntake;

  /// No description provided for @substanceDeactivate.
  ///
  /// In de, this message translates to:
  /// **'Deaktivieren'**
  String get substanceDeactivate;

  /// No description provided for @substanceDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get substanceDelete;

  /// No description provided for @substanceConfirmDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Wirklich löschen?'**
  String get substanceConfirmDeleteTitle;

  /// No description provided for @substanceConfirmDeleteBody.
  ///
  /// In de, this message translates to:
  /// **'{name} wird dauerhaft entfernt.'**
  String substanceConfirmDeleteBody(String name);

  /// No description provided for @substanceSaving.
  ///
  /// In de, this message translates to:
  /// **'Speichern…'**
  String get substanceSaving;

  /// No description provided for @substanceLogIntakeAction.
  ///
  /// In de, this message translates to:
  /// **'Erfassen'**
  String get substanceLogIntakeAction;

  /// No description provided for @substanceHintVitaminD3.
  ///
  /// In de, this message translates to:
  /// **'z.B. Vitamin D3'**
  String get substanceHintVitaminD3;

  /// No description provided for @substanceHintIbuprofen.
  ///
  /// In de, this message translates to:
  /// **'z.B. Ibuprofen 400mg'**
  String get substanceHintIbuprofen;

  /// No description provided for @substanceHintDosageExample.
  ///
  /// In de, this message translates to:
  /// **'z.B. 400 mg'**
  String get substanceHintDosageExample;

  /// No description provided for @substanceLabelSubstance.
  ///
  /// In de, this message translates to:
  /// **'Substanz'**
  String get substanceLabelSubstance;

  /// No description provided for @substanceLabelDosis.
  ///
  /// In de, this message translates to:
  /// **'Dosis'**
  String get substanceLabelDosis;

  /// No description provided for @productNotFound.
  ///
  /// In de, this message translates to:
  /// **'Produkt nicht gefunden'**
  String get productNotFound;

  /// No description provided for @searchFoodHint.
  ///
  /// In de, this message translates to:
  /// **'Lebensmittel suchen...'**
  String get searchFoodHint;

  /// No description provided for @noProductsFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Produkte gefunden'**
  String get noProductsFound;

  /// No description provided for @waterUpper.
  ///
  /// In de, this message translates to:
  /// **'WASSER'**
  String get waterUpper;

  /// No description provided for @weeklyTrend.
  ///
  /// In de, this message translates to:
  /// **'Wochenverlauf'**
  String get weeklyTrend;

  /// No description provided for @createCustomProduct.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Produkt anlegen'**
  String get createCustomProduct;

  /// No description provided for @saveFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern'**
  String get saveFailed;

  /// No description provided for @urgent.
  ///
  /// In de, this message translates to:
  /// **'Dringend'**
  String get urgent;

  /// No description provided for @bookedAsExpense.
  ///
  /// In de, this message translates to:
  /// **'Als Ausgabe in Finanzen gebucht ✓'**
  String get bookedAsExpense;

  /// No description provided for @bookingFailed.
  ///
  /// In de, this message translates to:
  /// **'Buchung fehlgeschlagen'**
  String get bookingFailed;

  /// No description provided for @totalPaidUpper.
  ///
  /// In de, this message translates to:
  /// **'GESAMT BEZAHLT'**
  String get totalPaidUpper;

  /// No description provided for @shoppingListEmpty.
  ///
  /// In de, this message translates to:
  /// **'Einkaufsliste leer'**
  String get shoppingListEmpty;

  /// No description provided for @doneUpper.
  ///
  /// In de, this message translates to:
  /// **'ERLEDIGT'**
  String get doneUpper;

  /// No description provided for @deleteCompleted.
  ///
  /// In de, this message translates to:
  /// **'Erledigte löschen'**
  String get deleteCompleted;

  /// No description provided for @estimatedUpper.
  ///
  /// In de, this message translates to:
  /// **'VORAUSSICHTLICH'**
  String get estimatedUpper;

  /// No description provided for @inStore.
  ///
  /// In de, this message translates to:
  /// **'Im Laden 🛒'**
  String get inStore;

  /// No description provided for @inCartStatus.
  ///
  /// In de, this message translates to:
  /// **'IM KORB · ECHT · {inCart}/{total}'**
  String inCartStatus(int inCart, int total);

  /// No description provided for @completeShoppingLabel.
  ///
  /// In de, this message translates to:
  /// **'✓  Einkauf abschließen'**
  String get completeShoppingLabel;

  /// No description provided for @estimatedBudgetLabel.
  ///
  /// In de, this message translates to:
  /// **'Budget (geschätzt): {amount}'**
  String estimatedBudgetLabel(String amount);

  /// No description provided for @listEmpty.
  ///
  /// In de, this message translates to:
  /// **'Liste ist leer'**
  String get listEmpty;

  /// No description provided for @saveTemplate.
  ///
  /// In de, this message translates to:
  /// **'Vorlage speichern'**
  String get saveTemplate;

  /// No description provided for @templateNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Wocheneinkauf'**
  String get templateNameHint;

  /// No description provided for @templates.
  ///
  /// In de, this message translates to:
  /// **'Vorlagen'**
  String get templates;

  /// No description provided for @noTemplatesSaved.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Vorlagen gespeichert.'**
  String get noTemplatesSaved;

  /// No description provided for @nothingLogged.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts eingetragen'**
  String get nothingLogged;

  /// No description provided for @microNutrientsSupplements.
  ///
  /// In de, this message translates to:
  /// **'Mikronährstoffe & Supplements'**
  String get microNutrientsSupplements;

  /// No description provided for @supplementsToday.
  ///
  /// In de, this message translates to:
  /// **'SUPPLEMENTS HEUTE'**
  String get supplementsToday;

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

  /// No description provided for @allDataOnDevice.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten bleiben auf deinem Gerät.'**
  String get allDataOnDevice;

  /// No description provided for @startWorkout.
  ///
  /// In de, this message translates to:
  /// **'Workout starten'**
  String get startWorkout;

  /// No description provided for @newWorkoutTitle.
  ///
  /// In de, this message translates to:
  /// **'Neues Workout'**
  String get newWorkoutTitle;

  /// No description provided for @setTypeNormal.
  ///
  /// In de, this message translates to:
  /// **'Normaler Satz'**
  String get setTypeNormal;

  /// No description provided for @setTypeWarmup.
  ///
  /// In de, this message translates to:
  /// **'Aufwärmsatz'**
  String get setTypeWarmup;

  /// No description provided for @setTypeDrop.
  ///
  /// In de, this message translates to:
  /// **'Drop-Satz'**
  String get setTypeDrop;

  /// No description provided for @setTypeFailure.
  ///
  /// In de, this message translates to:
  /// **'Bis zum Muskelversagen'**
  String get setTypeFailure;

  /// No description provided for @lastWorkoutMinutesAgo.
  ///
  /// In de, this message translates to:
  /// **'Letztes Training vor {minutes} Min.'**
  String lastWorkoutMinutesAgo(int minutes);

  /// No description provided for @lastWorkoutHoursAgo.
  ///
  /// In de, this message translates to:
  /// **'Letztes Training vor {hours} Std.'**
  String lastWorkoutHoursAgo(int hours);

  /// No description provided for @lastWorkoutYesterday.
  ///
  /// In de, this message translates to:
  /// **'Letztes Training gestern'**
  String get lastWorkoutYesterday;

  /// No description provided for @lastWorkoutDaysAgo.
  ///
  /// In de, this message translates to:
  /// **'Letztes Training vor {days} Tagen'**
  String lastWorkoutDaysAgo(int days);

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

  /// No description provided for @ovulation.
  ///
  /// In de, this message translates to:
  /// **'Eisprung'**
  String get ovulation;

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

  /// No description provided for @reset_onboarding.
  ///
  /// In de, this message translates to:
  /// **'Onboarding wiederholen'**
  String get reset_onboarding;

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

  /// No description provided for @onboarding_privacy_title.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz & Einwilligung'**
  String get onboarding_privacy_title;

  /// No description provided for @onboarding_body_title.
  ///
  /// In de, this message translates to:
  /// **'Körper & Fitness'**
  String get onboarding_body_title;

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

  /// No description provided for @healthScorePotential.
  ///
  /// In de, this message translates to:
  /// **'Verbesserungspotenzial'**
  String get healthScorePotential;

  /// No description provided for @healthScoreBalance.
  ///
  /// In de, this message translates to:
  /// **'Gesamtbalance'**
  String get healthScoreBalance;

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

  /// No description provided for @milestoneProgressCaption.
  ///
  /// In de, this message translates to:
  /// **'{percent}% bis {milestone}'**
  String milestoneProgressCaption(int percent, String milestone);

  /// No description provided for @allMilestonesReached.
  ///
  /// In de, this message translates to:
  /// **'Alle Meilensteine erreicht'**
  String get allMilestonesReached;

  /// No description provided for @fieldDescription.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get fieldDescription;

  /// No description provided for @dateLabel.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get dateLabel;

  /// No description provided for @fieldNoteOptional.
  ///
  /// In de, this message translates to:
  /// **'Notiz (optional)'**
  String get fieldNoteOptional;

  /// No description provided for @saving.
  ///
  /// In de, this message translates to:
  /// **'Wird gespeichert...'**
  String get saving;

  /// No description provided for @all.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get all;

  /// No description provided for @categoryOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get categoryOther;

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

  /// No description provided for @editMeasurements.
  ///
  /// In de, this message translates to:
  /// **'Maße bearbeiten'**
  String get editMeasurements;

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

  /// No description provided for @permissionLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort'**
  String get permissionLocation;

  /// No description provided for @todos.
  ///
  /// In de, this message translates to:
  /// **'Aufgaben'**
  String get todos;

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

  /// No description provided for @permissionsContent.
  ///
  /// In de, this message translates to:
  /// **'{items}'**
  String permissionsContent(String items);

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

  /// No description provided for @pinLocked.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Fehlversuche. Erneut versuchen in {seconds}s.'**
  String pinLocked(int seconds);

  /// No description provided for @activeLabel.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get activeLabel;

  /// No description provided for @addMedication.
  ///
  /// In de, this message translates to:
  /// **'Medikament hinzufügen'**
  String get addMedication;

  /// No description provided for @editMedication.
  ///
  /// In de, this message translates to:
  /// **'Medikament bearbeiten'**
  String get editMedication;

  /// No description provided for @dosage.
  ///
  /// In de, this message translates to:
  /// **'Dosierung'**
  String get dosage;

  /// No description provided for @timeForMedication.
  ///
  /// In de, this message translates to:
  /// **'Zeit für {name}'**
  String timeForMedication(String name);

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

  /// No description provided for @amountGrams.
  ///
  /// In de, this message translates to:
  /// **'Menge (g)'**
  String get amountGrams;

  /// No description provided for @proteinG.
  ///
  /// In de, this message translates to:
  /// **'Protein (g)'**
  String get proteinG;

  /// No description provided for @completed.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get completed;

  /// No description provided for @addProduct.
  ///
  /// In de, this message translates to:
  /// **'Produkt hinzufügen'**
  String get addProduct;

  /// No description provided for @quantity.
  ///
  /// In de, this message translates to:
  /// **'Menge'**
  String get quantity;

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

  /// No description provided for @editSupplement.
  ///
  /// In de, this message translates to:
  /// **'Supplement bearbeiten'**
  String get editSupplement;

  /// No description provided for @category.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get category;

  /// No description provided for @fieldUnit.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get fieldUnit;

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

  /// No description provided for @addTodo.
  ///
  /// In de, this message translates to:
  /// **'Aufgabe hinzufügen'**
  String get addTodo;

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

  /// No description provided for @endBeforeStartError.
  ///
  /// In de, this message translates to:
  /// **'Die Endzeit muss nach der Startzeit liegen'**
  String get endBeforeStartError;

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

  /// No description provided for @addTracker.
  ///
  /// In de, this message translates to:
  /// **'Tracker hinzufügen'**
  String get addTracker;

  /// No description provided for @addSubstance.
  ///
  /// In de, this message translates to:
  /// **'Mittel hinzufügen'**
  String get addSubstance;

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

  /// No description provided for @habitsCompletedTodayLabel.
  ///
  /// In de, this message translates to:
  /// **'heute erledigt'**
  String get habitsCompletedTodayLabel;

  /// No description provided for @habitStreakDays.
  ///
  /// In de, this message translates to:
  /// **'{count} Tage in Folge'**
  String habitStreakDays(int count);

  /// No description provided for @habitStreakWeeks.
  ///
  /// In de, this message translates to:
  /// **'{count} Wochen in Folge'**
  String habitStreakWeeks(int count);

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

  /// No description provided for @supportSection.
  ///
  /// In de, this message translates to:
  /// **'Support'**
  String get supportSection;

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

  /// No description provided for @notificationCenterEmpty.
  ///
  /// In de, this message translates to:
  /// **'Alles erledigt — keine offenen Punkte'**
  String get notificationCenterEmpty;

  /// No description provided for @notificationCenterMedsToday.
  ///
  /// In de, this message translates to:
  /// **'Medikamente heute'**
  String get notificationCenterMedsToday;

  /// No description provided for @notificationCenterMedsStatus.
  ///
  /// In de, this message translates to:
  /// **'{taken} eingenommen · {active} aktiv'**
  String notificationCenterMedsStatus(int taken, int active);

  /// No description provided for @notificationCenterNextAppointment.
  ///
  /// In de, this message translates to:
  /// **'Nächster Termin'**
  String get notificationCenterNextAppointment;

  /// No description provided for @notificationCenterOpenTodos.
  ///
  /// In de, this message translates to:
  /// **'Offene Aufgaben'**
  String get notificationCenterOpenTodos;

  /// No description provided for @notificationCenterTodosStatus.
  ///
  /// In de, this message translates to:
  /// **'{count} offen · {title}'**
  String notificationCenterTodosStatus(int count, String title);

  /// No description provided for @notifMedicationHint.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen für Medikamente und Supplements stellst du direkt bei jedem einzelnen unter „Meine Mittel“ ein — nicht hier zentral.'**
  String get notifMedicationHint;

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

  /// No description provided for @notifPermissionDeniedTitle.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen deaktiviert'**
  String get notifPermissionDeniedTitle;

  /// No description provided for @notifPermissionDeniedMessage.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen werden nicht angezeigt, solange Traum in den Systemeinstellungen keine Benachrichtigungs-Berechtigung hat.'**
  String get notifPermissionDeniedMessage;

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

  /// No description provided for @importData.
  ///
  /// In de, this message translates to:
  /// **'Daten importieren'**
  String get importData;

  /// No description provided for @backupRunning.
  ///
  /// In de, this message translates to:
  /// **'Backup wird erstellt…'**
  String get backupRunning;

  /// No description provided for @backupProgressTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup wird erstellt…'**
  String get backupProgressTitle;

  /// No description provided for @backupProgressBody.
  ///
  /// In de, this message translates to:
  /// **'Das kann bei vielen Fotos/Videos einen Moment dauern. Danach wählst du im nächsten Dialog, wohin die Sicherung gespeichert wird (z. B. Dateien-App, Google Drive, E-Mail).'**
  String get backupProgressBody;

  /// No description provided for @importProgressTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup wird eingelesen…'**
  String get importProgressTitle;

  /// No description provided for @importProgressBody.
  ///
  /// In de, this message translates to:
  /// **'Das kann bei einer großen Datei einen Moment dauern.'**
  String get importProgressBody;

  /// No description provided for @backupProgressPhaseTables.
  ///
  /// In de, this message translates to:
  /// **'Daten werden gelesen…'**
  String get backupProgressPhaseTables;

  /// No description provided for @backupProgressPhaseMedia.
  ///
  /// In de, this message translates to:
  /// **'Fotos/Videos werden gelesen…'**
  String get backupProgressPhaseMedia;

  /// No description provided for @backupProgressPhaseEncoding.
  ///
  /// In de, this message translates to:
  /// **'Wird gepackt…'**
  String get backupProgressPhaseEncoding;

  /// No description provided for @backupCreated.
  ///
  /// In de, this message translates to:
  /// **'Backup erstellt: {rows} Einträge, {media} Medien'**
  String backupCreated(int rows, int media);

  /// No description provided for @backupFailed.
  ///
  /// In de, this message translates to:
  /// **'Backup fehlgeschlagen: {error}'**
  String backupFailed(String error);

  /// No description provided for @nutritionReport.
  ///
  /// In de, this message translates to:
  /// **'Ernährungsbericht (PDF)'**
  String get nutritionReport;

  /// No description provided for @nutritionReportRange7.
  ///
  /// In de, this message translates to:
  /// **'Letzte 7 Tage'**
  String get nutritionReportRange7;

  /// No description provided for @nutritionReportRange30.
  ///
  /// In de, this message translates to:
  /// **'Letzte 30 Tage'**
  String get nutritionReportRange30;

  /// No description provided for @nutritionReportRangeCustom.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum wählen'**
  String get nutritionReportRangeCustom;

  /// No description provided for @nutritionReportEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Ernährungsdaten im Zeitraum'**
  String get nutritionReportEmpty;

  /// No description provided for @importDone.
  ///
  /// In de, this message translates to:
  /// **'{rows} Einträge importiert, {media} Medien wiederhergestellt'**
  String importDone(int rows, int media);

  /// No description provided for @importFailed.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen: {error}'**
  String importFailed(String error);

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

  /// No description provided for @muscleForearms.
  ///
  /// In de, this message translates to:
  /// **'Unterarme'**
  String get muscleForearms;

  /// No description provided for @muscleCardio.
  ///
  /// In de, this message translates to:
  /// **'Cardio'**
  String get muscleCardio;

  /// No description provided for @myRoutines.
  ///
  /// In de, this message translates to:
  /// **'Meine Routinen'**
  String get myRoutines;

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

  /// No description provided for @dailyRoutines.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Routinen'**
  String get dailyRoutines;

  /// No description provided for @morningRoutine.
  ///
  /// In de, this message translates to:
  /// **'Morgenroutine'**
  String get morningRoutine;

  /// No description provided for @eveningRoutine.
  ///
  /// In de, this message translates to:
  /// **'Abendroutine'**
  String get eveningRoutine;

  /// No description provided for @routineTypeWorkout.
  ///
  /// In de, this message translates to:
  /// **'Workout'**
  String get routineTypeWorkout;

  /// No description provided for @startRoutine.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get startRoutine;

  /// No description provided for @noRoutinesYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Routinen — lege deine erste Morgen- oder Abendroutine an.'**
  String get noRoutinesYet;

  /// No description provided for @pickExercisesAfterSave.
  ///
  /// In de, this message translates to:
  /// **'Nach dem Speichern wählst du direkt die Übungen für diese Routine aus.'**
  String get pickExercisesAfterSave;

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

  /// No description provided for @deleteExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung löschen'**
  String get deleteExercise;

  /// No description provided for @similarExercises.
  ///
  /// In de, this message translates to:
  /// **'Ähnliche Übungen'**
  String get similarExercises;

  /// No description provided for @timesPerformed.
  ///
  /// In de, this message translates to:
  /// **'Ausgeführt'**
  String get timesPerformed;

  /// No description provided for @totalDurationLabel.
  ///
  /// In de, this message translates to:
  /// **'Gesamtdauer'**
  String get totalDurationLabel;

  /// No description provided for @totalVolumeLabel.
  ///
  /// In de, this message translates to:
  /// **'Gesamtvolumen'**
  String get totalVolumeLabel;

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

  /// No description provided for @removeBookmarkAction.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen entfernen'**
  String get removeBookmarkAction;

  /// No description provided for @addBookmarkAction.
  ///
  /// In de, this message translates to:
  /// **'Als Lesezeichen'**
  String get addBookmarkAction;

  /// No description provided for @exerciseFeedbackPrompt.
  ///
  /// In de, this message translates to:
  /// **'Hast du Tipps zu dieser Übung?'**
  String get exerciseFeedbackPrompt;

  /// No description provided for @selectCalendars.
  ///
  /// In de, this message translates to:
  /// **'Kalender auswählen'**
  String get selectCalendars;

  /// No description provided for @noCalendarsFoundHint.
  ///
  /// In de, this message translates to:
  /// **'Keine Kalender gefunden.\nBitte schließe den Planner und öffne ihn erneut.'**
  String get noCalendarsFoundHint;

  /// No description provided for @iconLabel.
  ///
  /// In de, this message translates to:
  /// **'Icon'**
  String get iconLabel;

  /// No description provided for @homeWidgetClock.
  ///
  /// In de, this message translates to:
  /// **'Uhr'**
  String get homeWidgetClock;

  /// No description provided for @homeWidgetWeather.
  ///
  /// In de, this message translates to:
  /// **'Wetter'**
  String get homeWidgetWeather;

  /// No description provided for @homeWidgetApps.
  ///
  /// In de, this message translates to:
  /// **'Apps'**
  String get homeWidgetApps;

  /// No description provided for @homeWidgetQuickAccess.
  ///
  /// In de, this message translates to:
  /// **'Schnellzugriff'**
  String get homeWidgetQuickAccess;

  /// No description provided for @homeWidgetDailyOverview.
  ///
  /// In de, this message translates to:
  /// **'Tagesübersicht'**
  String get homeWidgetDailyOverview;

  /// No description provided for @homeWidgetCalendar.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get homeWidgetCalendar;

  /// No description provided for @addWidgetTitle.
  ///
  /// In de, this message translates to:
  /// **'Widget hinzufügen'**
  String get addWidgetTitle;

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

  /// No description provided for @noFavoriteApps.
  ///
  /// In de, this message translates to:
  /// **'Keine Favoriten'**
  String get noFavoriteApps;

  /// No description provided for @appSingular.
  ///
  /// In de, this message translates to:
  /// **'App'**
  String get appSingular;

  /// No description provided for @appPlural.
  ///
  /// In de, this message translates to:
  /// **'Apps'**
  String get appPlural;

  /// No description provided for @quickActionNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get quickActionNote;

  /// No description provided for @quickActionPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto'**
  String get quickActionPhoto;

  /// No description provided for @quickActionExpense.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe'**
  String get quickActionExpense;

  /// No description provided for @waterLogFailed.
  ///
  /// In de, this message translates to:
  /// **'Wasser konnte nicht gespeichert werden'**
  String get waterLogFailed;

  /// No description provided for @cameraCaptureFailed.
  ///
  /// In de, this message translates to:
  /// **'Foto konnte nicht aufgenommen werden'**
  String get cameraCaptureFailed;

  /// No description provided for @cameraRecordingFailed.
  ///
  /// In de, this message translates to:
  /// **'Video konnte nicht gestartet werden'**
  String get cameraRecordingFailed;

  /// No description provided for @pointCameraAtBarcode.
  ///
  /// In de, this message translates to:
  /// **'Halte die Kamera auf den Barcode'**
  String get pointCameraAtBarcode;

  /// No description provided for @fetchingProduct.
  ///
  /// In de, this message translates to:
  /// **'Produkt wird abgefragt...'**
  String get fetchingProduct;

  /// No description provided for @manualEntry.
  ///
  /// In de, this message translates to:
  /// **'Manuell'**
  String get manualEntry;

  /// No description provided for @newCustomProductTitle.
  ///
  /// In de, this message translates to:
  /// **'Neues Produkt anlegen'**
  String get newCustomProductTitle;

  /// No description provided for @productNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name *'**
  String get productNameLabel;

  /// No description provided for @productNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Hausgemachte Bolognese'**
  String get productNameHint;

  /// No description provided for @brandOptionalLabel.
  ///
  /// In de, this message translates to:
  /// **'Marke (optional)'**
  String get brandOptionalLabel;

  /// No description provided for @brandOptionalHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Selbst gekocht'**
  String get brandOptionalHint;

  /// No description provided for @nutrientsPer100g.
  ///
  /// In de, this message translates to:
  /// **'Nährwerte pro 100g'**
  String get nutrientsPer100g;

  /// No description provided for @caloriesKcalLabel.
  ///
  /// In de, this message translates to:
  /// **'Kalorien (kcal)'**
  String get caloriesKcalLabel;

  /// No description provided for @proteinGramLabel.
  ///
  /// In de, this message translates to:
  /// **'Protein (g)'**
  String get proteinGramLabel;

  /// No description provided for @carbsGramLabel.
  ///
  /// In de, this message translates to:
  /// **'Kohlenhydrate (g)'**
  String get carbsGramLabel;

  /// No description provided for @fatGramLabel.
  ///
  /// In de, this message translates to:
  /// **'Fett (g)'**
  String get fatGramLabel;

  /// No description provided for @loadingCalendars.
  ///
  /// In de, this message translates to:
  /// **'Lade Kalender…'**
  String get loadingCalendars;

  /// No description provided for @noCalendarSelected.
  ///
  /// In de, this message translates to:
  /// **'Kein Kalender ausgewählt'**
  String get noCalendarSelected;

  /// No description provided for @calendarsSelectedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Kalender ausgewählt'**
  String calendarsSelectedCount(int count);

  /// No description provided for @syncedCalendarsTitle.
  ///
  /// In de, this message translates to:
  /// **'Synchronisierte Kalender'**
  String get syncedCalendarsTitle;

  /// No description provided for @noModulesSelectedError.
  ///
  /// In de, this message translates to:
  /// **'Keine Module ausgewählt'**
  String get noModulesSelectedError;

  /// No description provided for @sendFeedbackTitle.
  ///
  /// In de, this message translates to:
  /// **'Feedback senden'**
  String get sendFeedbackTitle;

  /// No description provided for @feedbackHelpText.
  ///
  /// In de, this message translates to:
  /// **'Dein Feedback hilft TRAUM besser zu machen.'**
  String get feedbackHelpText;

  /// No description provided for @feedbackTypeLabel.
  ///
  /// In de, this message translates to:
  /// **'TYP'**
  String get feedbackTypeLabel;

  /// No description provided for @shortTitleLabel.
  ///
  /// In de, this message translates to:
  /// **'KURZTITEL'**
  String get shortTitleLabel;

  /// No description provided for @feedbackTitleHintBug.
  ///
  /// In de, this message translates to:
  /// **'z.B. \"Wasser-Tracking aktualisiert nicht\"'**
  String get feedbackTitleHintBug;

  /// No description provided for @feedbackTitleHintFeature.
  ///
  /// In de, this message translates to:
  /// **'z.B. \"Darkmode für Widgets\"'**
  String get feedbackTitleHintFeature;

  /// No description provided for @feedbackTitleHintImprovement.
  ///
  /// In de, this message translates to:
  /// **'z.B. \"Tipp-Fehler im Onboarding\"'**
  String get feedbackTitleHintImprovement;

  /// No description provided for @descriptionSectionLabel.
  ///
  /// In de, this message translates to:
  /// **'BESCHREIBUNG'**
  String get descriptionSectionLabel;

  /// No description provided for @feedbackDescHintBug.
  ///
  /// In de, this message translates to:
  /// **'Beschreibe was passiert ist und wie man es reproduzieren kann...'**
  String get feedbackDescHintBug;

  /// No description provided for @feedbackDescHintOther.
  ///
  /// In de, this message translates to:
  /// **'Beschreibe deine Idee oder den gewünschten Verbesserungsvorschlag...'**
  String get feedbackDescHintOther;

  /// No description provided for @feedbackSystemInfoDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Systemdaten (App-Version, Android-Version, Gerät) werden automatisch angehängt.'**
  String get feedbackSystemInfoDisclaimer;

  /// No description provided for @openGitHubAndSubmit.
  ///
  /// In de, this message translates to:
  /// **'GitHub öffnen & absenden'**
  String get openGitHubAndSubmit;

  /// No description provided for @githubSubmitFooter.
  ///
  /// In de, this message translates to:
  /// **'Öffnet GitHub im Browser. Ein GitHub-Account ist zum Absenden nötig.'**
  String get githubSubmitFooter;

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

  /// No description provided for @weatherLocationNeededTitle.
  ///
  /// In de, this message translates to:
  /// **'Standortzugriff benötigt'**
  String get weatherLocationNeededTitle;

  /// No description provided for @weatherLocationNeededContent.
  ///
  /// In de, this message translates to:
  /// **'TRAUM benötigt deinen Standort, um das aktuelle Wetter auf der Startseite anzuzeigen.\n\nBitte erlaube den Standortzugriff in den Systemeinstellungen.'**
  String get weatherLocationNeededContent;

  /// No description provided for @continueWithoutWeather.
  ///
  /// In de, this message translates to:
  /// **'Ohne Wetter fortfahren'**
  String get continueWithoutWeather;

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

  /// No description provided for @notTrainedHeatmap.
  ///
  /// In de, this message translates to:
  /// **'Nicht trainiert'**
  String get notTrainedHeatmap;

  /// No description provided for @heatmapDays7.
  ///
  /// In de, this message translates to:
  /// **'7 Tage'**
  String get heatmapDays7;

  /// No description provided for @heatmapDays14.
  ///
  /// In de, this message translates to:
  /// **'14 Tage'**
  String get heatmapDays14;

  /// No description provided for @heatmapDays30.
  ///
  /// In de, this message translates to:
  /// **'30 Tage'**
  String get heatmapDays30;

  /// No description provided for @heatmapExercisesIn.
  ///
  /// In de, this message translates to:
  /// **'Übungen im Zeitraum'**
  String get heatmapExercisesIn;

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

  /// No description provided for @budgetMoreLink.
  ///
  /// In de, this message translates to:
  /// **'Mehr ›'**
  String get budgetMoreLink;

  /// No description provided for @budgetScanningReceipt.
  ///
  /// In de, this message translates to:
  /// **'Kassenzettel wird analysiert...'**
  String get budgetScanningReceipt;

  /// No description provided for @budgetSaveAsTemplate.
  ///
  /// In de, this message translates to:
  /// **'Als Vorlage speichern'**
  String get budgetSaveAsTemplate;

  /// No description provided for @budgetSplitTransaction.
  ///
  /// In de, this message translates to:
  /// **'Betrag aufteilen'**
  String get budgetSplitTransaction;

  /// No description provided for @budgetSplitRemaining.
  ///
  /// In de, this message translates to:
  /// **'Verbleibend: {amount}'**
  String budgetSplitRemaining(String amount);

  /// No description provided for @budgetTrend.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get budgetTrend;

  /// No description provided for @budgetIncome.
  ///
  /// In de, this message translates to:
  /// **'Einnahmen'**
  String get budgetIncome;

  /// No description provided for @budgetExpenses.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben'**
  String get budgetExpenses;

  /// No description provided for @budgetCategories.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get budgetCategories;

  /// No description provided for @budgetTransactions.
  ///
  /// In de, this message translates to:
  /// **'Transaktionen'**
  String get budgetTransactions;

  /// No description provided for @budgetSavingGoals.
  ///
  /// In de, this message translates to:
  /// **'Sparziele'**
  String get budgetSavingGoals;

  /// No description provided for @budgetDebts.
  ///
  /// In de, this message translates to:
  /// **'Schulden'**
  String get budgetDebts;

  /// No description provided for @addDebtItem.
  ///
  /// In de, this message translates to:
  /// **'Position hinzufügen'**
  String get addDebtItem;

  /// No description provided for @editDebtItem.
  ///
  /// In de, this message translates to:
  /// **'Position bearbeiten'**
  String get editDebtItem;

  /// No description provided for @debtItemDescription.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get debtItemDescription;

  /// No description provided for @debtItemPrice.
  ///
  /// In de, this message translates to:
  /// **'Preis'**
  String get debtItemPrice;

  /// No description provided for @debtTotalFromItems.
  ///
  /// In de, this message translates to:
  /// **'Gesamt aus {count} Positionen'**
  String debtTotalFromItems(int count);

  /// No description provided for @budgetAccounts.
  ///
  /// In de, this message translates to:
  /// **'Konten'**
  String get budgetAccounts;

  /// No description provided for @budgetRecentTransactions.
  ///
  /// In de, this message translates to:
  /// **'Letzte Transaktionen'**
  String get budgetRecentTransactions;

  /// No description provided for @budgetTemplateNameHint.
  ///
  /// In de, this message translates to:
  /// **'Vorlagenname'**
  String get budgetTemplateNameHint;

  /// No description provided for @budgetTemplateSaved.
  ///
  /// In de, this message translates to:
  /// **'Als Vorlage gespeichert'**
  String get budgetTemplateSaved;

  /// No description provided for @budgetDeleteTransactionConfirm.
  ///
  /// In de, this message translates to:
  /// **'Transaktion löschen?'**
  String get budgetDeleteTransactionConfirm;

  /// No description provided for @budgetSplitOriginalAmount.
  ///
  /// In de, this message translates to:
  /// **'Originalbetrag: {amount}'**
  String budgetSplitOriginalAmount(String amount);

  /// No description provided for @budgetSplitAddPart.
  ///
  /// In de, this message translates to:
  /// **'Weiteren Teil hinzufügen'**
  String get budgetSplitAddPart;

  /// No description provided for @budgetSplitConfirm.
  ///
  /// In de, this message translates to:
  /// **'Aufteilen'**
  String get budgetSplitConfirm;

  /// No description provided for @budgetTransactionSplitDone.
  ///
  /// In de, this message translates to:
  /// **'Transaktion aufgeteilt'**
  String get budgetTransactionSplitDone;

  /// No description provided for @budgetTransactionNotFound.
  ///
  /// In de, this message translates to:
  /// **'Transaktion nicht gefunden'**
  String get budgetTransactionNotFound;

  /// No description provided for @budgetTransferLabel.
  ///
  /// In de, this message translates to:
  /// **'Umbuchung'**
  String get budgetTransferLabel;

  /// No description provided for @budgetNoteLabel.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get budgetNoteLabel;

  /// No description provided for @budgetNoteEditHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe zum Bearbeiten...'**
  String get budgetNoteEditHint;

  /// No description provided for @budgetPhotoUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Foto nicht verfügbar'**
  String get budgetPhotoUnavailable;

  /// No description provided for @budgetCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get budgetCamera;

  /// No description provided for @budgetGallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get budgetGallery;

  /// No description provided for @budgetTransferAccountsRequired.
  ///
  /// In de, this message translates to:
  /// **'Von- und Nach-Konto wählen (verschieden)'**
  String get budgetTransferAccountsRequired;

  /// No description provided for @budgetInvalidAmount.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen gültigen Betrag eingeben'**
  String get budgetInvalidAmount;

  /// No description provided for @amountExceedsMax.
  ///
  /// In de, this message translates to:
  /// **'Betrag darf höchstens {max} sein'**
  String amountExceedsMax(String max);

  /// No description provided for @budgetDefaultDescriptionExpense.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe'**
  String get budgetDefaultDescriptionExpense;

  /// No description provided for @budgetDefaultDescriptionIncome.
  ///
  /// In de, this message translates to:
  /// **'Einnahme'**
  String get budgetDefaultDescriptionIncome;

  /// No description provided for @budgetAmountLabel.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get budgetAmountLabel;

  /// No description provided for @budgetNoAccount.
  ///
  /// In de, this message translates to:
  /// **'Kein Konto'**
  String get budgetNoAccount;

  /// No description provided for @budgetFromAccount.
  ///
  /// In de, this message translates to:
  /// **'Von'**
  String get budgetFromAccount;

  /// No description provided for @budgetToAccount.
  ///
  /// In de, this message translates to:
  /// **'Nach'**
  String get budgetToAccount;

  /// No description provided for @budgetDayBeforeYesterday.
  ///
  /// In de, this message translates to:
  /// **'Vorgestern'**
  String get budgetDayBeforeYesterday;

  /// No description provided for @budgetOtherDate.
  ///
  /// In de, this message translates to:
  /// **'Anderes ▼'**
  String get budgetOtherDate;

  /// No description provided for @budgetDescriptionHint.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung...'**
  String get budgetDescriptionHint;

  /// No description provided for @budgetReceiptAttachedHint.
  ///
  /// In de, this message translates to:
  /// **'Kassenbon angehängt'**
  String get budgetReceiptAttachedHint;

  /// No description provided for @budgetNoteOptionalHint.
  ///
  /// In de, this message translates to:
  /// **'Notiz (optional)...'**
  String get budgetNoteOptionalHint;

  /// No description provided for @budgetTemplateNameFieldHint.
  ///
  /// In de, this message translates to:
  /// **'Vorlagen-Name...'**
  String get budgetTemplateNameFieldHint;

  /// No description provided for @budgetMonthlyRecurring.
  ///
  /// In de, this message translates to:
  /// **'Monatlich wiederkehrend'**
  String get budgetMonthlyRecurring;

  /// No description provided for @budgetRecurringDayLabel.
  ///
  /// In de, this message translates to:
  /// **'Am Tag des Monats:'**
  String get budgetRecurringDayLabel;

  /// No description provided for @budgetNewCategoryTile.
  ///
  /// In de, this message translates to:
  /// **'Neu'**
  String get budgetNewCategoryTile;

  /// No description provided for @budgetTypeExpense.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe'**
  String get budgetTypeExpense;

  /// No description provided for @budgetTypeIncome.
  ///
  /// In de, this message translates to:
  /// **'Einnahme'**
  String get budgetTypeIncome;

  /// No description provided for @budgetTypeTransfer.
  ///
  /// In de, this message translates to:
  /// **'Umbuchen'**
  String get budgetTypeTransfer;

  /// No description provided for @addTransaction.
  ///
  /// In de, this message translates to:
  /// **'Buchung hinzufügen'**
  String get addTransaction;

  /// No description provided for @addDebt.
  ///
  /// In de, this message translates to:
  /// **'Schuld hinzufügen'**
  String get addDebt;

  /// No description provided for @debtsScreenTitle.
  ///
  /// In de, this message translates to:
  /// **'Schulden'**
  String get debtsScreenTitle;

  /// No description provided for @noDebtsRecorded.
  ///
  /// In de, this message translates to:
  /// **'Keine Schulden erfasst'**
  String get noDebtsRecorded;

  /// No description provided for @creditorLabel.
  ///
  /// In de, this message translates to:
  /// **'Gläubiger *'**
  String get creditorLabel;

  /// No description provided for @creditorHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Bank'**
  String get creditorHint;

  /// No description provided for @totalOpenDebts.
  ///
  /// In de, this message translates to:
  /// **'Offene Schulden gesamt'**
  String get totalOpenDebts;

  /// No description provided for @payInstallment.
  ///
  /// In de, this message translates to:
  /// **'Rate zahlen'**
  String get payInstallment;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @primaryAccount.
  ///
  /// In de, this message translates to:
  /// **'Hauptkonto'**
  String get primaryAccount;

  /// No description provided for @returnRateLabel.
  ///
  /// In de, this message translates to:
  /// **'Rendite: {rate}%'**
  String returnRateLabel(String rate);

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmContent.
  ///
  /// In de, this message translates to:
  /// **'„{name}\" wird entfernt. Bereits erfasste Transaktionen bleiben erhalten.'**
  String deleteAccountConfirmContent(String name);

  /// No description provided for @editAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto bearbeiten'**
  String get editAccount;

  /// No description provided for @addAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto hinzufügen'**
  String get addAccount;

  /// No description provided for @accountTypeChecking.
  ///
  /// In de, this message translates to:
  /// **'Girokonto'**
  String get accountTypeChecking;

  /// No description provided for @accountTypeSavings.
  ///
  /// In de, this message translates to:
  /// **'Sparkonto'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeCredit.
  ///
  /// In de, this message translates to:
  /// **'Kreditkarte'**
  String get accountTypeCredit;

  /// No description provided for @accountTypeInvestment.
  ///
  /// In de, this message translates to:
  /// **'Investment'**
  String get accountTypeInvestment;

  /// No description provided for @accountNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name *'**
  String get accountNameLabel;

  /// No description provided for @accountNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Girokonto'**
  String get accountNameHint;

  /// No description provided for @bankInstitutionLabel.
  ///
  /// In de, this message translates to:
  /// **'Bank / Institut'**
  String get bankInstitutionLabel;

  /// No description provided for @bankInstitutionHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Sparkasse'**
  String get bankInstitutionHint;

  /// No description provided for @accountBalanceLabel.
  ///
  /// In de, this message translates to:
  /// **'Kontostand *'**
  String get accountBalanceLabel;

  /// No description provided for @lastFourDigitsLabel.
  ///
  /// In de, this message translates to:
  /// **'Letzte 4 Stellen'**
  String get lastFourDigitsLabel;

  /// No description provided for @returnRatePercentLabel.
  ///
  /// In de, this message translates to:
  /// **'Rendite %'**
  String get returnRatePercentLabel;

  /// No description provided for @markAsPrimaryAccount.
  ///
  /// In de, this message translates to:
  /// **'Als Hauptkonto markieren'**
  String get markAsPrimaryAccount;

  /// No description provided for @deleteAccountButton.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get deleteAccountButton;

  /// No description provided for @recurringScreenTitle.
  ///
  /// In de, this message translates to:
  /// **'Wiederkehrend'**
  String get recurringScreenTitle;

  /// No description provided for @noRecurringTransactions.
  ///
  /// In de, this message translates to:
  /// **'Keine wiederkehrenden Buchungen'**
  String get noRecurringTransactions;

  /// No description provided for @monthlyIncome.
  ///
  /// In de, this message translates to:
  /// **'Monatliche Einnahmen'**
  String get monthlyIncome;

  /// No description provided for @monthlyExpenses.
  ///
  /// In de, this message translates to:
  /// **'Monatliche Ausgaben'**
  String get monthlyExpenses;

  /// No description provided for @recurringDayOfMonth.
  ///
  /// In de, this message translates to:
  /// **'Jeden {day}. im Monat'**
  String recurringDayOfMonth(int day);

  /// No description provided for @editRecurringTitle.
  ///
  /// In de, this message translates to:
  /// **'Wiederkehrend bearbeiten'**
  String get editRecurringTitle;

  /// No description provided for @budgetAmountWithCurrencyLabel.
  ///
  /// In de, this message translates to:
  /// **'Betrag ({currency})'**
  String budgetAmountWithCurrencyLabel(String currency);

  /// No description provided for @descriptionLabel.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get descriptionLabel;

  /// No description provided for @budgetOtherCategory.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get budgetOtherCategory;

  /// No description provided for @expensesByCategoryLabel.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben nach Kategorie · {month}'**
  String expensesByCategoryLabel(String month);

  /// No description provided for @total.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get total;

  /// No description provided for @monthlyOverview.
  ///
  /// In de, this message translates to:
  /// **'Monatliche Übersicht'**
  String get monthlyOverview;

  /// No description provided for @transactionDeleted.
  ///
  /// In de, this message translates to:
  /// **'Transaktion gelöscht'**
  String get transactionDeleted;

  /// No description provided for @undo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get undo;

  /// No description provided for @budgetCategoriesScreenTitle.
  ///
  /// In de, this message translates to:
  /// **'Budget-Kategorien'**
  String get budgetCategoriesScreenTitle;

  /// No description provided for @budgetNoCategoriesHint.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Kategorien.\nTippe auf + um eine anzulegen.'**
  String get budgetNoCategoriesHint;

  /// No description provided for @budgetDeleteCategoryConfirm.
  ///
  /// In de, this message translates to:
  /// **'Kategorie löschen?'**
  String get budgetDeleteCategoryConfirm;

  /// No description provided for @budgetDeleteCategoryContent.
  ///
  /// In de, this message translates to:
  /// **'„{name}\" wird entfernt. Bestehende Transaktionen bleiben erhalten und erscheinen als „Sonstiges\".'**
  String budgetDeleteCategoryContent(String name);

  /// No description provided for @deleteGoalConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Ziel löschen?'**
  String get deleteGoalConfirmTitle;

  /// No description provided for @deleteGoalConfirmContent.
  ///
  /// In de, this message translates to:
  /// **'„{name}\" wird unwiderruflich gelöscht.'**
  String deleteGoalConfirmContent(String name);

  /// No description provided for @deleteHabitConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Gewohnheit löschen?'**
  String get deleteHabitConfirmTitle;

  /// No description provided for @deleteHabitConfirmContent.
  ///
  /// In de, this message translates to:
  /// **'„{name}\" samt Verlauf wird unwiderruflich gelöscht.'**
  String deleteHabitConfirmContent(String name);

  /// No description provided for @deleteTrackerConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Tracker löschen?'**
  String get deleteTrackerConfirmTitle;

  /// No description provided for @deleteTrackerConfirmContent.
  ///
  /// In de, this message translates to:
  /// **'„{name}\" samt Verlauf wird unwiderruflich gelöscht.'**
  String deleteTrackerConfirmContent(String name);

  /// No description provided for @deleteAppointmentConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Termin löschen?'**
  String get deleteAppointmentConfirmTitle;

  /// No description provided for @deleteAppointmentConfirmContent.
  ///
  /// In de, this message translates to:
  /// **'„{name}\" wird unwiderruflich gelöscht.'**
  String deleteAppointmentConfirmContent(String name);

  /// No description provided for @deleteTodoConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Aufgabe löschen?'**
  String get deleteTodoConfirmTitle;

  /// No description provided for @deleteTodoConfirmContent.
  ///
  /// In de, this message translates to:
  /// **'„{name}\" wird unwiderruflich gelöscht.'**
  String deleteTodoConfirmContent(String name);

  /// No description provided for @budgetCategoryLimitLabel.
  ///
  /// In de, this message translates to:
  /// **'Limit: {amount} / Mo.'**
  String budgetCategoryLimitLabel(String amount);

  /// No description provided for @budgetNewCategoryButton.
  ///
  /// In de, this message translates to:
  /// **'+ Neue Kategorie'**
  String get budgetNewCategoryButton;

  /// No description provided for @budgetEditCategoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Kategorie bearbeiten'**
  String get budgetEditCategoryTitle;

  /// No description provided for @budgetCreateCategoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Kategorie anlegen'**
  String get budgetCreateCategoryTitle;

  /// No description provided for @budgetCategoryNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name *'**
  String get budgetCategoryNameLabel;

  /// No description provided for @budgetCategoryNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Lebensmittel'**
  String get budgetCategoryNameHint;

  /// No description provided for @budgetMonthlyLimitLabel.
  ///
  /// In de, this message translates to:
  /// **'Monatslimit (optional)'**
  String get budgetMonthlyLimitLabel;

  /// No description provided for @budgetTypeLabel.
  ///
  /// In de, this message translates to:
  /// **'Typ:'**
  String get budgetTypeLabel;

  /// No description provided for @budgetAvailableThisMonth.
  ///
  /// In de, this message translates to:
  /// **'Verfügbar diesen Monat'**
  String get budgetAvailableThisMonth;

  /// No description provided for @budgetHideAmountAction.
  ///
  /// In de, this message translates to:
  /// **'Verbergen'**
  String get budgetHideAmountAction;

  /// No description provided for @budgetShowAmountAction.
  ///
  /// In de, this message translates to:
  /// **'Anzeigen'**
  String get budgetShowAmountAction;

  /// No description provided for @budgetSavingsRate.
  ///
  /// In de, this message translates to:
  /// **'Sparquote'**
  String get budgetSavingsRate;

  /// No description provided for @budgetDayOfMonth.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} von {daysInMonth}'**
  String budgetDayOfMonth(int day, int daysInMonth);

  /// No description provided for @budgetDayOfMonthForecast.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} von {daysInMonth} · Prognose '**
  String budgetDayOfMonthForecast(int day, int daysInMonth);

  /// No description provided for @budgetForecastRemaining.
  ///
  /// In de, this message translates to:
  /// **'~{amount} übrig'**
  String budgetForecastRemaining(String amount);

  /// No description provided for @budgetTotalBalanceAllAccounts.
  ///
  /// In de, this message translates to:
  /// **'Gesamtsaldo · alle Konten'**
  String get budgetTotalBalanceAllAccounts;

  /// No description provided for @budgetRecurringLabel.
  ///
  /// In de, this message translates to:
  /// **'Wiederkehrend'**
  String get budgetRecurringLabel;

  /// No description provided for @budgetSeeAll.
  ///
  /// In de, this message translates to:
  /// **'Alle ›'**
  String get budgetSeeAll;

  /// No description provided for @budgetNoTransactionsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Transaktionen'**
  String get budgetNoTransactionsYet;

  /// No description provided for @budgetNoTransactionsHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf + Neu um eine einzutragen'**
  String get budgetNoTransactionsHint;

  /// No description provided for @diaryTitle.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch'**
  String get diaryTitle;

  /// No description provided for @diarySlideshow.
  ///
  /// In de, this message translates to:
  /// **'Diashow'**
  String get diarySlideshow;

  /// No description provided for @diaryNoteHint.
  ///
  /// In de, this message translates to:
  /// **'Schreib etwas zu diesem Moment... (optional)'**
  String get diaryNoteHint;

  /// No description provided for @diaryRetake.
  ///
  /// In de, this message translates to:
  /// **'Neu aufnehmen'**
  String get diaryRetake;

  /// No description provided for @diaryTotalEntries.
  ///
  /// In de, this message translates to:
  /// **'{count} Einträge'**
  String diaryTotalEntries(int count);

  /// No description provided for @diaryRecentEntries.
  ///
  /// In de, this message translates to:
  /// **'Letzte Einträge'**
  String get diaryRecentEntries;

  /// No description provided for @diaryYearOverview.
  ///
  /// In de, this message translates to:
  /// **'Jahresübersicht'**
  String get diaryYearOverview;

  /// No description provided for @diaryDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen?'**
  String get diaryDeleteTitle;

  /// No description provided for @diaryDeleteMessage.
  ///
  /// In de, this message translates to:
  /// **'Der Eintrag und die Mediendatei werden dauerhaft gelöscht.'**
  String get diaryDeleteMessage;

  /// No description provided for @diaryModuleLabel.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch'**
  String get diaryModuleLabel;

  /// No description provided for @diarySwitcherTitle.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch wählen'**
  String get diarySwitcherTitle;

  /// No description provided for @diaryNewDiary.
  ///
  /// In de, this message translates to:
  /// **'Neues Tagebuch'**
  String get diaryNewDiary;

  /// No description provided for @diaryEditCreateTitle.
  ///
  /// In de, this message translates to:
  /// **'Neues Tagebuch'**
  String get diaryEditCreateTitle;

  /// No description provided for @diaryEditEditTitle.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch bearbeiten'**
  String get diaryEditEditTitle;

  /// No description provided for @diaryNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get diaryNameLabel;

  /// No description provided for @diaryNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. „Reise Portugal“'**
  String get diaryNameHint;

  /// No description provided for @diaryIconLabel.
  ///
  /// In de, this message translates to:
  /// **'Icon'**
  String get diaryIconLabel;

  /// No description provided for @diaryColorLabel.
  ///
  /// In de, this message translates to:
  /// **'Farbe'**
  String get diaryColorLabel;

  /// No description provided for @diaryEnterName.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Namen eingeben'**
  String get diaryEnterName;

  /// No description provided for @diaryDeleteDiaryButton.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch löschen'**
  String get diaryDeleteDiaryButton;

  /// No description provided for @diaryDeleteDiaryTitle.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch löschen?'**
  String get diaryDeleteDiaryTitle;

  /// No description provided for @diaryDeleteDiaryMessage.
  ///
  /// In de, this message translates to:
  /// **'Das Tagebuch und alle seine Einträge werden dauerhaft gelöscht.'**
  String get diaryDeleteDiaryMessage;

  /// No description provided for @diaryCannotDeleteLast.
  ///
  /// In de, this message translates to:
  /// **'Das letzte Tagebuch kann nicht gelöscht werden.'**
  String get diaryCannotDeleteLast;

  /// No description provided for @cameraOverlayAlignHint.
  ///
  /// In de, this message translates to:
  /// **'Am letzten Foto ausrichten'**
  String get cameraOverlayAlignHint;

  /// No description provided for @cameraOverlayRefOff.
  ///
  /// In de, this message translates to:
  /// **'Kein Overlay'**
  String get cameraOverlayRefOff;

  /// No description provided for @cameraOverlayRefLastPhoto.
  ///
  /// In de, this message translates to:
  /// **'Letztes Foto'**
  String get cameraOverlayRefLastPhoto;

  /// No description provided for @cameraOverlayRefBodyFull.
  ///
  /// In de, this message translates to:
  /// **'Ganzkörper'**
  String get cameraOverlayRefBodyFull;

  /// No description provided for @cameraOverlayRefFaceSingle.
  ///
  /// In de, this message translates to:
  /// **'Gesicht'**
  String get cameraOverlayRefFaceSingle;

  /// No description provided for @cameraOverlayRefFacesTwo.
  ///
  /// In de, this message translates to:
  /// **'Zwei Gesichter'**
  String get cameraOverlayRefFacesTwo;

  /// No description provided for @cameraOverlayRefFood.
  ///
  /// In de, this message translates to:
  /// **'Essen'**
  String get cameraOverlayRefFood;

  /// No description provided for @cameraOverlayRefGenericHint.
  ///
  /// In de, this message translates to:
  /// **'An der Vorlage ausrichten'**
  String get cameraOverlayRefGenericHint;

  /// No description provided for @cameraOverlayPermissionDeniedTitle.
  ///
  /// In de, this message translates to:
  /// **'Kamera-Zugriff benötigt'**
  String get cameraOverlayPermissionDeniedTitle;

  /// No description provided for @cameraOverlayPermissionDeniedMessage.
  ///
  /// In de, this message translates to:
  /// **'Bitte erlaube den Kamera- und Mikrofon-Zugriff, um Fotos und Videos aufzunehmen.'**
  String get cameraOverlayPermissionDeniedMessage;

  /// No description provided for @cameraOverlayOpenSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get cameraOverlayOpenSettings;

  /// No description provided for @cameraOverlayGrantAccess.
  ///
  /// In de, this message translates to:
  /// **'Zugriff erlauben'**
  String get cameraOverlayGrantAccess;

  /// No description provided for @cameraOverlayModePhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto'**
  String get cameraOverlayModePhoto;

  /// No description provided for @cameraOverlayModeVideo.
  ///
  /// In de, this message translates to:
  /// **'Video'**
  String get cameraOverlayModeVideo;

  /// No description provided for @cameraOverlayNoCameraFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Kamera gefunden'**
  String get cameraOverlayNoCameraFound;

  /// No description provided for @nutritionTitle.
  ///
  /// In de, this message translates to:
  /// **'Ernährung'**
  String get nutritionTitle;

  /// No description provided for @myFoodsSection.
  ///
  /// In de, this message translates to:
  /// **'Meine Lebensmittel'**
  String get myFoodsSection;

  /// No description provided for @searchOnlineSection.
  ///
  /// In de, this message translates to:
  /// **'Online gefunden'**
  String get searchOnlineSection;

  /// No description provided for @sourceMerged.
  ///
  /// In de, this message translates to:
  /// **'Kombiniert'**
  String get sourceMerged;

  /// No description provided for @searchOffline.
  ///
  /// In de, this message translates to:
  /// **'Offline — nur lokale Ergebnisse'**
  String get searchOffline;

  /// No description provided for @usdaApiKeyLabel.
  ///
  /// In de, this message translates to:
  /// **'USDA API-Key'**
  String get usdaApiKeyLabel;

  /// No description provided for @usdaApiKeyHint.
  ///
  /// In de, this message translates to:
  /// **'Leer = DEMO_KEY (eingeschränktes Limit)'**
  String get usdaApiKeyHint;

  /// No description provided for @notes_title.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get notes_title;

  /// No description provided for @notes_new_folder.
  ///
  /// In de, this message translates to:
  /// **'Neuer Ordner'**
  String get notes_new_folder;

  /// No description provided for @notes_new_note.
  ///
  /// In de, this message translates to:
  /// **'Neue Notiz'**
  String get notes_new_note;

  /// No description provided for @notes_new_template.
  ///
  /// In de, this message translates to:
  /// **'Neue Vorlage'**
  String get notes_new_template;

  /// No description provided for @notes_toggle_preview.
  ///
  /// In de, this message translates to:
  /// **'Vorschau umschalten'**
  String get notes_toggle_preview;

  /// No description provided for @notes_toggle_bookmark.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen umschalten'**
  String get notes_toggle_bookmark;

  /// No description provided for @notes_toggle_panel.
  ///
  /// In de, this message translates to:
  /// **'Bereich ein-/ausklappen'**
  String get notes_toggle_panel;

  /// No description provided for @notes_recent.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt bearbeitet'**
  String get notes_recent;

  /// No description provided for @notes_bookmarks.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen'**
  String get notes_bookmarks;

  /// No description provided for @notes_graph.
  ///
  /// In de, this message translates to:
  /// **'Graph'**
  String get notes_graph;

  /// No description provided for @notes_tags.
  ///
  /// In de, this message translates to:
  /// **'Tags'**
  String get notes_tags;

  /// No description provided for @notes_search.
  ///
  /// In de, this message translates to:
  /// **'Suche'**
  String get notes_search;

  /// No description provided for @notes_daily.
  ///
  /// In de, this message translates to:
  /// **'Tagesnotizen'**
  String get notes_daily;

  /// No description provided for @notes_templates.
  ///
  /// In de, this message translates to:
  /// **'Vorlagen'**
  String get notes_templates;

  /// No description provided for @notes_trash.
  ///
  /// In de, this message translates to:
  /// **'Papierkorb'**
  String get notes_trash;

  /// No description provided for @notes_edit_mode.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get notes_edit_mode;

  /// No description provided for @notes_reading_mode.
  ///
  /// In de, this message translates to:
  /// **'Lesen'**
  String get notes_reading_mode;

  /// No description provided for @notes_backlinks.
  ///
  /// In de, this message translates to:
  /// **'Backlinks'**
  String get notes_backlinks;

  /// No description provided for @notes_outgoing_links.
  ///
  /// In de, this message translates to:
  /// **'Ausgehende Links'**
  String get notes_outgoing_links;

  /// No description provided for @notes_outline.
  ///
  /// In de, this message translates to:
  /// **'Gliederung'**
  String get notes_outline;

  /// No description provided for @notes_unresolved_links.
  ///
  /// In de, this message translates to:
  /// **'Unaufgelöste Links'**
  String get notes_unresolved_links;

  /// No description provided for @notes_no_backlinks.
  ///
  /// In de, this message translates to:
  /// **'Keine Backlinks'**
  String get notes_no_backlinks;

  /// No description provided for @notes_no_outgoing_links.
  ///
  /// In de, this message translates to:
  /// **'Keine ausgehenden Links'**
  String get notes_no_outgoing_links;

  /// No description provided for @notes_no_outline.
  ///
  /// In de, this message translates to:
  /// **'Keine Überschriften'**
  String get notes_no_outline;

  /// No description provided for @notes_move_to_folder.
  ///
  /// In de, this message translates to:
  /// **'In Ordner verschieben'**
  String get notes_move_to_folder;

  /// No description provided for @notes_delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get notes_delete;

  /// No description provided for @notes_restore.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get notes_restore;

  /// No description provided for @notes_delete_permanently.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get notes_delete_permanently;

  /// No description provided for @notes_word_count.
  ///
  /// In de, this message translates to:
  /// **'Wörter'**
  String get notes_word_count;

  /// No description provided for @notes_insert_template.
  ///
  /// In de, this message translates to:
  /// **'Vorlage einfügen'**
  String get notes_insert_template;

  /// No description provided for @notes_export_md.
  ///
  /// In de, this message translates to:
  /// **'Als .md exportieren'**
  String get notes_export_md;

  /// No description provided for @notes_create_note_named.
  ///
  /// In de, this message translates to:
  /// **'„{title}\" anlegen'**
  String notes_create_note_named(String title);

  /// No description provided for @notes_rename.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get notes_rename;

  /// No description provided for @notes_pin.
  ///
  /// In de, this message translates to:
  /// **'Anheften'**
  String get notes_pin;

  /// No description provided for @notes_unpin.
  ///
  /// In de, this message translates to:
  /// **'Lösen'**
  String get notes_unpin;

  /// No description provided for @notes_no_notes.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Notizen'**
  String get notes_no_notes;

  /// No description provided for @notes_root.
  ///
  /// In de, this message translates to:
  /// **'Wurzel'**
  String get notes_root;

  /// No description provided for @notes_folder_name.
  ///
  /// In de, this message translates to:
  /// **'Ordnername'**
  String get notes_folder_name;

  /// No description provided for @notes_note_title.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get notes_note_title;

  /// No description provided for @notes_template_name.
  ///
  /// In de, this message translates to:
  /// **'Vorlagenname'**
  String get notes_template_name;

  /// No description provided for @notes_no_tags.
  ///
  /// In de, this message translates to:
  /// **'Keine Tags'**
  String get notes_no_tags;

  /// No description provided for @notes_no_templates.
  ///
  /// In de, this message translates to:
  /// **'Keine Vorlagen'**
  String get notes_no_templates;

  /// No description provided for @notes_search_hint.
  ///
  /// In de, this message translates to:
  /// **'Notizen durchsuchen…'**
  String get notes_search_hint;

  /// No description provided for @notes_quick_switcher_hint.
  ///
  /// In de, this message translates to:
  /// **'Notiz suchen oder anlegen…'**
  String get notes_quick_switcher_hint;

  /// No description provided for @notes_untitled.
  ///
  /// In de, this message translates to:
  /// **'Unbenannt'**
  String get notes_untitled;

  /// No description provided for @notes_import_vault.
  ///
  /// In de, this message translates to:
  /// **'Vault importieren'**
  String get notes_import_vault;

  /// No description provided for @notes_export_vault.
  ///
  /// In de, this message translates to:
  /// **'Vault exportieren'**
  String get notes_export_vault;

  /// No description provided for @notes_local_graph.
  ///
  /// In de, this message translates to:
  /// **'Lokaler Graph'**
  String get notes_local_graph;

  /// No description provided for @notes_full_graph.
  ///
  /// In de, this message translates to:
  /// **'Gesamtgraph'**
  String get notes_full_graph;

  /// No description provided for @notes_neighbor_depth.
  ///
  /// In de, this message translates to:
  /// **'Nachbartiefe'**
  String get notes_neighbor_depth;

  /// No description provided for @notes_no_daily.
  ///
  /// In de, this message translates to:
  /// **'Keine Tagesnotiz für diesen Tag'**
  String get notes_no_daily;

  /// No description provided for @notes_cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get notes_cancel;

  /// No description provided for @notes_save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get notes_save;

  /// No description provided for @notes_create.
  ///
  /// In de, this message translates to:
  /// **'Anlegen'**
  String get notes_create;

  /// No description provided for @notes_no_results.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer'**
  String get notes_no_results;

  /// No description provided for @notes_confirm_delete_permanently.
  ///
  /// In de, this message translates to:
  /// **'Notiz endgültig löschen? Das kann nicht rückgängig gemacht werden.'**
  String get notes_confirm_delete_permanently;

  /// No description provided for @notes_no_trash.
  ///
  /// In de, this message translates to:
  /// **'Papierkorb ist leer'**
  String get notes_no_trash;

  /// No description provided for @notes_empty_note_hint.
  ///
  /// In de, this message translates to:
  /// **'Schreibe etwas in Markdown…'**
  String get notes_empty_note_hint;

  /// No description provided for @notes_import_done.
  ///
  /// In de, this message translates to:
  /// **'Vault importiert: {count} Notizen'**
  String notes_import_done(int count);

  /// No description provided for @experimentalSection.
  ///
  /// In de, this message translates to:
  /// **'Experimentell'**
  String get experimentalSection;

  /// No description provided for @appLauncher.
  ///
  /// In de, this message translates to:
  /// **'App-Launcher'**
  String get appLauncher;

  /// No description provided for @appLauncherSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Lieblings-Apps als Kacheln im Mehr-Menü starten'**
  String get appLauncherSubtitle;

  /// No description provided for @experimentalBadge.
  ///
  /// In de, this message translates to:
  /// **'EXPERIMENTELL'**
  String get experimentalBadge;

  /// No description provided for @appsSectionTitle.
  ///
  /// In de, this message translates to:
  /// **'Apps'**
  String get appsSectionTitle;

  /// No description provided for @addApp.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get addApp;

  /// No description provided for @selectApps.
  ///
  /// In de, this message translates to:
  /// **'Apps auswählen'**
  String get selectApps;

  /// No description provided for @searchApps.
  ///
  /// In de, this message translates to:
  /// **'Apps suchen…'**
  String get searchApps;

  /// No description provided for @noAppsInstalled.
  ///
  /// In de, this message translates to:
  /// **'Keine Apps gefunden'**
  String get noAppsInstalled;

  /// No description provided for @appNotFound.
  ///
  /// In de, this message translates to:
  /// **'App nicht gefunden'**
  String get appNotFound;

  /// No description provided for @removeFromLauncher.
  ///
  /// In de, this message translates to:
  /// **'Aus Launcher entfernen'**
  String get removeFromLauncher;

  /// No description provided for @setAsLauncher.
  ///
  /// In de, this message translates to:
  /// **'Als Standard-Launcher'**
  String get setAsLauncher;

  /// No description provided for @setAsLauncherActive.
  ///
  /// In de, this message translates to:
  /// **'TRAUM ist deine Standard-Home-App'**
  String get setAsLauncherActive;

  /// No description provided for @setAsLauncherInactive.
  ///
  /// In de, this message translates to:
  /// **'Tippen, um TRAUM als Startbildschirm festzulegen'**
  String get setAsLauncherInactive;

  /// No description provided for @setAsLauncherFailed.
  ///
  /// In de, this message translates to:
  /// **'Launcher-Einstellungen konnten nicht geöffnet werden'**
  String get setAsLauncherFailed;

  /// No description provided for @graffitiMapChooseMap.
  ///
  /// In de, this message translates to:
  /// **'Karte wählen'**
  String get graffitiMapChooseMap;

  /// No description provided for @graffitiMapNewMap.
  ///
  /// In de, this message translates to:
  /// **'Neue Karte erstellen'**
  String get graffitiMapNewMap;

  /// No description provided for @graffitiMapSinglePhotos.
  ///
  /// In de, this message translates to:
  /// **'Einzelfotos'**
  String get graffitiMapSinglePhotos;

  /// No description provided for @graffitiMapWithRating.
  ///
  /// In de, this message translates to:
  /// **'Mit Bewertung · mehrere Fotos'**
  String get graffitiMapWithRating;

  /// No description provided for @graffitiMapNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz hinzufügen...'**
  String get graffitiMapNote;

  /// No description provided for @graffitiMapHashtag.
  ///
  /// In de, this message translates to:
  /// **'Hashtag eingeben'**
  String get graffitiMapHashtag;

  /// No description provided for @graffitiMapSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get graffitiMapSave;

  /// No description provided for @graffitiMapOverview.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get graffitiMapOverview;

  /// No description provided for @graffitiMapNoLocation.
  ///
  /// In de, this message translates to:
  /// **'Kein Standort'**
  String get graffitiMapNoLocation;

  /// No description provided for @mapFieldTowerType.
  ///
  /// In de, this message translates to:
  /// **'Turmtyp'**
  String get mapFieldTowerType;

  /// No description provided for @mapFieldTowerHeight.
  ///
  /// In de, this message translates to:
  /// **'Höhe (m)'**
  String get mapFieldTowerHeight;

  /// No description provided for @mapFieldTowerOperator.
  ///
  /// In de, this message translates to:
  /// **'Betreiber'**
  String get mapFieldTowerOperator;

  /// No description provided for @mapOptionDecayed.
  ///
  /// In de, this message translates to:
  /// **'Verfallen'**
  String get mapOptionDecayed;

  /// No description provided for @mapOptionPartiallyPreserved.
  ///
  /// In de, this message translates to:
  /// **'Teilweise erhalten'**
  String get mapOptionPartiallyPreserved;

  /// No description provided for @mapOptionWellPreserved.
  ///
  /// In de, this message translates to:
  /// **'Gut erhalten'**
  String get mapOptionWellPreserved;

  /// No description provided for @mapOptionFreelyAccessible.
  ///
  /// In de, this message translates to:
  /// **'Frei zugänglich'**
  String get mapOptionFreelyAccessible;

  /// No description provided for @mapOptionFence.
  ///
  /// In de, this message translates to:
  /// **'Zaun'**
  String get mapOptionFence;

  /// No description provided for @mapOptionLocked.
  ///
  /// In de, this message translates to:
  /// **'Verschlossen'**
  String get mapOptionLocked;

  /// No description provided for @mapOptionDangerous.
  ///
  /// In de, this message translates to:
  /// **'Gefährlich'**
  String get mapOptionDangerous;

  /// No description provided for @mapOptionPlanned.
  ///
  /// In de, this message translates to:
  /// **'Geplant'**
  String get mapOptionPlanned;

  /// No description provided for @mapOptionVisited.
  ///
  /// In de, this message translates to:
  /// **'Besucht'**
  String get mapOptionVisited;

  /// No description provided for @mapOptionRadioMast.
  ///
  /// In de, this message translates to:
  /// **'Funkmast'**
  String get mapOptionRadioMast;

  /// No description provided for @mapOptionTransmissionMast.
  ///
  /// In de, this message translates to:
  /// **'Sendemast'**
  String get mapOptionTransmissionMast;

  /// No description provided for @mapOptionOtherType.
  ///
  /// In de, this message translates to:
  /// **'Sonstige'**
  String get mapOptionOtherType;

  /// No description provided for @mapEditCollectionTitle.
  ///
  /// In de, this message translates to:
  /// **'Karte bearbeiten'**
  String get mapEditCollectionTitle;

  /// No description provided for @mapIconLabel.
  ///
  /// In de, this message translates to:
  /// **'Icon'**
  String get mapIconLabel;

  /// No description provided for @mapColorLabel.
  ///
  /// In de, this message translates to:
  /// **'Farbe'**
  String get mapColorLabel;

  /// No description provided for @mapGroupRadiusLabel.
  ///
  /// In de, this message translates to:
  /// **'Gruppierungs-Radius'**
  String get mapGroupRadiusLabel;

  /// No description provided for @mapAutoGroupDescription.
  ///
  /// In de, this message translates to:
  /// **'Fotos im Umkreis werden zu einem Ort zusammengefasst'**
  String get mapAutoGroupDescription;

  /// No description provided for @mapNameHint.
  ///
  /// In de, this message translates to:
  /// **'Kartenname…'**
  String get mapNameHint;

  /// No description provided for @mapLabelHint.
  ///
  /// In de, this message translates to:
  /// **'Bezeichnung'**
  String get mapLabelHint;

  /// No description provided for @mapOptionsCommaHint.
  ///
  /// In de, this message translates to:
  /// **'Optionen, mit Komma getrennt'**
  String get mapOptionsCommaHint;

  /// No description provided for @mapPhotoLabel.
  ///
  /// In de, this message translates to:
  /// **'Foto'**
  String get mapPhotoLabel;

  /// No description provided for @mapImportLabel.
  ///
  /// In de, this message translates to:
  /// **'Import'**
  String get mapImportLabel;

  /// No description provided for @mapUndoAction.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get mapUndoAction;

  /// No description provided for @mapUnnamedPoint.
  ///
  /// In de, this message translates to:
  /// **'Punkt'**
  String get mapUnnamedPoint;

  /// No description provided for @mapNameFieldHint.
  ///
  /// In de, this message translates to:
  /// **'Name…'**
  String get mapNameFieldHint;

  /// No description provided for @mapEnterHint.
  ///
  /// In de, this message translates to:
  /// **'Eingeben…'**
  String get mapEnterHint;

  /// No description provided for @mapNoEntriesYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge'**
  String get mapNoEntriesYet;

  /// No description provided for @mapEntryLabel.
  ///
  /// In de, this message translates to:
  /// **'Eintrag'**
  String get mapEntryLabel;

  /// No description provided for @mapNoteLabel.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get mapNoteLabel;

  /// No description provided for @mapHashtagsLabel.
  ///
  /// In de, this message translates to:
  /// **'Hashtags'**
  String get mapHashtagsLabel;

  /// No description provided for @mapCreateTitle.
  ///
  /// In de, this message translates to:
  /// **'Neue Karte erstellen'**
  String get mapCreateTitle;

  /// No description provided for @mapTemplate.
  ///
  /// In de, this message translates to:
  /// **'Vorlage wählen'**
  String get mapTemplate;

  /// No description provided for @mapTemplateGraffiti.
  ///
  /// In de, this message translates to:
  /// **'Graffiti'**
  String get mapTemplateGraffiti;

  /// No description provided for @mapTemplateTowers.
  ///
  /// In de, this message translates to:
  /// **'Türme'**
  String get mapTemplateTowers;

  /// No description provided for @mapTemplateLostPlaces.
  ///
  /// In de, this message translates to:
  /// **'Lost Places'**
  String get mapTemplateLostPlaces;

  /// No description provided for @mapTemplateCustom.
  ///
  /// In de, this message translates to:
  /// **'Eigene Karte'**
  String get mapTemplateCustom;

  /// No description provided for @mapFunctions.
  ///
  /// In de, this message translates to:
  /// **'Funktionen'**
  String get mapFunctions;

  /// No description provided for @mapFields.
  ///
  /// In de, this message translates to:
  /// **'Felder'**
  String get mapFields;

  /// No description provided for @mapFieldCondition.
  ///
  /// In de, this message translates to:
  /// **'Zustand'**
  String get mapFieldCondition;

  /// No description provided for @mapFieldAccess.
  ///
  /// In de, this message translates to:
  /// **'Zugänglichkeit'**
  String get mapFieldAccess;

  /// No description provided for @mapFieldVisited.
  ///
  /// In de, this message translates to:
  /// **'Besucht-Status'**
  String get mapFieldVisited;

  /// No description provided for @mapFieldDanger.
  ///
  /// In de, this message translates to:
  /// **'Gefahren-Hinweis'**
  String get mapFieldDanger;

  /// No description provided for @mapFieldHidden.
  ///
  /// In de, this message translates to:
  /// **'Privat-Markierung'**
  String get mapFieldHidden;

  /// No description provided for @mapCreateButton.
  ///
  /// In de, this message translates to:
  /// **'Karte erstellen'**
  String get mapCreateButton;

  /// No description provided for @mapDistanceFromYou.
  ///
  /// In de, this message translates to:
  /// **'{distance} von dir'**
  String mapDistanceFromYou(String distance);

  /// No description provided for @mapTowerName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get mapTowerName;

  /// No description provided for @mapRating.
  ///
  /// In de, this message translates to:
  /// **'Bewertung'**
  String get mapRating;

  /// No description provided for @obInterestsTitle.
  ///
  /// In de, this message translates to:
  /// **'Welche Bereiche interessieren dich?'**
  String get obInterestsTitle;

  /// No description provided for @obInterestsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle aus, was du nutzen möchtest. Du kannst alles später ändern.'**
  String get obInterestsSubtitle;

  /// No description provided for @obInterestsSelected.
  ///
  /// In de, this message translates to:
  /// **'{count} ausgewählt'**
  String obInterestsSelected(int count);

  /// No description provided for @obTabsTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine 4 Tabs'**
  String get obTabsTitle;

  /// No description provided for @obTabsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Diese Module erscheinen unten in der Leiste. Home ist immer links.'**
  String get obTabsSubtitle;

  /// No description provided for @obTabsHint.
  ///
  /// In de, this message translates to:
  /// **'Du kannst die Leiste jederzeit in den Einstellungen ändern.'**
  String get obTabsHint;

  /// No description provided for @obTrainingTitle.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get obTrainingTitle;

  /// No description provided for @obTrainingSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Erzähl uns kurz von dir – den Plan baust du später selbst.'**
  String get obTrainingSubtitle;

  /// No description provided for @obTrainingLevel.
  ///
  /// In de, this message translates to:
  /// **'Erfahrung'**
  String get obTrainingLevel;

  /// No description provided for @obLevelBeginner.
  ///
  /// In de, this message translates to:
  /// **'Anfänger'**
  String get obLevelBeginner;

  /// No description provided for @obLevelIntermediate.
  ///
  /// In de, this message translates to:
  /// **'Fortgeschritten'**
  String get obLevelIntermediate;

  /// No description provided for @obLevelAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Profi'**
  String get obLevelAdvanced;

  /// No description provided for @obTrainingGoalLabel.
  ///
  /// In de, this message translates to:
  /// **'Hauptziel'**
  String get obTrainingGoalLabel;

  /// No description provided for @obGoalMuscle.
  ///
  /// In de, this message translates to:
  /// **'Muskelaufbau'**
  String get obGoalMuscle;

  /// No description provided for @obGoalLose.
  ///
  /// In de, this message translates to:
  /// **'Abnehmen'**
  String get obGoalLose;

  /// No description provided for @obGoalFitness.
  ///
  /// In de, this message translates to:
  /// **'Fitness halten'**
  String get obGoalFitness;

  /// No description provided for @obTrainingPerWeek.
  ///
  /// In de, this message translates to:
  /// **'Trainingstage pro Woche'**
  String get obTrainingPerWeek;

  /// No description provided for @obAbstinenceTitle.
  ///
  /// In de, this message translates to:
  /// **'Abstinenz'**
  String get obAbstinenceTitle;

  /// No description provided for @obAbstinenceSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Verfolge Streaks und gesparte Zeit oder Geld.'**
  String get obAbstinenceSubtitle;

  /// No description provided for @obAbstinenceFeature1.
  ///
  /// In de, this message translates to:
  /// **'Live-Streak seit deinem Startdatum'**
  String get obAbstinenceFeature1;

  /// No description provided for @obAbstinenceFeature2.
  ///
  /// In de, this message translates to:
  /// **'Gespartes Geld & gewonnene Zeit'**
  String get obAbstinenceFeature2;

  /// No description provided for @obAbstinenceFeature3.
  ///
  /// In de, this message translates to:
  /// **'Mehrere Verzichte gleichzeitig'**
  String get obAbstinenceFeature3;

  /// No description provided for @obAbstinenceQuickAdd.
  ///
  /// In de, this message translates to:
  /// **'Worauf möchtest du verzichten? (optional)'**
  String get obAbstinenceQuickAdd;

  /// No description provided for @obAbstinenceHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Rauchen, Alkohol, Zucker'**
  String get obAbstinenceHint;

  /// No description provided for @obAbstinenceStart.
  ///
  /// In de, this message translates to:
  /// **'Startdatum'**
  String get obAbstinenceStart;

  /// No description provided for @obSubstancesTitle.
  ///
  /// In de, this message translates to:
  /// **'Substanzen'**
  String get obSubstancesTitle;

  /// No description provided for @obSubstancesSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Behalte Einnahmen und Wechselwirkungen im Blick.'**
  String get obSubstancesSubtitle;

  /// No description provided for @obSubstancesFeature1.
  ///
  /// In de, this message translates to:
  /// **'Einnahmen protokollieren'**
  String get obSubstancesFeature1;

  /// No description provided for @obSubstancesFeature2.
  ///
  /// In de, this message translates to:
  /// **'Interaktions-Check zwischen Stoffen'**
  String get obSubstancesFeature2;

  /// No description provided for @obSubstancesFeature3.
  ///
  /// In de, this message translates to:
  /// **'Verlauf & Häufigkeit'**
  String get obSubstancesFeature3;

  /// No description provided for @obPlanningTitle.
  ///
  /// In de, this message translates to:
  /// **'Planung'**
  String get obPlanningTitle;

  /// No description provided for @obPlanningSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Aufgaben, Gewohnheiten und Termine an einem Ort.'**
  String get obPlanningSubtitle;

  /// No description provided for @obPlanningFeature1.
  ///
  /// In de, this message translates to:
  /// **'To-dos mit Fälligkeiten'**
  String get obPlanningFeature1;

  /// No description provided for @obPlanningFeature2.
  ///
  /// In de, this message translates to:
  /// **'Gewohnheiten im Habit-Tracker'**
  String get obPlanningFeature2;

  /// No description provided for @obPlanningFeature3.
  ///
  /// In de, this message translates to:
  /// **'Termine & Kalender-Sync'**
  String get obPlanningFeature3;

  /// No description provided for @obDiaryTitle.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch'**
  String get obDiaryTitle;

  /// No description provided for @obDiarySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Halte Momente in Foto & Video fest.'**
  String get obDiarySubtitle;

  /// No description provided for @obDiaryFeature1.
  ///
  /// In de, this message translates to:
  /// **'Ein Eintrag pro Tag'**
  String get obDiaryFeature1;

  /// No description provided for @obDiaryFeature2.
  ///
  /// In de, this message translates to:
  /// **'Kalender & Jahres-Heatmap'**
  String get obDiaryFeature2;

  /// No description provided for @obDiaryFeature3.
  ///
  /// In de, this message translates to:
  /// **'Rückblick als Slideshow'**
  String get obDiaryFeature3;

  /// No description provided for @obNotesTitle.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get obNotesTitle;

  /// No description provided for @obNotesSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Gedanken festhalten und verknüpfen.'**
  String get obNotesSubtitle;

  /// No description provided for @obNotesFeature1.
  ///
  /// In de, this message translates to:
  /// **'Markdown mit Tags'**
  String get obNotesFeature1;

  /// No description provided for @obNotesFeature2.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfungen & Graph'**
  String get obNotesFeature2;

  /// No description provided for @obNotesFeature3.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Notizen & Vorlagen'**
  String get obNotesFeature3;

  /// No description provided for @obMapTitle.
  ///
  /// In de, this message translates to:
  /// **'Graffiti-Map'**
  String get obMapTitle;

  /// No description provided for @obMapSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Markiere Orte mit Fotos auf der Karte.'**
  String get obMapSubtitle;

  /// No description provided for @obMapFeature1.
  ///
  /// In de, this message translates to:
  /// **'Eigene Orte setzen'**
  String get obMapFeature1;

  /// No description provided for @obMapFeature2.
  ///
  /// In de, this message translates to:
  /// **'Fotos je Ort sammeln'**
  String get obMapFeature2;

  /// No description provided for @obMapFeature3.
  ///
  /// In de, this message translates to:
  /// **'Sammlungen & Touren'**
  String get obMapFeature3;

  /// No description provided for @obHealthScoreTitle.
  ///
  /// In de, this message translates to:
  /// **'Gesundheits-Score'**
  String get obHealthScoreTitle;

  /// No description provided for @obHealthScoreSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Ein täglicher Wert aus all deinen Daten.'**
  String get obHealthScoreSubtitle;

  /// No description provided for @obHealthScoreFeature1.
  ///
  /// In de, this message translates to:
  /// **'Score aus Schlaf, Schritten & mehr'**
  String get obHealthScoreFeature1;

  /// No description provided for @obHealthScoreFeature2.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Insights'**
  String get obHealthScoreFeature2;

  /// No description provided for @obHealthScoreFeature3.
  ///
  /// In de, this message translates to:
  /// **'Radar & Verlauf'**
  String get obHealthScoreFeature3;

  /// No description provided for @obDashboardTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Dashboard'**
  String get obDashboardTitle;

  /// No description provided for @obDashboardSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Startbildschirm gehört dir.'**
  String get obDashboardSubtitle;

  /// No description provided for @obDashboardFeature1.
  ///
  /// In de, this message translates to:
  /// **'Widgets hinzufügen & entfernen'**
  String get obDashboardFeature1;

  /// No description provided for @obDashboardFeature2.
  ///
  /// In de, this message translates to:
  /// **'Frei verschieben im Edit-Modus'**
  String get obDashboardFeature2;

  /// No description provided for @obDashboardFeature3.
  ///
  /// In de, this message translates to:
  /// **'Fünf Größen pro Kachel'**
  String get obDashboardFeature3;

  /// No description provided for @obDashboardSeeded.
  ///
  /// In de, this message translates to:
  /// **'Wir haben dein Dashboard schon an deine Interessen angepasst.'**
  String get obDashboardSeeded;

  /// No description provided for @obUnderstood.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get obUnderstood;

  /// No description provided for @obBirthDate.
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum'**
  String get obBirthDate;

  /// No description provided for @obBirthDatePick.
  ///
  /// In de, this message translates to:
  /// **'Datum wählen'**
  String get obBirthDatePick;

  /// No description provided for @phaseMenstrual.
  ///
  /// In de, this message translates to:
  /// **'Menstruation'**
  String get phaseMenstrual;

  /// No description provided for @phaseFollicular.
  ///
  /// In de, this message translates to:
  /// **'Follikelphase'**
  String get phaseFollicular;

  /// No description provided for @phaseFertile.
  ///
  /// In de, this message translates to:
  /// **'Fruchtbare Phase'**
  String get phaseFertile;

  /// No description provided for @phaseOvulation.
  ///
  /// In de, this message translates to:
  /// **'Eisprung'**
  String get phaseOvulation;

  /// No description provided for @phaseLuteal.
  ///
  /// In de, this message translates to:
  /// **'Lutealphase'**
  String get phaseLuteal;

  /// No description provided for @logPeriodShort.
  ///
  /// In de, this message translates to:
  /// **'Periode'**
  String get logPeriodShort;

  /// No description provided for @logSymptomShort.
  ///
  /// In de, this message translates to:
  /// **'Symptom'**
  String get logSymptomShort;

  /// No description provided for @logTempShort.
  ///
  /// In de, this message translates to:
  /// **'Temp'**
  String get logTempShort;

  /// No description provided for @logMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get logMore;

  /// No description provided for @nextPeriodIn.
  ///
  /// In de, this message translates to:
  /// **'Periode in {days} Tagen'**
  String nextPeriodIn(int days);

  /// No description provided for @predictedRange.
  ///
  /// In de, this message translates to:
  /// **'Wahrscheinlich {start}–{end}'**
  String predictedRange(Object start, Object end);

  /// No description provided for @fertileWindowLabel.
  ///
  /// In de, this message translates to:
  /// **'Fruchtbares Fenster'**
  String get fertileWindowLabel;

  /// No description provided for @ovulationEstimatedLabel.
  ///
  /// In de, this message translates to:
  /// **'Eisprung (geschätzt)'**
  String get ovulationEstimatedLabel;

  /// No description provided for @ovulationConfirmedLabel.
  ///
  /// In de, this message translates to:
  /// **'Eisprung (bestätigt)'**
  String get ovulationConfirmedLabel;

  /// No description provided for @loggedToday.
  ///
  /// In de, this message translates to:
  /// **'Heute geloggt'**
  String get loggedToday;

  /// No description provided for @nothingLoggedToday.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts geloggt'**
  String get nothingLoggedToday;

  /// No description provided for @cycleLengthsTitle.
  ///
  /// In de, this message translates to:
  /// **'Zykluslängen'**
  String get cycleLengthsTitle;

  /// No description provided for @cycleLengthsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Ø {avg} T · Normbereich 21–35'**
  String cycleLengthsSubtitle(int avg);

  /// No description provided for @bbtCurveTitle.
  ///
  /// In de, this message translates to:
  /// **'Basaltemperatur-Kurve'**
  String get bbtCurveTitle;

  /// No description provided for @cycleAnalysisTitle.
  ///
  /// In de, this message translates to:
  /// **'Zyklus-Analyse'**
  String get cycleAnalysisTitle;

  /// No description provided for @regularityRegular.
  ///
  /// In de, this message translates to:
  /// **'Regelmäßig'**
  String get regularityRegular;

  /// No description provided for @regularitySlightly.
  ///
  /// In de, this message translates to:
  /// **'Leicht unregelmäßig'**
  String get regularitySlightly;

  /// No description provided for @regularityIrregular.
  ///
  /// In de, this message translates to:
  /// **'Unregelmäßig'**
  String get regularityIrregular;

  /// No description provided for @regularityUnknown.
  ///
  /// In de, this message translates to:
  /// **'Zu wenig Daten'**
  String get regularityUnknown;

  /// No description provided for @variabilityDays.
  ///
  /// In de, this message translates to:
  /// **'Schwankung ±{days} Tage'**
  String variabilityDays(int days);

  /// No description provided for @gynAgeYears.
  ///
  /// In de, this message translates to:
  /// **'Gyn. Alter: {years} J seit Menarche'**
  String gynAgeYears(int years);

  /// No description provided for @symptomPatternsTitle.
  ///
  /// In de, this message translates to:
  /// **'Muster über Zyklen'**
  String get symptomPatternsTitle;

  /// No description provided for @healthFlagConsistentlyLong.
  ///
  /// In de, this message translates to:
  /// **'Mehrere Zyklen länger als 35 Tage.'**
  String get healthFlagConsistentlyLong;

  /// No description provided for @healthFlagConsistentlyShort.
  ///
  /// In de, this message translates to:
  /// **'Mehrere Zyklen kürzer als 21 Tage.'**
  String get healthFlagConsistentlyShort;

  /// No description provided for @healthFlagLongPeriod.
  ///
  /// In de, this message translates to:
  /// **'Deine Periode dauert ungewöhnlich lange.'**
  String get healthFlagLongPeriod;

  /// No description provided for @healthFlagHighVariability.
  ///
  /// In de, this message translates to:
  /// **'Deine Zykluslänge schwankt stark.'**
  String get healthFlagHighVariability;

  /// No description provided for @healthAllNormal.
  ///
  /// In de, this message translates to:
  /// **'Alles im Normbereich.'**
  String get healthAllNormal;

  /// No description provided for @menarcheTitle.
  ///
  /// In de, this message translates to:
  /// **'Erste Periode (Menarche)'**
  String get menarcheTitle;

  /// No description provided for @menarcheNotSet.
  ///
  /// In de, this message translates to:
  /// **'Nicht festgelegt'**
  String get menarcheNotSet;

  /// No description provided for @lutealPhaseTitle.
  ///
  /// In de, this message translates to:
  /// **'Lutealphasen-Länge'**
  String get lutealPhaseTitle;

  /// No description provided for @cycleSettingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Zyklus-Einstellungen'**
  String get cycleSettingsTitle;

  /// No description provided for @energyLabel.
  ///
  /// In de, this message translates to:
  /// **'Energie'**
  String get energyLabel;

  /// No description provided for @bbtInputLabel.
  ///
  /// In de, this message translates to:
  /// **'Basaltemperatur (°C)'**
  String get bbtInputLabel;

  /// No description provided for @cervicalMucusLabel.
  ///
  /// In de, this message translates to:
  /// **'Zervixschleim'**
  String get cervicalMucusLabel;

  /// No description provided for @mucusDry.
  ///
  /// In de, this message translates to:
  /// **'Trocken'**
  String get mucusDry;

  /// No description provided for @mucusSticky.
  ///
  /// In de, this message translates to:
  /// **'Klebrig'**
  String get mucusSticky;

  /// No description provided for @mucusCreamy.
  ///
  /// In de, this message translates to:
  /// **'Cremig'**
  String get mucusCreamy;

  /// No description provided for @mucusWatery.
  ///
  /// In de, this message translates to:
  /// **'Wässrig'**
  String get mucusWatery;

  /// No description provided for @mucusEggWhite.
  ///
  /// In de, this message translates to:
  /// **'Eiweißartig'**
  String get mucusEggWhite;

  /// No description provided for @sexLabel.
  ///
  /// In de, this message translates to:
  /// **'Sex'**
  String get sexLabel;

  /// No description provided for @sexNone.
  ///
  /// In de, this message translates to:
  /// **'Keiner'**
  String get sexNone;

  /// No description provided for @sexProtected.
  ///
  /// In de, this message translates to:
  /// **'Geschützt'**
  String get sexProtected;

  /// No description provided for @sexUnprotected.
  ///
  /// In de, this message translates to:
  /// **'Ungeschützt'**
  String get sexUnprotected;

  /// No description provided for @logTodayTitle.
  ///
  /// In de, this message translates to:
  /// **'Heute eintragen'**
  String get logTodayTitle;

  /// No description provided for @saveLog.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get saveLog;

  /// No description provided for @periodMedicalDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Kein medizinischer Rat und keine Verhütungsgarantie.'**
  String get periodMedicalDisclaimer;

  /// No description provided for @periodWeek.
  ///
  /// In de, this message translates to:
  /// **'Woche'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get periodMonth;

  /// No description provided for @periodSixMonths.
  ///
  /// In de, this message translates to:
  /// **'6 Monate'**
  String get periodSixMonths;

  /// No description provided for @periodYear.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get periodYear;

  /// No description provided for @moduleSubstances.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get moduleSubstances;

  /// No description provided for @moduleProgress.
  ///
  /// In de, this message translates to:
  /// **'Fortschritt'**
  String get moduleProgress;

  /// No description provided for @moduleGraffitiMap.
  ///
  /// In de, this message translates to:
  /// **'Graffiti Map'**
  String get moduleGraffitiMap;

  /// No description provided for @calendarAccessDeniedSyncOff.
  ///
  /// In de, this message translates to:
  /// **'Kalender-Zugriff verweigert — Sync deaktiviert'**
  String get calendarAccessDeniedSyncOff;

  /// No description provided for @editAppointment.
  ///
  /// In de, this message translates to:
  /// **'Termin bearbeiten'**
  String get editAppointment;

  /// No description provided for @syncDone.
  ///
  /// In de, this message translates to:
  /// **'{synced} synchronisiert, {errors} Fehler'**
  String syncDone(int synced, int errors);

  /// No description provided for @updateAvailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Update verfügbar — v{version}'**
  String updateAvailableTitle(String version);

  /// No description provided for @updateNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt aktualisieren'**
  String get updateNow;

  /// No description provided for @updatePreparing.
  ///
  /// In de, this message translates to:
  /// **'Wird vorbereitet…'**
  String get updatePreparing;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In de, this message translates to:
  /// **'Download fehlgeschlagen'**
  String get updateDownloadFailed;

  /// No description provided for @updateInstallPermissionMissing.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung fehlt. Aktiviere \"Unbekannte Apps\" in den Einstellungen und versuche es erneut.'**
  String get updateInstallPermissionMissing;

  /// No description provided for @updateInstallLaunchFailed.
  ///
  /// In de, this message translates to:
  /// **'Installation konnte nicht gestartet werden ({reason}). Öffne die Datei traum-update.apk manuell aus dem Downloads-/Cache-Ordner.'**
  String updateInstallLaunchFailed(String reason);

  /// No description provided for @diaryStreakDays.
  ///
  /// In de, this message translates to:
  /// **'Streak: {days} Tage'**
  String diaryStreakDays(int days);

  /// No description provided for @diaryCaptureMomentHint.
  ///
  /// In de, this message translates to:
  /// **'Halte diesen Moment fest.'**
  String get diaryCaptureMomentHint;

  /// No description provided for @diaryPhotoLabel.
  ///
  /// In de, this message translates to:
  /// **'Foto'**
  String get diaryPhotoLabel;

  /// No description provided for @diaryVideoLabel.
  ///
  /// In de, this message translates to:
  /// **'Video'**
  String get diaryVideoLabel;

  /// No description provided for @weekdaysFull.
  ///
  /// In de, this message translates to:
  /// **'Montag,Dienstag,Mittwoch,Donnerstag,Freitag,Samstag,Sonntag'**
  String get weekdaysFull;

  /// No description provided for @diaryEntryNotFound.
  ///
  /// In de, this message translates to:
  /// **'Eintrag nicht gefunden'**
  String get diaryEntryNotFound;

  /// No description provided for @diaryShareLabel.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get diaryShareLabel;

  /// No description provided for @diaryShareText.
  ///
  /// In de, this message translates to:
  /// **'Tagebucheintrag {date}'**
  String diaryShareText(String date);

  /// No description provided for @diaryHeatmapStats.
  ///
  /// In de, this message translates to:
  /// **'{count} Einträge · {percent}% Tage'**
  String diaryHeatmapStats(int count, String percent);
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

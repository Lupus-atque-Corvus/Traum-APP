# CLAUDE.md — TRAUM Flutter App

> Einstiegspunkt für Claude Code in diesem Projekt.
> Repo: **Lupus-atque-Corvus/Traum-APP** · Version **0.7.19+68** · schemaVersion **18**.
> Alle Angaben unten sind direkt aus dem Quellcode dieses Repos verifiziert (Stand v0.7.19).

---

## Deine Aufgabe
- Analysiere zuerst die vorhandene Codebase, bevor du etwas schreibst
- Baue fehlende Features und verbessere bestehende nach der echten Architektur
- Erkenne Fehler, Inkonsistenzen und veraltete Patterns selbstständig
- Bei Designentscheidungen, die nicht eindeutig festgelegt sind — frag mich BEVOR du implementierst
- Modernisiere veraltete Patterns, ohne die Konventionen oder Non-Negotiables zu brechen

---

## Projekt-Fakten (aus dem Code verifiziert)
- **Name / App-ID:** TRAUM · `de.traum.traum` (Android applicationId + iOS Bundle, beide Plattformen)
- **Version:** 0.7.19+68 · Drift schemaVersion: 18
- **Plattformen:** Android (minSdk 26) · iOS (Deployment Target 13.0)
- **SDK:** Dart ^3.9.2
- **Datenablage:** ausschließlich lokal — kein Backend, kein Server, keine Internet-Pflicht
- **UI-Sprache:** Deutsch. ARB nur **de + en** (zwei Sprachen, nicht mehr)
- **Splash/Theme-Basis:** `#0D0D1A`

## 19 Feature-Module (lib/features/)
home · training · health · nutrition · substances · supplements · planning ·
medication · abstinence · budget · diary · notes · graffiti_map · period_tracking ·
profile · settings · notifications · legal · lock · onboarding · app_launcher

## Tech Stack (echt, aus pubspec.yaml)
- State: `flutter_riverpod` ^2.5.1 + `riverpod_annotation` ^2.3.5
- Navigation: `go_router` ^14.0.0 (ShellRoute + floating Pill-NavBar)
- Datenbank: `drift` ^2.20.0 + `sqlite3` + `sqlite3_flutter_libs`
- Preferences: `shared_preferences` + `flutter_secure_storage`
- Health: `health` ^13.1.4 · Kalender-Sync: `device_calendar`
- Charts: `fl_chart` ^0.69.0 · Kalender-UI: `table_calendar`
- Notifications: `flutter_local_notifications` + `timezone` + `flutter_timezone` + `workmanager`
- Widgets: `home_widget` ^0.6.0
- Biometrie/Lock: `local_auth` (+ eigenes `core/security/pin_service.dart`)
- **Schrift: DM Sans LOKAL eingebettet** (`assets/fonts/DMSans-*.ttf`, family `DMSans`) + NotoSansArabic-Fallback. KEIN google_fonts.
- Bilder/Video: `image_picker`, `video_player`, `video_thumbnail`
- **Barcode-Scanner: `mobile_scanner`** · **OCR: `google_mlkit_text_recognition`**
- **Notes: `flutter_markdown_plus` (+ _latex), `markdown`, `flutter_math_fork`, `yaml` (Frontmatter), `graphview` (Graph View)**
- **Graffiti Map: `flutter_map`, `latlong2`, `flutter_map_marker_cluster`, `flutter_map_location_marker`, `flutter_map_cache`, `geocoding`, `exif`, `gpx`, `image`, `flutter_staggered_grid_view`, dio/http cache**
- Sonstige: `share_plus`, `archive`, `file_picker`, `flutter_svg`, `connectivity_plus`, `wakelock_plus`, `installed_apps` (app_launcher, experimentell), `device_info_plus`, `package_info_plus`, `permission_handler`, `url_launcher`, `open_file`, `geolocator`

## Verzeichnisstruktur (echt)
```
lib/
├── main.dart      # Init: DB, Notifications, Widget-Service, periodischer Widget-Refresh, 5 Seeder
├── app.dart       # MaterialApp.router, Theme, Locale, Lock-Lifecycle, Widget-Deep-Links
├── core/
│   ├── components/      # TraumCard, TraumNavigationBar, Ringe, Bars …
│   ├── navigation/      # router.dart, routes.dart, traum_scaffold.dart
│   ├── notifications/   # notification_service.dart
│   ├── providers/       # preferences_provider.dart, database_provider.dart …
│   ├── security/        # pin_service.dart  (PIN-Lock)
│   ├── services/
│   ├── theme/           # colors, radius, typography, traum_theme
│   └── utils/
├── data/
│   ├── database/
│   │   ├── traum_database.dart   # @DriftDatabase — ~62 Tabellen, 19 DAOs, schemaVersion 18
│   │   ├── tables/               # 14 Tabellen-Dateien
│   │   └── daos/                 # 19 DAO-Dateien
│   ├── models/
│   ├── preferences/
│   ├── repositories/             # Repository-Wrapper + Seeder
│   └── services/                 # health_service.dart, substance_api_service.dart
├── features/                     # 19 Module (feature-first)
├── l10n/                         # app_de.arb, app_en.arb + generierte Localizations
└── widget/                       # widget_data_service, widget_catalog, widget_update_scheduler
```

## Design System (echt, aus core/theme/colors.dart)
```
background:      #0D0D1A
surface:         #1A1A2E
surfaceVariant:  #22223A
surfaceElevated: #1E1E32
bottomNav:       #12121F
onBackground:        #FFFFFF
onBackgroundMuted:   #8888AA
onBackgroundSubtle:  #555577
coralOrange:  #FF6B3D   peachOrange: #FFAA55   coralDim: #33FF6B3D
cyanBlue:     #00D4D4   turquoiseBlue: #0099BB  cyanDim:  #3300D4D4
lavender:     #9B8EC4   mintGreen: #3DD68C      amberGold: #F5A623
indigoBlue:   #5B6CF9   roseRed:   #F43F5E
success = mintGreen · warning = amberGold · error = roseRed · overbudget = roseRed
periodRose: #FF8FAB · ovulationCyan: #00C9C8 · fertileCyan: #0093AB
```
- Jede Komplementärfarbe hat eine `…Dim`-Variante mit 20% Alpha (0x33…)
- Gradients: gradientWarm, gradientCool (weitere in colors.dart)
- Typografie: family `DMSans` (lokal), Fallback `['NotoSansArabic','Arial']`, vollständige TextTheme in typography.dart

> THEME — wichtig und bewusst: In `app.dart` ist `themeMode: ThemeMode.dark` **hartkodiert**.
> Es gibt KEINEN themeProvider und KEINEN Theme-Umschalter. `TraumTheme.light` existiert zwar als
> gebautes ThemeData, wird aber aktuell NIE ausgewählt — die App läuft immer im Dark Mode.
> Konsequenz: Neue UI muss im Dark-Theme korrekt aussehen. Farben NICHT direkt hardcoden —
> immer `TraumColors`-Tokens bzw. `Theme.of(context)` verwenden. Den Light-Pfad NICHT „aus Versehen"
> aktiv schalten oder entfernen; wenn Light Mode wieder live werden soll, ist das eine bewusste
> Entscheidung (dann themeProvider + Settings-Umschalter sauber einbauen) — vorher mit mir abstimmen.

## Datenbank — ~62 Tabellen, 19 DAOs (echt, schemaVersion 18)
- Planning: Appointments, Todos, Goals, SubTasks, Habits, HabitLogs
- Training: WorkoutPlans, WorkoutDays, Exercises, WorkoutSessions, WorkoutSets, WorkoutDayExercises
- Health: WeightLogs, BodyMeasurements, SleepLogs, MoodLogs, PhotoLogs
- Nutrition: NutritionLogs, MealTemplates, WaterLogs, ShoppingListItems
- Shopping erweitert: GroceryPrices, ShoppingTemplates, ShoppingTemplateItems
- Nutrition erweitert: FoodProducts, MealEntries, MealTemplateItems, WeeklyMealPlan
- Supplements: Supplements, SupplementLogs
- Medication: Medications, MedicationLogs
- Abstinence: AbstinenceTrackers, AbstinenceEvents
- Budget: BudgetCategories, Transactions, SavingsGoals, Debts, QuickTemplates, Accounts
- Period: PeriodEntries, CycleCalculations, PeriodSymptoms, DailyLogs, CycleProfile
- Substances: SubstanceCaches, SubstanceIntakeLogs, SubstanceDatabaseEntries (Offline-DB)
- Diary: DiaryEntries
- Notes: Notes, NoteFolders, NoteLinks, Tags, NoteTags, NoteTemplates  (Wikilinks über NoteLinks/Tags/NoteTags indiziert)
- Graffiti Map: MapCollections, MapMarkers, MarkerPhotos
- DAOs: Planning, Training, Health, Nutrition, Supplement, Medication, Abstinence, Budget, Accounts, Period, Substance, Diary, FoodProducts, MealEntries, SubstanceDatabase, Notes, MapCollections, MapMarkers, MarkerPhotos
- Seeder (in main.dart): Exercise, Supplement, SubstanceDatabaseCopier, MapCollection, GroceryPrice

## Navigation / NavBar (echt)
- ShellRoute mit `TraumScaffold` + floating Pill-`TraumNavigationBar`
- Konfigurierbare Slots; `Routes.moduleRoutes` mappt Modul-Keys → Pfade
- Initialroute `/home`; Onboarding-Redirect bis abgeschlossen
- Lock: bei Cold-Start und Resume → `/biometric-lock` oder `/pin-entry`, wenn konfiguriert
- Widget-Deep-Links: nur Routen aus `widgetCatalog` werden akzeptiert (Validierung gegen beliebige Routen)

---

## NON-NEGOTIABLES — niemals brechen
1. **`withValues(alpha:)` statt `withOpacity()`** (withOpacity deprecated ab Flutter 3.27+)
2. **DM Sans lokal** über family `DMSans` — niemals google_fonts hinzufügen
3. **Theme bleibt Dark** (hartkodiert in app.dart). Keine hardcoded Farben in Widgets — immer `TraumColors`/`Theme.of(context)`
4. **Stream-first:** DAOs liefern `Stream<List<T>>`; Screens nutzen StreamProvider/StreamBuilder
5. **Repository-Pattern:** Screens kennen keine DAOs — Mutation via `ref.read(xRepositoryProvider).method()`
6. **Nach Tabellen-/Schema-Änderung:** `dart run build_runner build --delete-conflicting-outputs` UND schemaVersion erhöhen + Migration in `traum_database.dart` ergänzen
7. **StreamProvider-Family nur mit primitiven Parametern** (keine Objekte/Records — Riverpod-Einschränkung)
8. **Material 3:** `CardThemeData`, `DialogThemeData`, `TabBarThemeData` (keine Legacy-Namen)
9. **Timezone vor `zonedSchedule`** initialisieren (`timezone` + `flutter_timezone`)
10. **iOS App Group / Widget-Channel** konsistent: App Group `group.de.traum.widgets`, Widget-Channel `MethodChannel('de.traum/widget')`, Widget-URIs `traum://…`
11. **`SharePlus.instance.share(ShareParams(...))`** verwenden (share_plus ≥12). Dateien über `ShareParams(files: [XFile(...)], text:, subject:)`, reiner Text über `ShareParams(text: …)`. Die alte `Share.shareXFiles()`/`Share.share()`-API ist ab share_plus 11 deprecated und NICHT mehr verwenden.
12. **`table_calendar`** für alle Kalender-UI
13. **ARB nur de + en** pflegen — neue Strings in beide ARB-Dateien
14. **Widget-Deep-Links validieren** gegen `widgetCatalog` (keine beliebigen Routen zulassen)
15. **`flutter analyze` → Ziel 0 Issues** vor jedem Commit (keine `withOpacity`, `child:` als letztes Property)
16. **`flutter test`** muss grün bleiben (aktuell 200+ Tests unter test/features/…)
17. **Versionierung:** Bis einschließlich Build **+79** bleibt die Version bei **0.7.x** (z.B. `0.7.13+62`, `0.7.20+79`). Erst ab Build **+80** auf **0.8.0** wechseln (`0.8.0+80`). Den `version:`-Eintrag in `pubspec.yaml` entsprechend pflegen — den Build-Zähler bei jedem Release um 1 erhöhen, den Minor-Sprung auf 0.8.0 nicht vor +80 machen.

## Bewährte Muster
- Seeder: `seedIfNeeded(db, prefs)` → wenn schon vorhanden, `return`; sonst Assets laden und einfügen
- Dialog: AlertDialog mit Abbrechen/Speichern, nach `await` `if (ctx.mounted) Navigator.pop(ctx)`
- Routen mit Parametern: Helfer wie `Routes.workoutDetailPath(id)`, Empfang via `int.parse(state.pathParameters['id']!)`
- Import-Alias bei Namenskonflikten (z.B. `as traum_dates`)
- Substanz-Daten: Offline-DB (`assets/substances.db` → SubstanceDatabaseEntries) + optional `substance_api_service`

---

## Arbeitsweise (Schritt für Schritt)
1. Lies CLAUDE.md, dann die für die Aufgabe relevanten Dateien — bevor du schreibst
2. Erstelle einen Plan und zeig ihn mir zur Bestätigung (nutze `/write-plan`)
3. Implementiere Modul für Modul / Feature für Feature — nicht alles auf einmal
4. Nach jedem Schritt: kurze Zusammenfassung was gemacht wurde + was als nächstes
5. Bei mehreren Lösungsansätzen: `/brainstorm`, dann frag mich
6. Vor jedem Commit: `flutter analyze` (0 Issues) und `flutter test` (grün)
7. Nach Schema-Änderungen: build_runner + schemaVersion hochzählen + Migration

## Erster Startbefehl (sag mir das beim Start)
Analysiere die vorhandene Codebase und erstelle einen Plan: was fehlt, was fehlerhaft ist,
was modernisiert werden sollte. Warte auf meine Bestätigung, bevor du implementierst.

---

## GitHub
- Repository: https://github.com/Lupus-atque-Corvus/Traum-APP
- Handle: Lupus-atque-Corvus

> Hinweis: Es existiert noch ein älteres, abweichendes Repo (`Android-app-`, v1.2.1). Dieses hier
> (`Traum-APP`, v0.7.19) ist der aktuelle, weiter entwickelte Stand (19 Module, embedded DM Sans,
> Dark hartkodiert, Notes/Diary/Graffiti-Map/Substances vorhanden). Nicht verwechseln.

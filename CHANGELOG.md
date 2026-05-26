# Changelog

## v0.5.0 (2026-05-26) — Feature-Release: WINGS · Kalender · Scanner · Tagebuch

### Neue Features

#### WINGS Calisthenics Tab
- Nativer Flutter-Tab mit allen Inhalten von wingssw.com (kein WebView)
- Skill-Tree: sechs Kategorien (Vertical Pull, Horizontal Pull, Push, Legs, Core) mit interaktiven Skill-Karten
- Übungsbibliothek: 45+ Übungen mit Suche, Kategorie-Filter, Schwierigkeitsgrad, Muskelgruppen, Schritt-für-Schritt-Anleitung, Good/Bad-Form-Cues
- Trainingsguide: Anfänger- & Fortgeschrittenen-Workouts, Progressive Overload, Front Lever- & Handstand-Guide

#### Kalender-Synchronisation (bidirektional)
- Termine vom Gerät-Kalender in die App importieren (letzte 30 / nächste 90 Tage)
- App-Termine in einen eigenen "TRAUM"-Kalender auf dem Gerät exportieren
- Doppelte Einträge werden automatisch erkannt und übersprungen
- Sync-Buttons direkt im Kalender-Tab

#### Daten-Import / Export
- Vollständiger JSON-Backup aller 9 Module (Training, Gesundheit, Ernährung, Supplemente, Planung, Medikamente, Abstinenz, Budget, Zyklus)
- Export via Share-Sheet; Import aus einer JSON-Datei via Dateiauswahl
- `INSERT OR REPLACE`-Logik: vorhandene Einträge werden aktualisiert, neue eingefügt
- Einzel-Modul-Export (Auswahl per Checkbox) oder kompletter Gesamt-Export

#### Ernährungs-Barcode-Scanner
- Kamera-Barcode-Scanner (mobile_scanner) direkt im Ernährungs-Tab
- OpenFoodFacts API v2: Produktname, Marke, Kalorien, Protein, Kohlenhydrate, Fett pro 100 g
- Portionsgröße anpassbar; Makros werden live neu berechnet
- Mahlzeitentyp wählen und direkt in die Datenbank speichern

#### Todos – Habitify-Style
- Neuer `TodoDetailScreen`: Titel, Notiz, Liste (Gruppenname), Priorität (Niedrig / Mittel / Hoch), Fälligkeitsdatum, Unteraufgaben
- Unteraufgaben (Sub-Items) als eigene Tabelle mit Checkbox und Lösch-Funktion
- Todos in der Liste zeigen Listname, Datum und Notiz-Vorschau als Untertitel
- Farbige Prioritäts-Indikatoren (Grün / Gold / Rot)

#### Foto-Tagebuch (1SE-Style)
- Monatskalender-Grid: jeder Tag kann mit einem Foto belegt werden
- Fotos per Kamera aufnehmen oder aus der Galerie wählen
- Vollbild-Viewer mit Pinch-to-Zoom und Löschen-Funktion
- Horizontale Vorschau der letzten Einträge unterhalb des Kalenders
- Fotos werden lokal im App-Verzeichnis gespeichert (diary/)
- Nutzt die bestehende PhotoLogs-Tabelle (category = 'diary')

#### Navigationsleiste & Wetter-Widget
- Neue Navigationsleiste mit Drag-and-Drop-Sortierung, Icon-Auswahl, Show/Hide pro Modul
- Uhrzeit- & Wetter-Widget auf der Startseite (Standort-basierte Wetterdaten)

### Verbesserungen & Bugfixes

- **Schrittzähler**: Health Connect Schritte werden jetzt korrekt aus dem Tages-Query geladen
- **Wasser-Tracking**: Eingabe erlaubt jetzt auch negative Werte (Korrektur-Funktion)
- **Workout-Daten**: Letztes Gewicht/Wiederholungen werden beim Erfassen vorausgefüllt
- **Datenbank-Audit**: Alle Drift-Migrations bereinigt, Analyzer-Warnungen behoben
- **Übersetzungen**: Alle hartcodierten deutschen/englischen Strings vollständig in ARB-Dateien überführt
- **Planung-Tab**: Goals & Habits entfernt; Abstinenz-Tracker in Kalender-Tab integriert

### Technische Details

- Neue Pakete: `device_calendar ^4.3.3`, `file_picker ^8.0.0`, `mobile_scanner ^6.0.0`
- Datenbank Schema v4: neue Tabelle `TodoSubItems`, neue Spalte `todos.listName`
- Neue Dart-Dateien: `wings_screen`, `wings_data`, `wings_tutorials_screen`, `wings_skill_tree_screen`, `wings_training_screen`, `wings_exercise_detail_screen`, `calendar_sync_service`, `data_import_export_service`, `open_food_facts_service`, `barcode_scanner_screen`, `todo_detail_screen`, `diary_screen`
- AndroidManifest: `READ_CALENDAR`, `WRITE_CALENDAR`, `CAMERA` Permissions hinzugefügt

---

## v0.0.2 (2026-05-16) — Bugfix-Release

### Fehlerbehebungen

#### Gestensteuerung
- Die Zurück-Geste / der Zurück-Button schmeißt den Nutzer nicht mehr aus der App heraus
- Stattdessen wird immer zum Hauptmenü (Home) navigiert; auf dem Home-Screen passiert nichts (kein App-Beenden)

#### Onboarding & Sicherheit (via PR #1)
- Biometrie- und PIN-Sperre im Onboarding vollständig implementiert
- Korrekturen am Berechtigungssystem (Kamera, Benachrichtigungen, Health)
- Health-API-Aufruf auf aktuelle `health` 13.1.4 angepasst

#### Kritischer Ladefehler behoben — alle Screens zeigen jetzt Daten
- **Ursache:** Alle Daten-Screens (Supplements, Planung, Medikamente, Abstinenz, Profil, Budget, Ernährung, Training, Gesundheit, Zyklus u.a.) litten unter einem kritischen Riverpod-Fehler: `StreamProvider` und `FutureProvider` wurden inline innerhalb von `ref.watch()` erstellt, was bei jedem Widget-Rebuild einen neuen, unbekannten Provider erzeugte — dadurch blieben alle Streams ewig im Lade-Zustand
- **Lösung:** 42 korrekte Top-Level-Provider in `database_provider.dart` eingeführt (einfache Provider, `.family`-Provider für datums- oder ID-parametrisierte Abfragen) — alle 19 betroffenen Screen-Dateien aktualisiert
- Betroffen waren: Supplements, Planung (Termine, Todos, Ziele, Gewohnheiten), Medikamente, Abstinenz, Budget (Übersicht, Statistiken, Transaktionen, Sparziele, Transaktion-Hinzufügen), Ernährung (Übersicht, Mahlzeiten, Einkaufsliste), Profil, Gesundheit (Schlaf, Gewicht, Maßnahmen), Training (Übungen, Routinen, Session-Details, Fortschritt, Heatmap), Zyklus (Übersicht, Kalender, Historie)

### Technische Details

- `StreamProvider.autoDispose` und `.family` für alle datenbank-gestützten Screens eingeführt
- `FutureProvider.autoDispose.family` für parametrisierte Einzel-Abfragen (z.B. Schlaf der letzten 7 / 30 Tage, Trainings-Sets der letzten 7 / 30 / 90 Tage)
- Kein Breaking Change — alle Datenbankstrukturen bleiben kompatibel

---

## v0.0.1 (2026-05-16) — Erste Veröffentlichung

### Neue Features

#### Gesundheitsscore
- Neuer "Score"-Tab im Gesundheitsbereich mit einem gewichteten Score (0–100)
- Sechs Faktoren: Training (20 %), Ernährung (20 %), Regeneration (20 %), Supplemente (10 %), Medikamente (15 %), Stress & Mental (15 %)
- Sparkline-Chart mit 7-Tage-Trend
- Detailansicht mit Radar-Chart und Faktoren-Übersicht
- Faktor-Karten mit Mini-Balkendiagramm
- Motivationstexte und Verbesserungshinweise je Faktor

#### Homescreen-Widgets
- 11 native Android-Widgets (Abstinenz, Budget, Kalender, Gewohnheiten, Gesundheit, Medikamente, Ernährung, Übersicht, Zyklus, Schritte, Todo)
- Kompatibel mit home_widget 0.6.0 API (SharedPreferences statt Bundle)

#### Benachrichtigungen & Hintergrundaufgaben
- Tägliche Erinnerungen für Medikamente, Training und Gewohnheiten
- 8 Kotlin-Worker für Hintergrundbenachrichtigungen (WorkManager)
- Kompatibel mit workmanager 0.9.x

#### Auto-Update
- Automatische Update-Prüfung über GitHub Releases API
- Nutzer wird bei neuer Version benachrichtigt

### Technische Verbesserungen

- Flutter Gradle Plugin mit Core Library Desugaring (android:minSdk 26)
- Dependency-Upgrades: flutter_timezone 3.0.1, workmanager 0.9.0
- Entfernung der veralteten flutter_app_badger-Abhängigkeit
- Vollständige ARB-Lokalisierung (Deutsch & Englisch) für alle Features
- Alle DAO-Methoden für Datumsbereich-Abfragen ergänzt (Training, Ernährung, Gesundheit, Supplemente, Medikamente)

### Unterstützte Architekturen

- arm64-v8a (64-Bit ARM — empfohlen)
- armeabi-v7a (32-Bit ARM)
- x86_64 (Emulatoren / x86-Geräte)

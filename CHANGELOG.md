# Changelog

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

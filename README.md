# TRAUM — Dein persönliches Dashboard

**TRAUM** ist eine umfassende persönliche Dashboard-App für Android, die dir hilft, alle wichtigen Bereiche deines Lebens im Blick zu behalten — von Fitness und Ernährung über Schlaf und Medikamente bis hin zu Finanzen und Gewohnheiten.

---

## Features

### Gesundheitsscore
Ein intelligenter Score (0–100), der sechs Lebensbereiche bewertet:
- **Training** — Workout-Häufigkeit vs. Wochenziel
- **Ernährung** — Kalorien- & Proteinzufuhr
- **Regeneration** — Schlafqualität (WHO-Empfehlungen)
- **Supplemente** — Einnahmetreue
- **Medikamente** — Medikamentencompliance
- **Stress & Mental** — Stimmungsverlauf

Mit Sparkline-Trend der letzten 7 Tage, Radar-Chart und detaillierter Faktorenanalyse.

### Ernährung
- Kalorientracking mit Makronährstoffen (Protein, Fett, Kohlenhydrate)
- Wassertracking mit individuellen Tageszielen
- Tages- und Wochenverlauf

### Training
- Workout-Protokollierung mit Übungen, Sätzen und Wiederholungen
- Wöchentliche Fortschrittsverfolgung

### Gesundheit
- Schlafprotokoll mit Qualitätsbewertung
- Stimmungstracking
- Herzfrequenz-Integration (Google Health / Apple Health)

### Medikamente & Supplemente
- Einnahme-Erinnerungen mit individuellen Zeiten
- Tägliche Einnahmebestätigung
- Compliance-Tracking

### Gewohnheiten
- Benutzerdefinierte Gewohnheiten mit täglichem Check-in
- Streak-Tracking

### Finanzen
- Budget-Überwachung mit Kategorien
- Ausgabenverlauf

### Homescreen-Widgets
Native Android-Widgets für schnellen Überblick direkt vom Homescreen:
- Abstinenz-Widget
- Budget-Widget
- Kalender-Widget
- Gewohnheiten-Widget
- Gesundheits-Widget
- Medikamenten-Widget
- Ernährungs-Widget
- Übersichts-Widget
- Zyklus-Widget
- Schritte-Widget
- Todo-Widget

### Benachrichtigungen
Konfigurierbare tägliche Erinnerungen für:
- Medikamente
- Training
- Gewohnheiten
- Supplements
- Wassertrinking
- Fällige Todos

### Sicherheit
- Biometrische App-Sperre (Fingerabdruck / Face ID)
- Lokale Datenspeicherung — keine Cloud-Abhängigkeit

### Sprachen
Vollständig auf **Deutsch** und **Englisch** verfügbar.

### Auto-Update
Automatische Update-Prüfung über GitHub Releases.

---

## Screenshots

*Coming soon*

---

## Technische Details

| Eigenschaft | Wert |
|---|---|
| Plattform | Android |
| Min. Android-Version | Android 8.0 (API 26) |
| Framework | Flutter 3.x |
| Datenbank | SQLite (Drift ORM) |
| State Management | Riverpod |
| Navigation | GoRouter |

---

## Installation

### Aus dem Release

1. Gehe zu [Releases](https://github.com/Lupus-atque-Corvus/Traum-APP/releases)
2. Lade die passende APK für dein Gerät herunter:
   - `app-arm64-v8a-release.apk` — für die meisten modernen Android-Geräte (64-Bit ARM)
   - `app-armeabi-v7a-release.apk` — für ältere Android-Geräte (32-Bit ARM)
   - `app-x86_64-release.apk` — für Emulatoren und x86-Geräte
3. Erlaube die Installation aus unbekannten Quellen in den Android-Einstellungen
4. Öffne die heruntergeladene APK-Datei und installiere sie

---

## Build aus dem Quellcode

### Voraussetzungen

- Flutter SDK (>= 3.9.2)
- Android Studio / Android SDK
- Android SDK 26+

### Schritte

```bash
git clone https://github.com/Lupus-atque-Corvus/Traum-APP.git
cd Traum-APP
flutter pub get
flutter build apk --release --split-per-abi
```

Die fertigen APKs befinden sich in `build/app/outputs/flutter-apk/`.

---

## Lizenz

Privates Projekt — alle Rechte vorbehalten.

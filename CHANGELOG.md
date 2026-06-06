# Changelog

## v0.6.8 (2026-06-06) — Graffiti Map

### Neue Funktion

- **Graffiti Map:** Neues Modul mit Foto-Markern auf einer OpenStreetMap-Karte (dunkles Design, Marker-Clustering bei vielen Punkten). Alle Fotos und Daten bleiben **lokal** auf dem Gerät
- **Mehrere Karten-Typen:** Über das Karten-Menü oben rechts zwischen beliebig vielen Karten wechseln. Mitgeliefert: **Graffiti** (Einzelfotos), **Türme** (Sterne-Bewertung + mehrere Fotos) und **Lost Places** (Zustand, Zugänglichkeit, Besucht-Status, Gefahren-Hinweis, Privat-Markierung)
- **Eigene Karten:** Frei konfigurierbar mit Name, Icon, Farbe, Funktionen und eigenen Feldern (Auswahl/Text/Schalter/Zahl)
- **Foto-Metadaten:** Standort und Datum werden aus den EXIF-Daten gelesen (Fallback auf aktuelle GPS-Position), Ort per Reverse-Geocoding
- **Megapixel-Anzeige** bei jedem Foto, **Hashtag- und Volltextsuche**, **Entfernungsanzeige** und **Navigations-Button** (öffnet Google Maps)
- **Export:** Karten als **GPX** oder **JSON** teilen (privat markierte Punkte werden ausgelassen)
- **Panorama-Stitching:** UI vorhanden (experimentell; das Zusammenfügen ist in diesem Build noch deaktiviert)

---

## v0.6.7 (2026-06-05) — Tab-Switcher schneller

### Verbesserung

- **Schnelleres Ansprechen:** Der Gesten-Tab-Switcher startet jetzt nach 200 ms Halten (statt 500 ms) — deutlich direkter
- **Beschleunigtes Durchblättern:** Kleine, langsame Wischer blättern weiterhin präzise Tab für Tab; größere/schnellere Wischer beschleunigen und springen durch viele Tabs auf einmal

---

## v0.6.6 (2026-06-05) — Gesten-Tab-Switcher

### Neue Funktion

- **Schneller Tab-Wechsel per Geste:** Die Navigationsleiste **gedrückt halten** und nach **links/rechts wischen** blättert durch **alle** App-Module. Oberhalb der Leiste erscheint dabei groß das Icon des jeweiligen Moduls (in Modulfarbe); **Loslassen** wechselt zum gewählten Modul
- Haptisches Feedback beim Start und bei jedem Modulwechsel; kein Umlauf an den Listenenden
- Normale Einzel-Taps auf die Tabs funktionieren unverändert

### Technisches

- Modul-Icon-Zuordnung vereinheitlicht (geteilte `moduleIcon`-Funktion für Leiste, „Mehr"-Menü und Switcher)
- Reine, unit-getestete Index-Logik für das Wischen (`switcherIndexFor`)

---

## v0.6.5 (2026-06-05) — Pflicht-Updates

### Änderung

- **Updates sind jetzt verpflichtend:** Ist eine neuere Version verfügbar, lässt sich der Update-Dialog nicht mehr mit „Später" oder der Zurück-Taste schließen. TRAUM ist erst nach dem Update wieder nutzbar
- Offline bleibt die App wie bisher uneingeschränkt nutzbar (die Update-Prüfung schlägt dann still fehl)

---

## v0.6.4 (2026-06-05) — Fix: Standard-Launcher-Button

### Fehlerbehebung

- **Standard-Launcher:** Der Eintrag im experimentellen Bereich öffnete auf den meisten Geräten nichts. Ursache: `RoleManager.ROLE_HOME` lässt sich nicht über den Rollen-Dialog vergeben, sodass keine sichtbare Oberfläche erschien. Der Button öffnet jetzt zuverlässig die System-Einstellung „Standard-Home-App", in der TRAUM auswählbar ist
- Lässt sich die Einstellungsseite nicht öffnen, erscheint nun ein Hinweis (statt stiller Stille)

---

## v0.6.3 (2026-06-05) — Standard-Launcher (experimentell)

### Neues experimentelles Feature

- **Als Standard-Launcher festlegen:** In den Einstellungen unter **Experimentell** (nur Android) lässt sich TRAUM jetzt als Standard-Home-App des Geräts auswählen. Ein Tipp öffnet den System-Auswahldialog; die Statuszeile zeigt live, ob TRAUM aktuell die Home-App ist
- Die App bleibt unverändert: Wird TRAUM als Home gewählt und die Home-Taste gedrückt, öffnet sich das normale Dashboard — keine separate Launcher-Oberfläche
- Lokalisiert (de/en); der Eintrag erscheint nur auf Android

### Technisches

- `CATEGORY_HOME`-Intent-Filter im Android-Manifest, damit TRAUM in der System-Launcher-Auswahl erscheint
- Neuer nativer `traum/launcher`-MethodChannel: System-Auswahldialog via `RoleManager` (Android 10+) mit Fallback auf die Home-Einstellungen; Live-Statusabfrage über `PackageManager`
- Status aktualisiert sich beim Zurückkehren in die App (App-Resume); Unit-Tests für den `LauncherService`

---

## v0.6.2 (2026-06-04) — App-Launcher (experimentell)

### Neues experimentelles Feature

- **App-Launcher:** In den Einstellungen unter **Experimentell** aktivierbar (nur Android). Ist er aktiv, erscheint im **Mehr**-Menü ein Bereich „Apps", in dem sich Lieblings-Apps als Kacheln ablegen und per Tippen direkt starten lassen — wie ein schlanker Launcher
- App-Auswahl über einen Picker mit Suche; angezeigt werden die **echten** System-Icons der installierten Apps (kein gebündeltes Icon-Set)
- Favoriten per „+" hinzufügen, per Langdruck entfernen. Wurde eine App deinstalliert, scheitert der Start sanft mit Hinweis und „Entfernen"-Aktion
- Lokalisiert (de/en); Toggle und Bereich werden auf iOS gar nicht angezeigt (dort technisch nicht möglich)

### Technisches

- Neue Abhängigkeit `installed_apps`; `QUERY_ALL_PACKAGES`-Berechtigung im Android-Manifest (nur Sideload-APK, kein Play-Release)
- Persistenz über `SharedPreferences` (Aktiv-Flag + Favoriten-Paketliste); Unit-Tests für Repository und Favoriten-Provider

---

## v0.6.1 (2026-06-04) — Stabilität & Code-Aufräumung

### Fehlerbehebungen

- **Budget:** Der „+"-Button in der Transaktionsliste führte auf eine nicht registrierte Route ins Leere — öffnet jetzt korrekt die Schnell-Erfassung
- **Datenbank:** Fehlt das SQLite-FTS5-Modul, blockierte das Anlegen der Notizen-Suchtabelle bisher das Öffnen der **gesamten** App-Datenbank. Die Volltextsuche degradiert nun sanft, statt die App unbrauchbar zu machen
- **Medikamente/Mittel:** `BuildContext` wurde über asynchrone Lücken hinweg verwendet (Lokalisierung jetzt vorab erfasst)

### Aufräumarbeiten & Wartung

- ~3.900 Zeilen ungenutzten Code entfernt: 3 verwaiste Screens (Medikamente/Supplements/Transaktion-Hinzufügen — durch konsolidierte Ansichten ersetzt), 3 redundante Services, 12 verlassene Budget-Widgets, alter JSON-Substanz-Seeder sowie weitere tote Dateien
- Veraltete Flutter-APIs migriert (`activeColor` → `activeThumbColor`, `onReorder` → `onReorderItem`)
- Statische Analyse vollständig bereinigt: **0 Analyzer-Meldungen**, alle Tests grün

---

## v0.6.0 (2026-06-04) — Notizen-Modul (Obsidian-artiges PKM)

### Neues Modul „Notizen"

- Vollständiges Personal-Knowledge-Management-Modul, als zuweisbares Nav-Slot-Modul registriert und über „Mehr" erreichbar
- **Datenmodell:** Drift als Source of Truth (Notizen, Ordner, Links, Tags, Vorlagen); Schemaversion 11 mit Migration. Volltextsuche über **SQLite FTS5** inkl. Sync-Triggern
- **Editor:** Edit-/Reading-Toggle (Pill), automatisches Speichern mit Debounce, Syntax-Highlighting im Roh-Editor
- **Markdown:** CommonMark + GFM plus Obsidian-Erweiterungen — `[[Wikilinks]]`, Embeds `![[…]]`, Callouts `> [!type]`, `#tags` (verschachtelt), Highlights `==…==`, Kommentare `%% … %%`, abhakbare Aufgabenlisten, LaTeX (`$…$`, `$$…$$`), YAML-Frontmatter/Properties. Mermaid-Blöcke werden als formatierte Codeblöcke dargestellt
- **Verlinkung:** Wikilink-/Tag-Index beim Speichern; Backlinks-, Outgoing- und Outline-Panel; unaufgelöste Links werden markiert
- **Suche & Navigation:** Volltextsuche mit Treffer-Hervorhebung, Quick-Switcher mit „Notiz anlegen"
- **Weitere Ansichten:** Tag-Browser (verschachtelter Baum), Tagesnotizen über `table_calendar`, Vorlagen mit Platzhaltern (`{{title}}`, `{{date:FORMAT}}`, `{{time}}`), kraftgerichteter **Graph View** (Knotengröße nach eingehenden Links, lokaler Graph), Papierkorb (Soft-Delete), Vault-Import/-Export als `.md`-ZIP
- Vollständig lokalisiert (de/en); Soft-UI im bestehenden Dark-Theme und Gradient-Akzenten

### Technisches

- Markdown-Engine von `flutter_markdown` (eingestellt) auf den gepflegten Nachfolger `flutter_markdown_plus` (+ LaTeX) migriert
- Neue Abhängigkeiten: `flutter_markdown_plus`, `flutter_markdown_plus_latex`, `flutter_math_fork`, `markdown`, `yaml`, `graphview`, `file_picker`

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

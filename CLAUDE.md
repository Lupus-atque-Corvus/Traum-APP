# CLAUDE.md — TRAUM Flutter App

> Einstiegspunkt für Claude Code in diesem Projekt.
> Repo: **Lupus-atque-Corvus/Traum-APP** · Version **1.2.4+124** · schemaVersion **29**.
> Alle Angaben unten sind direkt aus dem Quellcode dieses Repos verifiziert.

---

## 📋 OFFENE PUNKTE (Stand 2026-08-17 — hier in der nächsten Session weitermachen)

**Braucht dein Handy (adb-Verbindung):**
- [ ] **105-Pakete-Update, Rest.** 59 von 105 sind in v1.1.9 bereits sicher aktualisiert
  (nur Versionen innerhalb bestehender `^x.y.z`-Constraints). Offen: ~46 Pakete mit
  Major-Versionssprüngen — u. a. `flutter_local_notifications` (18.0.1→22.3.0, **das
  Paket, das gerade erst den ProGuard/Gson-Bug in v1.1.4 verursacht hat** — hier besonders
  vorsichtig testen), `health`, `permission_handler`, `camera`, `google_mlkit_text_recognition`,
  `connectivity_plus`, `share_plus`, `geocoding`, `device_info_plus`, `sqlite3`,
  `flutter_secure_storage`, `flutter_timezone`, `open_file`, `package_info_plus`. Eigener
  Nachmittag, gruppenweise (ein Paket/eine kleine Gruppe nach der anderen), nach jeder Gruppe
  `flutter analyze` + `flutter test` + Release-Build + **echter Gerätetest**, bevor die
  nächste Gruppe angefasst wird.
- [ ] **Zweiter, nie bestätigter Fehler aus der Live-Diagnose (v1.1.4):**
  `PlatformException(500, ...Integer.intValue()... null...)`, kein Stacktrace. Verdacht
  (nicht bestätigt): Alt-/Restdaten von `flutter_local_notifications` aus den monatelangen
  fehlgeschlagenen Reschedule-Läufen vor dem ProGuard-Fix. `run-as` funktioniert auf dem
  signierten Release-Build nicht (nicht debuggable) — kann nicht direkt inspiziert werden.
  **Falls dir eine konkrete Erinnerung/Benachrichtigung mal nicht kommt: bitte melden**, dann
  gezielt mit `adb logcat` nachgehen.
- [ ] **Kamera-Referenz-Overlay live durchspielen** (Berechtigung, Aufnahme, App-Wechsel
  während offener Kamera) — nur am echten Gerät testbar.

**Braucht einen Mac:**
- [ ] **iOS-Homescreen-Widgets** — kein Build/Test ohne Mac möglich.

**Reine Entscheidung/Setup, kein Code-Risiko:**
- [ ] **Play-Store-Signing.** `android/key.properties` existiert nicht, `traum-release-key.jks`
  liegt bereit aber unverdrahtet — alle bisherigen Releases sind debug-signiert (siehe
  Kommentar in `android/app/build.gradle.kts`). Für privaten Sideload-Gebrauch unkritisch,
  nur relevant falls je ein echter Play-Store-Release geplant ist.
- [ ] **Äußeres Workspace-Repo** (`C:\Users\Lupus\Desktop\Traum\`, NICHT `traum_app`) hat noch
  uncommittete Änderungen aus der Icon-Pipeline-Arbeit (`exercise_icons_workspace/`
  batch-Umbenennungen, `remaining_pool.txt`, `README.md`). Bewusst nicht automatisch
  committet — nur `traum_app` bekommt die "immer Release"-Behandlung. Falls gewünscht, im
  äußeren Repo selbst committen (kurz absprechen, was rein soll).

**Niedrigprior, rein optional:**
- [ ] **App-weites Tap-Target-Audit (<44dp).** Aus einer frühen Audit-Runde, nie
  systematisch abgearbeitet — separate Aufgabe von den jetzt abgeschlossenen 48
  Semantics-Fundstellen.

**Bereits erledigt in dieser Session** (zur Einordnung, nicht mehr offen): Update-Dialog-
Hotfix (v1.1.5), `dart format` (in v1.1.6er-Commit), SettingsScreen-Testabdeckung (v1.1.6),
alle 48 Barrierefreiheits-Fundstellen (v1.1.7 + v1.2.0), Home-Widget-Katalog vollständig
lokalisiert (v1.1.8), 59 sichere Paket-Updates (v1.1.9), Diary-Header-Vereinheitlichung
geprüft (kein sicherer Kandidat gefunden, keine Änderung nötig).

---

## ⏩ AKTUELLER STAND / HANDOFF  (2026-08-19 — v1.2.4, Geräte-zu-Geräte-Backup-Übertragung im LAN)

**Auf Nutzerwunsch: Backups lassen sich jetzt direkt zwischen zwei TRAUM-Geräten im selben WLAN
übertragen — ohne Cloud, Kabel oder manuelles Datei-Teilen, in jede Richtung (Handy↔Handy,
Handy↔Desktop, Desktop↔Desktop), für Android/iOS/Windows/Linux. Architektur an LocalSend
angelehnt (Flutter-App, reines LAN-REST-Protokoll, kein Signaling-Server), NICHT an PairDrop
(Node.js+WebRTC, vom Nutzer als Ausgangsinspiration genannt, aber nicht direkt einbettbar).**

1. **Protokoll:** Empfänger startet einen lokalen `HttpServer` (nur während der Empfangs-Screen
   offen ist), zeigt QR-Code + Klartext-Pairing-Code (`XXXX-XXXX`, Crockford Base32, 5 zufällige
   Bytes, 2 Min. Ablauf, 5-Versuche-Sperre). Sender scannt (oder gibt auf Desktop manuell IP/Port/
   Code ein) → `POST /pair` → **Bestätigung #1** auf dem Empfänger ("Gerät X möchte senden —
   Annehmen/Ablehnen") → verschlüsselter Upload → Empfänger dekodiert + zeigt Vorschau
   (Tabellen/Zeilen/Medien-Anzahl) → **Bestätigung #2** ("Wirklich importieren?") → erst danach
   läuft `BackupService.restoreFromBytes()` — das ist der EINZIGE Aufrufpfad, nie automatisch.
   Sender pollt `GET /status/{sessionId}` alle ~750ms für Live-Fortschritt (kein Push-Kanal nötig).
2. **Sicherheit:** Anwendungsschicht-Verschlüsselung statt TLS — bewusste Entscheidung, da echtes
   Selbstsigniert-TLS + Zertifikat-Pinning deutlich mehr neue, sicherheitskritische Fläche gebraucht
   hätte (On-Device-X.509-Erzeugung) für denselben Vertrauensanker (Kenntnis des Pairing-Codes).
   `HKDF-SHA256(pairingCode) → AES-256-GCM`, Session-ID fließt als HKDF-Info ein. Gleiches Muster
   wie Magic Wormhole/croc. LAN-only, keine automatische Geräte-Erkennung (kein mDNS/Broadcast).
3. **Neue Dateien:** `lib/core/services/backup_transfer/` (`backup_transfer_models.dart` —
   `PairingCode`/`PairingSession`/`PairingInfo`/`TransferStatus`/`BackupPreview`;
   `backup_transfer_crypto.dart` — HKDF+AES-GCM; `backup_receive_server.dart` —
   `BackupReceiveServer`, 3-Endpunkt-Dispatch über rohes `dart:io HttpServer`, kein `shelf`;
   `backup_send_client.dart` — `BackupSendClient`, treibt Pairing→Poll→Upload→Poll;
   `device_name.dart`/`local_ip.dart` — Anzeige-Helfer). Additiv-only-Erweiterung von
   `backup_service.dart`: neue `previewBackup()`-Methode, teilt sich die Decode-Logik mit
   `restoreFromBytes()` über eine extrahierte private `_decodeBackupJson()` (verhaltensgleich,
   verifiziert vor der Änderung).
4. **Neue UI:** `lib/features/backup_transfer/` (`receive_backup_screen.dart` — QR/Code-Anzeige,
   treibt beide Bestätigungsdialoge; `send_backup_screen.dart` — baut Backup, dann QR-Scan
   (`mobile_scanner`, per `!isDesktop` ausgeblendet auf Desktop) oder manuelle Eingabe;
   `pairing_manual_entry_sheet.dart` — Desktop-/Kein-Kamera-Fallback). **Zwei neue
   Einstellungen-Buttons** wie vom Nutzer gefordert: `_SecuritySection` in `settings_screen.dart`,
   direkt neben Export/Import — „An anderes Gerät senden" / „Von anderem Gerät empfangen".
   Volle Screens (`Navigator.push`), keine neuen `go_router`-Routen (nicht Widget-Deep-Link-fähig,
   analog zum Barcode-Scanner-Muster).
5. **TDD durchgehend** (Rot→Grün für jede neue Logikdatei, wie im Projekt vorgeschrieben): 19
   Pairing-Tests (Crockford-Rundreise, Ablauf via `fake_async`, Sperre), 12 Krypto-Tests
   (Determinismus, Rundreise, Manipulationserkennung), 5 Ende-zu-Ende-Roundtrip-Tests mit echtem
   `HttpServer`+`http.Client` auf `127.0.0.1` (Happy Path, falscher Code, Ablehnung #1, Ablehnung
   #2 — beweist bytes-empfangen-aber-nicht-angewendet —, Sender sieht Geräte-Namen), 6
   Screen-Widget-Tests gegen Fakes (`test/features/backup_transfer/fakes.dart` —
   `FakeBackupReceiveServer`/`FakeBackupSendClient`, da `TestWidgetsFlutterBinding` echte Sockets/
   Plattformkanäle nie zuverlässig auflöst, auch nicht mit `runAsync`).
6. **Echte Builds + Läufe auf allen 3 hier baubaren Plattformen verifiziert, nicht nur
   angenommen:** Windows-Release-Build gestartet und beide neuen Screens per Screenshot-Automation
   durchgeklickt — echtes `HttpServer.bind`, echte `NetworkInterface.list()`-IP-Erkennung, echte
   QR-Anzeige, echter `buildBackupZip()`-Lauf (84.334 Zeilen in ~6,5s). Linux via WSL-Klon
   neu gebaut, headless gestartet, Log auf Exceptions geprüft — sauber. Android-Emulator: APK
   installiert, beide Screens durchgeklickt (Receive zeigt echten QR+Code; Send fragt echte
   Kamera-Berechtigung ab und öffnet den `MobileScanner`-Viewport ohne Absturz), `adb logcat` auf
   FATAL/Exception geprüft — keine gefunden.
7. **iOS:** `NSLocalNetworkUsageDescription` zu `Info.plist` ergänzt (Pflicht, sobald die App im
   lokalen Subnetz kommuniziert — betrifft sowohl den eingehenden Bind des Empfängers als auch die
   ausgehende Verbindung des Senders). Kein `NSBonjourServices` nötig — Pairing verbindet über eine
   direkte IP:Port aus QR/PIN, nie über Bonjour/mDNS. **Nicht gebaut/getestet** — mangels Mac wie
   der Rest des Projekts.
8. **Bewusst nicht verifizierbar in dieser Umgebung — für dich zu bestätigen:** eine echte
   Zwei-Geräte-Übertragung übers eigene Heim-WLAN (z. B. Handy → Windows-PC). Falls ein Router/
   öffentliches WLAN AP-Isolation nutzt, sehen sich die Geräte gegenseitig nicht — das ist eine
   Router-Einstellung außerhalb der App-Kontrolle, kein Bug, aber gut zu wissen, falls die
   Übertragung in einem bestimmten Netz partout nicht anläuft.

**Versionshinweis:** Wurde zunächst versehentlich als `v1.3.0` getaggt/veröffentlicht (Minor-Bump
für "echtes neues Feature" — das war ein Fehler, siehe Regel #17: die Ziffern-Rollover-Regel ist
rein mechanisch, kein SemVer-Feature/Fix-Unterschied). Da 0 Downloads registriert waren, wurde der
`v1.3.0`-Tag/-Release noch komplett gelöscht und sauber als `v1.2.4` neu veröffentlicht — anders
als beim historischen `0.9.9`→`v0.10.0`-Vorfall (dort blieb der bereits publizierte Tag stehen,
weil er nicht mehr rückstandsfrei entfernbar war/schon Downloads hatte). Für künftige Releases
gilt unverändert: Patch-Ziffer läuft einfach +1 pro Release, Minor-Bump nur beim Ziffern-Überlauf
über 9 — unabhängig davon, ob es sich inhaltlich um ein Feature oder einen Fix handelt.

`flutter analyze` → **0 Issues**. `flutter test` → **631/631 grün** (588 vorher + 43 neu).
Release: https://github.com/Lupus-atque-Corvus/Traum-APP/releases/tag/v1.2.4 (Android arm64 +
Windows x64 lokal gebaut und angehängt, Linux x64 automatisch per CI-Workflow beim Veröffentlichen
angehängt).

---

## ⏩ VORHERIGER STAND (2026-08-19 — v1.2.3, echtes App-Icon auf allen 4 Plattformen)

**Auf Nutzerwunsch: das vom Nutzer gelieferte Logo (stilisiertes blaues "T" mit
Stadt-/Globus-Motiv) als tatsächliches App-Icon auf Android, iOS, Windows und Linux
eingebunden.**

1. **🔴 Echter, bislang unbemerkter Bestandsbug gefunden, kein reines Kosmetik-Update:**
   `assets/icon/icon.png` war buchstäblich ein **1×1-Pixel-Platzhalter** (69 Bytes) — trotz
   seit Projektbeginn konfiguriertem `flutter_launcher_icons` in `pubspec.yaml` wurde der
   Generator offenbar nie mit einem echten Quellbild ausgeführt. **Jeder bisherige Release
   ist mit dem simplen Standard-Flutter-Logo als App-Icon ausgeliefert worden** — direkt am
   bestehenden `android/.../mipmap-xxxhdpi/ic_launcher.png` verifiziert (zeigte das blaue
   Flutter-"F", nicht TRAUM), nicht nur vermutet.
2. Logo (1254×1254, bereits quadratisch) nach `assets/icon/icon.png` kopiert,
   `dart run flutter_launcher_icons` neu ausgeführt (Android + iOS + neu aktiviertes
   `windows:`) — alle Icon-Größen für alle drei Plattformen neu generiert.
3. **Linux hat kein äquivalentes Tool** — manuell verdrahtet: 256×256-Kopie des Logos unter
   `linux/resources/icon.png`, von `linux/CMakeLists.txt` mit ins Bundle (`data/icon.png`)
   installiert, zur Laufzeit in `my_application.cc` per `gtk_window_set_icon_from_file()`
   geladen (Pfad relativ zur laufenden Programmdatei über `/proc/self/exe` aufgelöst — läuft
   sowohl aus dem Build-Ordner als auch aus dem installierten Bundle, fehlt die Datei mal,
   gibt's einfach kein Icon statt eines Absturzes). Zusätzlich `linux/traum.desktop` als
   Vorlage für einen Anwendungsmenü-Eintrag ergänzt.
4. **Auf jeder tatsächlich hier baubaren Plattform visuell verifiziert, nicht nur
   angenommen:** Android-Mipmap-PNG zeigt jetzt das echte Logo (direkt gegen die alte
   Flutter-Standard-Icon-Datei verglichen), die aus der gebauten Windows-`.exe` extrahierte
   Icon-Ressource zeigt das Logo noch bei 32×32 erkennbar, das über den WSL-Klon neu gebaute
   Linux-Bundle hat `data/icon.png` tatsächlich im Bundle und startet weiterhin sauber ohne
   neue Exceptions. iOS-Icon-Set wurde mit erzeugt, konnte mangels Mac aber nicht gebaut/
   getestet werden — gleiche Einschränkung wie beim Rest des Projekts.

`flutter analyze` → **0 Issues**. `flutter test` → **588/588 grün**.

---

## ⏩ VORHERIGER STAND (2026-08-19 — v1.2.2, erster Windows/Linux-Desktop-Release)

**Auf Nutzerwunsch: nach dem README-Update (siehe VORHERIGER STAND direkt unten) Windows- und
Linux-Desktop-Support aufgebaut — "Companion-Modus" wie zuvor abgestimmt: Kernmodule laufen,
mobile-exklusive Features werden sauber ausgeblendet statt abzustürzen. Kein Daten-Sync
zwischen Geräten (bewusst, eigene Entscheidung).**

1. **`flutter create --platforms=windows,linux .`** — neue Plattformordner, **keine einzige
   Dart-Änderung nötig, damit die App überhaupt kompiliert**: Drifts `NativeDatabase` +
   `path_provider` funktionieren bereits unverändert cross-platform.
2. **Zwei echte, durch tatsächliches Bauen+Ausführen verifizierte Bugs gefunden und behoben**
   (nicht nur "sollte gehen" angenommen):
   - `home_widget` hat gar keine Desktop-Implementierung — `app.dart`s
     `HomeWidget.widgetClicked`-Listener warf beim ersten Frame eine
     `MissingPluginException`. Neuer zentraler Gate `lib/core/platform/desktop.dart`
     (`isDesktop`), verdrahtet in `main.dart` (Widget-/WorkManager-Init übersprungen) und
     `app.dart` (Listener + periodischer Refresh übersprungen).
   - Linux-Build scheiterte hart an einem Compiler-Fehler: `flutter_secure_storage_linux`
     bringt eine ältere `nlohmann/json` mit, die einen inzwischen von neuerem Clang als
     Fehler behandelten Literal-Operator-Syntax verwendet — fremder, nicht selbst
     kontrollierter Code. Gezielt nur diese eine Diagnose in `linux/CMakeLists.txt` von
     Error zurück auf Warning gestuft (`-Wno-error=deprecated-literal-operator`,
     Clang-only), statt `-Werror` projektweit zu deaktivieren.
3. **Systematisch nach dem exakt gleichen Fehlerbild wie beim v1.2.1-Tagebuch-Bug gesucht**
   ("nichts passiert beim Antippen") — `try { … } finally { … }` ohne `catch`, das eine
   Plattform-Exception einfach verschluckt statt sie zu zeigen. Gefunden und per UI-Ausblenden
   behoben (nicht per Try/Catch — die Funktion selbst ist auf Desktop grundsätzlich nicht
   nutzbar):
   - Tagebuch-Kamera-Aufnahme (kein Kamera-Backend unter Linux, ungeprüft unter Windows) —
     Foto/Video-Buttons durch Hinweistext ersetzt, Ansicht/Notizen/Kalender bleiben nutzbar.
   - Barcode-Scanner an allen 3 Stellen (Hauptscreen, Mahlzeit-Schnelleintrag,
     Vorlagen-Suche) — manuelle Eingabe bleibt überall erhalten.
   - Kassenzettel-OCR (Budget-Schnelleingabe **und** Einkaufsmodus-Checkout) — weder
     `image_picker` noch `google_mlkit_text_recognition` haben ein Desktop-Backend.
   - **Wichtigster Einzelfund:** `PlanningScreen.initState()` löst bei **jedem** Öffnen des
     Planung-Tabs einen automatischen Kalender-Sync aus (`addPostFrameCallback`) —
     `CalendarSyncService.requestPermissions()` ruft `device_calendar` direkt auf, **komplett
     ungeschützt**. Hätte auf Desktop bei jedem einzelnen Tab-Besuch geworfen. Auto-Sync +
     manueller Sync-Button im AppBar jetzt auf Desktop übersprungen; Settings-Sektion
     ebenfalls ausgeblendet.
4. **Health-Modul und Biometrie-Sperre brauchten dagegen KEINE Änderung** — beide kapseln
   bereits jeden Plugin-Aufruf in Try/Catch mit sauberem Fallback (`HealthService` liefert
   überall `0`/leere Liste, `_checkBiometric()` deaktiviert den Schalter bei
   `!_biometricAvailable`). Direkt im Quellcode verifiziert, nicht nur vermutet.
5. **Fenstergröße auf beiden Plattformen von 1280×720 (Querformat) auf 480×900 (Hochformat)
   geändert** + Fenstertitel auf "TRAUM" vereinheitlicht — die UI ist ein
   Einspalten-Layout für Telefonbreite, bei 1280px unschön in die Breite gezogen.
6. **Neuer `.github/workflows/linux-release.yml`**: baut das Linux-Bundle automatisch bei
   jedem veröffentlichten Release und hängt es an — notwendig, weil die eigene Maschine
   Windows-only ist und Linux nur via WSL2 gebaut werden kann (siehe unten).
7. **WSL2 Ubuntu als echte lokale Linux-Build-Umgebung eingerichtet** (nicht nur für CI
   verlassen): eigenes natives Linux-Flutter-SDK unter `~/flutter-linux` (die Windows-seitige
   Installation unter `/mnt/c/dev/flutter` scheitert an CRLF-Zeilenenden in ihren
   Shell-Skripten, wenn man sie aus WSL heraus aufruft), kompletter Build-Toolchain
   (`clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-13-dev
   libsecret-1-dev`) per `apt`. **Wichtige Falle:** Bauen direkt auf `/mnt/c/...` (DrvFs)
   schlägt mit "Operation not permitted" in CMakes `configure_file()` fehl — Workaround: Repo
   zusätzlich in einen echten Linux-Pfad klonen (`~/traum_app_linux`) und dort bauen.

`flutter analyze` → **0 Issues**. `flutter test` → **588/588 grün**. Beide Plattformen
tatsächlich gebaut UND laufen lassen, nicht nur kompiliert — Windows-`.exe` per PowerShell-
Screenshot visuell bestätigt, Linux-Bundle per `timeout`-Lauf mit Log-Prüfung: **keine einzige
`MissingPluginException` mehr**, vorher zwei verschiedene.

**Bewusst noch offen — als eigener, künftiger Durchgang, kein Blocker:**
`installed_apps`-basierter App-Launcher (bereits Android-only markiert, im Onboarding gar
nicht als wählbares Modul auswählbar — auf Desktop strukturell unerreichbar, kein Fix nötig).
`video_player`s Windows/Linux-Unterstützung für Tagebuch-Video-Wiedergabe noch nicht geprüft
(betrifft nur das Abspielen bereits vorhandener Video-Einträge, die auf Desktop mangels
Kamera ohnehin nie neu entstehen). `flutter_local_notifications` hat auf der gepinnten Version
keinen funktionierenden Windows-Pfad — bereits vorher exception-sicher (aus einer früheren
Runde), degradiert also nur still, kein neuer Fix nötig. Kein echter Windows-/Linux-Rechner mit
Play-Store-ähnlicher Distribution getestet — nur der lokale Build+Lauf.

---

## ⏩ VORHERIGER STAND (2026-08-18 — v1.2.1, Tagebuch-Speichern-Bug auf jedem Bestandsgerät)

**Erste echte Live-Nutzung des Tagebuch-Kamera-Flows (seit Phase 1 als offener, nie am echten
Gerät getesteter Punkt geführt) fand einen kritischen Bug: nach Foto/Video-Aufnahme passierte
beim Antippen von "Speichern" im "Speichern und Notizen"-Sheet nichts — kein Fehler, keine
Navigation, kein gespeicherter Eintrag.**

1. **🔴 Root Cause per `systematic-debugging` gefunden, nicht geraten — betraf JEDES
   Bestandsgerät, nicht nur einen Sonderfall.** `DiaryDao.upsertEntry()`
   (`diary_dao.dart`) gibt SQLite ein `ON CONFLICT(diary_id, date)`-Ziel ohne `WHERE`-Klausel
   vor. Der reale Unique-Index, den die v27→v28-Migration (v0.9.4) auf jedem je aktualisierten
   Gerät angelegt hatte, war aber fälschlich PARTIAL (`WHERE diary_id IS NOT NULL`) — nur
   `createAll()`-Neuinstallationen bekamen über `uniqueKeys` in `DiaryEntries` einen
   nicht-partiellen Constraint und blieben verschont. SQLite muss den `ON CONFLICT`-Zielindex
   beim Vorbereiten des Statements exakt auflösen (Spalten UND `WHERE`-Klausel) — bei einer
   Abweichung wirft es sofort `"ON CONFLICT clause does not match any PRIMARY KEY or UNIQUE
   constraint"`, unabhängig davon, ob überhaupt ein echter Konflikt vorliegt. Traf damit
   ausnahmslos den ALLERERSTEN Speichern-Versuch nach einem Foto/Video auf jedem Gerät, das je
   durch die v28-Migration gelaufen ist — nicht erst beim zweiten Eintrag für denselben Tag.
   Die Exception blieb unsichtbar: `DiaryCaptureSheet._save()` hat ein `try {…} finally {…}` ohne
   `catch`, und da `ElevatedButton.onPressed`-Callbacks nicht awaited werden, wird der
   abgelehnte Future zu einem unbehandelten Async-Fehler — kein Dialog, keine Snackbar, der
   Spinner setzt sich einfach zurück.
2. **Fix: beide Schema-Erzeugungspfade auf denselben, nicht-partiellen Unique-Index
   vereinheitlicht**, statt einseitig eine `targetCondition` zu ergänzen (Drifts `DoUpdate`
   böte das an, hätte aber die beiden Pfade dauerhaft auseinanderlaufen lassen).
   `_fixDiaryEntryDuplicates()` erzeugt den Index jetzt ohne die Partial-Klausel (SQLite behandelt
   `NULL` in Unique-Indizes ohnehin als von jedem anderen `NULL` verschieden — die Klausel war
   unnötige Vorsicht, keine Notwendigkeit). **schemaVersion 28→29:** neuer Migrationsschritt
   droppt den alten partiellen Index auf Bestandsgeräten und legt ihn nicht-partiell neu an
   (`_fixDiaryEntryUpsertConflictTarget()`). `DiaryDao.upsertEntry()` selbst blieb unverändert —
   sobald beide Pfade übereinstimmen, löst das bestehende `target: [diaryId, date]` korrekt auf.
3. **TDD, wie vom Projekt vorgeschrieben:** neuer
   `test/data/database/diary_upsert_migration_v29_test.dart` seedet eine reale v28-Datenbank
   (inkl. des alten partiellen Index) und reproduziert den exakten `SqliteException`-Fehler des
   Nutzers 1:1 — schlug vor dem Fix fehl, ist jetzt grün. Zusätzlich
   `legacy_v1_migration_test.dart` (kompletter v1→aktuell-Kettentest) um einen echten
   `upsertEntry()`-Aufruf am Ende erweitert, damit auch der volle Migrationspfad end-to-end
   geprüft ist, nicht nur der isolierte v28→v29-Schritt.

`flutter analyze` → **0 Issues**. `flutter test` → **588/588 grün** (586 vorher + 2 neu).
**Nicht mehr live am Emulator nachvollzogen** (Emulator lief unter starker Ressourcen-Konkurrenz
auf dieser Maschine in eine wiederkehrende "System UI isn't responding"-ANR-Schleife) — die
automatisierten Migrationstests reproduzieren aber die exakte, real gemeldete SQLite-Exception
und beweisen den Fix direkt, nicht nur indirekt.

---

## ⏩ VORHERIGER STAND (2026-08-15 — v1.2.0, Barrierefreiheit: die restlichen 9 Fundstellen)

**Abschluss der 48-Fundstellen-Liste aus dem 10.08.-Audit: v1.1.7 hatte 39 gefixt, hier die
restlichen 9 gelisteten Dateien (tatsächlich mehr Einzelfundstellen, da mehrere Dateien
2+ Treffer hatten) — die komplette Liste ist damit durchgearbeitet.**

1. **Gleiches etabliertes Muster wie v1.1.7**, konsequent angewendet: `Semantics(button:,
   label:) + ExcludeSemantics(child:)` außen um Container-wrappende GestureDetector/InkWell,
   Label individuell aus dem sichtbaren Inhalt hergeleitet. Über alle 20 gelisteten Dateien:
   `graffiti_map/{create_collection_screen (3), dynamic_marker_sheet, graffiti_map_screen (2:
   _circleButton + _actionButton, je an mehreren Aufrufstellen genutzt), marker_detail_screen}.dart`,
   `home/{home_edit_overlay (2: Entfernen-/Resize-Handles), home_widget_frame}.dart`,
   `lock/pin_lock_screen.dart` (PIN-Numpad), `notes/{notes_search_screen (2),
   widgets/notes_common (2)}.dart`, `nutrition/{amount_entry_sheet, shopping/
   {checkout_sheet (3), list_view (3), mode_screen (2)}}.dart`, `onboarding/{onboarding_screen
   (3: PIN-Numpad + Security-Options-Karte + Geburtsdatum-Picker), widgets/training_setup_page}.dart`,
   `period_tracking/daily_log_sheet.dart` (3), `settings_screen.dart` (4: Uhrzeit-Chip,
   Währungs-Picker, PIN-Numpad ×2), `substances/database_tab.dart` (3), `training/
   {exercise_picker_screen (2), muscle_heatmap_screen (2), routines_screen}.dart`.
2. **🔴 Wichtigster Einzelfund: `home_widget_frame.dart` hatte schon eine äußere
   `Semantics(button:, label: title)`-Hülle aus einer früheren Runde — aber ohne
   `ExcludeSemantics`.** Das betrifft JEDE der 68 gerade erst in v1.1.8 lokalisierten
   Home-Kacheln: TalkBack merged bisher den inneren Titel-Text (und was die Kachel selbst an
   Semantik mitbringt) als zusätzliche Knoten neben der äußeren Beschriftung — der Titel wurde
   doppelt vorgelesen. Jetzt mit `ExcludeSemantics` behoben.
3. **Eine bewusste Ausnahme vom Standardmuster:** `routines_screen.dart`s `_PlanCard` bekommt
   NUR das `button`-Trait ohne `ExcludeSemantics`/Label-Override (wie `TraumCard`) — die Karte
   enthält einen eigenen, unabhängig antippbaren `TextButton` ("Aktivieren"); `ExcludeSemantics`
   hätte dessen eigene Ansage stillschweigend verschluckt.
4. **Nebenbei 3 weitere hartcodierte deutsche Strings gefixt** (aufgefallen, weil der exakte
   Text ohnehin fürs Semantics-Label gebraucht wurde): `shopping_checkout_sheet.dart`s
   Buchen-Button, `shopping_list_view.dart`s „Einkaufen starten"-Button, sowie die beiden neuen
   `_CircleAction`-Label in `shopping_list_view.dart`. Neue ARB-Keys entsprechend ergänzt.
5. **Jede Datei einzeln mit `dart format` auf Syntaxfehler geprüft**, bevor zur nächsten
   gewechselt wurde — mehrere Klammer-Ungleichgewichte durch die zusätzliche Verschachtelung
   dabei sofort gefunden und korrigiert (nicht erst bei der finalen Analyse).

`flutter analyze` → **0 Issues**. `flutter test` → **586/586 grün**. Release-Build erfolgreich.
Rein additive Semantics-Änderungen (bis auf die 3 Text-Fixes), kein Layout-/Verhaltens-Risiko.

**Damit ist die komplette 48-Fundstellen-Liste aus dem 10.08.-Audit abgearbeitet** (39 in
v1.1.7 + 9 gelistete Dateien hier, tatsächlich ~48 Einzelfundstellen insgesamt).

---

## ⏩ VORHERIGER STAND (2026-08-15 — v1.1.9, sichere Paket-Updates — Rest bewusst zurückgestellt)

**Letzter Punkt der "alles andere"-Liste: 105 veraltete Pakete. Bewusst NICHT komplett
abgearbeitet — siehe Begründung unten.**

1. **Scope bewusst eingeschränkt.** Der ursprüngliche Umsetzungsplan verlangt für diesen
   Punkt explizit "einen echten Gerätetest danach" — das Handy war zum Zeitpunkt dieser
   Session bereits wieder getrennt (seit der Live-Diagnose-Session in v1.1.4). Eine volle
   `--major-versions`-Aktualisierung hätte u. a. `flutter_local_notifications` von 18.0.1 auf
   22.3.0 gehievt — genau das Paket, dessen fehlende ProGuard-Keep-Regel gerade erst in v1.1.4
   als monatelanger Bug gefunden wurde. Ein so großer Versionssprung an genau dieser Stelle
   blind (ohne Gerät) zu machen wäre grob fahrlässig gewesen.
2. **Stattdessen: nur `flutter pub upgrade` ohne `--major-versions`.** Das zieht ausschließlich
   Versionen, die die **bestehenden** `^x.y.z`-Constraints in `pubspec.yaml` bereits erlauben —
   per Semver-Definition rückwärtskompatibel, kein Constraint-Edit nötig. 59 Pakete
   aktualisiert, u. a. `flutter_riverpod` 3.1.0→3.2.1, `riverpod`/`riverpod_annotation`/
   `riverpod_generator`, `drift`-Unterbau (`sqlparser` 0.41.2→0.43.1), `go_router` bereits
   aktuell, `video_player` 2.11.1→2.14.0 (inkl. nativer Android/iOS-Unterpakete),
   `workmanager` 0.9.0+3→0.9.3, `table_calendar`, `mobile_scanner`-Unterbau. Nur
   `pubspec.lock` geändert, `pubspec.yaml` unangetastet.
3. **Bewusst NICHT angefasst** (bräuchten `--major-versions` + Einzelprüfung + Gerätetest):
   `flutter_local_notifications` (18.0.1→22.3.0), `health` (13.1.4→13.3.2), `permission_handler`
   (12.0.3→13.0.1), `camera` (0.11.4→0.12.0+2), `google_mlkit_text_recognition` (0.13.1→0.16.0),
   `connectivity_plus`, `share_plus`, `geocoding`, `device_info_plus`, `sqlite3`,
   `flutter_secure_storage`, `flutter_timezone`, `open_file`, `package_info_plus`, u. a. — noch
   ~46 Pakete offen, siehe `flutter pub outdated` für die aktuelle Liste.
4. **Release-Build zur Verifikation gebaut** (nicht nur `flutter analyze`/`flutter test` — ein
   echter `flutter build apk --release` fängt Gradle/R8-Probleme ab, die reine Dart-Analyse
   nicht sieht). Baute sauber durch.

`flutter analyze` → **0 Issues**. `flutter test` → **586/586 grün**. Release-Build erfolgreich.

**Für die nächste Runde:** volle `--major-versions`-Aktualisierung bleibt ein eigener,
sorgfältiger Nachmittag mit angeschlossenem Gerät — nicht vorher anfangen.

---

## ⏩ VORHERIGER STAND (2026-08-15 — v1.1.8, Home-Widget-Katalog vollständig lokalisiert)

**Letzter offener Übersetzungs-Rest aus Phase 6: die Titel der 68 Home-Widget-Kacheln waren
hartcodiertes Deutsch, unabhängig von der App-Sprache. Vorher sorgfältig die Architektur
geklärt (siehe unten), dann die eigentliche 8-Dateien/68-Stellen-Änderung mechanisch
ausgeführt und selbst gegengeprüft (Diff-Stichproben + eigenständiger `flutter analyze`/
`flutter test`-Lauf, nicht nur den Ausführungs-Bericht übernommen).**

1. **Ursache:** `HomeWidgetDescriptor.title` in `home_widget_registry.dart` war ein simples
   `final String`, gesetzt in 8 modul-eigenen `final Map<HomeWidgetType, HomeWidgetDescriptor>`
   (training/planning/health/general/misc/nutrition/budget/diary). Jeder Eintrag hatte den
   deutschen Titel-String **zweimal** hartcodiert dupliziert: einmal im äußeren `title`-Feld
   (nur von der Widget-Auswahl-Sheet für Suche/Anzeige gelesen) und nochmal inline im
   `builder:` (der die tatsächlich auf dem Homescreen sichtbare Kachel baut) — Letzteres war
   der eigentliche, dauerhaft sichtbare Übersetzungsfehler.
2. **Fix:** `title` von `String` auf `String Function(AppLocalizations l10n)` umgestellt —
   bewusst KEIN Umbau der Maps selbst nötig (sie sind `final`, nicht `const`, Aufrufe nutzen
   ohnehin kein `const`-Keyword, ein nicht-capturing Closure-Literal ist dort unproblematisch).
   Alle 68 Descriptor-Einträge über 8 Dateien konvertiert: äußeres Feld auf
   `title: (l10n) => l10n.homeWidgetXTitle` umgestellt, inline-`builder`-Titel auf
   `AppLocalizations.of(context)!.homeWidgetXTitle` (gleicher Key, `context` war dort schon
   vorhanden). Die 2 Lesestellen des äußeren Feldes (`home_widget_catalog_sheet.dart`:
   Suchfilter + `_WidgetChip`-Anzeige) auf `.title(l10n)` umgestellt.
3. **61 neue ARB-Keys** (DE+EN, Muster `homeWidget<TypeName>Title`). `general_widgets.dart`
   hatte teils schon lokalisierte `builder`-Titel aus einer früheren Phase — dort bestehende
   Keys fürs äußere Feld wiederverwendet statt Duplikate anzulegen.
4. **8 Testdateien mussten mitgezogen werden** (beim Umbau selbst gefunden, nicht vorher
   geplant): `home_registry_completeness_test.dart` griff direkt auf `.title.trim()` zu — jetzt
   `AppLocalizationsDe()` direkt instanziiert (kein `BuildContext` in einem reinen `test()`
   verfügbar) und `.title(l10n).trim()`. 7 von 8 `group_*_test.dart`-Dateien bauten ein rohes
   `MaterialApp` ohne `localizationsDelegates`/`supportedLocales` — genau das gleiche
   Fehlerbild wie bei den Phase-6/Phase-9-Übersetzungs-Nacharbeiten (`AppLocalizations.of(context)!`
   wirft ohne Delegates einen Null-Check-Fehler) — Delegates ergänzt nach dem Muster, das
   `group_general_test.dart` schon hatte.
5. **Eigenständig gegengeprüft, nicht nur den Bericht übernommen:** Diff von
   `home_widget_registry.dart` und `training_widgets.dart` stichprobenartig gelesen, dann
   selbst `flutter analyze` und `flutter test` neu laufen lassen statt dem Ausführungs-Bericht
   allein zu vertrauen.

`flutter analyze` → **0 Issues**. `flutter test` → **586/586 grün**.

---

## ⏩ VORHERIGER STAND (2026-08-14 — v1.1.7, Barrierefreiheit: fragmentierte TalkBack-Ansagen)

**Fortsetzung der "alles andere"-Liste nach dem v1.1.5-Hotfix, jetzt mit fester Vorgabe: jede
Aufgabe einzeln vorher kurz planen, dann Release. v1.1.6 (dazwischen) war ein reiner
Test-Coverage-Release ohne Verhaltensänderung, siehe Git-Tag, hier nicht extra dokumentiert.**

1. **Vor dem eigentlichen Fix: die "48 Fundstellen" aus einer früheren Audit-Runde per
   claude-mem recherchiert statt blind draufloszuarbeiten.** Beobachtung #10315/#10340 vom
   10.08. zeigt: diese 48 `GestureDetector`/`InkWell`-um-`Container`-Treffer wurden damals
   bereits identifiziert und **bewusst zurückgestellt** — es sind keine echten "silent
   buttons" (die 4 Bild-Tap-Targets + Icon-Only-Buttons wurden schon in v1.0.5–v1.0.7
   gefixt), sondern Container mit sichtbarem Text, den TalkBack als mehrere separate Knoten
   statt einer kombinierten "Button, Name"-Ansage vorliest. Echt, aber niedrigprior — und
   naives Draufwrappen hätte das Risiko von Doppel-Ansagen (genau das Problem, das das
   `ExcludeSemantics`-Muster aus v1.0.7 vermeidet).
2. **39 von 48 Fundstellen über 14 Dateien gefixt**, jede mit individuell hergeleitetem Label
   aus dem tatsächlich sichtbaren Inhalt (Kategorie-/Konto-/Eintragsname etc.), nach dem
   etablierten Muster `Semantics(button: true, label: ...) + ExcludeSemantics(child: ...)`:
   `appointment_chip.dart`, `gradient_button.dart`, `medication_dot_row.dart`,
   `traum_card.dart` (nur `button`-Trait, kein Label-Override — `child` ist pro Aufrufstelle
   unterschiedlich, ein Override hätte reichhaltigere Semantik verschluckt),
   `traum_scaffold.dart` (3 von 5 Kandidaten — der bei Zeile ~805 ist ein bestätigter
   False Positive aus der Vorrunde, bewusst unangetastet), `abstinence_screen.dart` (4),
   `budget_categories_screen.dart` (5), `quick_entry_bottom_sheet.dart` (9),
   `transaction_list_screen.dart` (2), `widgets/accounts_card.dart` (4, dabei nebenbei einen
   hartcodierten String `'+ Konto hinzufügen'` auf den bestehenden `addAccount`-l10n-Key
   umgestellt), `diary_edit_sheet.dart` (2), `diary_screen.dart` (2, dekoratives Avatar-Bild
   bewusst per `ExcludeSemantics` von der Ansage ausgenommen, um keine Dopplung mit dem
   danebenliegenden Namens-Button zu erzeugen), `widgets/diary_entry_card.dart` (1),
   `health_screen.dart` (3). `diary_calendar_grid.dart` komplett übersprungen — alle 3
   dortigen Kandidaten waren schon in v1.0.6/v1.0.7 gefixt.
3. **Neue ARB-Keys (DE+EN):** `a11yMedicationDoseTaken`/`a11yMedicationDoseNotTaken`
   (parametrisiert mit Name+Uhrzeit), `a11yHabitDoneToday`/`a11yHabitNotDoneToday`
   (parametrisiert mit Name), `a11yAddCategory`, `a11yColorOption` (parametrisiert mit Index),
   `a11yVideoEntry`.
4. **Noch offen (bewusst zeitlich begrenzt, nicht alle 48 an einem Stück):**
   `graffiti_map/{create_collection_screen,dynamic_marker_sheet,graffiti_map_screen,
   marker_detail_screen}.dart`, `home/{home_edit_overlay,home_widget_frame}.dart`,
   `lock/pin_lock_screen.dart`, `notes/{notes_search_screen,widgets/notes_common}.dart`,
   `nutrition/{amount_entry_sheet,shopping/*}.dart`,
   `onboarding/{onboarding_screen,widgets/training_setup_page}.dart`,
   `period_tracking/daily_log_sheet.dart`, `settings_screen.dart`,
   `substances/database_tab.dart`,
   `training/{exercise_picker_screen,muscle_heatmap_screen,routines_screen}.dart`. Gleiches
   Muster anwendbar, wenn wieder Zeit dafür ist — kein Blocker, reine Politur.

`flutter analyze` → **0 Issues**. `flutter test` → **586/586 grün**. Rein additive
Semantics-Änderungen, kein Layout-/Verhaltens-Risiko.

---

## ⏩ VORHERIGER STAND (2026-08-14 — v1.1.5, Hotfix: stiller Absturz des In-App-Updaters)

**Nutzer-Meldung nach der Live-Diagnose-Session:** "beim Installieren wird immer noch 1.1.3
angezeigt und man wird immer zum Updaten gezwungen." Root-Cause-Suche, keine Vermutung.

1. **Geprüft und ausgeschlossen:** GitHub-API `/releases/latest` liefert live und korrekt
   `tag_name: v1.1.4` mit passendem `traum-v1.1.4-arm64.apk`-Asset (per `curl` verifiziert,
   nur genau ein Asset angehängt — kein Altlast-Duplikat). Kein hartcodiertes `"1.1.3"` irgendwo
   in `lib/` (per Grep über den gesamten Baum bestätigt). `_isNewer()`/`_parse()` in
   `update_service.dart` fehlerfrei. `_VersionTile` in `settings_screen.dart` liest
   `PackageInfo.fromPlatform()` frisch bei jedem Build, kein Caching. `versionName` kommt
   sauber aus `pubspec.yaml` über `flutter.versionName` in `build.gradle.kts`, keine
   Überschreibung.
2. **🔴 Root Cause gefunden:** `_UpdateDialogState._download()` (`lib/core/utils/update_service.dart`)
   rief `await OpenFile.open(file.path)` auf, um den heruntergeladenen APK-Installer zu starten
   — **ohne das Ergebnis zu prüfen**. `open_file` liefert ein `OpenResult` mit `ResultType`
   (`done`, `permissionDenied`, `noAppToOpen`, `fileNotFound`, `error`) zurück; `done` bedeutet
   nur „Installer-Intent erfolgreich gestartet", nicht „Installation erfolgreich" (das
   entscheidet der Nutzer im System-Dialog danach, außerhalb unserer Kontrolle — inhärente
   Plattform-Grenze, nicht behebbar). Schlug aber schon der *Start* fehl — z. B.
   `permissionDenied` durch Timing bei der „Unbekannte Apps"-Berechtigung, `noAppToOpen` auf
   manchen OEM-ROMs — blieb das bisher komplett unbemerkt: die Download-Fläche setzte sich
   lautlos zurück, der (bewusst nicht abbrechbare, `barrierDismissible: false` +
   `PopScope(canPop: false)`) Update-Zwangsdialog blieb stehen, „Jetzt aktualisieren" war
   erneut auswählbar — ohne jede Erklärung, warum. Exakt das gemeldete Symptom: endlos im
   Update-Zwang gefangen, ohne sichtbaren Fortschritt.
   Fix: `OpenResult` wird jetzt geprüft; bei `type != ResultType.done` erscheint eine konkrete,
   lokalisierte Fehlermeldung mit der Plattform-Begründung (neuer ARB-Key
   `updateInstallLaunchFailed`, DE+EN) statt des stillen Resets.
3. **Bewusst NICHT verändert:** die selbst gebauten Release-APKs sind mangels
   `android/key.properties` weiterhin debug-signiert (Fallback in `build.gradle.kts`,
   `traum-release-key.jks` liegt bereit, ist aber nicht verdrahtet). Das ist seit Projektbeginn
   so und für privaten Sideload-Gebrauch unkritisch (siehe Umsetzungsplan) — geprüft, ob ein
   Signatur-Wechsel zwischen Builds die Ursache sein könnte: unwahrscheinlich, da derselbe
   Debug-Keystore (`~/.android/debug.keystore`) über die gesamte Projektlaufzeit auf derselben
   Maschine stabil bleibt.
4. **Für dich zu prüfen, falls der Fehler nochmal auftritt:** jetzt erscheint im Update-Dialog
   eine konkrete Fehlermeldung statt des stillen Hängers — bitte den genauen Text melden, dann
   lässt sich die Plattform-Ursache (Berechtigung, OEM, o. Ä.) gezielt weiterverfolgen. Auf
   deinem Gerät ist aktuell ohnehin schon v1.1.4 installiert (per `adb` während der
   Live-Session), der Zwangsdialog sollte also gar nicht mehr erscheinen, solange kein neueres
   Release veröffentlicht ist.

`flutter analyze` → **0 Issues**. `flutter test` → **584/584 grün**.

---

## ⏩ VORHERIGER STAND (2026-08-13 — v1.1.4, Live-Gerätediagnose: die Benachrichtigungslücke gefunden)

**Erste Live-USB-Diagnose-Session, wie seit Phase 1 mehrfach angekündigt. Handy per `adb`
angeschlossen, `logcat` live mitgeschnitten während echter Nutzung — kein Rätselraten mehr.**

1. **🔴 Root Cause der monatelang gemeldeten Benachrichtigungslücke gefunden und bestätigt
   behoben.** Direkt beim App-Start (`rescheduleAllNotifications()`, läuft bei jedem Kaltstart
   seit v1.0.1) schlug JEDER Aufruf mit einer `PlatformException` fehl:
   ```
   TypeToken must be created with a type argument: new TypeToken<...>() {};
   When using code shrinkers (ProGuard, R8, ...) make sure that generic
   signatures are preserved.
   ```
   `flutter_local_notifications` persistiert geplante Erinnerungen intern über Gson
   (`new TypeToken<ArrayList<NotificationDetails>>(){}`), um sie nach einem Geräteneustart
   wiederherzustellen — R8 (aktiv seit v0.8.5, Non-Negotiable #18) entfernt ohne eigene
   ProGuard-Keep-Regel die für Gsons Reflection nötige generische Signatur. Das Paket bringt
   selbst **keine** `consumer-rules.pro` mit (verifiziert: keine `.pro`-Datei im Paket) — jede
   App, die es mit aktivierter Minifizierung nutzt, muss die Regeln selbst ergänzen. **Erklärt
   exakt, warum das nie in einer früheren Runde auffiel:** der Fehler tritt AUSSCHLIESSLICH in
   einem minifizierten Release-Build auf, nie im Debug-Modus (kein Shrinking) und nie im
   Emulator-Test aus einer früheren Runde (lief damals auf einem `--debug`-Build). Da der
   Reschedule schon ganz am Anfang scheiterte, wurde **überhaupt keine** Erinnerung geplant —
   unabhängig von Berechtigungen, Medikamenten-Konfiguration oder sonst irgendwas, das in
   v1.0.1–v1.0.3 bereits (korrekterweise) untersucht und für in Ordnung befunden wurde.
   Fix: `android/app/proguard-rules.pro` um die Standard-Gson-unter-ProGuard-Regeln ergänzt
   (`-keepattributes Signature` — exakt das, was die Fehlermeldung selbst als fehlend nennt —
   plus `-keep class com.dexterous.**`/Gson-TypeAdapter-Keeps). **Live auf dem Gerät verifiziert,
   nicht nur angenommen:** vor dem Fix kein einziger Alarm für die App in
   `adb shell dumpsys alarm`; nach Neuinstallation des reparierten Release-Builds (gleiche
   `versionCode`, `-r`-Reinstall, keine Datenverluste) erscheinen vier echte
   `RTC_WAKEUP`-Alarme (`tag=*walarm*:de.traum.traum/…ScheduledNotificationReceiver`,
   `exactAllowReason=policy_permission`) für die konfigurierten Erinnerungszeiten. Kein anderes
   Paket im Projekt verwendet denselben Gson-`TypeToken`-Musters (verifiziert per Grep über den
   gesamten Pub-Cache) — der Fix ist vollständig.
2. **Backup-Performance (Phase 1, letzte offene Frage) live bestätigt: kein Problem mehr.**
   Echter Export auf dem Gerät — 84.679 Zeilen über 59 Tabellen, 6–8 Mediendateien, 45,6 MB
   JSON — lief in **~1,6–1,9 Sekunden** komplett durch (mehrfach reproduziert). Die
   STORE-statt-DEFLATE- und Background-Isolate-Fixes aus v0.9.5–v0.9.9 haben das Problem
   tatsächlich vollständig gelöst; die "Wird gepackt…"-Hänger von damals treten nicht mehr auf.
3. **Ein zweiter, bisher ungeklärter Fehler beim Live-Test beobachtet, NICHT Teil dieses
   Fixes.** Während intensiven Testens (App auf/zu, Tab-Wechsel, extreme Werte in den
   Einstellungen) erschien wiederholt:
   ```
   PlatformException(500, Attempt to invoke virtual method
   'int java.lang.Integer.intValue()' on a null object reference, null, null)
   ```
   Kein Stacktrace, kein Tag — schwer eindeutig zuzuordnen. Naheliegendster Verdacht (nicht
   bestätigt): `castObjectToByteArray()` in `flutter_local_notifications`, dieselbe
   Gson-Persistierungsschicht wie oben, tritt aber nur auf, wenn eine gespeicherte Erinnerung
   Byte-Array-Icon-Daten enthält — die App setzt aktuell nirgends solche Daten (verifiziert per
   Grep), am wahrscheinlichsten also **Alt-/Restdaten aus den monatelangen fehlgeschlagenen
   Reschedule-Läufen**, die jetzt beim ersten erfolgreichen Lesen zum Vorschein kommen. Kein
   sichtbarer Absturz, App lief während des gesamten Tests weiter. `run-as` funktioniert auf
   dem signierten Release-Build nicht (nicht debuggable) — konnte die persistierten
   Preferences des Plugins deshalb nicht direkt inspizieren/bereinigen. **Für dich zu
   beobachten:** falls eine bestimmte Erinnerung nicht zuverlässig kommt, bitte melden — dann
   gezielter nachgehen.

`flutter analyze` → **0 Issues**. Keine Dart-Testsuite-Änderung nötig (reine
`proguard-rules.pro`-Ergänzung, kein Dart-Code geändert) — `flutter test` unverändert grün.

**Damit sind beide seit Phase 1 offen gehaltenen Punkte geklärt:** die Backup-Performance ist
bestätigt gelöst, und die Benachrichtigungslücke hat jetzt eine konkrete, live verifizierte
Ursache und einen bestätigten Fix — nicht mehr nur eine Vermutung wie in den vorherigen
Fix-Versuchen (v1.0.1, v1.0.2).

---

## ⏩ VORHERIGER STAND (2026-08-12 — v1.1.3, Phase 9: Housekeeping)

**Neunte und letzte Phase des Nacharbeitungs-Plans. Grab-Bag aus kleineren Aufräumarbeiten, wie im
Plan selbst als "kein/kaum User-Test nötig" eingestuft. Keine schemaVersion-Änderung.**

1. **Lokales Crash-Logging eingebaut** (`lib/core/services/crash_log_service.dart`, neu).
   `runZonedGuarded` um den kompletten `main()`-Rumpf (inkl. `runApp()`) + `FlutterError.onError`/
   `PlatformDispatcher.onError`-Handler schreiben unbehandelte Fehler in eine lokale Textdatei
   (`<support>/crash_log.txt`, 1-MB-Rotation). Kein Cloud-Dienst — die Datei wird stattdessen in
   `BackupService.buildBackupZip()` als zusätzlicher `crash_log.txt`-Eintrag mitexportiert (nur
   falls vorhanden), damit ein gemeldeter Absturz aus dem exportierten Backup rekonstruierbar ist,
   ohne dass zuerst `adb logcat` mitgeschnitten werden muss.
2. **`apk lostplace/`-Ordner gelöscht** (28 MB, unversionierter Recherche-Rest aus der
   Lost-Places-Datenquellen-Suche in einer früheren Phase, Inhalt längst ausgewertet).
3. **Icon-Workspace: `batch_09_PENDING` → `batch_09_DONE` umbenannt.** War nur falsch
   beschriftet — alle 64 SVGs lagen bereits vollständig vor (verifiziert: jede der 64
   nummerierten Übungs-Unterordner hatte schon ihre fertige `.svg`; der 65. Unterordner "Bild/"
   ist kein Übungs-Eintrag, nur Restmaterial). `remaining_pool.txt` um die 64 jetzt fertigen
   Namen bereinigt, `README.md` um einen kurzen, ehrlichen Status-Hinweis ergänzt (der
   ursprüngliche Statusabschnitt war aus einer viel früheren Planungsphase und blieb als
   historischer Kontext stehen, statt ihn komplett umzuschreiben).
4. **`TraumTheme.light` als toten Code entfernt** (aus dem Plan bereits vorab entschieden: kein
   Umschalter). War technisch referenziert (`theme: TraumTheme.light` in `app.dart`), aber wegen
   `themeMode: ThemeMode.dark` nie tatsächlich gerendert — Zeile ersatzlos entfernt, `darkTheme`
   bleibt unverändert alleinige Quelle.
5. **Leere `catch (_) {}`-Blöcke: 87 Vorkommen über 18 Dateien geprüft, 3 echte
   Nutzeraktions-Bugs gefunden und behoben (Priorität laut Plan: Speichern/Löschen/Import
   zuerst).** 60 der 87 liegen allein in `widget_data_collector.dart` — dort bewusst und bereits
   in einer früheren Phase dokumentiert so gewollt (jeder Homescreen-Widget-Datenpunkt hat seinen
   eigenen Fehler-Fallback, damit ein einzelner fehlschlagender Read nicht den ganzen
   Hintergrund-Refresh crasht). Der große Rest der übrigen 27 sind legitime Best-Effort-Fallbacks
   (Parsing mit sinnvollem Default direkt danach, Aufräumen einer Mediendatei NACH einem bereits
   erfolgreichen DB-Löschen, optionale Kartenauflösung) — bewusst unverändert gelassen. Echte
   Bugs behoben:
   - `general_widgets.dart`s `_addWater()` (Home-Widget-Schnellaktion "+250 ml") schluckte einen
     DB-Fehler komplett lautlos — Nutzer tippt, nichts passiert, keine Erklärung. Jetzt SnackBar.
   - `overlay_camera_screen.dart`s `_capturePhoto()`/`_toggleVideoRecording()` (Start) — Foto/
     Video-Aufnahme konnte lautlos fehlschlagen. Jetzt je eine SnackBar-Fehlermeldung.
   Neue Keys: `waterLogFailed`, `cameraCaptureFailed`, `cameraRecordingFailed`.
6. **Tests für lock/settings/legal/profile/notifications/planning nachgezogen** — 6 neue
   Testdateien für zuvor komplett bzw. faktisch ungetestete Screens:
   - `lock/`: `pin_lock_screen_test.dart` — falscher PIN zeigt Fehlermeldung und leert die Eingabe.
   - `legal/`: `legal_document_screen_test.dart` — echtes Markdown-Asset rendert, fehlendes Asset
     zeigt Fehlertext statt zu crashen.
   - `profile/`: `profile_screen_test.dart` — rendert ohne Gewichtseintrag, leitet die korrekte
     BMI-Kategorie aus Körpergröße + letztem Gewichtseintrag her.
   - `notifications/`: `notification_center_screen_test.dart` — Leerzustand, sowie befüllter
     Zustand mit Medikament/Termin/Aufgabe. **Beim Schreiben gefunden:** dieser komplette Screen
     hatte Phase 6 komplett verpasst — 8 hartcodierte deutsche Strings (Titel, Leerzustand, alle
     drei Abschnittstitel/-untertitel), jetzt lokalisiert. Neue Keys:
     `notificationCenterEmpty/MedsToday/MedsStatus/NextAppointment/OpenTodos/TodosStatus`.
   - `settings/`: `feedback_type_test.dart` (`feedback/`-Untermodul — die restlichen 18
     Settings-Sektionen sind private Klassen in einer einzigen 2800-Zeilen-Datei, ein
     Voll-Screen-Rendertest lief in einen echten 10-Minuten-Timeout — vermutlich ein hängender
     Timer/Kanal in `_CalendarSyncSection` oder `_SecuritySection` — bewusst NICHT
     weiterverfolgt, siehe unten).
   - `planning/`: `calendar_picker_dialog_test.dart` — leere Kalenderliste zeigt Hinweis statt
     leerer Liste, "Fertig" bleibt deaktiviert bis eine Auswahl getroffen wurde, Abbrechen liefert
     `null`. (`planning_screen.dart` selbst löst beim Mounten einen echten Kalender-Sync aus —
     dasselbe Hänge-Risiko wie bei `_CalendarSyncSection`, deshalb hier bewusst nicht direkt
     angefasst.)
   **Beim Testen zweimal denselben echten UI-Bug gefunden:** `TraumCard` (geteilte Komponente)
   UND `settings_screen.dart`s eigene `_Section`-Komponente wickelten ihren Inhalt in einen
   rohen `Container(decoration: …)` statt in ein `Material`-Widget — jedes `ListTile` darin
   (24 allein in Settings) hätte dadurch einen unsichtbaren Tap-Ripple gehabt. Beide mit
   `Material(type: MaterialType.transparency, child: …)` behoben — rein additiv, ändert nichts
   an Farben/Layout, betrifft aber potenziell jeden Screen, der `TraumCard` mit einem `ListTile`
   nutzt.
7. **Bewusst NICHT umgesetzt — `dart format` über die Codebasis.** Im Plan als eigener, inhalts-
   loser Commit vorgesehen. Aus demselben Grund wie schon einmal in einer früheren Phase
   dokumentiert (siehe v0.8.8-Eintrag weiter unten) zurückgestellt: das Projekt ist nicht
   durchgehend formatiert, ein voller `dart format .`-Lauf würde eine sehr große, schwer
   review-bare Diff über praktisch jede Datei erzeugen. Bleibt als eigener, bewusst separat zu
   planender Schritt offen.

`flutter analyze` → **0 Issues**. `flutter test` → **584/584 grün** (562 vorher + 22 neu).

**Nicht weiterverfolgt — echter, aber isolierter Befund, kein Teil dieser Phase:** ein
Voll-Screen-Rendertest für `SettingsScreen` hing 10 Minuten lang fest (vermutlich ein
`Timer.periodic` oder ein unbeantworteter Plattform-Kanal in `_CalendarSyncSection` oder
`_SecuritySection`, die beim Mounten echte Kalender-/Biometrie-Abfragen auslösen). Kein
bestätigter Produktivbug — die App selbst hängt beim normalen Öffnen der Einstellungen nicht,
nur der isolierte Test-Kontext ohne echte Plattform-Antworten. Wert, bei Gelegenheit mit mehr
Zeit zu untersuchen, aber nicht blockierend für diesen Release.

**Damit ist der komplette 9-Phasen-Plan aus dem ursprünglichen Tiefenaudit durchlaufen.**
Weiterhin offen, wie durchgehend seit Phase 1 vermerkt: die Backup-Performance-Frage und die
Benachrichtigungslücke, beide auf eine gemeinsame Live-USB-Gerätediagnose verschoben, plus die
separat gehaltene 105-Pakete-Aktualisierung (eigener Nachmittag) und jetzt `dart format` (siehe
oben).

---

## ⏩ VORHERIGER STAND (2026-08-12 — v1.1.2, Phase 8: Header-Vereinheitlichung)

**Achte Phase des Nacharbeitungs-Plans. Vorab ein Vorschau-Testbuild (v1.1.1-test1, GitHub
Pre-Release) an einem einzelnen Nutrition-Screen gezeigt und vom Nutzer bestätigt ("sieht gut
aus"), bevor auf weitere Screens ausgerollt wurde — Sequenz explizit vom Nutzer so gewünscht, da
der Plan selbst "höchste Sorgfalt" für diese Phase vorschreibt. Keine schemaVersion-Änderung.**

1. **`TraumSubHeader`** (`lib/core/components/traum_sub_header.dart`, neu) aus Budgets eigenem
   `BudgetSubHeader` extrahiert (abgerundeter Zurück-Chevron + fetter Titel). `BudgetSubHeader`
   ist jetzt ein dünner Wrapper mit fixiertem `scale: kBudgetScale` — **pixelgenau unverändert**
   für alle 5 bestehenden Budget-Sub-Screens (Schulden, Wiederkehrend, Sparziele, Kategorien,
   Transaktionsliste). **Subtiler Fallstrick beim Extrahieren gefunden:** Budgets Original-Header
   skalierte Struktur-Maße (Padding, Button-Größe, Radius) explizit über `bs()`, ließ die
   Schriftgröße aber bewusst unskaliert (`fontSize: 15`, roh) — Budget-Screens bekommen ihre
   Text-Skalierung stattdessen über den ambienten `BudgetTextScale`-MediaQuery-Wrapper. Hätte
   `TraumSubHeader` `scale` auch auf die Schriftgröße angewendet, wäre sie dort doppelt skaliert
   worden (1.12× im Layout-Code, nochmal 1.12× durch den MediaQuery-Wrapper). Fix: `scale`
   multipliziert nur Struktur-Maße, Schriftgröße bleibt fix bei 15 — exakt wie im Original.
   Regressionstest (`test/core/components/traum_sub_header_test.dart`) sichert das ab.
2. **Auf Nutrition ausgerollt:** `add_custom_product_screen.dart` ("Neues Produkt anlegen") und
   `shopping_mode_screen.dart` ("Im Laden") nutzen jetzt `TraumSubHeader` statt einer eigenen
   `AppBar`. **Bewusst NICHT angefasst:** `barcode_scanner_screen.dart` — zeigt seine
   (transparente) AppBar über der Live-Kamera-Vorschau; ein solider `TraumSubHeader` würde die
   Vorschau sichtbar verdecken, exakt dieselbe Abwägung wie bei Diary (siehe unten).
3. **Diary bewusst ausgelassen — echter struktureller Konflikt, keine offene Frage mehr.** Der
   Tagebuch-Eintrag-Screen (`diary_entry_screen.dart`) zeigt sein Foto/Video randlos
   (`extendBodyBehindAppBar: true`) hinter einem schwebenden, transparenten, TITELLOSEN AppBar
   (nur Zurück-Pfeil + Popup-Menü). `TraumSubHeader` verlangt einen Pflicht-Titel und ist ein
   fester Balken im Layout-Fluss (kein Overlay) — ein Austausch würde entweder einen bisher gar
   nicht gezeigten Titel neu einführen (Inhaltsänderung, nicht nur Stil) oder die Foto-Ansicht
   sichtbar verkleinern. Auf Nutzerentscheidung hin unverändert gelassen. `diary_search_screen.dart`
   (aus Phase 7) passt ebenfalls nicht — dort ist der "Titel" ein Live-Suchfeld, kein fester Text.
4. **Beim Umsetzen gefunden:** zwei weitere von Phase 6 übersehene hartcodierte deutsche Strings
   in `shopping_mode_screen.dart` ("✓  Einkauf abschließen", "Budget (geschätzt): …") — jetzt
   `completeShoppingLabel`/`estimatedBudgetLabel(amount)`.

`flutter analyze` → **0 Issues**. `flutter test` → **565/565 grün** (562 vorher + 3 neu:
`test/core/components/traum_sub_header_test.dart`).

**Nächste Phase laut Plan:** Phase 9 — Housekeeping (`catch (_) {}`-Blöcke, `dart format`,
Icon-Workspace-Umbenennung, `TraumTheme.light` als toten Code entfernen, lokales
Crash-Logging, Tests für lock/settings/legal/profile/notifications/planning, `apk lostplace/`
löschen).

---

## ⏩ VORHERIGER STAND (2026-08-11 — v1.1.0, Nutzer-gemeldete Live-Bugs nach v1.0.9)

**Direktes Nutzer-Feedback mit vier Screenshots, kurz nach dem v1.0.9-Release: Tagebuch-Suche
nach `%%_%` lieferte alle Einträge statt gar keinen Treffer; ein absurd hoher Betrag im Budget
("−1e+44 €") ließ sich weder korrekt anzeigen noch löschen, mit sichtbarem `RangeError` in der
UI; das Lösch-Bestätigungsfenster für eine Transaktion blieb nach dem Bestätigen auf dem Bildschirm
stehen. Alle drei Root-Causes gefunden und behoben, keine schemaVersion-Änderung.**

1. **🔴 SQL-LIKE-Wildcard-Injection in JEDER Textsuche der App — nicht nur der neuen
   Tagebuch-Suche.** `t.note.like('%$query%')` (und identisch in vier weiteren DAOs) baute das
   `LIKE`-Pattern per roher String-Interpolation aus der Nutzereingabe — `%` und `_` sind in SQL
   `LIKE` Wildcard-Zeichen, kein Escaping bedeutete: eine Suche nach z. B. `%` matched jede Zeile
   (`LIKE '%%%'`), unabhängig vom tatsächlichen Inhalt. Neue `lib/core/utils/sql_like.dart`
   (`escapeLikePattern()` + `likeEscapeChar`, nutzt Drifts eingebaute `escapeChar:`-Option auf
   `.like()`) an **allen** betroffenen Stellen verdrahtet: `DiaryDao.searchEntries` (neu in
   Phase 7, der gemeldete Fall), `FoodProductsDao.search`, `MapMarkersDao.search` +
   `byHashtagSubstring`, `NotesDao.searchTitles` — alle vier bereits **vor** dieser Phase
   bestehend und genauso betroffen, nur bisher nie mit `%`/`_` als Sucheingabe getestet worden.
2. **🔴 Echter Absturz-Bug in `fmtAmount()` gefunden, nicht nur eine fehlende Obergrenze.**
   `double.toStringAsFixed(2)` wechselt ab einer bestimmten Größenordnung (~10^21) laut
   Dart-Spezifikation stillschweigend auf wissenschaftliche Notation ("1e+44", **kein**
   Dezimalpunkt mehr) statt eine feste Nachkommastellen-Darstellung zu liefern.
   `fmtAmount()` ging aber immer von genau einem Dezimalpunkt aus (`str.split(',')` gefolgt von
   ungeprüftem Zugriff auf `parts[1]`) — bei einer einstelligen Ergebnisliste ohne Punkt/Komma
   crashte das mit exakt der gemeldeten `RangeError (length): Invalid value: Only valid value is
   0: 1`. Das erklärt auch das zweite Symptom ("kann Transaktion nicht mehr löschen") — die
   Transaktionsliste crashte beim Rendern des kaputten Betrags, bevor der Löschen-Button überhaupt
   erreichbar war. Fix zweigleisig:
   - `fmtAmount()` selbst robust gemacht (prüft auf fehlenden Dezimalpunkt, bevor `parts[1]`
     zugegriffen wird) — Absicherung, unabhängig davon, wie ein extremer Wert zustande kam.
   - **Neue Obergrenze `kMaxAmount = 50.000.000` (`core/utils/validators.dart`)**, an allen
     direkten Betrags-Eingabepunkten im Budget-Modul durchgesetzt (Nutzer-Vorschlag): Schnelleingabe/
     Überweisung (`quick_entry_bottom_sheet.dart`, der tatsächliche Reproduktionspfad — das
     Nummernfeld selbst begrenzt nur Nachkommastellen, keine Ganzzahlstellen), Konto-Kontostand
     (`accounts_card.dart`), Sparziel-Zielbetrag/-Startbetrag/-Einzahlung (`savings_screen.dart`),
     Schulden-Ratenzahlung/-Posten-Preis (`debts_screen.dart`), wiederkehrender Betrag
     (`recurring_screen.dart`), Kategorie-Limit (`budget_categories_screen.dart`). Neuer
     parametrisierter Key `amountExceedsMax(max)`.
3. **🔴 Lösch-Dialog blieb nach Bestätigung sichtbar stehen — echter Navigator-Bug, kein reiner
   Anzeigefehler.** `transaction_detail_screen.dart`s `_delete()` und `diary_entry_screen.dart`s
   Lösch-Bestätigung bauten ihren `AlertDialog` mit `builder: (_) => ...` — der dialogeigene
   `BuildContext` wurde verworfen, die Knöpfe riefen stattdessen `Navigator.pop(context, …)` mit
   dem **äußeren Screen-Context** auf. Da `showDialog()` standardmäßig auf dem ROOT-Navigator
   pusht, der äußere Screen aber innerhalb der verschachtelten `ShellRoute`-Navigator-Ebene von
   go_router lebt, poppte `Navigator.pop(context)` die FALSCHE (Shell-)Navigator-Ebene — der
   Dialog auf dem Root-Navigator schloss sich nie. Fix: dialogeigenen `builder`-Context
   (`ctx`/`dialogCtx`) für die Pop-Aufrufe verwenden statt des äußeren. Per gezieltem Audit über
   alle 21 `showDialog`-Aufrufstellen der App verifiziert: dies waren die einzigen zwei
   Vorkommen dieses Musters — der etablierte Rest der App (u. a. der geteilte
   `confirmDeleteDialog()`-Helfer) macht es bereits richtig.
4. **Nebenbei gefunden:** ein weiterer von Phase 6 übersehener hartcodierter „Speichern"-String
   im Schulden-Posten-Bearbeiten-Sheet (`debts_screen.dart`) — jetzt `l10n.save`.

`flutter analyze` → **0 Issues**. `flutter test` → **562/562 grün** (551 vorher + 11 neu:
`test/core/utils/sql_like_test.dart`, `test/features/budget/budget_helpers_test.dart`,
`diary_dao_test.dart` um einen Wildcard-Escaping-Regressionstest erweitert).

**Für dich zu prüfen:**
- Im Tagebuch nach `%` oder `_` suchen — sollte jetzt nur Einträge finden, die dieses Zeichen
  tatsächlich enthalten, nicht mehr alle
- Versuchen, einen Betrag über 50 Millionen einzugeben (Schnelleingabe, Konto, Sparziel, Schuld,
  wiederkehrend, Kategorie-Limit) — sollte jetzt mit einer Fehlermeldung abgelehnt werden statt
  die Anzeige zu zerstören
- Eine Transaktion löschen — der Bestätigungsdialog sollte sich nach „Löschen" jetzt zuverlässig
  schließen; gleiches beim Löschen eines Tagebuch-Eintrags

**Nächste Phase laut Plan:** Phase 8 — Header-Vereinheitlichung (`TraumSubHeader` aus
`BudgetSubHeader` extrahieren, Nutrition/Diary darauf umstellen — pixelgenau, höchste Sorgfalt).

---

## ⏩ VORHERIGER STAND (2026-08-11 — v1.0.9, Phase 7: Code-Qualität & neue Suchfelder)

**Siebte Phase des Nacharbeitungs-Plans. Vier Teile: zentrale Betrags-Validierung, vereinheitlichte
Übungssuche, zwei neue Suchfunktionen, kleinere Riverpod-Aufräumarbeiten. Keine schemaVersion-Änderung.**

1. **`lib/core/utils/validators.dart`** (neu) — `parseLocaleAmount(String)` ersetzt das
   25-fach duplizierte `double.tryParse(text.replaceAll(',', '.'))`-Muster über 17 Dateien
   (Budget, Health, Nutrition, Abstinence, Training, Settings, Period Tracking, Shopping). Bewusst
   NICHT angefasst: `receipt_scanner.dart`s OCR-Betrag-Extraktion — arbeitet auf rohem
   Kamera-Scan-Text, nicht auf einem Nutzer-Eingabefeld, andere Fehlerklasse.
2. **Übungssuche vereinheitlicht.** Drei fast identische Kopien (`exercise_library_screen.dart`,
   `exercise_picker_screen.dart`, `wizard_exercises_step.dart`s `_ExercisePickerSheet`) nutzten
   je eigene `.where((e) => e.name...contains(...))`-Filterlogik — nur die Bibliotheks-Ansicht
   hatte ein 250ms-Debounce, Picker und Wizard-Sheet filterten bei 815+ Übungen auf jeden
   Tastenanschlag. Neue `lib/features/training/exercise_search.dart` (`filterExercisesByQuery`)
   + generischer `lib/core/utils/search_debouncer.dart` (`SearchDebouncer`, jetzt auch von den
   beiden neuen Suchfeldern unten verwendet) an allen drei Stellen verdrahtet.
3. **Riverpod-Aufräumarbeiten** — gezielter Audit (kein pauschaler Scan) fand über 235
   `ref.read(...)`-Fundstellen nur 2 echte "liest im `build()` einen Wert, der sich ändern kann,
   ohne ihn zu beobachten"-Bugs (der Rest folgt korrekt dem Repository-Pattern aus
   Non-Negotiable #5):
   - `settings_screen.dart`s `_NotificationsSection`: die drei Erinnerungszeiten (Training/
     Gewohnheiten/Todos) wurden per `ref.read(preferencesRepositoryProvider).notifXTime` gelesen
     — nach dem Ändern einer Zeit blieb die Anzeige bis zum nächsten zufälligen Rebuild (z.B.
     Schalter umlegen) auf dem alten Wert stehen. Fix: drei neue `Notifier<String>`-Provider
     (`notifWorkoutTimeProvider`/`notifHabitTimeProvider`/`notifTodoTimeProvider` in
     `preferences_provider.dart`), exakt nach dem bereits etablierten Muster der Bool-Toggle-
     Notifier — jetzt `ref.watch(...)` statt `ref.read(...)`.
   - `home_widget_catalog_sheet.dart`: `_HomeWidgetCatalog` bekam `WidgetRef` bisher als
     Konstruktor-Feld vom Aufrufer gereicht und las `isPeriodTrackingEnabledProvider` darüber per
     `.read()` — niedrige Praxis-Relevanz (das Sheet wird bei jedem Öffnen neu gebaut), aber
     strukturell derselbe Fehler. Fix: `_HomeWidgetCatalog` ist jetzt ein echtes
     `ConsumerStatefulWidget` mit eigenem `ref`, `showHomeWidgetCatalog()` braucht dadurch auch
     keinen `WidgetRef`-Parameter mehr. **Beim Umsetzen gefunden:** derselbe Screen hatte noch
     zwei hartcodierte deutsche Strings ("Widget hinzufügen", "Suchen…") aus Phase 6 übersehen
     (kein `Text('...')`-Literal-Match, weil in einer anderen Form) — neuer Key `addWidgetTitle`
     + Wiederverwendung von `searchHint`.
4. **Neu: Tagebuch-Suche.** `DiaryDao.searchEntries(diaryId, query)` (LIKE-Filter auf `note`,
   200 Treffer, neueste zuerst) → `DiaryRepository` → neuer `diarySearchResultsProvider`
   (`FutureProvider.family<List<DiaryEntry>, (int, String)>`, lädt nur bei nicht-leerer Query) →
   neuer `diary_search_screen.dart` (Such-Icon im Tagebuch-Header, führt zu einer eigenen Seite
   mit Ergebnis-Kacheln: Datum + Notiz-Ausschnitt, Tap öffnet den Eintrag). **Beim Umsetzen
   gefunden:** `DiaryEntryCard` (Kurzvorschau-Kachel in der "Letzte Einträge"-Leiste) hatte ein
   eigenes, drittes hartcodiertes deutsches Monats-Array — derselbe Bug-Typ wie mehrfach in
   Phase 4/6 gefunden, hier aber übersehen, weil die Datei bis jetzt nie angefasst wurde. Auf
   `AppLocalizations`-Monatsnamen umgestellt.
5. **Neu: Budget-Transaktionssuche.** `transaction_list_screen.dart` bekam ein permanentes
   Suchfeld über den bestehenden Alle/Ausgaben/Einnahmen-Filterchips — filtert client-seitig
   (die Liste ist ohnehin schon vollständig geladen) nach Beschreibung, Notiz und Kategorie-Name,
   mit Debounce. Leerer Zustand unterscheidet jetzt "keine Transaktionen" von "keine Treffer für
   ⟨Suchbegriff⟩" (wiederverwendet `noResultsForQuery`).
6. **`fake_async` als `dev_dependency` ergänzt** (war bisher nur transitiv über `flutter_test`
   auflösbar) — für den neuen `search_debouncer_test.dart`, der echtes Timer-Verhalten
   deterministisch statt über reale Verzögerungen testet.

`flutter analyze` → **0 Issues**. `flutter test` → **551/551 grün** (534 vorher + 17 neu:
`test/core/utils/validators_test.dart`, `test/core/utils/search_debouncer_test.dart`,
`test/features/training/exercise_search_test.dart`,
`test/core/providers/notif_time_providers_test.dart`, `diary_dao_test.dart` um `searchEntries`
erweitert).

**Nicht umgesetzt — bewusst außerhalb des Phase-7-Scopes:** `home_widget_catalog_sheet.dart`s
eigenes Suchfeld (Widget-Katalog, kleine Liste) bekam absichtlich KEIN Debounce — bei einer
Handvoll Katalogeinträgen ist sofortiges Filtern unproblematisch, ein Debounce hätte nur
gefühlte Verzögerung ohne Performance-Nutzen gebracht.

**Nächste Phase laut Plan:** Phase 8 — Header-Vereinheitlichung (`TraumSubHeader` aus
`BudgetSubHeader` extrahieren, Nutrition/Diary darauf umstellen — pixelgenau, höchste Sorgfalt).

---

## ⏩ VORHERIGER STAND (2026-08-11 — v1.0.8, Phase 6: Übersetzung)

**Sechste Phase des Nacharbeitungs-Plans aus dem Tiefenaudit. Große, flächendeckende
Textänderung — jeder hartcodierte deutsche/englische String außerhalb von `l10n.*` wurde gesucht
und über ~35 Dateien hinweg auf `AppLocalizations` umgestellt. Keine schemaVersion-Änderung.**

1. **Budget (Spitzenreiter, ~30 Fundstellen über 8 Dateien).** `debts_screen.dart`,
   `accounts_card.dart`, `recurring_screen.dart`, `budget_stats_screen.dart`,
   `transaction_list_screen.dart`, `budget_screen.dart` vollständig lokalisiert. Dabei
   `accounts_card.dart`s Konto-Löschen-Dialog auf die geteilte `confirmDeleteDialog()`-Komponente
   umgestellt (bisher eigener `AlertDialog`). `buildDonutSlices()` und `_monthYear()` bekamen
   einen zusätzlichen Parameter (`otherLabel`/`context`), weil die "Sonstiges"-Kategorie bzw. das
   hartcodierte Monats-Array vorher unabhängig von der App-Sprache waren.
2. **Training.** `training_screen.dart`s `_lastWorkoutLabel` nutzt jetzt tatsächlich den bereits
   übergebenen, aber bis dato ungenutzten `l10n`-Parameter statt fest codierter englischer Strings
   ("X min ago" etc.). Drei fast identische, über `exercise_library_screen.dart`/
   `exercise_picker_screen.dart`/`exercise_progress_screen.dart` verstreute
   `_mgDisplay()`-Kopien (hartcodierte englische anatomische Begriffe, uneinheitliche
   Groß-/Kleinschreibung) durch die bereits vorhandene, einheitliche
   `muscleGroupLabel(canonical, l10n)`-Funktion ersetzt (`lib/features/training/
   muscle_groups.dart`). `active_workout_screen.dart`s Satz-Typ-Auswahl (Normal/Warm-up/Drop/
   Failure) lokalisiert. `'Bilateral'`/`'Unilateral'` bewusst NICHT angefasst — geprüft, das sind
   identische Fachbegriffe in beiden Sprachen, kein Übersetzungsfehler.
3. **Rest der App:** Home-Widgets (`general_widgets.dart` — Uhr-/Wetter-Karten, App-Favoriten,
   Schnellzugriff-Labels; `widget_data_collector.dart` — derselbe Wetter-Text-Mapping-Fix für den
   kontextlosen Homescreen-Widget-Refresh-Pfad, über `lookupAppLocalizations(Locale)` statt
   `BuildContext`), Nutrition (Barcode-Scanner, Produkt-anlegen-Formular), Settings
   (Kalender-Sync-Bereich, komplettes Feedback-Sheet inkl. `FeedbackType.label`), geteilte
   Chart-Komponenten (`donut_chart.dart`, `traum_line_chart.dart`), Notes
   (`notes_repository.dart`s "Unbenannt"-Fallback jetzt von der UI durchgereicht statt intern
   hartcodiert — Repository hat kein `BuildContext`), Planning (Kalenderauswahl-Dialog),
   Abstinence ("Icon"-Feldlabel), Weather (Standort-Berechtigungsdialog in
   `weather_repository.dart`).
4. **Echter Bug gefunden, nicht nur fehlende Lokalisierung:** `settings_screen.dart`s
   `l10n.backupFailed('No modules selected')` interpolierte einen rohen ENGLISCHEN String in eine
   sonst komplett deutsche Fehlermeldung — Sprachmischung mitten im Satz. Jetzt
   `l10n.backupFailed(l10n.noModulesSelectedError)`.
5. **`custom_lint`-Regel `avoid_hardcoded_strings_in_text_widget` gebaut, aber NICHT ins
   Haupt-Projekt eingebunden — strukturell blockiert, keine Notlösung möglich.** Das Regelwerk
   selbst existiert vollständig und funktionsfähig in `tool/traum_lints/` (eigenständiges,
   unveröffentlichtes Dart-Paket, `dart pub get`/`dart analyze` dort laufen sauber durch). Beim
   Einbinden als `path:`-`dev_dependency` der Haupt-App schlug `flutter pub get` fehl:
   `custom_lint_builder 0.7.6` verlangt `analyzer: ^7.0.0`, aber das Haupt-Projekt hat über
   `build_runner`/`riverpod_generator`/`drift_dev` bereits `analyzer 8.4.1` aufgelöst — eine
   Versionsobergrenze in `custom_lint_builder` selbst, nicht behebbar durch Anpassen der eigenen
   Constraint in `tool/traum_lints/pubspec.yaml`. `pubspec.yaml`/`analysis_options.yaml`-Änderungen
   wieder zurückgenommen, `tool/traum_lints/` bleibt als fertiges, eigenständig lauffähiges Paket
   liegen (in `analysis_options.yaml` per `analyzer: exclude: tool/traum_lints/**` von der
   Haupt-App-Analyse ausgenommen, damit es kein eigenes `flutter analyze`-Rauschen erzeugt) — sobald
   `custom_lint_builder` eine `analyzer 8.x`-kompatible Version veröffentlicht (oder die separate,
   bereits im Plan als eigener Nachmittag vorgesehene Paket-Aktualisierung die App auf einen
   niedrigeren `analyzer` zurückzieht), kann es ohne weitere Codeänderung eingebunden werden.
6. **Bewusst nicht angetastet:** die GitHub-Issue-Markdown-Vorlagen in
   `feedback_bottom_sheet.dart`s `_buildBody()`/`_buildSystemInfo()` — entwicklerseitiger
   GitHub-Issue-Inhalt, konventionell englisch unabhängig von der App-Sprache. Das ÄUSSERE
   `HomeWidgetDescriptor.title`-Feld (Widget-Katalog-Auswahl-Sheet, 69 Instanziierungsstellen über
   4+ Widget-Registry-Dateien) — nur die tatsächlich gerenderten inneren
   `HomeWidgetFrame(title:)`-Aufrufe wurden lokalisiert; das äußere Feld dient zusätzlich als
   Such-Filter-Text im Katalog-Sheet, eine Umstellung auf `l10n` würde den Feldtyp app-weit ändern
   müssen — deutlich größerer, eigener Umbau, bewusst zurückgestellt. Kein ICU-Plural für
   App-Anzahl-Text (`{n} App`/`Apps`) — einfache Ternary-Lösung passend zum Rest der Codebasis, die
   nirgends ICU-Plurale nutzt.

**Beim Testen gefunden:** `test/features/home/group_general_test.dart` und
`home_registry_completeness_test.dart` bauten ihre `MaterialApp` bisher ohne
`localizationsDelegates`/`supportedLocales` — unauffällig, solange kein Widget in
`generalHomeWidgets` `AppLocalizations.of(context)` aufrief. Mit der Uhr-/Wetter-Lokalisierung
dieser Runde schlug `AppLocalizations.of(context)!` dort mit einem Null-Check-Fehler fehl. Beide
Tests um die Delegates ergänzt statt die Produktivcode-Lokalisierung wieder zu entfernen.

`flutter analyze` → **0 Issues**. `flutter test` → **534/534 grün** (unverändert in der Zahl —
`stats_donut_test.dart` an die neue `buildDonutSlices`-Signatur angepasst, die beiden
Home-Widget-Tests um Localization-Delegates ergänzt, keine neuen Testdateien).

**Nächste Phase laut Plan:** Phase 7 — Code-Qualität & neue Suchfelder (zentrale
`validators.dart`/`parseLocaleAmount()`, Übungssuche vereinheitlichen, Riverpod-Aufräumarbeiten,
neue Tagebuch-Suche, neue Budget-Transaktionssuche).

---

## ⏩ VORHERIGER STAND (2026-08-10 — v1.0.7, zweite Phase-5-Nachbesserung: Bild-Tap-Ziele + Kalenderzellen)

**Auf Nutzerwunsch ("überprüfe ob du noch irgendwas übersehen hast") ein zweiter, tieferer
Selbst-Audit nach v1.0.6 — diesmal gezielt nach Mustern gesucht, die die beiden vorherigen Sweeps
(`IconButton(`/`FloatingActionButton(`, dann `GestureDetector`/`InkWell` um nacktes `Icon(`)
nicht abdeckten.**

1. **4 tappbare Bilder ohne jede Sprachausgabe-Information gefunden** (`GestureDetector`/`InkWell`
   um `Image.file`/`Image.memory` statt um ein `Icon`, daher von den vorherigen Sweeps nicht
   erfasst):
   - App-Launcher-Favoriten-Kachel (`traum_scaffold.dart`) — zeigte App-Icon + Name als
     unverbundene Geschwister-Widgets unter einem nackten `GestureDetector`; jetzt
     `Semantics(button:, label: appName)` außen, `ExcludeSemantics` innen (kein Doppel-Ansagen).
   - Beleg-Foto in der Buchungs-Detailansicht (`transaction_detail_screen.dart`) — jetzt
     „Beleg-Foto" (wiederverwendet `a11yReceiptPhoto` aus v1.0.6).
   - Karten-Galerie-Kachel (`map_gallery_screen.dart`) — jetzt Marker-Titel als Label (Fallback
     „Kartenmarker" bei leerem Titel).
   - Foto-Karussell in der Marker-Detailansicht (`marker_detail_screen.dart`) — jetzt „Foto X von
     Y" (neuer parametrisierter Key `a11yViewPhoto`).
2. **Tagebuch-Kalenderzellen hatten nur die nackte Tageszahl als Text, keinen vollen Kontext.**
   Kein Totalausfall (die Zahl war technisch vorlesbar), aber ohne Monat/Jahr/Eintrag-Status
   wenig hilfreich. Jetzt volle `Semantics(button: hatEintrag, label: "5. August, Eintrag
   vorhanden"/"…, Kein Eintrag")`, visuelle Zelle per `ExcludeSemantics` stummgeschaltet, damit
   nicht doppelt vorgelesen wird. Neuer Key `a11yDiaryDayHasEntry`.

`flutter analyze` → **0 Issues**. `flutter test` → **534/534 grün** (unverändert).

**Bewusst nicht weiter verfolgt — als eigener, künftiger Durchgang eingestuft, nicht Teil dieser
Nachbesserung:** Ein breiterer Scan nach `GestureDetector`/`InkWell` um einen reinen `Container`
(ohne direktes `Icon`/`Text` in unmittelbarer Nähe, aber mit sichtbarem Text etwas weiter im
Widget-Baum, z. B. Zeilen-weite Tap-Ziele wie Budget-Kategorie-Zeilen, Konten-Karten,
Tagebuch-Eintrags-Karten) ergab **~48 weitere Fundstellen** über nahezu alle Module. Stichproben
zeigten: das sind überwiegend **keine stummen Buttons** — der sichtbare Text (z. B. Kategorie-
Name) ist einzeln durch TalkBack erreichbar, nur eben nicht zu einem einzigen „Button,
Kategorie-Name"-Knoten zusammengefasst (mehrere separate Ansagen statt einer sauberen). Das ist
spürbar niedrigere Priorität als die in v1.0.5/v1.0.6/v1.0.7 behobenen echten Totalausfälle
(gar keine Ansage) und würde einen eigenen, größeren Durchgang über praktisch jede Listenzeile
der App bedeuten — bewusst zurückgestellt statt hier unkontrolliert auszuweiten.

**Nächste Phase laut Plan:** Phase 6 — Übersetzung (Budget ~30 hardcodierte Strings, Training
EN/DE-Mischung, Rest verteilt über ~35 Dateien, neue ARB-Keys, `custom_lint`-Regel gegen künftige
hardcodierte Strings).

---

## ⏩ VORHERIGER STAND (2026-08-10 — v1.0.6, Phase 5 Nachbesserung: TalkBack fand weitere Lücken)

**Direktes Nutzer-Feedback nach v1.0.5: beim echten TalkBack-Test wurden weiterhin viele Elemente
ohne aussagekräftige Ansage vorgelesen ("leere Platzhalter"). Root Cause: v1.0.5s Sweep suchte
gezielt nach dem `IconButton`-Widget — aber ein erheblicher Teil der App baut Icon-Buttons als
rohen `GestureDetector`/`InkWell` um ein `Icon(...)`, und `FloatingActionButton` wurde komplett
übersehen (hat ebenfalls ein `tooltip`-Property, genau wie `IconButton`, aber eine andere
Such-Signatur). Beides fehlte im ursprünglichen Grep.**

1. **Alle 17 `FloatingActionButton`s app-weit hatten kein `tooltip`** — jeder zeigte nur ein
   „+"/Stift-Icon ohne jeden Kontext, TalkBack sagte nur „Schaltfläche". Betroffen:
   Abstinence (3: Tracker/Ziel/Gewohnheit hinzufügen), Budget (4: Schnelleingabe ×2, Schuld,
   Sparziel), Health (3: Schlaf/Gewicht eintragen, Maße bearbeiten), Notes (2: neue Notiz, neue
   Vorlage), Planning (2: Termin, Aufgabe), Substances (1), Training (2: neue Routine, Training
   starten). Wo passend, existierende l10n-Keys wiederverwendet
   (`logSleep`/`logWeight`/`addGoal`/`addHabit`/`addAppointment`/`newRoutine`/`startWorkout`),
   sonst neue ergänzt (`addTracker`, `addSubstance`, `addTodo`, `addTransaction`, `addDebt`,
   `editMeasurements`, `notes_new_template`).
2. **15 rohe `GestureDetector`/`InkWell`-um-`Icon`-Konstrukte ohne jede Semantics gefunden**,
   über 13 Dateien verteilt (Suche: alle `GestureDetector(`/`InkWell(`, deren `child:` innerhalb
   von 8 Zeilen ein nacktes `Icon(` ist, ohne `Semantics(` in der Nähe). Jeweils mit
   `Semantics(button: true, label: …)` umwickelt statt auf `IconButton` umgestellt (hätte an
   vielen Stellen Layout/Styling-Nebenwirkungen gehabt). Zwei besonders wirkungsvolle Funde:
   - **Die komplette untere Navigationsleiste** (`core/navigation/traum_scaffold.dart`s
     `_NavItem`) hatte in BEIDEN Zuständen (aktiv/inaktiv) keine Semantics — der inaktive Zustand
     zeigt nur ein Icon (kein Text), der aktive Zustand zeigt Icon+Text, aber ein reiner
     `GestureDetector` fasst das nicht automatisch zu einem einzigen „Button, Home"-Knoten
     zusammen. Jetzt beide Zustände mit `Semantics(button: true, selected: isActive, label: …)`,
     aktiver Zustand zusätzlich mit `ExcludeSemantics` um die visuelle Icon+Text-Kombination, um
     Doppel-Ansagen zu vermeiden. **Das ist vermutlich die Hauptursache des gemeldeten Problems**
     — die Haupt-Navigation ist das Allererste, was ein TalkBack-Nutzer ausprobiert.
   - **Alle Home-Kacheln** (`home_widget_frame.dart`s `HomeWidgetFrame`, von praktisch jedem
     Home-Widget verwendet) waren ein nackter `GestureDetector` um beliebigen Kachel-Inhalt
     (Charts, Progress-Ringe, Sparklines — nichts davon hat von sich aus Semantics). Jetzt
     `Semantics(button: route != null, label: title)` um den ganzen Rahmen — jede Kachel sagt
     jetzt mindestens ihren Titel an ("Notizen", "Budget" etc.), unabhängig vom internen Inhalt.
   - Weitere Fundstellen: Monats-Vor/Zurück-Navigation (Budget-Kopfzeile, Tagebuch-Kalender),
     Beleg-Foto-Button (Budget-Schnelleingabe), Zurück-Pfeil (Budget-Unterkopfzeile), Schließen-
     Buttons (Tagebuch-Diashow, Karten-Suche), Stern-Bewertungen (Karten-Marker, Schlafqualität —
     je Stern jetzt „Bewertung: X Sterne"), Info-Icon (Health-Score-Detail), Markdown-Checkbox
     (Notizen-Checklisten, mit `checked:`-Semantics statt nur `button:`), Scanner/Hinzufügen-Icons
     (Ernährungs-Mahlzeit-Abschnitt), Entfernen-Icon (Trainings-Assistent-Übungsliste),
     Modul-Entfernen-Button (Navigations-Anpassung).
   Neue generische ARB-Keys: `a11yPreviousMonth`, `a11yNextMonth`, `a11yReceiptPhoto`,
   `a11yMoreInfo`, `a11yToggleCheck`, `a11yStarRating(count)`.

`flutter analyze` → **0 Issues**. `flutter test` → **534/534 grün** (unverändert — reine
Accessibility-Ergänzung ohne Verhaltensänderung, kein neuer automatisierter Test nötig über den
bereits in v1.0.5 ergänzten Kontrasttest hinaus).

**Lehre für spätere Accessibility-Durchgänge:** Ein Grep nach `IconButton(` allein reicht nicht —
`FloatingActionButton(` hat dieselbe Lücke, und rohe `GestureDetector`/`InkWell`-Icon-Konstrukte
sind in dieser Codebasis mindestens so verbreitet wie das offizielle Widget. Ein vollständiger
Audit muss beide zusätzlichen Muster explizit mit-scannen.

---

## ⏩ VORHERIGER STAND (2026-08-10 — v1.0.5, Phase 5: Barrierefreiheit)

**Fünfte Phase des Nacharbeitungs-Plans aus dem Tiefenaudit. Große, flächendeckende, aber
größtenteils unsichtbare Änderung (Screenreader-Labels) plus ein einzelner, sichtbarer
Kontrast-Fix. Keine schemaVersion-Änderung.**

1. **`TraumColors.onBackgroundSubtle`-Kontrast auf WCAG AA angehoben.** Der Farbwert lag bei
   `#555577` gegen den `#0D0D1A`-Hintergrund rechnerisch nur bei ~2,7:1 Kontrast — WCAG AA
   verlangt 4,5:1 für normalen Text. Der Token wird in 75 Dateien für Sekundärtext, Platzhalter
   und Icons verwendet. Neuer Wert `#7878A4` (rechnerisch ~4,61:1) — entlang derselben
   lavendel-grauen Farbrichtung aufgehellt, bleibt aber sichtbar dunkler als
   `onBackgroundMuted` (#8888AA), damit die bestehende Drei-Stufen-Text-Hierarchie
   (onBackground/onBackgroundMuted/onBackgroundSubtle) erhalten bleibt statt zu kollabieren.
   Neuer Test `test/core/theme/colors_contrast_test.dart` berechnet den echten WCAG-2.1-
   Kontrastwert (relative Luminanz-Formel) direkt aus dem Farbwert — verhindert, dass eine
   künftige Änderung dieses zentralen Tokens den Kontrast unbemerkt wieder unter 4,5:1 drückt.
2. **Screenreader-Labels für IconButtons app-weit ergänzt.** Vorheriger Audit-Befund: von 54
   reinen Icon-Buttons hatten höchstens 10 ein `tooltip` (Flutters De-facto-Ersatz für ein
   Screenreader-Label, sofern kein separates `semanticLabel` gesetzt ist) — der Großteil war für
   TalkBack/VoiceOver nur als unbeschrifteter „Button" hörbar. Systematisch jede verbleibende
   Fundstelle nachgetragen (42 `tooltip:`-Ergänzungen über 28 Dateien: Home, Diary, Budget,
   Nutrition, Notes, Training, Planning, Substances, Period Tracking, Onboarding, Graffiti Map,
   Kamera-Overlay). Wo ein passender l10n-Key schon existierte (`l10n.back`/`close`/`search`/
   `add`/`delete`/`edit`/`save`/`more`/`done`/`startWorkout`/`calendarSyncTitle`), wurde er
   wiederverwendet statt dupliziert; wo keiner existierte, neue de+en ARB-Keys ergänzt
   (`a11yToggleFavorite`, `a11yAddSet`, `a11yToggleTorch`, `a11yScanBarcode`,
   `a11yWorkoutHistory`, `a11ySwitchCamera`, `notes_new_note`, `notes_toggle_preview`,
   `notes_toggle_bookmark`, `notes_toggle_panel`, `diarySlideshow`).
   **Sonderfall gefunden:** `core/camera/overlay_camera_screen.dart` nutzt für seine
   Kamera-Steuerelemente (Schließen ×2, Kamera wechseln) eine eigene `_RoundIconButton`-Klasse
   (`GestureDetector` statt `IconButton`) — hat also kein `tooltip`-Property. Statt eine
   Ersatzlösung zu bauen, hat die Klasse jetzt einen `label`-Parameter bekommen, der intern in
   `Semantics(button: true, label: …)` um den `GestureDetector` gewickelt wird — dieselbe
   Screenreader-Wirkung wie `tooltip` bei echten `IconButton`s.
   **Bereits vorher korrekt beschriftet, unverändert gelassen:** `period_screen.dart` (3),
   `notes_trash_screen.dart` (2), `workout_plan_detail_screen.dart`s Start-Button (1),
   `graffiti_map_screen.dart`s Bearbeiten-Button (1).
   `custom_lint`-Regel gegen künftige unbeschriftete IconButtons (analog zur für Phase 6
   vorgesehenen Hardcoded-String-Regel) **nicht** eingerichtet — das war nicht Teil des
   Plan-Scopes für diese Phase und wäre eine eigene, größere Entscheidung.

`flutter analyze` → **0 Issues**. `flutter test` → **534/534 grün** (532 vorher + 2 neu:
`colors_contrast_test.dart`).

**Bewusst nicht angetastet — außerhalb des Phase-5-Scopes laut Plan:** Tap-Target-Größen
(minWidth/minHeight < 44dp, z.B. `active_workout_screen.dart`s 36×36-Constraints) — das war
Gegenstand des bereits in Phase 4 erledigten Einzelfunds (Übungs-Picker-Button), eine
vollständige App-weite Tap-Target-Runde ist ein separates, größeres Vorhaben und nicht Teil
dieser Phase. `Colors.grey`/hartcodierte Kontrastwerte außerhalb des einen zentralen Tokens
wurden im vorherigen Audit als unauffällig eingestuft (0 Treffer) und daher nicht erneut geprüft.

**Nächste Phase laut Plan:** Phase 6 — Übersetzung (Budget ~30 hardcodierte Strings, Training
EN/DE-Mischung, Rest verteilt über ~35 Dateien, neue ARB-Keys, `custom_lint`-Regel gegen künftige
hardcodierte Strings).

---

## ⏩ VORHERIGER STAND (2026-08-09 — v1.0.4, Phase 4: Verteilte Kleinbugs)

**Vierte Phase des Nacharbeitungs-Plans aus dem Tiefenaudit. 14 über viele Module verstreute
Einzelfunde, keine schemaVersion-Änderung. Zwischendurch kam direktes Nutzer-Feedback zur
Benachrichtigungslücke ("ich bekomme immernoch keine Benachrichtigungen", zweites Mal trotz
v1.0.1/v1.0.2) — auf Nutzerwunsch bewusst NICHT blind weiter gefixt, sondern zusammen mit der
noch offenen Backup-Performance-Frage aus Phase 1 auf eine gemeinsame Live-USB-Diagnose am Ende
des Gesamtplans verschoben.**

1. **Home-Kachel-Reorder Off-by-one.** `HomeLayoutNotifier.reorder()` zog beim Verschieben einer
   Kachel nach hinten (`oldIndex < newIndex`) den Ziel-Index nicht um 1 zurück, obwohl das
   Entfernen der Quell-Kachel alle dazwischenliegenden Kacheln (inkl. Ziel) einen Index nach vorn
   verschiebt — die Kachel landete dadurch immer eine Position hinter der eigentlich gewählten
   Zielposition. Klassischer `ReorderableListView`-Bug, hier aber in einer eigenen
   Drag-and-Drop-Implementierung (`LongPressDraggable`/`DragTarget`).
2. **Abstinence: `frequency`-Feld jetzt tatsächlich im Streak berücksichtigt.** Eine wöchentliche
   Gewohnheit lief bisher immer durch den Tages-Streak-Algorithmus — ein Habit, das treu jede
   Woche geloggt wurde, zeigte praktisch immer Streak 0 oder 1, weil an den meisten Tagen
   dazwischen naturgemäß kein Log existiert. Neuer wochenbasierter Streak-Zweig
   (Montag-verankerte Wochen-Buckets) für `frequency == 'weekly'`, inkl. eigenem Label
   ("X Wochen in Folge" statt "X Tage in Folge").
3. **Planning: Validierung Endzeit ≥ Startzeit** beim Speichern eines Termins ergänzt (vorher
   ließ sich ein Termin mit Ende vor Beginn anlegen).
4. **Notes: zwei Performance-Fixes.** Backlinks/Outgoing-Links liefen bisher als N+1-Query (eine
   DB-Abfrage pro verlinkter Notiz) — jetzt eine Batch-Auflösung über die bereits geladene
   Notiz-Liste. Der Force-directed Graph (`FruchtermanReingoldAlgorithm`, 600 Iterationen)
   simulierte bisher bei JEDER Notiz-Änderung neu (Titel-Edit, Bookmark-Toggle — nicht nur
   Struktur-Änderungen), wodurch der ganze Graph beim Bearbeiten irgendeiner Notiz sichtbar
   sprang. Jetzt gecacht, nur bei tatsächlich geänderter Knoten-/Kanten-Menge neu berechnet.
5. **App-Launcher: hängender Lade-Spinner behoben.** `listInstalledApps()` (experimentelles
   Feature) ließ bei einem Plattform-Fehler `_apps` dauerhaft `null` — jetzt try/catch mit
   Fallback auf leere Liste, erreicht wenigstens den vorhandenen „Keine Apps"-Zustand.
6. **Datumsformat: toter Code mit hartcodiertem `'de'` entfernt, echter Bug behoben.**
   `core/utils/date_utils.dart`s `formatDate`/`formatDateTime`/`formatTime` stellten sich als
   komplett unbenutzt heraus (einzige Importstelle nutzt nur `greeting()`) — entfernt statt mit
   falscher Locale-Logik weiterzuschleppen. Der tatsächlich sichtbare Bug steckte in
   `diary_slideshow_screen.dart`: ein hartcodiertes deutsches Monats-Array (`'Jan','Feb','Mär'…`)
   unabhängig von der App-Locale — jetzt wie in `diary_screen.dart`/`diary_entry_screen.dart`
   über `AppLocalizations`-Monatsnamen.
7. **Graffiti-Map: Hashtag-Filter jetzt kollektionsweit statt nur im Kartenausschnitt.** Der
   Filter arbeitete bisher als Client-seitiges `.where()` auf `markersInViewportProvider` — ein
   Treffer außerhalb des sichtbaren Ausschnitts war unauffindbar, ohne dass die Karte dorthin
   zoomte oder irgendein Hinweis erschien. Neue DAO-Methode `byHashtagSubstring` (LIKE-Vorfilter,
   Limit 500, analog zu `search()`) + neuer `hashtagFilteredMarkersProvider`
   (`FutureProvider.autoDispose.family`) ersetzt bei aktivem Filter komplett die
   Viewport-Quelle — exaktes Tag-Matching (kommagetrennt) läuft weiterhin in Dart, jetzt aber über
   die ganze Collection statt nur die sichtbaren Marker.
8. **Launcher-Homescreen-Widget: echte App-Namen statt Package-Namen-Fragment.** Die
   „App-Favoriten"-Kachel zeigte bisher den letzten Segment-Teil des Package-Namens
   (z. B. `chrome` statt „Google Chrome"). Neuer `_favoriteAppNamesProvider` löst bis zu 3
   Favoriten über `AppLauncherService.getApp()` auf echte Namen auf, Fallback auf die alte
   Heuristik nur bei Auflösungsfehler.
9. **Abstinence/Planning: Bestätigungsdialog vor Swipe-Löschen.** 5 `Dismissible`s (Goal, Habit,
   AbstinenceTracker, Appointment, Todo) hatten kein `confirmDismiss` — ein versehentliches Wischen
   löschte sofort, ohne Rückfrage. Neue geteilte Komponente `core/components/
   confirm_delete_dialog.dart` (`confirmDeleteDialog()`, gleiches visuelles Muster wie das
   bestehende `budget_categories_screen.dart`-Vorbild) an allen 5 Stellen verdrahtet, je mit
   Name des betroffenen Eintrags im Dialogtext.
10. **Period Tracking: defensive Prüfung Ende ≥ Start.** Code-Prüfung ergab: die AKTUELLE UI kann
    `endDate < startDate` gar nicht erzeugen (Start-Picker `lastDate: DateTime.now()`, der einzige
    Ende-Schreibpfad setzt immer `DateTime.now()`) — keine UI-Validierung für einen nicht
    existierenden Bearbeitungspfad ergänzt. Stattdessen defensiver Ausschlussfilter in
    `cycle_analyzer.dart`s `_avgPeriodLength()`, für den Fall, dass ein wiederhergestelltes Backup
    doch mal so einen Datensatz enthält (Restore validiert nicht erneut).
11. **Dezimaltrennzeichen Health/Training auf Komma umgestellt (wie Budget).** Health/Training
    parsten Komma-Eingaben zwar bereits korrekt, zeigten gespeicherte Werte aber mit Punkt an
    (`95.5` statt `95,5`) — inkonsistent zum in Budget etablierten Muster. 20 Fundstellen über
    `health_screen.dart` (9 Körpermaß-Felder + 4 weitere Anzeigen), `active_workout_screen.dart`
    (Gewichts-Eingabefeld), `exercise_progress_screen.dart` (6 Stellen, inkl. Achsenbeschriftung
    und Mini-Stats), `training_screen.dart` (Tonnen-Anzeige) sowie zwei generische
    Settings-Dialoge (Körpergröße, Gewichtsziel) auf `.replaceAll('.', ',')` umgestellt.
12. **6 Dialog-`TextEditingController` jetzt disponiert** (Vorlage: `debts_screen.dart`s
    `.whenComplete(ctrl.dispose)`). Betroffen: `health_screen.dart` (Gewicht-Dialog),
    `savings_screen.dart` (Einzahlungs-Dialog), `shopping_templates_sheet.dart`
    (Vorlagen-Dialog), `notes_common.dart`s `showNotesTextDialog` (mehrfach wiederverwendeter
    Text-Eingabedialog), `settings_screen.dart` (3 Dialoge: Ganzzahl/Kommazahl-Editor,
    API-Key-Editor) und `active_workout_screen.dart`s Notiz-Dialog — insgesamt 8 statt der im
    Plan geschätzten 6, da die genaue Fundstellen-Zahl beim Umsetzen höher lag als beim
    ursprünglichen Audit-Scan.
13. **18×18-px-Button im Übungs-Picker auf 44×44 vergrößert.** Der Entfernen-Button auf den
    ausgewählten Übungs-Thumbnails in der Sidebar saß als `Positioned(top: -4, right: -4, …)`
    teilweise außerhalb der Bounds seines eigenen `Stack` (56×56). **Beim Umsetzen gefunden:**
    ein `Stack` hit-testet `Positioned`-Kinder nur innerhalb seiner EIGENEN Layout-Größe, auch
    bei `clipBehavior: Clip.none` — der über den Rand hinausragende Teil des alten 18px-Badges
    war zwar sichtbar, aber vermutlich gar nicht antippbar. Fix: 44×44-Hit-Fläche jetzt komplett
    innerhalb der 56×56-Thumbnail-Bounds (`Positioned(top: 0, right: 0, …)`, visuelles 18px-Badge
    per `Align`/`Padding` in der Ecke), dadurch kein Overflow-Hit-Test-Risiko mehr.
14. **Verweigerte Standort-/Kalenderberechtigung: Hinweis mit Link zu den Systemeinstellungen.**
    Graffiti-Map (`_goToMyLocation`) zeigte bei verweigertem Standort bisher nur eine reine
    Text-SnackBar — jetzt mit `SnackBarAction` zu `Geolocator.openAppSettings()`. Gleiches für
    den Kalender-Sync-Fehlschlag in `planning_screen.dart` (`openAppSettings()` aus
    `permission_handler`). **Beim Umsetzen gefunden:** `settings_screen.dart`s
    Kalenderauswahl-Dialog öffnete bei fehlender Berechtigung eine LEERE Kalenderliste ohne jede
    Erklärung (die native Channel-Abfrage scheitert dort lautlos) — jetzt wird bei leerer Liste
    zuerst `requestPermissions()` versucht, bleibt sie leer, erscheint derselbe
    Einstellungen-Hinweis statt eines leeren Pickers.

`flutter analyze` → **0 Issues**. `flutter test` → **532/532 grün** (527 vorher + 5 neu:
`home_layout_provider_test.dart` um den Vorwärts-Reorder-Test erweitert, neuer
`test/features/abstinence/habit_weekly_streak_test.dart`, `map_markers_dao_test.dart` um 3 Tests
für `byHashtagSubstring` erweitert).

**Bewusst nicht angetastet — außerhalb des Phase-4-Scopes:** `dynamic_marker_sheet.dart` und
`training_widgets.dart` verwenden weiterhin reines `dd.MM.`-Zahlenformat ohne Monatsnamen (keine
Sprach-Strings, nur Ziffern-Reihenfolge — eine vollständige Locale-abhängige Datums-*Ordnung*
wäre ein deutlich größerer Umbau und gehört eher in Phase 6/7 als in diesen Kleinbug-Durchgang).

**Nächste Phase laut Plan:** Phase 5 — Barrierefreiheit (44 unbeschriftete Icon-Buttons,
`TraumColors.onBackgroundSubtle`-Kontrastanhebung).

**Weiterhin offen, bewusst verschoben auf eine gemeinsame Live-Geräte-Diagnose am Ende des
Gesamtplans:** Backup-„Wird gepackt…"-Performance auf echtem Gerät (Phase 1) UND die wiederholt
gemeldete Benachrichtigungslücke (zwei Fix-Versuche in v1.0.1/v1.0.2 ohne bestätigte Wirkung) —
auf ausdrücklichen Nutzerwunsch NICHT weiter blind per Ferndiagnose angegangen, sondern per USB
mit `adb logcat` zusammen untersucht, sobald Zeit dafür ist.

---

## ⏩ VORHERIGER STAND (2026-08-08 — v1.0.3, Phase 3: Unsichtbare Backend-Fixes)

**Dritte Phase des Nacharbeitungs-Plans aus dem Tiefenaudit. Reine Backend-Fixes ohne
beabsichtigte sichtbare UI-Änderung — außer eventuell leicht andere Zahlen im Budget-
Verlaufschart und im Health-Wochenverlauf, wo tatsächlich falsche Werte korrigiert wurden.**

1. **Index auf `transactions(date)` + `PRAGMA journal_mode=WAL`.** Beide in `beforeOpen`
   (läuft bei jedem Öffnen, idempotent) statt in einem einzelnen Migrationsschritt — WAL erlaubt
   nebenläufige Leser neben einem Schreiber und entschärft `SQLITE_BUSY`-Konflikte zwischen der
   Vordergrund-App und dem periodischen Homescreen-Widget-Hintergrundabgleich (WorkManager, eigene
   `TraumDatabase()`-Verbindung, siehe `widget_data_collector.dart`).
   **Beim Testen gefunden:** mehrere Migrations-Test-Fixtures (z.B. `diary_migration_v27_test.dart`,
   `lost_place_migration_v25_test.dart`) seeden nur die für ihren jeweiligen Versionssprung
   relevanten Tabellen — nicht `transactions`. Das ungeschützte `CREATE INDEX ... ON transactions`
   crashte dort mit „no such table". Fix: Existenzprüfung über `sqlite_master` vor dem
   `CREATE INDEX`, analog zum etablierten `pragma_table_info`-Muster für `_addColumnIfMissing`.
2. **`markerSearchProvider` auf `.autoDispose` umgestellt.** War zuvor ein reiner
   `FutureProvider.family` ohne AutoDispose — jede eingetippte Zeichenkette während der
   Kartensuche erzeugte eine neue, dauerhaft im Speicher gehaltene Provider-Instanz samt
   Marker-Liste. Bei Suche-als-du-tippst wächst das unbegrenzt über die App-Laufzeit.
3. **`healthScoreHistoryProvider`: echter Tag-vs-Wochenziel-Bug behoben.** Der Trainings-Faktor
   im 7-Tage-Verlauf verglich bisher die Workout-Sessions eines EINZELNEN Tages direkt gegen das
   WÖCHENTLICHE Ziel (`workoutGoalPerWeek`) — ein Trainingstag zeigte praktisch nie einen guten
   Trainings-Score, weil 1 Session gegen z.B. ein Ziel von 3 verglichen wurde, statt die
   kumulierten Sessions der Kalenderwoche bis zu diesem Tag heranzuziehen (wie es der
   Haupt-Score `healthScoreProvider` bereits korrekt macht). Zusätzlich: die Schleife führte
   pro Tag 5 einzelne, sich überlappende DB-Abfragen aus (7 Tage × 5 = 35 sequenzielle Queries,
   jede mit wachsendem Zeitfenster). Jetzt: je Datenquelle **eine** Abfrage für das gesamte
   7-Tage-Fenster (Trainings-Sessions sogar bis zum Wochenanfang der ältesten Verlaufs-Woche),
   parallel per `Future.wait`, danach In-Memory-Bucketing pro Tag — 35 auf 7 Abfragen reduziert.
4. **`dailyBalanceSpotsProvider`: Konto-Filterlogik an `totalAccountBalanceProvider`
   angeglichen.** Das Budget-Verlaufschart zählte bislang Einnahmen/Ausgaben OHNE zugewiesenes
   Konto (`accountId == null`) in seine laufende Summe mit — die „Kontostand"-Summe
   (`deriveAccountBalances`/`totalAccountBalanceProvider`, sichtbar in `AccountsCard`) hatte
   solche Buchungen dagegen schon immer stillschweigend ausgeschlossen (sie berühren ja kein
   echtes Konto). Beide Werte konnten dadurch dauerhaft auseinanderlaufen. Jetzt identische
   Filterregel in beiden: nur Buchungen mit `accountId != null` zählen, Transfers bleiben
   wie gehabt netto null über alle Konten hinweg.
   **Beim Testen gefunden:** ein bestehender Test (`cashflow_line_test.dart`) hatte genau das
   alte, inkonsistente Verhalten als Erwartung einprogrammiert (seine Test-Transaktionen hatten
   nie ein `accountId` gesetzt) — korrigiert auf realistische, kontogebundene Transaktionen bei
   unveränderter Testabsicht (gleiche erwarteten Werte).

`flutter analyze` → **0 Issues**. `flutter test` → **527/527 grün** (525 vorher + 2 neu:
`test/features/budget/derived_balance_test.dart` um den Konto-Filter-Konsistenztest erweitert,
`test/features/health/health_score_history_test.dart` neu für den Wochenziel-Fix; zusätzlich
`test/features/budget/cashflow_line_test.dart` korrigiert).

**Nächste Phase laut Plan:** Phase 4 — Verteilte Kleinbugs (14 Einzelfunde über viele Module,
u.a. Home-Kachel-Reorder Off-by-one, Abstinence-Frequenz, Planning-Zeitvalidierung,
Notes-N+1-Query, Dezimaltrennzeichen-Konsistenz).

---

## ⏩ VORHERIGER STAND (2026-08-08 — v1.0.2, Medikamente/Supplements: Zeitauswahl, Bearbeiten, Wochentage)

**Direktes Nutzer-Feedback zu v1.0.1, drei zusammenhängende Punkte über mehrere Nachrichten:**
1. Beim Anlegen von Supplements fehlte eine Zeitauswahl komplett (Medikamente hatten sie schon
   seit Phase 2).
2. Es fehlte generell eine Möglichkeit, Medikamente/Supplements nachträglich zu bearbeiten (nur
   Hinzufügen/Löschen/(De-)Aktivieren existierten).
3. Der globale „Supplements"-Schalter in den Einstellungen wurde als überflüssig gemeldet —
   analog zum bereits in v1.0.1 entfernten „Medikamente"-Schalter.
4. Zusätzlich gewünscht: Auswahl, an welchen Wochentagen ein Medikament/Supplement genommen
   wird, und dass unterschiedliche Uhrzeiten an unterschiedlichen Tagen möglich sind (man nimmt
   ja nicht alles jeden Tag zur gleichen Zeit).

**Umsetzung:**

1. **Supplements bekommen dieselbe Zeit-Infrastruktur wie Medikamente.** Die `Supplements`-
   Tabelle hatte bereits eine `timings`-Spalte (seit jeher ungenutzt) — jetzt tatsächlich verdrahtet.
   `SupplementDao.getActiveSupplements()` ergänzt (mirror von `getActiveMedications()`).
2. **Bearbeiten-Menüpunkt** in beiden Kontextmenüs (`_MedCard`/`_SuppCard`, langes Drücken) vor
   Deaktivieren/Löschen. `_AddMedSheet`/`_AddSuppSheet` nehmen jetzt einen optionalen `existing`-
   Parameter: vorbefüllt aus dem bestehenden Datensatz (`Medication.toCompanion(true).copyWith(...)`
   bzw. `Supplement.toCompanion(true).copyWith(...)` — bewahrt Felder wie `isActive`/`createdAt`/
   `notificationId`, die das Formular nicht zeigt), Titel wechselt zu „… bearbeiten", Speichern
   erkennt Update vs. Insert anhand `companion.id.present`.
3. **Globaler „Supplements"-Schalter entfernt**, exakt wie zuvor beim Medikamenten-Schalter:
   `notifSupplement`/`notifSupplementTime` aus `PreferencesRepository`, `notifSupplementProvider`
   entfernt, `id=4`-Block aus `NotificationService.rescheduleAll()` entfernt. Der Hinweistext in
   den Einstellungen erwähnt jetzt „Medikamente und Supplements" statt nur Medikamente.
4. **🆕 Wochentag-Auswahl pro Erinnerungszeit — neue Datenstruktur.** `timings` ist bisher ein
   JSON-Array reiner `"HH:mm"`-Strings gewesen (implizit „jeden Tag"). Neues Format (rückwärts-
   kompatibel, Alt-Daten werden automatisch als „jeden Tag" interpretiert):
   ```json
   [{"time":"08:00","days":[1,2,3,4,5,6,7]}, {"time":"20:00","days":[1,3,5]}]
   ```
   Neue Datei `lib/core/notifications/reminder_time.dart`: `ReminderTime`-Klasse (`time` +
   `days`-Set, ISO-Wochentage 1–7), `parseReminderTimes()`/`encodeReminderTimes()` als einzige
   Stelle, die dieses Format kennt — sowohl `my_substances_tab.dart` (UI) als auch
   `notification_service.dart` (Planung) importieren nur diese Datei, keine Duplikation.
   Neue wiederverwendbare UI-Komponente `_ReminderTimesEditor` (in `my_substances_tab.dart`):
   je Zeit-Eintrag ein Zeit-Chip + 7 Wochentag-Toggle-Chips (Mo–So, aus dem bereits vorhandenen
   `l10n.weekdaysShort` abgeleitet). Mindestens ein Wochentag muss ausgewählt bleiben (Tippen auf
   den letzten verbleibenden Tag wird ignoriert). Medikamente behalten die alte Mindestanforderung
   „mindestens 1 Zeit-Eintrag" (`minEntries: 1`), Supplements dürfen auf 0 Einträge (= keine
   Erinnerung) reduziert werden.
5. **Scheduling erweitert:** `NotificationService.scheduleWeeklyAt()` (neu, analog zu
   `scheduleDailyAt`, aber `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime`,
   berechnet den nächsten passenden Wochentag+Uhrzeit-Zeitpunkt). `medicationReminderId`/
   `supplementReminderId` bekommen einen optionalen dritten `weekday`-Parameter (0 = „jeden Tag",
   sonst ISO-Wochentag) und reservieren jetzt 1000 statt 100 IDs pro Medikament/Supplement (10 pro
   Zeit-Slot statt 1 — jeder ausgewählte Wochentag braucht einen eigenen wiederkehrenden Alarm).
   Supplement-Basis-Offset auf `10.000.000` angehoben (vorher `500.000`), um mit dem größeren
   Medikamenten-Bereich garantiert kollisionsfrei zu bleiben. `rescheduleAll()`s Medikamenten-/
   Supplement-Schleifen rufen jetzt einen gemeinsamen `_scheduleReminderTime()`-Helfer auf: bei
   „jeden Tag" ein `scheduleDailyAt()`-Aufruf, sonst ein `scheduleWeeklyAt()`-Aufruf pro
   ausgewähltem Wochentag. `markMedicationsTakenFromNotification()` (Background-Isolate-Handler
   für den „Genommen"-Aktionsknopf) ebenfalls auf `parseReminderTimes()` umgestellt — hätte sonst
   beim neuen Objekt-Format gecrasht.
6. **„Heute"-Status-Karte** (`_TodayStatusCard`) filtert Zeiten jetzt zusätzlich auf den heutigen
   Wochentag (`t.days.contains(DateTime.now().weekday)`) — zeigt nur noch Dosen, die tatsächlich
   heute fällig sind, statt aller je konfigurierten Zeiten unabhängig vom Wochentag.
7. **Aufräumen nebenbei:** doppelte `_parseTimes`-Methode (zwei fast identische private Kopien in
   verschiedenen Klassen) durch eine einzige `_formatReminderTimes()`-Anzeigefunktion ersetzt;
   beim Umbau des Supplement-Toggles ein Bestandsbug entdeckt und mitbehoben — `onToggle` baute
   bisher einen unvollständigen `SupplementsCompanion(id:, name:, isActive:)` und hätte über
   `.replace()` beim nächsten Aktivieren/Deaktivieren `category`/`dosageAmount`/`dosageUnit`/
   `timings`/`notes`/`nutrientKey` stillschweigend auf `null`/Default zurückgesetzt; jetzt
   `supp.toCompanion(true).copyWith(isActive: ...)`.

`flutter analyze` → **0 Issues**. `flutter test` → **525/525 grün** (514 vorher + 11 neu:
`test/core/notifications/reminder_time_test.dart` — Legacy-/neues Format, Round-Trip, leeres
Array, `copyWith`; `test/core/notifications/notification_service_test.dart` erweitert um
Wochentag-Kollisionsfreiheit zwischen Zeit-Slots und zwischen Medikament/Supplement über einen
realistischen ID-Bereich).

**Nicht in dieser Runde geändert:** Die generischen Settings-Erinnerungen für Training/Gewohnheiten/
Todo/Wasser/Zyklus bleiben unverändert (eine gemeinsame Uhrzeit für alle, kein Wochentag-Konzept)
— das war nicht Teil des Feedbacks und bewusst nicht mit ausgeweitet, um den Umfang dieser Runde
nicht unnötig zu vergrößern.

---

## ⏩ VORHERIGER STAND (2026-08-07 — v1.0.1, Nachbesserung zu Phase 2: Medikamenten-Erinnerungen)

**Versionshinweis vorab:** Dieser Release heißt `v1.0.1`, nicht `v0.10.1` — der Nutzer hat direkt
in dieser Runde auf einen Fehler in der eigenen Anwendung von Non-Negotiable #17 hingewiesen: die
Regel "jede Ziffer läuft nur 0–9" gilt für **minor genauso wie für patch**, nicht nur für patch.
Nach `0.9.9` hätte `1.0.0` kommen müssen, nicht `0.10.0`. Der bereits veröffentlichte
`v0.10.0`-Tag/-Release bleibt unverändert (kein Force-Rewrite eines publizierten Tags), zählt aber
gedanklich als `1.0.0` — Details dazu direkt bei Regel #17 weiter unten.

**Direktes Nutzer-Feedback zu v0.10.0, zwei Punkte in einer Nachricht:**
> „die Erinnerung für jedes Medikament einzelnt einstellbar nicht für alle in den Einstellungen
> und es kommt keine benachrichtigung generell kommt keine benachrichtigung der rest geht“

**Punkt 1 — Design-Korrektur, nicht nur Bugfix.** Analyse des Codes zeigte: Es gab bereits *zwei
parallele* Medikamenten-Erinnerungssysteme. (a) Jedes Medikament bekommt beim Anlegen eigene,
individuell konfigurierte Einnahmezeiten — das lief bereits unabhängig von jedem Einstellungen-
Schalter. (b) Zusätzlich existierte in Einstellungen → Benachrichtigungen ein generischer
„Medikamente"-Schalter mit EINER gemeinsamen Uhrzeit (`notif_medication`/`notif_medication_time`,
Notification-ID 1) — eine komplett separate, pauschale Erinnerung ohne jeden Bezug zu den echten
Medikamenten. Genau dieser zweite, verwirrende Schalter ist das, was der Nutzer zu Recht als
unpassend empfand: „für alle in den Einstellungen" statt „für jedes Medikament einzeln".
**Fix:** Der generische Schalter (b) wurde vollständig entfernt — `PreferencesRepository.
notifMedication`/`notifMedicationTime`, der zugehörige `notifMedicationProvider`, der
`id=1`-Block in `NotificationService.rescheduleAll()`, die ARB-Keys `notifMedication`. Statt der
toten Kachel zeigt der Benachrichtigungen-Bereich jetzt einen Hinweistext
(`notifMedicationHint`): „Medikamenten-Erinnerungen stellst du direkt bei jedem Medikament unter
‚Meine Mittel' ein — nicht hier zentral." Die persistente Berechtigungswarnung berücksichtigt
jetzt `allMedicationsStreamProvider` (aktive Medikamente mit konfigurierten Zeiten), damit sie
auch für reine Medikamenten-Nutzer ohne sonstige aktivierte Erinnerungskategorie greift.

**Punkt 2 — echter, struktureller Bug gefunden (nicht nur vermutet, aber ohne Live-Gerät nicht zu
100 % verifizierbar).** `rescheduleAllNotifications()` (der zentrale Neuaufbau-Mechanismus aus
Phase 2) wurde bislang **ausschließlich durch explizite Nutzerinteraktion** ausgelöst — ein
Einstellungen-Toggle, oder Medikament hinzufügen/löschen/(de)aktivieren. Es gab **keinen Aufruf
beim App-Start.** Für jeden, der seine Erinnerungen unter einer älteren App-Version eingerichtet
hatte (inkl. der kollidierenden `id: 100+i`-Schemas aus vor v0.10.0) und seitdem keinen
Benachrichtigungs-Schalter mehr angefasst hat, wurden die Erinnerungen nie auf den aktuellen,
korrekten Stand migriert — sie blieben, was auch immer beim letzten manuellen Touch geplant wurde
(oder gar nichts, falls nie manuell angefasst).
**Fix:** `main.dart` baut jetzt einen expliziten `ProviderContainer` (über
`UncontrolledProviderScope` statt `ProviderScope`, damit `main()` selbst Zugriff auf ihn behält)
und ruft `rescheduleAllNotifications(container)` bei **jedem Kaltstart** im bestehenden
`addPostFrameCallback` auf, direkt nach `NotificationService.init()`. Damit synchronisiert sich
der Erinnerungs-Zustand garantiert bei jedem App-Start neu aus DB/Preferences, unabhängig davon,
ob der Nutzer je einen Schalter berührt.
**Ehrlich eingeordnet:** Dies ist die plausibelste, am besten zur Fehlerbeschreibung passende
Ursache — aber ohne Zugriff auf das reale Gerät (kein USB-Debugging in dieser Runde) nicht per
`adb logcat` verifizierbar. Falls das Problem nach v1.0.1 fortbesteht, braucht es einen Live-Test
wie bei der Backup-Performance-Diagnose in Phase 1.

`flutter analyze` → **0 Issues**. `flutter test` → **514/514 grün** (unverändert — reine
Verhaltensänderung an bereits getesteten Pfaden, kein neuer Testbedarf für die reine
Schalter-Entfernung; der Startup-Reschedule ist dieselbe Funktion, die `pin_service_test.dart`/
`notification_service_test.dart` bereits über `medicationReminderId`/`hasPermission` abdecken).

**Für dich zu prüfen:** Am saubersten testbar über ein **neu angelegtes** Medikament mit
Erinnerungszeit (garantiert über den neuen Pfad geplant) — kommt die Erinnerung zur eingestellten
Zeit? Falls ja, ist der Startup-Reschedule vermutlich die tatsächliche Ursache gewesen. Falls
weiterhin nichts kommt: bitte melden, dann brauchen wir einen Live-Test mit deinem Handy per USB.

---

## ⏩ VORHERIGER STAND (2026-08-07 — v0.10.0, Phase 2: Sicherheit & Erinnerungen)

**Zweite Phase des Nacharbeitungs-Plans aus dem Tiefenaudit
(`C:\Users\Lupus\.claude\plans\schaue-dir-mithilfe-von-agile-wozniak.md`). Phase 1
(Datensicherheit) bleibt formal offen — die Backup-„Wird gepackt…“-Performance auf einem echten
Gerät steht noch aus, der Nutzer hat sich entschieden das erst am Ende des Gesamtplans per
Live-`adb logcat`-Test zu klären, statt jetzt weiter zu raten. Diese Runde: Phase 2.**

1. **PIN-Lockout.** `PinService` (`core/security/pin_service.dart`) zählt fehlgeschlagene
   `verify()`-Aufrufe jetzt persistent (`flutter_secure_storage`, dieselbe Storage-Instanz wie der
   PIN selbst). Die ersten 3 Fehlversuche verhalten sich wie bisher (nur Fehlermeldung), ab dem 4.
   greift eine eskalierende Sperre (30s → 60s → 120s → 300s, gedeckelt). Während der Sperre wird
   *kein* `verify()`-Aufruf mehr ausgewertet (auch der korrekte PIN wird abgelehnt) und der
   Fehlerzähler nicht weiter erhöht — Spam während der Sperre verlängert sie nicht zusätzlich. Ein
   erfolgreicher `verify()` sowie `save()` (PIN ändern) und `clear()` (PIN entfernen) setzen den
   Zähler/die Sperre zurück. `PinLockScreen` zeigt einen Sekunden-Countdown
   (`l10n.pinLocked(seconds)`) und sperrt das Zahlenfeld währenddessen komplett.
2. **🔴 Echte Medikamenten-Notification-Kollision behoben.** Die pro-Medikament-Erinnerungen (eine
   je Einnahmezeit) wurden bisher als `id: 100 + i` geplant — reiner Listen-Index *innerhalb* der
   Zeiten eines Medikaments, ohne Bezug zur Medikamenten-ID. Zwei Medikamente mit derselben
   Zeitslot-Position (z.B. beide „morgens“ als erste Zeit) kollidierten auf derselben
   Notification-ID; das zweite überschrieb lautlos die geplante Erinnerung des ersten.
   Fix: `NotificationService.medicationReminderId(medicationId, timeIndex)` — deterministisches,
   kollisionsfreies Schema (`10000 + medicationId * 100 + timeIndex`), reserviert 100 Zeitslots pro
   Medikament, kollidiert nicht mit den fixen Settings-Erinnerungs-IDs (1-7).
3. **Fehlender Cancel bei Löschen/Deaktivieren behoben.** Weder Medikament löschen noch
   deaktivieren hat bisher die zugehörigen geplanten Erinnerungen entfernt — sie feuerten
   unverändert weiter. Gelöst nicht durch gezieltes Cancel pro Medikament, sondern strukturell:
   neuer zentraler Helper `rescheduleAllNotifications()`
   (`core/notifications/notification_scheduler.dart`) baut bei jeder relevanten Änderung *alle*
   geplanten Erinnerungen aus dem aktuellen DB-/Prefs-Zustand neu auf (`NotificationService.
   rescheduleAll()` cancelt zuerst alles, liest dann `getActiveMedications()` frisch aus der DB und
   plant nur noch für tatsächlich aktive Medikamente). Aufgerufen nach Medikament hinzufügen/
   löschen/(de)aktivieren (`my_substances_tab.dart`) UND nach jedem Settings-Notification-Toggle
   (`settings_screen.dart`) — vorher rief `_reschedule()` in den Settings sogar versehentlich
   `cancelAll()` auf, ohne die pro-Medikament-Erinnerungen je neu zu planen, ein bislang
   unbemerkter Nebenschaden des ursprünglichen Designs.
4. **Tote Supplement-/Wasser-/Todo-/Zyklus-Erinnerungen jetzt echt verdrahtet.** Die Settings-Toggles
   existierten bereits vollständig in der UI (inkl. gespeicherter Uhrzeit/Intervall/Vorlaufzeit),
   aber `NotificationService.rescheduleAll()` kannte bisher nur `notif_medication`/`_workout`/
   `_habit` — Supplement, Wasser, Todo und Zyklus taten beim Umschalten schlicht nichts. Fund beim
   Umsetzen entdeckt, nicht nur die im Plan genannten Todo/Wasser/Zyklus — Supplement war
   ebenfalls betroffen. Jetzt:
   - Supplement/Todo: normale tägliche `zonedSchedule`-Erinnerung wie Medikament/Training/Gewohnheit.
   - Wasser: `periodicallyShowWithDuration(Duration(minutes: notifWaterInterval))` mit
     `AndroidScheduleMode.inexactAllowWhileIdle` — bewusst *nicht* exakt: ein Wasser-Reminder
     braucht keine `SCHEDULE_EXACT_ALARM`-Berechtigung, ein paar Minuten Abweichung sind irrelevant.
   - Zyklus: einmalige (nicht tägliche) `zonedSchedule`-Erinnerung `notifPeriodDays` Tage vor
     `CycleCalculation.nextPeriodPredicted` (dieselbe Vorhersage, die auch die Homescreen-Widgets
     nutzen) — verschiebt sich jeden Zyklus neu, im Gegensatz zu den echten Tages-Erinnerungen.
5. **Sichtbare Warnung bei fehlender Benachrichtigungs-Berechtigung.** Vorher: ein Toggle in den
   Einstellungen wirkte aktiviert, aber ohne OS-Berechtigung feuerte nie etwas — stilles Scheitern.
   `NotificationService.hasPermission()` (Wrapper um `Permission.notification.status`) wird nach
   jedem Reschedule geprüft; `_NotificationsSection` zeigt bei aktivierten, aber nicht erlaubten
   Erinnerungen eine persistente Warnkarte mit Link zu den Systemeinstellungen, zusätzlich eine
   SnackBar direkt nach dem auslösenden Toggle (Settings) bzw. nach Medikament-Hinzufügen
   (`my_substances_tab.dart`).
6. **Reschedule-Fehler dürfen nie eine primäre Nutzeraktion crashen.** `rescheduleAllNotifications()`
   fängt jeden internen Fehler ab (`debugPrint`, kein Rethrow) — Erinnerungen sind eine
   Zusatzfunktion zu „Medikament speichern/löschen“, kein Blocker dafür. Beim Testen sichtbar
   geworden: zwei bestehende Widget-Tests (`my_substances_tab_test.dart`,
   `substance_add_flow_test.dart`) hatten kein `sharedPreferencesProvider`-Override, weil sie vor
   dieser Änderung nie einen Preferences-Pfad berührten — mit dem Try/Catch bleiben sie unverändert
   grün, statt jeden Testaufbau einzeln um Prefs-/Plugin-/Timezone-Mocking zu erweitern.

**schemaVersion unverändert (28) — reine Verhaltens-/Logikänderung, kein Schema-Fund.**
`flutter analyze` → **0 Issues**. `flutter test` → **514/514 grün** (498 vorher + 16 neu:
`test/core/security/pin_service_test.dart` deckt die komplette Lockout-Eskalation inkl.
„Sperre wird durch weitere Fehlversuche nicht verlängert“ und Reset bei Erfolg/`save()`/`clear()`
ab; `test/core/notifications/notification_service_test.dart` deckt `medicationReminderId`-
Determinismus/Kollisionsfreiheit und `hasPermission()` über alle drei relevanten
`PermissionStatus`-Fälle ab).

**Nicht in dieser Runde umgesetzt (bewusst, kein Bug):** Ein Medikament *bearbeiten* (Zeiten
ändern) existiert in der UI noch nicht — nur Hinzufügen/Löschen/(De-)Aktivieren — daher gab es
auch keinen „Reschedule nach Edit“-Fall zu behandeln.

**Nächste Phase laut Plan:** Phase 3 — Unsichtbare Backend-Fixes (fehlender Index auf
`transactions(date)`, `PRAGMA journal_mode=WAL`, `markerSearchProvider` auf `.autoDispose`,
Health-Score Tag-/Wochenziel-Vergleich + `Future.wait`-Parallelisierung, Budget-Verlaufschart-
Kontofilter-Konsistenz) — sobald Phase 1 (Backup-Performance) und Phase 2 (diese Runde) vom Nutzer
am echten Gerät bestätigt sind.

---

## ⏩ VORHERIGER STAND (2026-08-07 — v0.9.9, Hotfix #5: JSON-Metadaten waren trotz v0.9.8 weiter komprimiert + Root-Cause-Grenze via Emulator gefunden)

**Direktes Nutzer-Feedback zu v0.9.8: "Wird gepackt…" hing weiterhin, obwohl die Datenmenge laut
eigener Einschätzung klein war (wenige Videos, insgesamt < 500 MB). Diesmal nicht weiter aus dem
Code geraten, sondern auf explizite Anweisung des Nutzers ein Android-Emulator gestartet und mit
echten ~363 MB Test-Videos live per `adb logcat` gemessen.**

**Root Cause #1 (echter Bug, gefunden):** `_encodeBackupArchive` setzte `compress = false` in
v0.9.8 nur auf den Medien-`ArchiveFile`s — der JSON-Metadaten-Eintrag (bei diesem Testfall
28,3 MB) blieb weiterhin per DEFLATE komprimiert. `archive`s DEFLATE ist eine reine
Dart-Implementierung ohne native zlib-Anbindung — auch bei einem mittelgroßen JSON-Blob allein
schon mehrere Sekunden zusätzlich. Fix: `..compress = false` jetzt auch auf dem JSON-Eintrag.

**Root Cause #2 (strukturelle Grenze, kein Bug):** Nach dem Fix blieb die Emulator-Messung bei
~15,6 s für 363 MB Payload (`[backup] zip encoded (+15624ms total)`). Quellcode-Prüfung von
`archive` (`zip_encoder.dart`, `crc32.dart`) bestätigt: **CRC32 wird für jeden ZIP-Eintrag immer
berechnet, unabhängig von `compress`** — das ist Pflicht im ZIP-Format, nicht optional, und läuft
ebenfalls als reine, tabellenbasierte Dart-Implementierung (kein natives Hardware-CRC32). Das ist
der verbleibende, durch dieses Feature nicht weiter wegoptimierbare Kostenfaktor — proportional
zur tatsächlichen Mediengröße.

**Versuch einer echten Release/AOT-Vergleichsmessung auf dem Emulator scheiterte an einer
Sicherheitsgrenze, nicht an einem Fehler:** `run-as` (nötig, um Testdaten in den App-Ordner zu
injizieren) funktioniert nur bei debuggable Builds, ein echter `--release`-Build lehnt das korrekt
mit "package not debuggable" ab; `adb root` schlägt auf diesem (nicht gerooteten) AVD-Image mit
"cannot run as root in production builds" fehl. Damit lässt sich auf diesem Emulator-Setup keine
faire Release-Zeitmessung erzwingen. Die 15,6 s sind eine **Debug/JIT-Messung** — laut
Non-Negotiable #18 läuft Debug „um ein Vielfaches langsamer" als Release/AOT; der reale Wert auf
einem echten Gerät im Release-Modus (wie es Nutzer tatsächlich installieren) sollte spürbar
niedriger liegen, konnte aber in dieser Runde nicht mehr selbst gemessen werden.

**Diagnose-Logging bewusst NICHT wieder entfernt:** die `debugPrint('[backup] …')`-Zeilen in
`_encodeBackupArchive`/`buildBackupZip` waren ursprünglich als temporär gedacht, bleiben jetzt
aber dauerhaft im Code — es gibt keine Crash-Reporting-Infrastruktur (siehe Phase 9, noch offen),
und genau diese Stelle wird mit wachsender Datenmenge am ehesten wieder diagnosebedürftig.
`debugPrint` kostet praktisch nichts.

`flutter analyze` → **0 Issues**. `flutter test` → **498/498 grün** (unverändert — reine
Kompressions-Verhaltensänderung + Logging-Ergänzung, vom bestehenden Medien-Roundtrip-Test
weiterhin abgedeckt).

**Für dich zu prüfen und zurückzumelden, damit Phase 1 endgültig abgeschlossen werden kann:**
Nach dem Update ein Backup mit deinen echten Fotos/Videos exportieren und die tatsächliche Dauer
der "Wird gepackt…"-Phase auf deinem echten Gerät (Release-Build, kein Emulator) zurückmelden.
Falls es jetzt spürbar schneller ist (Sekunden statt Minuten) gilt Phase 1 als abgeschlossen und
Phase 2 (Sicherheit & Erinnerungen: PIN-Lockout, Medikamenten-Notification-Kollision,
Benachrichtigungs-Berechtigungsprüfung, tote Todo/Wasser/Zyklus-Erinnerungen) startet als
nächstes. Falls es weiterhin spürbar hängt: bitte möglichst genau angeben, wie viele Fotos/Videos
und wie groß in etwa (Systemeinstellungen → Apps → Traum → Speicher zeigt die App-Datengröße).

---

## ⏩ VORHERIGER STAND (2026-08-06 — v0.9.8, Hotfix #4: "Wird gepackt…" dauerte weiter Minuten)

**Direktes Nutzer-Feedback zu v0.9.7: Das Sammeln der Daten war jetzt schnell (Marker-Filter
wirkt), aber die Phase "Wird gepackt…" hing weiterhin ein bis zwei Minuten.**

**Root Cause:** `ZipEncoder().encode(archive)` komprimiert standardmäßig JEDEN Eintrag per
DEFLATE — auch Fotos (JPEG) und Videos (MP4), die bereits komprimierte Formate sind. DEFLATE auf
bereits komprimierten Binärdaten bringt praktisch keine Größenersparnis, kostet aber echte
CPU-Zeit — bei einer größeren Tagebuch-/Foto-Bibliothek war genau das jetzt der letzte
verbleibende Engpass, nachdem v0.9.7 die eigentliche Datenmenge (JSON + Zeilenzahl) bereits
drastisch reduziert hatte.

**Fix:** `ArchiveFile.compress = false` für alle Medien-Einträge in `_encodeBackupArchive`
(`backup_service.dart`) — Fotos/Videos werden im ZIP nur noch gespeichert (STORE), nicht mehr
komprimiert. Nur der JSON-Metadaten-Eintrag (Text, komprimiert gut) bleibt wie gehabt per DEFLATE
komprimiert. Entpacken funktioniert transparent für beide Modi (verifiziert: Medien-Rückgabe-Test
mit echten Foto-Bytes lief unverändert grün).

`flutter analyze` → **0 Issues**. `flutter test` → **498/498 grün** (unverändert — reine
Kompressions-Verhaltensänderung, keine neue Testinfrastruktur nötig, bestehender Medien-Roundtrip-
Test deckt es ab).

**Lehre, wieder für spätere Phasen:** Bei binären, bereits komprimierten Medien in Archiven immer
`compress = false` setzen — DEFLATE auf JPEG/MP4/PNG/ZIP-artigen Formaten ist reine
CPU-Verschwendung, unabhängig vom konkreten Feature.

---

## ⏩ VORHERIGER STAND (2026-08-06 — v0.9.7, Hotfix #3: Backup dauerte mehrere Minuten)

**Direktes Nutzer-Feedback zu v0.9.6: Backup lief jetzt zuverlässig durch, dauerte aber mehrere
Minuten — Wunsch nach echtem Fortschrittsbalken statt Spinner UND spürbar schnellerer Erstellung.**

**Root Cause der Langsamkeit, zwei Anteile:**
1. **Übersehener Rest-Bug aus v0.9.5/v0.9.6:** Nur die ZIP-Kompression lief bereits im
   Hintergrund-Isolate — die JSON-Kodierung des kompletten `tables`-Objekts
   (`const JsonEncoder().convert(backup)`) lief weiterhin synchron auf dem Haupt-Isolate, *bevor*
   `compute()` überhaupt aufgerufen wurde. Bei einer Datenbank mit hunderttausenden Zeilen ist
   genau das der dominante Kostenfaktor, nicht die ZIP-Stufe.
2. **Der eigentliche Umfang:** Die ~496.000 bulk-importierten Türme-/Lost-Places-Marker (aus
   `towers.tsv`/`lost_places.json`) machen die überwältigende Mehrheit der Datenbank aus und
   wurden bei *jedem* Backup vollständig mitgesichert — obwohl sie bei einer Neuinstallation
   ohnehin automatisch neu geseedet werden.

**Fix:**
1. Neue kombinierte Isolate-Funktion `_encodeBackupArchive` in `backup_service.dart` macht JSON-
   Kodierung UND ZIP-Kompression in einem `compute()`-Aufruf — nichts Synchrones bleibt mehr auf
   dem Haupt-Isolate.
2. **Gefilterte `map_markers`-Abfrage** (`_tableWhereClauses`): unveränderte Bulk-Marker (kein
   `osm_id`/`external_id` UND leere Notiz UND leere Hashtags UND keine Bewertung UND nicht
   ausgeblendet UND kein Foto) werden vom Voll-Backup ausgeschlossen. **Alles vom Nutzer
   Bearbeitete bleibt erhalten** — Nutzer hat vor der Umsetzung bestätigt, dass er einzelne Marker
   fotografiert/bearbeitet hat, daher bewusst nicht pauschal ausgeschlossen, sondern anhand
   `note`/`hashtags`/`rating`/`is_hidden`/vorhandener `marker_photos`-Zeile gefiltert. Neuer Test
   (`buildBackupZip keeps custom and user-touched markers, drops untouched bulk-imported ones`)
   verifiziert genau diese vier Fälle (unverändert / bewertet / fotografiert / rein eigener
   Marker).
3. **Echter horizontaler Fortschrittsbalken** (`_BackupProgressBar`, `LinearProgressIndicator`)
   ersetzt den rotierenden Spinner — mit echten Phasen: "Daten werden gelesen (X/Y Tabellen)",
   "Fotos/Videos werden gelesen (X/Y)", "Wird gepackt…" (letzteres zwangsläufig unbestimmt, da ein
   einzelner atomarer Isolate-Aufruf). `buildBackupZip`/`buildBackupFile` haben dafür
   `onTableProgress`/`onMediaProgress`/`onEncodingStart`-Callbacks bekommen.

`flutter analyze` → **0 Issues**. `flutter test` → **498/498 grün** (497 vorher + 1 neuer
Marker-Filter-Test).

**Für spätere Phasen wichtig:** Dasselbe Muster (bulk-importierte, re-seedbare Referenzdaten nicht
blind in jedes Voll-Backup packen) könnte künftig auch für die Substanzen-Referenz-DB relevant
werden, falls die je Teil des generischen Backups würde — aktuell ist sie eine separate,
schreibgeschützte sqlite3-Datei außerhalb von Drift und dadurch ohnehin nicht betroffen.

---

## ⏩ VORHERIGER STAND (2026-08-06 — v0.9.6, Hotfix #2: Ladedialog blieb nach dem Speichern offen)

**Direktes Nutzer-Feedback zu v0.9.5: Backup-Export fror nicht mehr ein, aber nach dem Speichern
der Datei schloss sich der Ladedialog nicht mehr.**

**Root Cause:** Der Ladedialog wartete in v0.9.5 weiterhin auf das `await` von
`SharePlus.instance.share(...)` — und genau dieser Completion-Callback ist auf Android über
`Intent.createChooser`-Ergebnisse unzuverlässig: manche „Speichern unter…"-Ziele (Dateien-App,
Drive, etc.) melden ihr Fertigsein nie zuverlässig an die aufrufende App zurück, selbst wenn der
Nutzer die Datei erfolgreich gespeichert hat. Der Ladedialog hing dadurch auf `await` fest.

**Fix:** Baustein „ZIP bauen" (isoliert, begrenzt, bereits über `compute()` entkoppelt) und
Baustein „Teilen-Sheet öffnen" (natives OS-UI, Abschluss nicht zuverlässig beobachtbar) in
`backup_service.dart` sauber getrennt: `buildBackupFile()`/`buildModulesFile()` bauen nur noch die
Datei, `shareFile()` öffnet das Teilen-Sheet **unawaited** und getrennt vom Ladedialog. Der
Ladedialog schließt jetzt direkt, nachdem die Sicherung fertig auf der Platte liegt — unabhängig
davon, was der Nutzer im nachfolgenden Teilen-Dialog tut. `exportBackup()`/`exportModules()`
bleiben als dünne Wrapper für Aufrufer, die die zwei Schritte nicht getrennt steuern müssen.

`flutter analyze` → **0 Issues**. `flutter test` → **497/497 grün**.

**Lehre für die verbleibenden Phasen:** Bei jedem Feature, das einen OS-Share-/Save-Dialog
anstößt, den Abschluss dieses Dialogs NICHT als Signal für „App-Arbeit fertig" verwenden — nur den
eigenen, deterministischen Teil (Datei bauen) an Ladeanzeigen koppeln.

---

## ⏩ VORHERIGER STAND (2026-08-06 — v0.9.5, Hotfix: Backup fror App ein)

**Direktes Nutzer-Feedback zu v0.9.4: Backup-Export ließ die App manchmal einfrieren/abstürzen,
manchmal war unklar, ob und wohin die Sicherung gespeichert wurde.**

**Root Cause:** `ZipEncoder().encode(...)` (Export) und `ZipDecoder().decodeBytes(...)` (Import)
sind synchrone, CPU-gebundene Aufrufe — liefen bislang direkt auf dem UI-Isolate. Bei vielen/
großen Fotos blockierte das die App für die gesamte Dauer der Kodierung: kein Rendering, keine
Touch-Events — sah aus wie ein Absturz, war bei Android teils sogar einer (ANR-Kill bei zu langer
Nicht-Reaktion).

**Fix:**
1. Die eigentliche ZIP-Kodierung/-Dekodierung läuft jetzt über `compute()` in einem
   Hintergrund-Isolate (`_encodeZipArchive`/`_decodeZipArchive`, top-level Funktionen in
   `backup_service.dart`) — an allen drei Stellen: Voll-Backup, CSV-Selektiv-Export, Import.
   DB-/Datei-Lesevorgänge (bereits async) bleiben auf dem Haupt-Isolate, nur die synchrone
   Kodierung wandert rüber.
2. Blockierender Fortschritts-Dialog (`_showBackupProgressDialog`/`_hideBackupProgressDialog`,
   freistehende Funktionen in `settings_screen.dart`, genutzt von `_SecuritySectionState` UND
   `_ExportSheetState`) ersetzt die bisherige kurze SnackBar — mit Hinweistext, dass danach der
   native Teilen-Dialog kommt, um den Speicherort zu wählen (der existierte schon immer, kam aber
   nie sichtbar an, weil die App vorher eingefroren war).
3. `importBackup()` in `backup_service.dart` in `pickBackupFile()` (Datei-Auswahl) +
   `restoreFromBytes()` (der eigentlich langsame Teil) aufgeteilt, damit der Ladedialog nur um den
   tatsächlich langsamen Teil läuft, nicht um die native Datei-Auswahl-UI.

`flutter analyze` → **0 Issues**. `flutter test` → **497/497 grün** (unverändert — die
Backup-Roundtrip-Tests aus v0.9.4 laufen weiterhin korrekt über die neuen `compute()`-Pfade,
zusätzlicher gezielter Isolate-Test wäre Overkill für reines Threading-Verhalten).

---

## ⏩ VORHERIGER STAND (2026-08-06 — v0.9.4, Datensicherheit: Diary-Duplikate + Migrationskette)

**Erste Phase eines mehrteiligen Nacharbeitungs-Plans aus einem umfassenden Tiefenaudit (5 Analyse-Runden via graphify/claude-mem über die gesamte App: Architektur, alle 19 Module, Übersetzung, Performance, Sicherheit, Speicherlecks, Tests, Crash-Reporting, Backup, Barrierefreiheit, Berechtigungen, Release-Konfiguration, DB-Migrationen, Provider-Korrektheit, Suche). Plan liegt in `C:\Users\Lupus\.claude\plans\schaue-dir-mithilfe-von-agile-wozniak.md`, priorisiert in 9 Phasen. Diese Runde: Phase 1 — Datensicherheit.**

1. **Tagebuch-Duplikat-Bug (kritisch) behoben.** `upsertEntry` war kein echtes Upsert — kein
   Unique-Index, `id` wurde nie mitgegeben, daher legte Drift bei jedem Speichern eine neue Zeile
   an. Ein Doppel-Tap auf „Foto"/„Video" (kein Debounce) konnte zwei Einträge für denselben Tag
   erzeugen. Fix: `uniqueKeys => [{diaryId, date}]` direkt auf `DiaryEntries` (wirkt für
   Neuinstallationen/Tests über `createAll()`), `DiaryDao.upsertEntry` nutzt jetzt ein echtes
   `insert(..., onConflict: DoUpdate(..., target: [diaryId, date]))`. `_TodayEmptyCard` in
   `diary_screen.dart` ist jetzt ein `StatefulWidget` mit `_busy`-Guard gegen den Doppel-Tap.
   `diary_entry_screen.dart` behandelt `snapshot.hasError` jetzt getrennt von „kein Eintrag".
2. **🔴 Echter, bisher unbekannter Absturz-Bug in der Migrationskette gefunden — nicht nur ein
   Testartefakt.** Beim Schreiben eines Migrationstests, der den kompletten Pfad von Schema v1
   bis zur aktuellen Version in einem Rutsch durchspielt (`test/data/database/
   legacy_v1_migration_test.dart` — bislang startete kein Migrationstest vor v22), schlug die
   Migration bei `workout_day_exercises.notes` mit „duplicate column name" fehl.
   **Ursache, grundsätzlich:** `migrator.createTable(x)` legt eine Tabelle immer nach der
   HEUTIGEN, vollständigen Dart-Schema-Definition an — nicht nach dem historischen Stand zum
   Zeitpunkt des jeweiligen `if (from < N)`-Schritts. Bei normalen, inkrementellen Updates (ein
   Release nach dem anderen) fällt das nie auf, weil die zum Build-Zeitpunkt „heutige" Definition
   jeweils der historisch richtigen entspricht. Ein Gerät, das aber viele Versionen auf einmal
   überspringt (z.B. eine seit v0.2.x nie aktualisierte Installation), trifft auf ein frühes
   `createTable`, das Spalten schon enthält, die ein *späterer* Schritt per `addColumn`
   nachträgt — Absturz, App bliebe **dauerhaft startunfähig**.
   Fix: neuer Helfer `_addColumnIfMissing(migrator, table, column, columnName)` (prüft
   `pragma_table_info` vorher, exakt das Muster, das für `osm_id`/`external_id` schon galt) an
   allen ~14 betroffenen `addColumn`-Stellen von v3 bis v22. Migrationstest deckt jetzt den
   kompletten Pfad v1→v28 ab, inkl. Datenerhalt (Bestandszeilen überleben mit korrekten
   Spalten-Defaults) und Endzustand-Prüfung (Diaries-Tabelle, neue Indizes, alte Substanz-DB
   gedroppt).
3. **`android:allowBackup="false"`** gesetzt (+ `fullBackupContent="false"`) — ohne das hätte
   Androids automatisches Cloud-Backup die komplette `traum.sqlite` (Tagebuch-, Zyklus-,
   Substanz-, Finanzdaten) unverschlüsselt mitgesichert, unabhängig vom eigenen In-App-Backup.
4. **Backup-Medienliste erweitert:** `photo_logs.image_path` (Gesundheits-Verlaufsfotos) und
   `transactions.receipt_image_path` (Belegfotos) waren in `BackupService._mediaColumns` nicht
   gelistet — die Dateien selbst wurden beim Export nicht mitgebündelt, nur die (dann ins Leere
   zeigenden) Pfade. Neuer Test bestätigt den Round-Trip beider Felder.
5. **Video-Thumbnail-Backfill:** neuer, einmaliger `DiaryThumbnailBackfill.runIfNeeded()`
   (App-Start, analog zu den bestehenden Seedern) trägt Vorschaubilder für Video-Einträge nach,
   die vor v0.8.9 angelegt wurden und bislang dauerhaft den Platzhalter zeigten.
6. **Performance-Index ergänzt:** `idx_diary_entries_diary_created` auf
   `(diary_id, created_at)` — bislang Tabellenscan bei `getRecentEntries`/`getLastEntry`/
   `getDatesLastYear`.

**schemaVersion 27→28.** `flutter analyze` → **0 Issues**. `flutter test` → **497/497 grün**
(494 vorher + 3 neu: Migrationstest v1→v28, Upsert-Dedup-Test, Backup-Medientest).

**Nächste Phase laut Plan:** Sicherheit & Erinnerungen (PIN-Lockout, Medikamenten-Notification-
Kollision, Benachrichtigungs-Berechtigungsprüfung, tote Todo/Wasser/Zyklus-Erinnerungen).

---

## ⏩ VORHERIGER STAND (2026-08-05 — v0.9.3, SVG-Rahmen-Fix + Versionierungsregel)

**Fund: die vier in v0.8.12 eingebauten SVG-Referenzvorlagen zeigten nur den Umriss, keine
gefüllte Fläche — sichtbar z.B. an der Ganzkörper-Vorlage, die als reine Kontur statt als
Silhouette erschien.**

Ursache: Die vom Bildkonvertierungsdienst gelieferten SVGs enthalten (typisch für
potrace-artige Tools) ein ganzflächiges Rahmen-Rechteck als **erste Teilkontur** innerhalb
desselben `<path>`-Elements wie die eigentliche Silhouette, verbunden über `z m…` (Closepath +
neuer relativer Moveto). Mit `fill-rule="nonzero"` ergibt das: der Rahmen wird gefüllt, die
eigentliche Silhouette bleibt als **Loch** ausgespart — exakt umgekehrt zu dem, was gebraucht
wird. Fix: das Rahmen-Teilstück aus dem ersten `<path>` jeder Datei entfernt (Bounding-Box-Skript
zur Verifikation: `analyze.js`, Node), den direkt folgenden relativen `m…`-Befehl in einen
absoluten `M…` umgerechnet, alle weiteren `<path>`-Elemente unverändert gelassen (die hatten den
Rahmen nie). Betrifft `assets/reference_templates/*.svg` — jetzt füllt die Kontur selbst die
Fläche, kein Rahmen mehr im Bild.

**Neue Versionierungsregel (Non-Negotiable #17 aktualisiert):** Patch-Ziffer läuft nur 0–9, danach
Minor-Sprung (`0.9.9` → `0.10.0`, nicht `0.9.10`) — der Build-Zähler läuft unabhängig davon
einfach weiter. Rückwirkend angewendet auf die zuvor als `0.8.10`/`0.8.11`/`0.8.12` bezeichneten
Zwischenstände ergibt das lückenlos `0.9.0`/`0.9.1`/`0.9.2` — dieser Fund-Release ist entsprechend
**v0.9.3**.

`flutter analyze` → **0 Issues**. `flutter test` → **494/494 grün** (unverändert — reine
Asset-Korrektur ohne Code-Logikänderung).

---

## ⏩ VORHERIGER STAND (2026-08-05 — v0.8.12, echte SVG-Referenzvorlagen + Deckkraft-Regler)

**Zwei Nachbesserungen aus dem Feedback zu v0.8.11:**

1. **Die vier festen Referenz-Vorlagen (Ganzkörper, Gesicht, zwei Gesichter, Essen) waren bis
   v0.8.11 freihändig nachgezeichnete `CustomPainter`-Linienzeichnungen — der Nutzer fand sie zu
   kantig und nicht nah genug am Original. Er hat die vier Original-Vorlagen als potrace-artig
   vektorisierte SVGs geschickt (via Bildkonvertierungsdienst). Neu: `assets/reference_templates/`
   (`body_full.svg`, `face_single.svg`, `faces_two.svg`, `food.svg`) — unverändert übernommen
   (nur die Zuordnung Datei→Vorlage wurde anhand der Pfad-Bounding-Boxen verifiziert, z. B. beim
   Essen: zwei schmale hohe Formen = Gabel/Messer, zwei zentrierte runde Formen = Teller-Ringe).
   `reference_templates.dart` rendert sie jetzt über `SvgPicture.asset` mit weißem
   `ColorFilter` (`BlendMode.srcIn`) statt eigener Pfad-Berechnung — die vier
   `CustomPainter`-Klassen sind komplett entfallen.
2. **Deckkraft war fest auf 35 % verdrahtet** (bewusste Entscheidung vor der ersten
   Umsetzung) — nach dem ersten Test doch als Regler gewünscht. `OverlayCameraScreen` hat jetzt
   einen `Slider` (10–90 %, Default weiterhin 35 %) unterhalb der Vorlagen-Leiste, wenn eine
   Referenz aktiv ist; `ReferenceOverlayLayer` nimmt `opacity` als Parameter statt es intern
   festzulegen.

`flutter analyze` → **0 Issues**. `flutter test` → **494/494 grün** (unverändert).

---

## ⏩ VORHERIGER STAND (2026-08-05 — v0.8.11, Diary-Umschalter-Button + feste Referenz-Vorlagen)

**Nutzer-Feedback nach dem ersten Gerätetest von v0.8.10, zwei Punkte:**

1. **Tagebuch-Umschalter war nicht auffindbar genug.** Nur der Titel-Text selbst war tippbar,
   ohne jeden visuellen Hinweis darauf. Neu: `_DiarySwitchAvatar` in `diary_screen.dart` — ein
   44×44-Icon-Button **vor** dem Namen (Tagebuch-Icon in Akzentfarbe + kleines Swap-Symbol als
   Badge unten rechts), macht auf den ersten Blick klar, dass hier eine wechselbare Identität
   sitzt. Öffnet denselben Umschalter wie der Titel-Tap.
2. **Referenz-Overlay hatte nur den Geist des letzten Fotos — die ursprünglich gezeigten festen
   Vorlagen (Ganzkörper, Gesicht, zwei Gesichter, Essen) fehlten.** Bei der Brainstorming-Frage
   vor der Umsetzung hatte sich der Nutzer zunächst nur für "Geist-Overlay" entschieden; nach dem
   ersten Test wollte er zusätzlich die festen Vorlagen aus den Referenzbildern. Neu:
   `lib/core/camera/reference_templates.dart` — `ReferenceOverlayMode`-Enum
   (`off, lastPhoto, bodyFull, faceSingle, facesTwo, food`), die vier festen Vorlagen sind reine
   `CustomPainter`-Linienzeichnungen (keine Rasterbilder/Emojis — bleiben in jeder Auflösung
   scharf): Ganzkörper-Silhouette (per Punktliste + Achsenspiegelung), Gesichts-Umriss
   (Haaransatz + Ohren), zwei Gesichter nebeneinander (das zweite mit Dutt zur Unterscheidung),
   Teller mit Gabel/Messer. `OverlayCameraScreen` zeigt jetzt eine horizontale Icon-Leiste mit
   allen verfügbaren Optionen direkt sichtbar (nicht hinter einem Menü versteckt) statt des
   vorherigen einzelnen "Referenz an/aus"-Chips; "Letztes Foto" erscheint darin nur, wenn es
   tatsächlich ein vorheriges Foto in diesem Tagebuch gibt.

`flutter analyze` → **0 Issues**. `flutter test` → **494/494 grün** (unverändert — reine
UI-Ergänzung, keine neue Testinfrastruktur nötig).

---

## ⏩ VORHERIGER STAND (2026-08-05 — v0.8.10, Mehrfach-Tagebücher + Kamera-Referenz-Overlay)

**Zwei Features auf Nutzerwunsch: mehrere parallele Tagebücher statt einem einzigen, und eine
eigene Kamera-Aufnahme mit Referenz-Overlay für konsistente Foto-/Video-Ausrichtung über die
Zeit.**

1. **Mehrfach-Tagebücher.** Neue `Diaries`-Tabelle (`id, name, iconName, colorHex, sortOrder,
   createdAt`), `DiaryEntries` bekommt eine `diaryId`-Fremdschlüsselspalte (nullable angelegt —
   SQLite erlaubt `ALTER TABLE ADD COLUMN NOT NULL` nur mit statischem Default, ungeeignet für
   eine FK-ID; die App setzt beim Anlegen eines Eintrags immer einen Wert).
   **schemaVersion 26→27:** legt `diaries` an, fügt ein Default-Tagebuch "Mein Tagebuch" ein und
   befüllt `diary_id` bei allen Bestandseinträgen zurück (`_migrateToMultipleDiaries` in
   `traum_database.dart`). Neuinstallationen laufen nicht durch die Migration — dafür sorgt
   `DiarySeeder.seedIfNeeded` (in `main.dart`, neben den anderen Seedern) für dasselbe
   Default-Tagebuch.
   Neuer `DiariesDao` + `DiaryRepository` (kapselt jetzt auch `DiaryDao` — das Feature griff
   bisher direkt auf den DAO zu, eine Abweichung von Non-Negotiable #5, die dabei mit behoben
   wurde). Alle `DiaryDao`-Methoden sind jetzt `diaryId`-scoped. `activeDiaryProvider` ist
   **persistiert** (`PreferencesRepository.activeDiaryId`, Default 1) — anders als das
   In-Memory-Vorbild `activeCollectionProvider` der Graffiti-Map, das Vorbild für den
   Umschalter-Aufbau war.
   UI: Titel im Tagebuch-Header ist jetzt antippbar und öffnet ein Umschalter-Sheet
   (Icon/Farbe/Name/Eintragszahl je Tagebuch, Häkchen beim aktiven, "+ Neues Tagebuch"), plus
   `diary_edit_sheet.dart` zum Anlegen/Bearbeiten (Name, Icon- und Farbraster nach dem Vorbild
   von `create_collection_screen.dart`) und Löschen (gesperrt beim letzten verbleibenden
   Tagebuch, räumt vor dem DB-Löschen auch die Medien-Dateien auf der Festplatte auf).
2. **Kamera-Referenz-Overlay.** Aufnahmen liefen bisher komplett über `image_picker`, das nur
   die native Kamera-App öffnet — darüber lässt sich kein Flutter-Overlay legen. Neu:
   `lib/core/camera/overlay_camera_screen.dart` mit einer eigenen Live-Vorschau
   (`camera`-Package, neue Abhängigkeit), bewusst feature-unabhängig gehalten (kein Import aus
   `features/`), damit sie später auch außerhalb des Tagebuchs nutzbar ist (z. B.
   Fortschrittsfotos).
   Zeigt beim Aufnehmen das letzte Foto/Video-Vorschaubild **desselben Tagebuchs** halbtransparent
   (fest 35 % Deckkraft) über der Live-Vorschau, dazu ein Drittel-Raster und ein
   Referenz-an/aus-Chip zum kurzen Ausblenden. `DiaryCameraService.capturePhoto`/`captureVideo`
   öffnen bei `ImageSource.camera` jetzt diesen Screen statt `image_picker`; die Galerie-Auswahl
   bleibt unverändert über `image_picker` (dort gibt es keine Live-Vorschau, über die sich ein
   Overlay legen ließe). Video-Aufnahme braucht `RECORD_AUDIO`
   (Android)/`NSMicrophoneUsageDescription` (iOS) — neu ergänzt, `CAMERA`/
   `NSCameraUsageDescription` existierten bereits. Berechtigungsabfrage nach dem etablierten
   Muster aus `onboarding_screen.dart` (Status prüfen, bei `isPermanentlyDenied` →
   `openAppSettings()`, sonst `request()`).
   **Nicht auf echtem Gerät getestet** — Kamera-Hardware/-Verhalten im Android-Emulator ist
   unzuverlässig bis nicht vorhanden. Noch zu prüfen: Berechtigungsdialog (erstmalig + dauerhaft
   verweigert → Einstellungen), Aufnahme (Foto/Video, max. 60 s), Lifecycle (App in
   Hintergrund/Vordergrund während offener Kamera), Kamera wechseln.
3. Migrationstest-Fixtures (`tower_migration_v24_test.dart`, `lost_place_migration_v25_test.dart`,
   `map_index_migration_v26_test.dart`, `substances_v23_migration_test.dart`) fehlte
   `diary_entries` — dieselbe Fallgrube wie bei `marker_photos` in einer früheren Runde (siehe
   Hinweis unten bei v0.8.2). Fixtures ergänzt, nicht die Migration aufgeweicht.

13 neue Tests (Migration v27, `DiariesDao`, `DiaryDao`-Scoping, `DiarySeeder`).
`flutter analyze` → **0 Issues**. `flutter test` → **494/494 grün**.

---

## ⏩ VORHERIGER STAND (2026-08-01 — v0.8.9, Video-Vorschaubilder, sichtbare Fehler, APK-Größe)

**Vier Themen in dieser Runde.**

1. **Video-Vorschaubilder im Tagebuch — Funktionslücke geschlossen.** `diary_capture_sheet.dart`
   setzte `thumbnailPath` beim Speichern **immer** auf `null`; Video-Einträge hatten deshalb nie
   ein Vorschaubild (die Liste zeigte den Platzhalter). Neu:
   `DiaryCameraService.generateVideoThumbnail()` (720 px JPEG nach
   `<support>/diary/thumbs/`), aufgerufen beim Speichern, wenn `mediaType == 'video'`.
   Schlägt es fehl → `null`, Eintrag bleibt speicherbar. `video_thumbnail` ist deshalb wieder
   Abhängigkeit (in v0.8.8 als ungenutzt entfernt — diesmal tatsächlich verdrahtet).
   **Offen:** Bereits vorhandene Video-Einträge bekommen **kein** Vorschaubild nachträglich —
   ein Backfill wäre ein eigener kleiner Auftrag.
2. **52 unsichtbare Fehlerzustände sichtbar gemacht.** In 25 Dateien stand
   `error: (_, _) => const SizedBox.shrink()` — ein gescheiterter Provider war damit von „noch
   keine Daten" nicht zu unterscheiden. Genau daran hing der „Budget-Screen ist schwarz"-Fehler,
   dessen Diagnose zwei Release-Runden gekostet hat (v0.7.27/28). Neu:
   `core/components/inline_error.dart` → `InlineError(e)`, ein 16-px-Symbol mit der Meldung im
   Tooltip (langes Drücken) **und** im Log (per `adb logcat` auffindbar). Bewusst nur ein Symbol,
   keine Textzeile: viele der Stellen sitzen in engen Zeilen/Kacheln.
   **Weiterhin offen:** 85 leere `catch (_) {}` — die verschlucken Fehler nach wie vor.
3. **Performance-Reste.**
   - `transaction_list_screen.dart` baute über `ListView(children: …)` **alle Transaktionen aller
     Monate** auf einmal — wächst mit jedem Nutzungsmonat. Jetzt `ListView.builder` über die
     Monatsgruppen; innerhalb eines Monats bewusst weiterhin eine `Column`, damit die Optik
     (eine abgerundete Karte je Monat) unverändert bleibt.
   - Der 36-MB-Lost-Places-Datensatz wird beim Erststart jetzt via `compute()` in einem
     Hintergrund-Isolate geparst und **dort schon** auf die Marker-Felder reduziert
     (`lost_place_row.dart`, Top-Level-Funktion — `compute` kann keine Closures übertragen).
     Vorher lagen 36-MB-String und der komplette JSON-Objektgraph gleichzeitig im UI-Isolate.
   - **Bewusst gelassen:** `jsonDecode` in vier `build()`-Methoden (u.a.
     `marker_detail_screen.dart`). Das sind Detailansichten mit wenigen Rebuilds; der nötige
     Cache-Zustand wäre mehr Fehlerrisiko als Gewinn.
4. **APK-Größe: der Brocken sind die nativen Bibliotheken, nicht die Assets.**
   Messung am v0.8.8-APK (`unzip -v`, gepackte Größen): **133 von 177 MB** sind native Libs für
   **drei** Architekturen — arm64-v8a 45,8 MB · armeabi-v7a 39,0 MB · x86_64 48,8 MB. Ein Gerät
   nutzt genau eine davon.
   **Korrektur einer früheren Annahme:** Die Assets sind unkritisch — im APK komprimiert nur
   ~29 MB gesamt (`substances_reference.sqlite3` 71 MB → 16,5 MB, `lost_places.json` 34 MB →
   5,5 MB, `towers.tsv` 22 MB → 6,6 MB). Die früher genannten „149 MB Assets" waren die
   **unkomprimierte** Größe und damit irreführend.
   → Releases werden jetzt mit `--split-per-abi` gebaut. **arm64-v8a ist die richtige Datei für
   jedes moderne Handy**; x86_64 wird nur für Emulatoren gebraucht.

`flutter analyze` → **0 Issues**. `flutter test` → **481/481 grün**.

**Noch offen:** 85 leere `catch (_) {}` · 105 veraltete Pakete (eigenes Vorhaben, Breaking
Changes möglich; die Kotlin-Plugin-Warnung beim Build kommt daher) · `dart format` über die
Codebasis (erzeugt ~1.200 geänderte Zeilen, gehört in einen eigenen Commit) · Backfill für
Vorschaubilder bestehender Video-Einträge.

---

## ⏩ VORHERIGER STAND (2026-08-01 — v0.8.8, Code-Audit: toter Code + Invalidierungs-Bug)

**Systematischer Audit über alle Module (Plan:
`docs/superpowers/plans/2026-08-01-code-audit-aufraeumen.md` im Haupt-Repo).**

1. **🔴 Bug behoben, der in v0.8.6 selbst verursacht wurde.** Beim Umstellen der Galerie auf
   `galleryMarkersProvider` wurde `activeMarkersProvider` zum Waisen: **von niemandem mehr
   beobachtet**, aber an neun Stellen weiterhin per `ref.invalidate()` angesprochen. Folge: nach
   Marker löschen / Bewertung ändern / Foto hinzufügen / Standort verschieben aktualisierten sich
   Karte und Galerie nicht mehr.
   Fix: Waisen-Provider gelöscht, neue zentrale Funktion `invalidateMarkerViews(WidgetRef)` in
   `graffiti_map_provider.dart` invalidiert **alle** abgeleiteten Provider (Viewport, Galerie,
   Kartenzentrierung, Hashtags). Alle Aufrufer darauf umgestellt.
   **Merke:** Wird ein Marker-Provider hinzugefügt, gehört er in diese eine Funktion — nicht in
   verstreute Einzelaufrufe. Genau daran ist es beim letzten Mal gescheitert.
2. **Ungenutzte Abhängigkeiten entfernt:** `lottie` und `video_thumbnail` — kein einziger Import
   in `lib/`. Bei `video_thumbnail` steckt eine **unbemerkte Funktionslücke** dahinter: das
   Tagebuch setzt `thumbnailPath` beim Anlegen immer hart auf `null`
   (`diary_capture_sheet.dart`), Video-Einträge haben also überhaupt kein Vorschaubild. Wer das
   nachrüsten will, braucht das Paket wieder.
   **Nicht entfernt:** `flutter_math_fork` — kein direkter Import, wird aber von
   `flutter_markdown_plus_latex` transitiv gebraucht.
3. **283 tote ARB-Schlüssel entfernt** (von 1.406 auf 1.123, ~20 %) — Überbleibsel entfernter
   Features. Vorgehen: Schlüssel gegen alle `.identifier`-Vorkommen in `lib/` **und** `test/`
   abgeglichen, entfernt, dann `flutter analyze` als Netz (hätte jeden noch benutzten Schlüssel
   sofort als Compile-Fehler gemeldet) → 0 Issues.
4. **`assets/svg/`** aus `pubspec.yaml` entfernt: die Körperkarte rendert aus eingebetteten
   Dart-Strings (`body_map_svg_data.dart`), die beiden Dateien wurden nie geladen.
   **Gegengeprüft und NICHT angefasst:** `assets/icons/progress/`, `assets/supplements/`,
   `assets/exercises/*.json` — die werden über zusammengesetzte Pfade (`'…/$key.svg'`) geladen
   und sehen bei einer reinen Dateinamen-Suche fälschlich ungenutzt aus.
5. **`mapModeLabel()`** in `map_tile_config.dart` gelöscht — hatte zwar einen Test, aber **keine
   einzige Aufrufstelle in der App**; der Test prüfte reinen toten Code und ist mit entfallen
   (daher 476 statt 477 Tests).

**Bewusst nicht gemacht:** `dart format` über die Codebasis — probeweise ausgeführt und wieder
verworfen, weil es **1.200 geänderte Zeilen in 5 Dateien** für eine 25-Zeilen-Änderung erzeugte
(das Projekt ist nicht durchgehend formatiert). Gehört, wenn überhaupt, in einen eigenen Commit.
Ebenso offen: 105 Pakete mit neueren Versionen.

`flutter analyze` → **0 Issues**. `flutter test` → **476/476 grün**.

---

## ⏩ VORHERIGER STAND (2026-08-01 — v0.8.7, Performance Phase 3: Übungs-Icons vorkompiliert)

**Fortsetzung der Performance-Arbeit (Plan:
`docs/superpowers/plans/2026-07-31-performance-optimierung.md` im Haupt-Repo).**

Die 838 bespoke Übungs-Icons lagen als SVG vor (~24 KB im Schnitt, größtes 57 KB, zusammen
20 MB) und wurden von `flutter_svg` **zur Laufzeit geparst** — beim Scrollen durch die
Übungsbibliothek/-auswahl also pro sichtbarer Zeile ein kompletter XML- und Pfad-Parse.

- **Vorkompiliert nach `.vec`** (Binärformat von `vector_graphics`, bereits geparst) mit dem
  ohnehin vorhandenen `vector_graphics_compiler`:
  ```
  dart run vector_graphics_compiler \
    --input-dir assets/exercises/icons_exercise \
    --out-dir assets/exercises/icons_exercise_vec
  ```
  Ergebnis: Das Parsen entfällt zur Laufzeit komplett — **das ist der eigentliche Gewinn.**
  **Nicht** der Speicherplatz: unkomprimiert sind es zwar 13 MB statt 20 MB, im APK ist das
  Ergebnis aber sogar minimal größer (177,2 statt 176,4 MB), weil SVG als XML sehr gut
  komprimiert (~5×) und das Binärformat kaum. Verifiziert per `unzip -l`: 838 `.vec` im APK,
  0 `.svg`.
- **Dateinamen:** Der Compiler hängt `.vec` an den vollständigen Quellnamen an →
  `<slug>.svg.vec` (nicht `<slug>.vec`).
- **Auslieferung:** `assets/exercises/icons_exercise/` (die .svg-Quellen) ist **nicht mehr** im
  `assets:`-Block von `pubspec.yaml` — sonst lägen beide Formate im Bundle (33 MB). Die Quellen
  bleiben im Repo, damit die .vec neu erzeugt werden können.
- `ExerciseIcon` nutzt für bespoke Icons jetzt `VectorGraphic(loader: AssetBytesLoader(...))`,
  für die 9 generischen Muskelgruppen-Icons weiterhin `SvgPicture` (winzig, kein Gewinn).
  `vector_graphics` ist dafür als direkte Abhängigkeit ergänzt (war vorher nur transitiv).
- **Testfalle beim Prüfen:** `SvgPicture` rendert intern selbst ein `VectorGraphic` — ein
  `find.byType(VectorGraphic)` matcht deshalb in **beiden** Fällen. Aussagekräftig ist die
  **Abwesenheit von `SvgPicture`**; genau so prüft der Test jetzt.
- Neuer Test stellt sicher, dass zu **jedem** Slug im generierten Manifest auch eine kompilierte
  `.vec` existiert — sonst fiele ein künftiger Icon-Batch erst zur Laufzeit als fehlendes Asset
  auf. **Nach jedem neuen Icon-Batch also den Compiler erneut laufen lassen.**

`flutter analyze` → **0 Issues**. `flutter test` → **477/477 grün**.

**Noch offen aus dem Plan:** 36-MB-JSON wird beim Erststart am Stück im UI-Isolate geparst ·
149 MB Assets inkl. 72-MB-DB, die beim ersten Start nochmal kopiert wird · 35 nicht-lazy Listen ·
`jsonDecode` in `build()` (u.a. `marker_detail_screen.dart`).

---

## ⏩ VORHERIGER STAND (2026-07-31 — v0.8.6, Performance Phase 2: fehlende DB-Indizes)

**Fortsetzung der Performance-Arbeit (Plan:
`docs/superpowers/plans/2026-07-31-performance-optimierung.md` im Haupt-Repo).**

**Der zentrale Fund: `map_markers` hatte keinen Index auf `collection_id`.** Die einzigen beiden
Indizes waren die Unique-Indizes für die Import-Deduplizierung (`osm_id`, `external_id`). Jede
Abfrage nach Sammlung war damit ein vollständiger Tabellenscan über 496.000 Zeilen — auch die
Kartenausschnitt-Abfrage, die bei **jedem Verschieben und Zoomen** läuft. `marker_photos.marker_id`
hatte ebenfalls keinen Index, obwohl die Foto-Batch-Abfrage der Kartenansicht genau darauf filtert.

An der echten Geräte-Datenbank gemessen (identisches Ergebnis, 1355 Zeilen):
`SCAN map_markers` **2,337 s** → `SEARCH … USING INDEX` **0,058 s** (≈40×).

Das erklärt, warum die Karte trotz des Viewport-Providers aus v0.8.2 zäh blieb: der begrenzte,
was *zurückkommt*, aber SQLite musste weiterhin jedes Mal die ganze Tabelle durchsuchen.

- **schemaVersion 25→26:** `idx_map_markers_collection_pos` auf
  `(collection_id, latitude, longitude)` + `idx_marker_photos_marker` auf `(marker_id)`.
  Kosten: ~14 MB DB, einmalig ~2,4 s. Idempotent (`IF NOT EXISTS`).
- **Neuinstallationen:** dort läuft keine Migration — `db.createMapPerformanceIndexes()` wird
  in `main.dart` **nach** den Karten-Seedern aufgerufen. Bewusst danach: ein bestehender Index
  müsste bei jeder der 496.000 Import-Zeilen mitgepflegt werden.
- Weitere unbegrenzte Pfade behoben: `allHashtagsProvider` (neue DAO-Methode
  `hashtagStringsForCollection` — lädt nur die Hashtag-Spalte nicht-leerer Zeilen statt aller
  Marker), Galerie (neuer `galleryMarkersProvider` mit Limit statt `activeMarkersProvider`),
  Auto-Gruppierung beim Fotografieren (Bounding-Box um die Foto-Koordinate statt komplette
  Sammlung), `search()` (Limit 500), `create_collection_screen` (lädt Punkte nur noch bei
  aktiver Auto-Gruppierung, plus Nachladen beim Einschalten).
- **Achtung bei künftigen Migrationstests:** Die Fixtures in `tower_migration_v24_test.dart`,
  `lost_place_migration_v25_test.dart` und `substances_v23_migration_test.dart` legten
  `marker_photos` nie an, obwohl die Tabelle in echten Datenbanken seit v12 existiert. Die
  v26-Migration fiel darüber. Fixtures wurden ergänzt (nicht die Migration aufgeweicht) —
  neue Fixtures sollten das vollständige reale Tabellenset abbilden.
- Neuer Test `test/data/database/map_index_migration_v26_test.dart` prüft u.a. per
  `EXPLAIN QUERY PLAN`, dass der Index tatsächlich genutzt wird und kein `SCAN` mehr auftritt.

`flutter analyze` → **0 Issues**. `flutter test` → **474/474 grün**.

**Noch offen aus dem Plan:** 838 Übungs-SVGs à ~24 KB werden zur Laufzeit geparst
(`vector_graphics_compiler` ist bereits Abhängigkeit) · 36-MB-JSON wird beim Erststart am Stück
im UI-Isolate geparst · 149 MB Assets / 72-MB-DB-Kopie · 35 nicht-lazy Listen · `jsonDecode` in
`build()` (u.a. `marker_detail_screen.dart`).

---

## ⏩ VORHERIGER STAND (2026-07-31 — v0.8.5, Performance: Release-Build + Bild-Dekodierung)

**Nutzer meldete: App läuft trotz gutem Handy sehr ruckelig. Statt zu raten wurde der Code quer
über alle Module analysiert; Gesamtplan liegt in
`docs/superpowers/plans/2026-07-31-performance-optimierung.md` (Haupt-Repo). Diese Runde setzt
die beiden größten Hebel um:**

1. **Release-Builds funktionieren wieder — der eigentliche Durchbruch.**
   Alle Releases seit v0.7.27 waren **Debug-Builds** (JIT statt AOT, alle Framework-`assert`s
   aktiv, kein Tree-Shaking) — das ist die dominante Ruckel-Ursache, unabhängig von jedem
   Code-Problem. Begründet war das in Non-Negotiable #18 mit „Komplikationen mit dem
   Signing-Setup". **Das war eine Fehldiagnose:** Der Release-Build scheiterte in Wahrheit an
   `flutter_native_splash`. Das Paket stand als `dev_dependency` in `pubspec.yaml`, bringt aber
   (anders als `flutter_launcher_icons`) nativen Android-Code mit (`"native_build": true`) →
   landet in `GeneratedPluginRegistrant.java`, fehlt aber im Release-Compile-Classpath →
   `package net.jonhanson.flutter_native_splash does not exist`. Der Debug-Build lief durch,
   deshalb fiel es nie auf.
   Fix: dev_dependency entfernt (ausführlicher Kommentar steht in `pubspec.yaml`). Das Paket wird
   zur Laufzeit nicht gebraucht — der Splash läuft über bereits eingecheckte Android-Ressourcen
   (`res/drawable*/launch_background.xml`, `res/values*/styles.xml`), die Dart-API wird nirgends
   verwendet. Zum Neugenerieren des Splash: Paket temporär hinzufügen, `:create` laufen lassen,
   wieder entfernen.
   Ergebnis: `flutter build apk --release` läuft durch, **176 MB statt 282 MB** (Debug).
   Kein Keystore nötig (Gradle fällt ohne `key.properties` auf Debug-Signatur zurück).
   Non-Negotiable #18 entsprechend umgeschrieben.
2. **Fotos wurden in voller Kameraauflösung dekodiert.** 12 `Image.file`-Aufrufe, **kein
   einziger** mit `cacheWidth`/`cacheHeight`. Ein 12-MP-Foto belegt dekodiert ~48 MB im
   Bild-Cache — auch als 64-px-Thumbnail. Flutters Cache ist auf 100 MB begrenzt, ein Foto-Raster
   verdrängt sich damit permanent selbst und dekodiert beim Scrollen dieselben Bilder immer wieder
   neu. Neuer Helfer `lib/core/utils/image_decode.dart` (`decodePxFor(context, logischeGröße)`,
   rechnet Anzeigegröße × Pixeldichte); in **10 von 12** Stellen eingesetzt (Kartenmarker,
   Karten-Galerie-Raster, Marker-Detail-Galerie + Thumbnail-Leiste, Tagebuch-Liste/-Detail/
   -Slideshow/-Aufnahme, Beleg-Foto im Budget). Die 2 Vollbild-Betrachter
   (`marker_detail_screen.dart` Fullscreen, `transaction_detail_screen.dart` `_showFullscreenPhoto`)
   bleiben bewusst unlimitiert.
3. Nebenbei: nicht existierendes `assets/lottie/` aus `pubspec.yaml` entfernt (erzeugte bei jedem
   Analyze/Build eine Warnung). `flutter analyze` → **0 Issues**. `flutter test` → 471/471 grün.

**Noch offen aus dem Performance-Plan** (nach Wirkung sortiert): unbegrenzte Abfragen auf die
496k Marker in Galerie/Hashtags/Suche/Auto-Gruppierung · 838 Übungs-SVGs à ~24 KB werden zur
Laufzeit geparst (`vector_graphics_compiler` ist bereits als Abhängigkeit vorhanden) · 36-MB-JSON
wird beim Erststart am Stück im UI-Isolate geparst · 35 nicht-lazy Listen · `jsonDecode` in
`build()` (u.a. `marker_detail_screen.dart`).

---

## ⏩ VORHERIGER STAND (2026-07-31 — v0.8.4, Graffiti-Map zweisprachig de/en)

**User bat darum, die Graffiti-Map-Funktion (Feld-Labels, Dropdown-Optionen, Karten-/Vorlagennamen,
Bedienelemente) vollständig zweisprachig (de/en) zu machen — bestehende Beschreibungstexte der
importierten Lost-Places/Türme-Datensätze bleiben bewusst in ihrer Originalsprache (User-
Entscheidung: Massen-Übersetzung von 82k+ Freitext-Einträgen ist etwas anderes als App-UI und
wurde explizit zurückgestellt).**

- **Fund vor der Umsetzung:** Ein Großteil der nötigen ARB-Strings (Feld-Labels wie
  `mapFieldCondition`, Vorlagen-Namen wie `mapTemplateTowers`, diverse `graffitiMap*`-Screen-Texte)
  existierte bereits vollständig übersetzt in `app_de.arb`/`app_en.arb` — war aber nie verdrahtet
  (Screens nutzten stattdessen hartkodierte deutsche String-Literale). Nur ~30 wirklich neue Keys
  waren nötig (die 3 Turm-Feld-Labels, alle 12 Dropdown-Options-Werte, eine Handvoll Screen-Strings).
- **Architektur-Entscheidung — Anzeige-Resolver statt Datenmigration:** Feld-Labels/Options-Werte
  sind seit jeher als rohe deutsche Strings in `map_collections.field_config` (pro Karte, seit
  Erstellung eingefroren) UND in jedem Marker `customFields` (496k+ Bestandszeilen: 413k Türme +
  82k Lost Places) gespeichert. Statt einer riskanten Massen-Migration dieser Bestandsdaten gibt es
  jetzt `field_system/field_localization.dart` mit 4 reinen Anzeige-Resolvern
  (`localizedFieldLabel`, `localizedOptionValue`, `localizedCollectionName`,
  `localizedTemplateDisplayName`), die einen stabilen Schlüssel (Feld-`key`, roher Options-Wert,
  bzw. Icon+Name-Paar) auf den passenden ARB-String der aktuellen Locale abbilden — unbekannte
  (eigene, vom User angelegte) Felder/Optionen/Karten kommen unverändert durch. Speicherung bleibt
  komplett unangetastet (kein Schema-Update, kein Datenmigrationsrisiko für die 496k Zeilen).
  `localizedCollectionName` matched bewusst auf **Icon UND Namen exakt** (nicht nur Icon), damit
  eine vom User umbenannte oder mit demselben Icon neu angelegte eigene Karte nie versehentlich
  überschrieben wird.
- Verdrahtet in: `dynamic_marker_sheet.dart`, `marker_detail_screen.dart`, `graffiti_map_screen.dart`,
  `create_collection_screen.dart`, `map_gallery_screen.dart`, `settings_screen.dart` (Karten-Export-
  Liste). `map_export_service.dart` bekam einen neuen `unnamedPointLabel`-Parameter (statischer
  Service ohne `BuildContext` — Fallback-Text wird jetzt vom Aufrufer übergeben statt intern
  hartkodiert). `map_tile_config.dart`s `mapModeLabel` (Standard/Satellit/Hybrid) bewusst NICHT
  angefasst — verifiziert unbenutzter toter Code, keine Aufrufstelle im ganzen Repo.
- Neue Tests: `test/features/graffiti_map/field_localization_test.dart` (alle 4 Resolver, je
  de+en, inkl. Regressionstest dass ein umbenanntes/eigenes-Icon-wiederverwendendes User-Kollektion
  nie fälschlich übersetzt wird). `flutter analyze` → 1 vorbestehende unabhängige Warnung.
  `flutter test` → 471/471 grün.

---

## ⏩ VORHERIGER STAND (2026-07-31 — v0.8.3, Lost-Places-Kartensammlung)

**User schickte eine "LostPlace.Club"-APK und mehrere Urbex-Webseiten/-Links mit der Frage, ob
sich daraus Daten für die (bereits vorhandene, aber leere) "Lost Places"-Kartensammlung ziehen
lassen — analog zur Türme-Kartensammlung. Direkte Netz-Recherche (nicht nur Code-Review) an jeder
genannten Quelle, mit einem klaren Ausschlusskriterium: keine Quelle nutzen, die exakte
Koordinaten absichtlich hinter Login/Paywall/Community-Gate versteckt (Schutz vor Vandalismus/
Plünderung ist eine reale, ernstzunehmende Norm der Urbex-Community, kein bloßes Scraping-
Hindernis).**

1. **Geprüfte Quellen — nur 2 von ~15 sauber nutzbar:**
   - `lostfoundations.org`: offene, unauthentifizierte JSON-API (`/api/places`, Pagination über
     `skip`, NICHT `offset`/`page` — beide werden vom Server ignoriert), keine ToS-Einschränkung,
     72.306 brauchbare Orte (`status == "APPROVED"`, Rauscheinträge ohne Titel/Beschreibung
     rausgefiltert).
   - 2 vom User geteilte, öffentlich freigegebene **Google-My-Maps-Karten** ("LP V1"/"LP V2",
     handkuratiert): offizieller KML-Export (`google.com/maps/d/kml?mid=…&forcekml=1`, kein
     Scraping), 10.733 brauchbare Placemarks mit Titel/Beschreibung/Wikipedia-Referenzen.
   - **Alle anderen genannten Quellen ausgeschlossen** (lostplace-map.com, lostplace.club/
     app-api-2 — Backend der APK, gibt bei anonymem Zugriff nur `id`+`updated_at` mit `hide:1`
     zurück —, urbex-maps.com, urbexology.com, urbexvault.com, mapurbex.com, urbexobsession.com,
     zuniz.com, die-verlassenen-orte.de): entweder Login-/Paywall-Gate für exakte Koordinaten,
     explizites AGB-Verbot von Scraping/Weitergabe, oder (bei die-verlassenen-orte.de) gar kein
     Koordinaten-Datensatz vorhanden. Ein Gumroad-Link (bezahlte Kanada-Karte) wurde nicht
     angetastet; ein archivierter alter Google-My-Maps-Link ist tot (404). Details siehe
     `docs/superpowers/plans/…` (Plan-Datei dieser Runde, falls noch vorhanden) bzw. Git-Historie.
2. **Sammel-Skript** `tools/build_lost_places_dataset.py` (läuft einmalig lokal, nicht Teil der
   App) sammelt beide Quellen und schreibt `assets/data/lost_places.json` (82.666 Orte, 36 MB,
   dedupliziert über einen quellenpräfixierten `externalId`, z.B. `lostfoundations:<id>` /
   `gmymaps:<mid>:<hash>`).
3. **Schema v24→25:** neue generische `MapMarkers.externalId`-Spalte (nullable Text, partial
   unique index) — bewusst nicht `osmId` wiederverwendet/umbenannt, damit die 413k bestehenden
   Türme-Zeilen unangetastet bleiben; `externalId` ist als generischer Dedupe-Mechanismus für
   künftige weitere Fremd-Datensätze gedacht (Präfix-Konvention `"<quelle>:<id>"`).
4. **`lost_place_data_seeder.dart`** (1:1-Muster von `tower_data_seeder.dart`): befüllt beim
   ersten Start Titel/Notiz (Beschreibung + Quellenlink)/Koordinaten — bewusst **keine** der
   bestehenden Lost-Places-Felder (Zustand/Zugänglichkeit/Status/Gefahr) vorausgefüllt, die bleiben
   dem eigenen Besuch vorbehalten.
5. Neue Tests: `test/data/database/lost_place_migration_v25_test.dart`,
   `test/data/repositories/lost_place_data_seeder_test.dart` (inkl. Lauf gegen den echten
   82k-Zeilen-Datensatz). `flutter analyze` → 1 vorbestehende unabhängige Warnung (fehlender
   `assets/lottie/`-Ordner). `flutter test` → 467/467 grün.

---

## ⏩ VORHERIGER STAND (2026-07-30 — v0.8.2, Performance-Hotfix Türme-Karte)

**Nutzer meldete direkt nach v0.8.1: Türme erscheinen nirgends auf der Karte, App insgesamt sehr
ruckelig. Systematische Root-Cause-Analyse (kein Rätselraten) fand zwei konkrete Bugs, beide erst
durch die 413.634 neuen Türme-Zeilen aufgedeckt (vorher bei ein paar hundert Graffiti-Markern
unmerklich):**

1. **App-weites Ruckeln:** `widget_data_collector.dart` lud bei **jedem** Homescreen-Widget-Refresh
   `mapMarkersDao.getAll()` (alle Marker aller Collections, ungefiltert) nur um `.length` als
   Platz-Zähler zu benutzen. Fix: echte `COUNT(*)`-Query (`countAll()`).
2. **Türme erscheinen nicht:** `activeMarkersProvider`s `_withPhotos()` machte **eine sequenzielle
   DB-Query pro Marker** (N+1) um Fotos anzuhängen — bei 413.634 Türmen also 413.634 Anfragen
   nacheinander, bevor überhaupt etwas rendern konnte. Zusätzlich übergab die Karte die komplette,
   ungefilterte Collection an `MarkerClusterLayerWidget` (kein Kartenausschnitt-Limit). Fix:
   Foto-Batch-Query (`getByMarkerIds`, eine Query statt N) + neuer, kartenausschnittsbegrenzter
   Provider (`markersInViewportProvider`, DAO-Query mit Lat/Lon-Bounding-Box + Obergrenze 2000,
   lädt bei Pan/Zoom neu, 300ms entprellt). Initiale Kartenzentrierung nutzt jetzt eine billige
   `LIMIT 1`-Query (`getMostRecentByCollection`) statt die komplette Collection zu laden.

**Verifiziert gegen den echten ~413k-Zeilen-Datensatz** (nicht nur synthetische Testdaten,
`test/data/database/daos/map_markers_dao_scale_test.dart`): COUNT, eine realistische
stadtgroße Bounding-Box-Query und die Foto-Batch-Query laufen alle deutlich unter 2s.
`activeMarkersProvider` selbst bleibt für Hashtag-Liste/Voll-Collection-Ansichten normal-großer
Collections unverändert im Verhalten, profitiert aber vom selben N+1-Fix.

`flutter analyze` → 1 vorbestehende unabhängige Warnung. `flutter test` → 461/461 grün.

---

## ⏩ VORHERIGER STAND (2026-07-30 — v0.8.1, Türme-Kartensammlung + Übungs-Icons)

**Zwei unabhängige, parallel entwickelte Features in dieser Runde zusammengeführt (Merge ohne
Konflikte), `flutter analyze` → 1 vorbestehende unabhängige Warnung (fehlender `assets/lottie/`-
Ordner), `flutter test` → 449/449 grün:**

1. **Türme-Kartensammlung (Graffiti Map):** Die "Türme"-Sammlung wird nicht mehr per manuellem
   OSM/Overpass-Cloud-Import befüllt, sondern kommt als **gebündelter Offline-Datensatz**
   (`assets/data/towers.tsv`, per Overpass für Europa + USA/Kanada gesammelt) und wird beim ersten
   Start einmalig geseedet (`tower_data_seeder.dart`). Der manuelle Import-Button samt
   `tower_import_controller.dart`/`tower_import_sheet.dart`/`overpass_tower_repository.dart` wurde
   entfernt. `schemaVersion` 23→24 (neue `osmId`-Spalte auf `MapMarkers` für Dedupe/Re-Seed-Schutz).
2. **839 Übungen bekommen individuelle Piktogramme:** Neue Pipeline
   (`exercise_icons_workspace/scripts/` — außerhalb des Flutter-Projekts, siehe dortiges README)
   schneidet KI-generierte 8×8-Icon-Raster, vektorisiert sie lokal (vtracer + eigene
   Farb-Quantisierung/Nachbearbeitung, kein API-Call) und liefert handillustrations-artige
   Zwei-Farben-SVGs (`#FFFFFF` Figur / `#FF6B3D` Muskel-Akzent). `ExerciseIcon` löst jetzt über
   `exerciseName` + `slugifyExerciseName()` (`lib/features/training/exercise_icon_slug.dart`) ein
   bespoke Icon aus `assets/exercises/icons_exercise/<slug>.svg` auf, bevor es auf das generische
   Muskelgruppen-Icon zurückfällt; das Manifest (`lib/features/training/widgets/generated/
   exercise_icon_manifest.dart`) wird per `dart run tool/generate_exercise_icon_manifest.dart`
   generiert. **838 von 839 Übungen abgedeckt** (`Schulterkreisen` fehlt — nie in einen
   Generierungs-Batch aufgenommen, kein Bug, fällt auf das generische Icon zurück). Fügt
   ~20 MB SVGs zum Asset-Bundle hinzu — bewusst noch nicht optimiert (Dateigröße größer als bei
   den ursprünglichen 2 handgefertigten Test-Icons), da Bildqualität Vorrang hatte; bei Bedarf
   später über Pfad-Vereinfachung/Koordinaten-Rundung nachschärfen.

---

## ⏩ VORHERIGER STAND (2026-07-25 — v0.8.0, Mittel-Tab Komplettumbau)

**Kompletter Neubau des "Mittel"-Tabs (Substances-Modul): neue 6.580-Substanzen-Referenz-DB
(4.879 Medikamente, 1.701 Supplemente, 335 pflanzlich, DE/EN bilingual, FTS5-Volltextsuche),
Redesign beider Sub-Tabs ("Meine Mittel" + "Datenbank"), medizinischer Disclaimer-Gate,
Wikipedia/Wikidata-CC-BY-SA-Attribution. `flutter analyze` → 0, `flutter test` → 442/442 grün.**

- Alte ~108-Eintrag-Offline-DB (`assets/substances.db`) und der API-Fallback
  (openFDA/PubChem, `substance_api_service.dart`) sind komplett entfernt — die neue Referenz-DB
  (`assets/substances_reference.sqlite3`, ~71 MB) wird beim ersten Start einmalig als ganze Datei
  kopiert und danach als separate read-only sqlite3-Verbindung mit FTS5 abgefragt (nicht in
  `traum.sqlite` dupliziert). `schemaVersion` 22→23 (Migration löscht die alte
  `substance_database_entries`-Tabelle).
- Der strukturierte Interaktions-Checker (Banner + `InteractionService`) ist ersatzlos entfernt —
  die neue DB hat nur Freitext-Wechselwirkungen, die jetzt prominent in der Detailansicht jeder
  Substanz stehen (klar als Freitext gekennzeichnet, kein automatischer Check).
- **Der historische Cross-Tab-Add-Bug ist behoben:** "Zu meinen Mitteln hinzufügen" in der
  Datenbank-Detailansicht war nie verdrahtet (`onAddPressed` immer `null`). Funktioniert jetzt
  vollständig End-to-End (live auf Emulator verifiziert, inkl. DB-Check nach jedem Schritt).
  Dabei wurden bei der manuellen Verifikation zwei echte Bugs gefunden und behoben, die die
  automatisierten Tests nicht gefangen hatten: die Detailansicht ruft `Navigator.pop(context)`
  auf, *bevor* sie den Add-Sheet mit demselben `context`/`ref` öffnet — beide waren dadurch beim
  tatsächlichen Speichern (Sekunden später, nach Nutzereingabe) bereits unmounted. `ref.read(...)`
  bzw. `AppLocalizations.of(context)` warfen dadurch unbehandelte Exceptions, die den Save-Button
  für immer auf "Speichern…" hängen ließen, ohne dass je etwas persistiert wurde. Fix: Add-Sheets
  lesen jetzt aus ihrem eigenen, noch gemounteten `ProviderScope`/`BuildContext` statt aus dem
  des Aufrufers. Eine dritte, verwandte Regression (Cross-Tab-Supplement-Add setzte `nutrientKey`
  nie, wodurch die Ernährungs-Tab-Integration für diesen Eingabeweg stillschweigend abriss) wurde
  von der finalen Whole-Branch-Code-Review gefunden und ebenfalls gefixt.
- Löschen in "Meine Mittel" läuft jetzt über Long-Press-Kontextmenü (Bearbeiten/Deaktivieren/
  Löschen) statt Swipe-to-Delete.
- **Bekannte, nicht in diesem Release behobene Kleinigkeiten** (siehe
  `traum_app/.worktrees/mittel-tab-rebuild/.superpowers/sdd/progress.md`, falls der Worktree noch
  existiert, sonst Git-Historie des Feature-Branches `feature/mittel-tab-rebuild`): der
  "Anzeigen"-Button im "Hinzugefügt"-Snackbar wechselt noch nicht automatisch den Tab (derselbe
  Stale-Context-Grund, aber niedrige Priorität — kosmetisch, der Nutzer kann einfach manuell auf
  "Meine Mittel" tippen); die echte Datenbank hat 406 rohe Kategorie-Strings (u.a. ATC-Wirkmechanismus-
  Namen wie "Kinase Inhibitor") statt der ~12 kuratierten Kategorien, die das visuelle Design
  ursprünglich annahm — funktioniert korrekt, sieht aber nicht wie das Mockup aus; einzelne
  Rohdaten-Felder enthalten noch interne Pipeline-Notizen bzw. Wikitext-Reste.

- Release: https://github.com/Lupus-atque-Corvus/Traum-APP/releases/tag/v0.8.0 (Debug-Build).

---

## ⏩ VORHERIGER STAND (2026-07-23 — v0.7.30, Onboarding-Cleanup + Performance + Budget-Übertrag)

**Drei unabhängige Änderungen in dieser Runde, alle mit `flutter analyze` → 0 und `flutter test` →
398/398 grün verifiziert:**

1. **Toter Onboarding-Code entfernt:** Im Onboarding-Interessen-Picker ließen sich „Supplements"
   und „Medikamente" auswählen, inkl. eigener Formular-Seiten (`_SupplementsPage`/`_MedicationPage`
   + Add-Sheets, ~1000 Zeilen). Beide Module haben aber schon lange keine eigene Tab-Route mehr —
   `/supplements` und `/medication` leiten in `router.dart` längst auf `Substances` um, und
   `Routes.moduleRoutes` kennt beide Keys gar nicht, d.h. als Bottom-Nav-Tab gewählt landete man
   still auf Home. Entfernt: die Onboarding-Seiten/Provider/Add-Sheets, die beiden Interessen-Kacheln
   (`interests_page.dart`), die dadurch toten Einträge in `home_seed.dart`, sowie 32 nur dort
   verwendete ARB-Strings (de+en). Die Export/Backup-Funktion in den Settings, die „supplements"/
   „medication" weiterhin legitim als Datenkategorien nutzt, wurde nicht angefasst.
2. **App-Start beschleunigt:** In `main.dart` blockierten Notification-Service-Init
   (Zeitzonendatenbank + Plugin-Init + Channels), Widget-Service-Init und WorkManager-Registrierung
   bisher `runApp()`. Laufen jetzt — wie die Seeder — erst nach dem ersten Frame.
   **`widget_data_collector.dart` (`collect()`) parallelisiert:** ~50 vormals sequenzielle
   `await`s (DB-Queries + HealthConnect-Calls pro Homescreen-Widget-Refresh) laufen jetzt über
   einen `_safe`/`_or`-Helper gleichzeitig statt nacheinander; zusätzlich 9 vorher doppelt
   abgefragte Reads dedupliziert (u.a. `getAllWeightLogs`, `getSessionsAfter(365d)`,
   `recentTrainingSetsProvider(7)`, `getAllHabits`, `getRecentHabitLogs`,
   `categoryExpensesProvider`, `trendDataProvider(sixMonths)`, `todaysMealEntriesProvider`,
   `getLatestPeriodEntry`+`getCalculationForEntry`). Jeder Read behält seinen eigenen
   Fehler-Fallback — ein fehlschlagender Read kann weiterhin nicht den ganzen Refresh crashen.
3. **Budget-Übertrag:** Die große „Verfügbar diesen Monat"-Zahl auf dem Budget-Screen startete
   bisher am 1. jeden Monats wieder bei 0 (reine Monats-Bilanz). Neuer Provider
   `budgetRolloverBalanceProvider` (kumulierte Einnahmen − Ausgaben über ALLE Monate bis
   einschließlich des gewählten) treibt jetzt die Kopfzahl + Prognose in `_BudgetHeaderCard`.
   Bewusst NICHT angefasst: `budgetSummaryProvider` selbst (weiterhin rein monatsbezogen) sowie
   die Einnahmen/Ausgaben/Sparquote-Mini-Stats und das echte Homescreen-Widget — beide zeigen
   unverändert reine Monatswerte, wie vom User explizit gefordert.

- Release: https://github.com/Lupus-atque-Corvus/Traum-APP/releases/tag/v0.7.30 (Debug-Build).

---

## ⏩ VORHERIGER STAND (2026-07-23 — v0.7.29, Lebensmittelsuche-Root-Cause extern verifiziert)

**Nach v0.7.28:** User meldete, die Lebensmittelsuche funktioniere weiterhin nicht (z.B. "reis",
"ei", "hähnchen" finden nichts). Root Cause diesmal NICHT nur aus Code-Review, sondern durch
direkte `curl`-Anfragen gegen die echte OpenFoodFacts-API verifiziert: der öffentliche
`cgi/search.pl`-Suchendpunkt liefert nicht zuverlässig 200/JSON — identische Wiederholungsanfragen
bekamen abwechselnd gültige Daten und eine Bot-/Rate-Limit-HTML-Fehlerseite (503, "temporarily
unavailable") zurück. Feldnamen/Parsing wurden gegen eine echte Antwort geprüft und sind korrekt.
Fix: bis zu 2 Versuche pro Quelle + vollständigerer User-Agent (`open_food_facts_source.dart`).
Das ist eine Resilienz-Verbesserung gegen eine bekannt unzuverlässige kostenlose Drittanbieter-API,
kein klassischer Code-Bug — **kann die Erfolgsrate nicht auf 100% garantieren**, falls OFF weiterhin
blockt, hilft nur eine App-eigene API-Registrierung oder ein Quellenwechsel.

- Release: https://github.com/Lupus-atque-Corvus/Traum-APP/releases/tag/v0.7.29 (Debug-Build).

---

## ⏩ VORHERIGER STAND (2026-07-22 — nach zwei Pruefleitfaden-Testrunden)

**Wo wir sind:** v0.7.27 wurde nach der ersten Testrunde released, der User hat es getestet und
gemeldet, dass Budget IMMER NOCH schwarz war (jetzt sogar ohne FAB), die Lebensmittelsuche
weiterhin nichts fand (auch bei Frühstück/Mittag/etc.), und die App ruckeliger als vorher wirkte.
Diese zweite Runde wurde systematisch per Android-Emulator + Live-`adb logcat` untersucht
(nicht nur Code-Review) und ist als **Release v0.7.28** veröffentlicht:

1. **Budget schwarz — endgültig behoben:** Der v0.7.27-Fix (minExtent==maxExtent am
   `SliverPersistentHeader`) reichte NICHT — Live-Repro zeigte exakt dieselbe
   `SliverGeometry`-Exception weiterhin (paintExtent blieb bei 53.5, unabhängig vom
   konfigurierten Extent). Der Header lebt jetzt komplett außerhalb des `CustomScrollView`
   (`_BudgetHeader` als normale `Column`-Zeile statt Sliver) — **live über mehrfache
   Navigation verifiziert, rendert stabil.**
2. **Lebensmittelsuche (Frühstück/Mittag/Abend/Snack):** `MealTemplateSheet` nutzte
   `productSearchProvider` (rein lokale SQLite-Suche, nie Online) statt der
   Multi-Source-Suche wie der Produkte-Tab — bei leerer lokaler DB IMMER "nichts gefunden".
   Jetzt auf dieselbe Multi-Source-Suche umgestellt. **Nicht mit echtem Internet
   verifizierbar** (Emulator-Sandbox hat keine Netzwerkverbindung) — braucht Bestätigung
   auf echtem Gerät.
3. **Performance:** Per Live-Logcat einen konkreten, realen 3.6-Sekunden-Frame-Hänger
   nachgewiesen, ausgelöst durch mehrfache Pause/Resume-Zyklen während eines
   Berechtigungsdialogs, die jeweils den kompletten Widget-Daten-Refresh (mehrere
   HealthConnect-IPC-Calls + DB-Queries) neu auslösten. Jetzt auf min. 3s entprellt.
   **Ob das ALLE Ruckel-Beschwerden abdeckt, ist nicht 100% sicher** — nur diese eine,
   konkret nachgewiesene Ursache wurde gefixt.

Nutzer wurde vor dem Release explizit auf den Verifikationsstatus hingewiesen (Budget: sicher,
Suche/Performance: wahrscheinlich, aber Bestätigung auf echtem Gerät steht aus).

- Release: https://github.com/Lupus-atque-Corvus/Traum-APP/releases/tag/v0.7.28 (Debug-Build).
- Vorheriger Release: https://github.com/Lupus-atque-Corvus/Traum-APP/releases/tag/v0.7.27

**Git-Stand:** `master` = v0.7.28-Stand, gepusht + Tag v0.7.28. schemaVersion 22.
398 Tests grün, analyze 0. Kein offener Branch.

**Falls der User nach diesem Release weiterhin Suche/Ruckel-Probleme meldet:** NICHT erneut
raten — auf einem echten Gerät per `adb logcat` (Frame-Skips, HealthConnect/Netzwerk-Fehler)
oder mit dem User gemeinsam live mitschneiden (funktioniert gut: User navigiert, Claude sammelt
`adb logcat` parallel und sucht nach `Skipped`/`Davey`/`app_time_stats`-Ausreißern).

**Offene Aktionen (brauchen User):** Kalender-Edit-Sync (Phase 4 dieser Runde) braucht einen
echten Gerätetest, um den zugrunde liegenden device_calendar-Fehler zu sehen (jetzt sichtbar
statt verschluckt) · Lebensmittelsuche: falls auf dem eigenen Gerät weiterhin defekt, genauer
beschreiben (Tastatur? Cursor? Internet an?) — im Emulator-Test funktionierte das Suchfeld selbst
einwandfrei · Detail-Texte sind jetzt vollständig de+en lokalisiert, aber noch nicht in einem
neuen APK-Release/Tag veröffentlicht — auf Wunsch nachholen.

**Workflow-Erinnerung:** Änderungen im Submodule `traum_app` committen; pro Änderung
`flutter analyze` → 0 und `flutter test` → grün (aktuell 398). Bei ARB-Änderung `flutter gen-l10n`.

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
- **Version:** 0.7.26+75 · Drift schemaVersion: 22 (v20 Kalender-Sync-Metadaten, v21 FoodProducts-Quellen, v22 WorkoutPlans.planType)
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
│   │   ├── traum_database.dart   # @DriftDatabase — ~63 Tabellen, 19 DAOs, schemaVersion 19
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

## Datenbank — ~63 Tabellen, 19 DAOs (echt, schemaVersion 19)
- Planning: Appointments, Todos, Goals, SubTasks, Habits, HabitLogs
- Training: WorkoutPlans, WorkoutDays, Exercises, WorkoutSessions, WorkoutSets, WorkoutDayExercises
- Health: WeightLogs, BodyMeasurements, SleepLogs, MoodLogs, PhotoLogs
- Nutrition: NutritionLogs, MealTemplates, WaterLogs, ShoppingListItems
- Shopping erweitert: GroceryPrices, ShoppingTemplates, ShoppingTemplateItems
- Nutrition erweitert: FoodProducts, MealEntries, MealTemplateItems, WeeklyMealPlan
- Supplements: Supplements, SupplementLogs
- Medication: Medications, MedicationLogs
- Abstinence: AbstinenceTrackers, AbstinenceEvents
- Budget: BudgetCategories, Transactions, SavingsGoals, Debts, DebtItems, QuickTemplates, Accounts
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
17. **Versionierung:** `major.minor.patch+build`. **Jede Ziffer läuft nur 0–9** — wie ein
    Kilometerzähler, nicht nur die `patch`-Ziffer. Nach `x.y.9` kommt `x.(y+1).0`; wenn dabei
    auch `minor` bereits bei 9 stand, kommt `(x+1).0.0` (z.B. `0.9.9` → `1.0.0`, **nicht**
    `0.10.0` — `0.10` liest sich wie „Punkt-eins-null" und ist genau die Verwechslungsgefahr,
    die diese Regel vermeiden soll). Der `build`-Zähler (`+N`) zählt bei jedem Release
    unabhängig davon einfach um 1 weiter. Den `version:`-Eintrag in `pubspec.yaml` entsprechend
    pflegen.
    (Historisch: Bis Build +79 lag die Version bei 0.7.x, ab +80 bei 0.8.0. Ab v0.9.3+93 galt
    die erste Fassung dieser Regel — patch 0–9 → minor+1 —, wurde aber am 2026-08-07 falsch auf
    den Minor/Major-Übergang angewendet: der auf v0.9.9 folgende Release wurde fälschlich
    `v0.10.0` statt `v1.0.0` getaggt und veröffentlicht. Dieser bereits publizierte Tag/Release
    bleibt unverändert stehen (kein Force-Rewrite eines veröffentlichten Tags) — gedanklich zählt
    er aber als `1.0.0`. Ab dem direkt darauffolgenden Release gilt die oben stehende, korrigierte
    Fassung der Regel verbindlich: `v1.0.1+101` ist der erste Release unter der korrigierten
    Zählung.)
18. **Releases sind ab v0.8.5 wieder Release-Builds** (`flutter build apk --release`).
    Kein eigener Keystore nötig: `android/app/build.gradle.kts:57-70` fällt ohne
    `key.properties` automatisch auf die Debug-Signatur zurück, `isMinifyEnabled` + ProGuard
    sind konfiguriert.
    **Historie/Warnung:** Bis v0.8.4 wurde ausschließlich Debug gebaut, begründet mit
    „Komplikationen mit dem Signing-Setup". Das war eine Fehldiagnose — der Release-Build
    scheiterte tatsächlich an `flutter_native_splash` (als `dev_dependency` eingetragen, bringt
    aber nativen Android-Code mit → landet in `GeneratedPluginRegistrant.java`, fehlt im
    Release-Compile-Classpath). Ursache behoben durch Entfernen der dev_dependency (siehe
    Kommentar in `pubspec.yaml`). Debug-Builds laufen wegen JIT statt AOT um ein Vielfaches
    langsamer — **niemals Performance im Debug-Modus beurteilen**, und Releases nicht ohne
    zwingenden Grund wieder auf `--debug` umstellen.

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
> (`Traum-APP`, v0.7.20) ist der aktuelle, weiter entwickelte Stand (19 Module, embedded DM Sans,
> Dark hartkodiert, Notes/Diary/Graffiti-Map/Substances vorhanden). Nicht verwechseln.

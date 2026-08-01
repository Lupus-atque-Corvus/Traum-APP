# CLAUDE.md — TRAUM Flutter App

> Einstiegspunkt für Claude Code in diesem Projekt.
> Repo: **Lupus-atque-Corvus/Traum-APP** · Version **0.8.9+89** · schemaVersion **26**.
> Alle Angaben unten sind direkt aus dem Quellcode dieses Repos verifiziert.

---

## ⏩ AKTUELLER STAND / HANDOFF  (2026-08-01 — v0.8.9, Video-Vorschaubilder, sichtbare Fehler, APK-Größe)

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
17. **Versionierung:** Bis einschließlich Build **+79** bleibt die Version bei **0.7.x** (z.B. `0.7.13+62`, `0.7.20+79`). Erst ab Build **+80** auf **0.8.0** wechseln (`0.8.0+80`). Den `version:`-Eintrag in `pubspec.yaml` entsprechend pflegen — den Build-Zähler bei jedem Release um 1 erhöhen, den Minor-Sprung auf 0.8.0 nicht vor +80 machen.
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

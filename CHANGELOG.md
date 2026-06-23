# Changelog

## v0.7.19 (2026-06-23) — Budget-Header: Pille-Position beim Scrollen

### Korrektur

- **Sticky Monats-Pille:** sitzt im angehefteten Zustand (beim Herunterscrollen) jetzt 15px tiefer, damit sie nicht zu weit oben unter der Statusleiste klebt. Im aufgeklappten Zustand bleibt der Titel „Budget" links und blendet beim Scrollen weich aus.

## v0.7.18 (2026-06-23) — Budget-Tab: Prototyp-Feinschliff

### Neu

- **Kombinierter Sticky-Header:** Titel „Budget" und Monats-Pille stehen jetzt auf einer Zeile; beim Scrollen blendet der Titel aus und nur die rechtsbündige Monats-Navigation bleibt oben angeheftet.
- **Soll-Legende** im Budgets-Card-Header (kleiner weißer Strich + „Soll") erklärt den Tempo-Marker direkt an Ort und Stelle.

### Verbesserung

- **Schlankerer Hauptscreen:** Donut-Chart und Kategorie-Detailliste sind von der Budget-Hauptansicht entfernt — beides bleibt über „Verwalten ›" bzw. die Statistik erreichbar. Reihenfolge jetzt: Hero · Quick-Chips · Konten · Budgets · Verlauf · Letzte Transaktionen.
- **Budgets-Card** heißt jetzt „Budgets" (statt „Budgetübersicht") mit „Verwalten ›"-Link in die Kategorienverwaltung.
- **Schnell-Eintrag:** Beträge werden überall sauber mit zwei Nachkommastellen und Tausenderpunkten angezeigt — in der großen Anzeige **und** im Speichern-Button. Der mittlere Typ-Umschalter („Einnahme") hat jetzt korrekt eckige Ecken.
- **Verlauf-Card:** Perioden-Tabs sind kompakter und brechen auf schmalen Screens nicht mehr um (horizontal scrollbar).
- **Wiederkehrend bearbeiten:** Bearbeiten-Sheet hat jetzt einen Drag-Handle am oberen Rand.

### Technik

- Reines UI-Feintuning (keine Schema-Änderung, Schema bleibt v18). Toter Code (Donut-/Kategorie-Karten samt ungenutzter Helfer) entfernt. Release-Signing-Config für Android ergänzt (liest `android/key.properties`, fällt ohne Datei auf Debug-Signing zurück). `flutter analyze`: 0 Issues.

## v0.7.17 (2026-06-22) — Budget-Tab: Feinschliff & Korrekturen

### Neu

- **Überlauf-Indikator** am Budget-Balken: bei Überschreitung füllt sich der Balken bis 100 %, bekommt eine eckige rechte Kante und einen roten Auslauf-Gradienten als Hinweis auf das Über-Budget.
- **Wiederkehrende Buchungen bearbeiten:** jede Zeile hat jetzt einen blauen Stift-Button, der ein Bearbeiten-Sheet öffnet (Beschreibung, Betrag, Tag des Monats); der Löschen-Button ist als rundes Icon vereinheitlicht.
- **Sticky Monats-Pille:** der Titel „Budget" scrollt weg, während die Monats-Navigation oben angeheftet bleibt.

### Verbesserung

- **Soll-Tempo-Marker** ist breiter und kräftiger mit weichem Glow, dadurch auf vollen Balken besser erkennbar.

### Korrektur

- **Kategorie-Icons** wurden an mehreren Stellen (Budgetübersicht, Kategorieliste, Schnell-Eintrag, Transaktionsliste/-detail, Statistik) als roher Name angezeigt, wenn ein Icon aus dem Picker gewählt war. Ein gemeinsamer Glyph-Baustein rendert jetzt überall korrekt Icon **oder** Emoji.
- **Hauptkonto-Eindeutigkeit:** beim Markieren eines neuen Hauptkontos werden alle anderen automatisch entmarkiert, sodass nie zwei Konten gleichzeitig als Hauptkonto gelten (verlässliches Default-Konto bei neuen Buchungen).

## v0.7.16 (2026-06-21) — Budget-Tab: UI-Redesign

### Neu

- **Neue Hero-Card** auf der Budget-Hauptansicht: „Verfügbar diesen Monat" groß, Tag-/Prognose-Zeile, drei Mini-Kacheln (Einnahmen · Ausgaben · Sparquote) und ein integrierter **Gesamtsaldo-Footer mit Mini-Sparkline** und Δ%-Anzeige. Die bisherige separate Gesamtsaldo-Karte ist darin aufgegangen.
- **Quick-Action-Chips** direkt unter der Hero-Card (Sparziele · Transaktionen · Wiederkehrend · Schulden) statt verstecktem Overflow-Menü.
- **Soll-Tempo-Marker** auf jedem Budget-Balken (vertikale Linie = erwarteter Stand nach Tag im Monat) plus **„ÜBER"-Badge** und „noch / + X €" bei Überschreitung.
- **Verbergen = echter Weichzeichner:** Ein Tipp blurt jetzt wirklich **alle** Beträge des Tabs (Hero, Kacheln, Budget-Zeilen, Konten, Transaktionen) über einen gemeinsamen `HiddenAmount`-Baustein.
- **Statistik:** neue Tabelle „Monatliche Übersicht" (Einnahmen/Ausgaben/Bilanz der letzten 6 Monate).
- **Schulden:** Gesamt-Hero oben (offene Summe + offen/beglichen-Zähler). **Wiederkehrend:** Zusammenfassung monatlicher Einnahmen vs. Ausgaben oben.

### Verbesserung

- **Schnell-Eintrag** übersichtlicher: Template-Chips mit Bolt-Icon, „Wiederkehrend" und „Als Vorlage speichern" als klar sichtbare Schalter, Betragsfarbe je Typ.
- **Transaktionsliste:** Monats-Header (Großschreibung + Monatssumme) und Chevrons auf den Zeilen.
- **Kategorien:** farbiger Icon-Container und Typ-Badge (Ausgabe/Einnahme) je Zeile.
- **FAB** unten rechts; einheitliche Transfer-Farbe (Cyan) im ganzen Tab.

### Technik

- Reines UI-Redesign (keine Schema-Änderung, Schema bleibt v18). Neuer `HiddenAmount`-Baustein. `flutter analyze`: 0 Issues · 301 Tests grün.

---

## v0.7.15 (2026-06-21) — Konten: echter Wert + bearbeitbar

### Behoben

- **Kontostand wird wieder korrekt angezeigt:** Die alte Kreditkarten-Sonderlogik (erzwungenes Minus, rot, vom Gesamtvermögen abgezogen) ist entfernt. Jeder Kontotyp zeigt jetzt den **echten Wert** — ein positiv eingegebener Betrag erscheint positiv; Minus/Rot nur bei tatsächlich negativem Saldo. Der Gesamtsaldo summiert die echten Werte (konsistent mit den Zeilen).
- **Konten sind jetzt bearbeit- und löschbar:** Tippen auf eine Kontozeile öffnet ein Bearbeiten-Sheet (alle Felder vorausgefüllt) inkl. „Konto löschen" mit Bestätigung. Vorher gab es nach dem Anlegen keine Möglichkeit, ein Konto zu ändern.

---

## v0.7.14 (2026-06-20) — Budget-Tab vervollständigt

### Neu

- **Konten & Salden:** Transaktionen lassen sich einem Konto zuordnen; Kontostände werden aus Startsaldo + verknüpften Buchungen abgeleitet (nichts wird mutiert — Bearbeiten/Löschen/Rückgängig bleiben immer korrekt).
- **Überweisungen (Umbuchungen)** zwischen Konten — fließen nicht in Einnahmen/Ausgaben-Summen ein, bewegen aber beide Kontostände.
- **Wiederkehrende Transaktionen:** monatlich nach Tag-des-Monats, mit idempotenter Auto-Buchung beim App-Start und eigenem Verwaltungs-Screen.
- **Vorlagen nutzbar:** gespeicherte Schnell-Vorlagen erscheinen als Chips im Schnell-Eintrag (Tippen füllt aus, Long-press löscht).
- **Schulden-Screen:** Schulden anlegen, Raten zahlen, löschen.

### Verbesserung

- **Gesamtsaldo-Verlaufslinie** startet jetzt beim echten Saldo statt bei 0 (toter Pref entfernt); Überweisungen sind ausgenommen.
- **Tab-weite Währungs-Konsistenz:** überall das eingestellte Währungssymbol statt hartkodiertem €.
- **Tote Buttons funktionsfähig** (Gesamtsaldo-/Kategorie-Menüs, Auge-Umschalter), Transaktion antippen → Detail, Swipe-Löschen mit Rückgängig, Kategorien bearbeiten/löschen, einheitliche Kategorie-Farben + Farb-Picker.
- **Stream-first-Provider** beheben hängende Ladebalken und aktualisieren alle Karten + Home-Widgets sofort nach jeder Buchung.

### Technik

- DB-Schema **v18**: `Transactions` um `accountId`, `toAccountId`, `lastPostedMonth` erweitert (additive Migration). Neuer `RecurringPoster`-Service (idempotente Auto-Buchung). `flutter analyze`: 0 Issues · 301 Tests grün.

---

## v0.7.13 (2026-06-18) — Wartung: Abhängigkeiten modernisiert

### Technik

- **12 zentrale Abhängigkeiten auf aktuelle Major-Versionen gehoben** — keine sichtbaren Änderungen, aber modernere und länger gepflegte Bibliotheken unter der Haube: `flutter_riverpod` 2→3, `fl_chart` 0.69→1, `flutter_map` 7→8 (inkl. Marker-Clustering, Standort-Layer), `go_router` 14→17, `mobile_scanner` 5→7, `share_plus` 10→12, `local_auth` 2→3, `file_picker` 8→11, `permission_handler` 11→12, `home_widget` 0.6→0.9, `geocoding` 3→4, `geolocator` 12→14.
- Außerdem `flutter_local_notifications` 17→18, `device_info_plus` 10→11 sowie zahlreiche kleinere Aktualisierungen; Lint-Regeln auf `flutter_lints` 6 angehoben (Code entsprechend bereinigt).
- Interne Test-Abdeckung deutlich erweitert (neue Logik-Tests für Budget, Gesundheits-Score und Notizen). `flutter analyze`: 0 Issues · Testsuite grün.

---

## v0.7.12 (2026-06-16) — Zyklus-Tracking komplett überarbeitet

### Neu

- **Neues Zyklus-Ring-Dashboard:** Aktueller Zyklustag und Phase auf einen Blick als Ring-Visualisierung.
- **Studienbasierte Zyklus-Engine:** Eisprung-Schätzung mit fruchtbarem Fenster (nach Wilcox), symptothermale Eisprung-Bestätigung (Sensiplan, 3-über-6-Regel), Perioden-Vorhersage mit Unsicherheitsbereich, Zykluslängen-Statistik, Regelmäßigkeits-Klassifikation, gynäkologisches Alter und Schwangerschaftswahrscheinlichkeit.
- **Tages-Log-Sheet:** Stimmung, Energie, Basaltemperatur (BBT), Zervixschleim und Sex pro Tag erfassen — ein Eintrag pro Tag (Upsert-Schutz).
- **Symptom-Erfassung** zurück im Tages-Log; Perioden-Ende und Eintrag-Löschen in der Historie.
- **Zyklus-Einstellungen:** Menarche und Lutealphasen-Länge konfigurierbar.
- **Diagramme:** Zykluslängen- und BBT-Verlauf.
- **Gesundheits-Flags** mit Menarche-basierter Abschwächung; Kalender mit Phasen-Färbung.

### Technik

- DB-Schema **v17**: neue Tabellen `DailyLogs` + `CycleProfile` inkl. DAO und Migration. Alter `CycleCalculator` entfernt — Kalender und Historie lesen jetzt die neue Engine.

---

## v0.7.11 (2026-06-15) — Widget-Vorschau: statische Bilder

### Verbesserung

- **Statisches Vorschaubild je Widget-Gruppe:** Die Vorschau im Widget-Picker funktioniert jetzt launcher-unabhängig.

---

## v0.7.10 (2026-06-15) — Widget-Picker-Vorschau

### Verbesserung

- **Vorschau-Layout für alle Widget-Konfigurationen** inkl. Gradient- und Icon-Defaults — der Android-Picker zeigt jetzt eine echte Vorschau.

---

## v0.7.9 (2026-06-15) — Visuelle Widgets v2

### Neu

- **27 neue visuelle Widgets (v2)** im Funktions-Katalog.
- **Android:** Canvas-Grafik-Engine (Ringe, Balken, Sparkline, Donut), Gradient-Hintergründe je Widget-Gruppe und eigener Vektor-Icon-Satz.
- **iOS:** grafische Views mit Gradienten, SF-Symbol-Header und `widgetURL`-Deeplinks.

### Verbesserung

- iOS Widget-Klick-Routing und Android-Größen-API (die Datenquellen waren bereits seit v0.7.8 echt).

---

## v0.7.8 (2026-06-14) — Datenlücken geschlossen

### Neu

- **Health Connect / HealthKit wird ausgelesen:** Schritte, Puls, aktive Minuten und verbrannte Kalorien kommen jetzt echt vom Gerät (vorher wurde die Berechtigung nur angefragt, aber nie gelesen). Inkl. 7-Tage-Schritt-Schnitt; das Schritt-Ziel ist damit endlich erreichbar.
- **Medikamenten-Einnahme erfassen:** In der „Heute"-Karte lassen sich die Einnahme-Punkte antippen (genommen/zurücknehmen). Zusätzlich hat die Erinnerungs-Benachrichtigung einen **„Genommen"-Button**. Schaltet das `medsDone`-Widget und den Health-Score-Faktor frei.
- **Substanz-Konsum-Log:** Neuer „Konsum erfassen"-Dialog (Substanz, Dosis, Einheit, Zeitpunkt) im Mittel-Tab.
- **Geld gespart (Abstinenz):** Tracker haben jetzt ein optionales Feld „Kosten pro Tag" — daraus wird die Ersparnis berechnet und im Widget angezeigt.
- **Trainings-Verlauf:** Neuer Verlaufs-Screen (über das Verlauf-Icon im Training-Tab) listet alle abgeschlossenen Workouts.
- **Benachrichtigungs-Center:** Die Glocke auf dem Homescreen öffnet eine Übersicht über fällige Medikamente, offene Aufgaben und den nächsten Termin.
- **Supersätze im aktiven Workout:** Übungen lassen sich per Link-Button mit der nächsten Übung zum Superset verbinden.
- **Rest-Timer-Widget:** Der „Start"-Button startet jetzt einen echten Countdown direkt auf dem Homescreen (Tippen Start/Pause, lang drücken = Reset).

### Verbesserung

- **Homescreen-Widgets verdrahtet:** Supplements heute, Zyklusphase, Mahlzeiten heute, persönliche Rekorde und Monatstrend zeigen jetzt echte Werte statt Platzhalter.
- **Tote Buttons aktiviert:** „Mehr ›" in Budget (Konten/Übersicht), das ⋮-Menü und der Tipps-Link in der Übungs-Statistik, der Favoriten-Button im aktiven Workout sowie der Aktiv/Pause-Schalter bei Medikamenten haben jetzt Funktion.

### Technik

- DB-Schema **v16**: neue Spalte `costPerDay` (Abstinenz) und neue Tabelle `SubstanceIntakeLogs`.

---

## v0.7.4 (2026-06-11) — Backup: Export & Import

### Neu

- **Vollständiges Backup (Export & Import):** „Alles exportieren" erstellt jetzt ein echtes ZIP-Backup der **gesamten** Datenbank inklusive aller Fotos/Videos (Tagebuch, Graffiti-Map). Über **„Daten importieren"** lässt sich ein Backup wieder einspielen — Medien werden mit zurückgeschrieben, bestehende Einträge per Primärschlüssel zusammengeführt (insert-or-update).
- **Selektiver Export:** Einzelne Module (Training, Gesundheit, Ernährung, Supplements, Planung, Medikamente, Abstinenz, Budget, Zyklus) lassen sich gezielt als **JSON** (wieder importierbar) oder als **CSV** (ein CSV pro Tabelle, gebündelt im ZIP) exportieren.

### Hinweis

- Der Import akzeptiert ZIP-Backups (komplett, inkl. Fotos) sowie reine JSON-Exporte.

---

## v0.7.3 (2026-06-11) — Mikronährstoffe

### Neu

- **Mikronährstoff-Panel im Ernährung-Tab:** Aufklappbar in der Tagesübersicht — Zucker, Ballaststoffe, gesättigte Fettsäuren und Salz sowie Vitamin C/D/B12, Calcium, Eisen, Magnesium, Zink und Kalium mit aktuell/Ziel-Balken.
- **Barcode-Scan erfasst Vitamine & Mineralien:** OpenFoodFacts liefert die Mikronährstoffe jetzt mit; sie werden beim Loggen einer Mahlzeit anteilig zur Menge mitgezählt.
- **Supplements zählen mit:** Im Mittel-Tab lässt sich einem Supplement ein Nährstoff zuordnen (mit Auto-Vorschlag aus dem Namen, z. B. „Vitamin D3" → Vitamin D). Sobald es heute abgehakt ist, fließt seine Dosis in die Tageswerte ein — Medikamente bleiben außen vor.

### Verbesserung

- **Mahlzeiten-Einträge** zeigen den Produktnamen statt der internen ID.

---

## v0.7.2 (2026-06-10) — Onboarding komplett überarbeitet

### Neu

- **Modul-Auswahl im Onboarding:** Ein neuer Schritt „Welche Bereiche interessieren dich?" mit bunten Kacheln in den Modulfarben. Deine Auswahl bestimmt, welche Einrichtungs-Schritte erscheinen, belegt deine 4 Bottom-Tabs vor **und** stellt dein Home-Dashboard passend zusammen.
- **Alle Bereiche im Onboarding:** Eigene Schritte für **Training** (Level/Ziel/Tage), **Substanzen**, **Planung**, **Tagebuch**, **Notizen**, **Graffiti Map**, **Abstinenz** (mit optionalem ersten Tracker) und **Gesundheits-Score** — zusätzlich zu den bestehenden (Ernährung, Supplements, Medikamente, Budget, Zyklus).
- **Dashboard-Teaser:** Zeigt zum Abschluss, dass der Startbildschirm frei anpassbar ist (modulares Home aus v0.7).
- **Geburtsdatum** wird jetzt im Profil abgefragt — für ein korrektes Wasser- und Altersziel statt Schätzwert.

### Verbesserung

- **Phasen-Fortschritt:** Eine segmentierte Leiste (Basis · Interessen · Berechtigungen · Sicherheit) ersetzt die alte Punktanzeige und skaliert mit dem persönlichen Ablauf.
- **Durchgängiges Design:** Modulfarben, Gradienten und Karten-Look auf allen Onboarding-Seiten; Einwilligungen als Karten.
- **„Deine 4 Tabs":** Aus der Interessen-Auswahl vorbelegt und anpassbar — ersetzt den isolierten Navigations-Schritt.

---

## v0.7.1 (2026-06-09) — Home: mehr Größen & flotterer Drag

### Verbesserung

- **Fünf Kachelgrößen:** klein (1×1), hoch (1×2), breit (2×1), groß (2×2) und sehr groß (2×3) — jedes Widget lässt sich frei auf jede Größe stellen (⤢ im Bearbeiten-Modus)
- **Schnelleres Verschieben:** Beim Gedrückt-Halten startet das Ziehen jetzt deutlich früher (~120 ms statt 500 ms)

---

## v0.7.0 (2026-06-09) — Modularer Home-Screen

### Neu

- **Frei konfigurierbarer Home-Screen:** Der Startbildschirm ist jetzt ein Kachelraster, das du selbst zusammenstellst — wähle aus **68 Widgets** aus allen Bereichen (Allgemein, Gesundheit, Ernährung, Training, Planung, Budget, Tagebuch, Abstinenz, Substanzen, Periode, Notizen, Graffiti Map)
- **Bearbeiten-Modus:** Stift-Button → Kacheln per Drag sortieren, Größe ändern (klein/breit/groß), entfernen, und über „+ Widget" neue aus dem nach Bereichen gruppierten Katalog (mit Suche) hinzufügen
- **Drei Kachelgrößen:** klein (½ Breite), breit (volle Breite, flach), groß (volle Breite, hoch)
- **Persönliches Layout** wird gespeichert; Tippen auf ein Widget öffnet den jeweiligen Bereich. Bestehende Nutzer starten mit dem bisherigen Home-Inhalt als Standard-Layout.

---

## v0.6.14 (2026-06-08) — Graffiti Map: Gruppieren & Galerie

### Neu

- **Fotos automatisch gruppieren:** Eigener Schalter in den Karten-Einstellungen mit Radius-Slider (10–200 m). Fotos im Umkreis eines vorhandenen Punktes werden beim Aufnehmen automatisch angehängt (mit „Rückgängig")
- **Live-Vorschau:** Beim Verschieben des Radius-Sliders zeigt sich sofort, wie viele Orte entstehen („N Fotos → M Orte")
- **Umkehrbares Neugruppieren:** Fotos speichern jetzt ihre eigene Position — der Radius lässt sich nachträglich vergrößern (zusammenführen) oder verkleinern (aufsplitten)
- **Foto-Galerie im Detail:** Durch die Fotos eines Punktes wischen (links/rechts), Seiten-Zähler, Punkte-Indikator, Thumbnail-Leiste zum Anspringen und Vollbild mit Zoom

### Verbesserung

- **Karten-Kacheln werden gecacht:** Einmal geladene Kartenbereiche bleiben offline/ohne erneuten Download sichtbar

---

## v0.6.13 (2026-06-07) — Graffiti Map: Standortanzeige

### Neu

- **Eigener Standort auf der Karte:** Ein blauer Punkt zeigt jetzt live, wo du dich befindest — mit Genauigkeits-Kreis und Blickrichtung (wie in Google Maps)

---

## v0.6.12 (2026-06-07) — Graffiti Map: Verbesserungen

### Neu

- **Punkte ohne Foto:** Lange auf die Karte drücken oder der neue „Ort"-Button erstellt einen Punkt auch ohne Foto — Fotos lassen sich später in der Detail-Ansicht hinzufügen
- **Karte bearbeiten:** Jede Karte hat im Karten-Wähler ein Stift-Symbol; Name, Icon, Farbe, Bewertung, Mehrfoto und Felder lassen sich nachträglich ändern
- **Gruppierungs-Radius per Slider:** Der Radius fürs automatische Gruppieren von Fotos (10–200 m) ist jetzt frei einstellbar — auch nachträglich

### Verbesserung

- **Normale Kartenfarben:** Die Standard-Ansicht nutzt jetzt eine farbige, gut lesbare Karte (CartoDB Voyager) statt der invertierten Farben
- **Weicherer Gesten-Übergang:** Zoom „gewinnt" leichter gegen versehentliches Drehen (angepasste Schwellen)
- **Aktions-Buttons:** Sitzen noch näher an der Navigationsleiste

### Entfernt

- **Stitch/Panorama:** Die experimentelle Funktion wurde komplett entfernt

---

## v0.6.11 (2026-06-07) — Graffiti Map: UI-Korrekturen

### Fehlerbehebung

- **Zoom begrenzt:** Die Karte lässt sich nicht mehr so weit rauszoomen, dass sich die Welt mehrfach kachelt (minZoom + Weltgrenzen + begrenzte Kacheln)
- **Aktions-Buttons tiefer:** Foto/Galerie/Import/Stitch sowie Standort-/Kompass-Button sitzen jetzt knapp über der Navigationsleiste statt zu weit oben
- **Suchfeld:** Antippen der Lupe (gesamter Leistenbereich) fokussiert das Suchfeld

---

## v0.6.10 (2026-06-07) — Graffiti Map: Karten-Steuerung

### Verbesserung

- **Rotations-Sperre beim Zoomen:** Beim Pinch-Zoom dreht sich die Karte nicht mehr versehentlich mit — Zoom und Drehung schließen sich pro Geste gegenseitig aus (wer zuerst auslöst, gewinnt)
- **Freies Drehen:** Bewusstes Drehen mit zwei Fingern bleibt unbegrenzt in beide Richtungen möglich

---

## v0.6.9 (2026-06-06) — Graffiti Map: Karten-Verbesserungen

### Verbesserung

- **Karten-Ansichten:** Umschalter über der Karte für **Standard / Satellit / Hybrid** (Satellit & Hybrid über kostenloses Esri-Imagery, kein Konto nötig)
- **Navigation wie gewohnt:** Karte lässt sich mit zwei Fingern **drehen**, flüssiges Zoomen; neuer **Standort-Button** zentriert auf deine Position, ein **Kompass** erscheint bei gedrehter Karte und stellt Norden wieder her
- **Suchleiste:** Tippen an beliebiger Stelle der Leiste öffnet jetzt die Eingabe (vorher nur die Mitte)
- **Aktions-Buttons** (Foto/Galerie/Import/Stitch) sitzen weiter unten am Rand; **Stitch** erscheint nur noch bei Graffiti-Karten
- **Export** der Karten (GPX/JSON) ist in die **Einstellungen** zum übrigen Export gewandert

### Neue Funktion

- **Mehrere Fotos pro Ort:** Neue Fotos innerhalb eines einstellbaren **Radius** (Standard 50 m) werden automatisch demselben Ort zugeordnet; im Eintrag-Dialog umschaltbar auf „Neuer Eintrag"
- **Standort nachträglich anpassen:** Im Detail eines Ortes lässt sich die Position über eine Vollbild-Karte mit Fadenkreuz neu setzen

---

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

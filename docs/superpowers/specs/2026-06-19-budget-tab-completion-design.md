# Budget-Tab vervollständigen — Design / Spec

> Datum: 2026-06-19 · Modul: `lib/features/budget` · DB: schemaVersion **17 → 18**
> Ziel: Den Budget-Tab von einer Sammlung halb verdrahteter Funktionen zu einem
> kohärenten, vollständig nutzbaren Tab machen. Alle Befunde sind aus dem
> Quellcode dieses Repos verifiziert (Stand v0.7.13).

## Kontext & Problem

Audit des Budget-Tabs ergab mehrere Funktionen, die in Datenmodell/DAO/Providern
existieren, aber **nicht ins UI verdrahtet** sind, plus drei offene Designpunkte:

1. **Vorlagen (QuickTemplates):** speicherbar, aber nicht wiederverwendbar (write-only).
2. **Schulden (Debts):** Tabelle + DAO-CRUD + Provider vorhanden, **kein Screen**.
3. **Wiederkehrende Transaktionen:** Spalten `isRecurring`/`recurringDay` + Provider da,
   aber keine Erstellung/Verwaltung und keine Auto-Buchung → totes Feld.
4. **Verlauf-Balken-Tap:** setzt `trendBarDateRangeProvider`/`selectedCategoryNameProvider`,
   die nirgends gelesen werden → Tap ohne Wirkung.
5. **#6** Monats-Anfangssaldo (`monthly_start_balance_*`-Pref) wird nie gesetzt.
6. **#7** Konten und Transaktionen sind entkoppelt — Gesamtsaldo reagiert nicht auf Buchungen.
7. **#9** Zwei Quellen für Kategorie-Farben (Index-Palette vs. gespeicherte `color`).

Zusätzlich auf Wunsch in Scope: **Überweisungen zwischen Konten** und die
**Auto-Buchungs-Engine für wiederkehrende Transaktionen**.

## Leitentscheidung (bestätigt)

Kontostände werden **aus einem Startsaldo abgeleitet**, nicht mutiert:

```
Angezeigter Stand(Konto) =
    Startsaldo (= gespeichertes Accounts.balance)
  + Σ Einnahmen   (verknüpfte Transaktionen, type=income, accountId=Konto)
  − Σ Ausgaben    (verknüpfte Transaktionen, type=expense, accountId=Konto)
  − Σ Transfers raus (type=transfer, accountId=Konto)
  + Σ Transfers rein (type=transfer, toAccountId=Konto)
```

Nichts wird beim Buchen mutiert → Bearbeiten/Löschen/Undo sind automatisch korrekt.

## Schema-Änderung (17 → 18)

Drei nullbare Spalten auf `Transactions` (FK-los, analog zum bestehenden `categoryId`):

| Spalte (Dart / SQL)              | Typ        | Zweck |
|----------------------------------|------------|-------|
| `accountId` / `account_id`       | int?       | Verknüpftes Konto (Quelle bei Transfer) |
| `toAccountId` / `to_account_id`  | int?       | Zielkonto (nur bei `type='transfer'`) |
| `lastPostedMonth` / `last_posted_month` | text? | Wasserzeichen `'YYYY-MM'` für wiederkehrende Definitionen |

`Transactions.type` erhält einen dritten gültigen Wert: **`'transfer'`** (zusätzlich zu
`income`/`expense`). Da bestehende Summen `where(type=='income'|'expense')` filtern,
werden Transfers dort automatisch **nicht** als Einnahme/Ausgabe gezählt.

Migration in `traum_database.dart`:

```dart
int get schemaVersion => 18;
// ...
if (from < 18) {
  await migrator.addColumn(transactions, transactions.accountId);
  await migrator.addColumn(transactions, transactions.toAccountId);
  await migrator.addColumn(transactions, transactions.lastPostedMonth);
}
```

Nach der Tabellenänderung: `dart run build_runner build --delete-conflicting-outputs`
(NON-NEGOTIABLE #6).

## Phasen

### Phase 1 — Schema 18 + abgeleitete Salden (#7, #6)

- **Tabelle/Migration/build_runner** wie oben; `schemaVersion=18`.
- **`AccountsDao`**: neue Methoden
  - `Stream<List<Account>> watchAll()` (existiert) — bleibt Startsaldo-Quelle.
  - Abgeleiteter Saldo wird **nicht** im DAO mutiert, sondern in Providern berechnet
    aus Accounts-Stream × Transactions-Stream.
- **`budget_providers.dart`**:
  - `accountDerivedBalancesProvider` → `StreamProvider<Map<int,double>>` (Konto-ID → abgeleiteter Stand),
    kombiniert `accountsStreamProvider` + `allTransactionsStreamProvider`.
  - `totalAccountBalanceProvider` rechnet aus den abgeleiteten Ständen; Credit-Konten
    tragen weiterhin als Schuld bei (`-stand.abs()`), sonst `+stand` (Logik aus
    `AccountsDao.getTotalBalance` übernommen, aber auf den abgeleiteten Stand angewandt).
- **`AccountsCard`**: zeigt pro Konto den abgeleiteten Stand (Startsaldo bleibt im
  Bearbeiten-Dialog editierbar als „Startsaldo").
- **QuickEntry**: optionale Konto-Auswahl (Chips, Default = `isPrimary`-Konto, sonst keins);
  speichert `accountId`.
- **#6 (Verlaufslinie):** `dailyBalanceSpotsProvider` entfällt vom toten Pref. Die Linie
  bleibt eine **Cashflow-Linie** und zählt — wie bisher — **alle** Einnahmen/Ausgaben des
  Monats (unabhängig von Konto-Verknüpfung). **Überweisungen werden ausgeschlossen**, da sie
  das Gesamtvermögen nicht verändern (nur zwischen Konten verschieben). Der bisher tote
  Startwert 0 wird durch einen echten Anker ersetzt:
  `Startwert(Monat M) = Σ Konto-Startsalden + Σ(Einnahmen − Ausgaben) aller Buchungen vor dem
  ersten Tag von M` (Transfers ausgenommen); danach kumulative Tagesnettos der Einnahmen/
  Ausgaben. Funktioniert auch ohne Konto-Verknüpfung. Der `monthly_start_balance_*`-Pref
  wird entfernt.
  - **Konsequenz:** Die große „Gesamtsaldo"-Zahl (aus konto-abgeleiteten Ständen, nur
    verknüpfte Buchungen) und der Endwert der Cashflow-Linie (alle Buchungen) können
    auseinanderlaufen, wenn Buchungen keinem Konto zugeordnet sind — bewusst akzeptiert.
- **Edge cases:** Buchungen ohne `accountId` zählen weiter in Budget-Summen (Einnahmen/
  Ausgaben/Kategorien), beeinflussen aber **keinen** Kontostand (sie liegen „nirgendwo").
  Das ist gewollt und konsistent.

### Phase 2 — Überweisungen (Transfers)

- **QuickEntry**: dritter Typ-Chip **„Umbuchung"** neben Ausgabe/Einnahme. Bei Auswahl:
  Kategorie-Grid ausblenden, zwei Konto-Picker **Von**/**Nach** einblenden (Pflicht, müssen
  verschieden sein). Speichern als `type='transfer'`, `accountId=von`, `toAccountId=nach`.
- **Summen/Charts**: unverändert — Transfers sind weder income noch expense, fallen also
  automatisch aus `budgetSummary`, `categoryExpenses`, Trend etc. heraus.
- **Salden**: in `accountDerivedBalancesProvider` (Phase 1) bereits berücksichtigt
  (raus bei `accountId`, rein bei `toAccountId`).
- **Transaktionsliste/Detail**: Transfer-Zeile mit eigenem Icon (`swap_horiz`) und Text
  „Konto A → Konto B", neutrale Farbe. Detail zeigt Transfer schreibgeschützt (Von/Nach,
  Betrag, Datum, Notiz) + Löschen; Bearbeiten eines Transfers = Löschen + neu anlegen
  (kein Inline-Edit von Transfers in dieser Iteration).

### Phase 3 — Wiederkehrende Transaktionen + Auto-Buchung

- **Definition** = `Transactions`-Zeile mit `isRecurring=true`, `recurringDay` gesetzt.
  Definitionen sind **Vorlagen**, keine echten Buchungen.
- **Anzeige-Queries schließen Definitionen aus:** `watchTransactionsForMonth`,
  `getTransactionsForMonth`, `watchAllTransactions`, `getRecentTransactions`,
  `getNetForMonth` erhalten `..where((t) => t.isRecurring.equals(false))`.
- **`RecurringPoster` (neuer Service `lib/data/services/recurring_poster.dart`)**:
  - `Future<void> runIfNeeded(TraumDatabase db, {DateTime? now})`.
  - Für jede Definition: Startmonat = `lastPostedMonth + 1 Monat` bzw. Monat von `date`.
    Für jeden Monat M von Start bis aktuellen Monat, der fällig ist
    (`M < aktueller Monat` oder `M == aktuell && now.day >= recurringDay`):
    echte Buchung einfügen (`isRecurring=false`, Felder kopiert inkl. `accountId`,
    `date = min(recurringDay, daysInMonth(M))`), danach `lastPostedMonth = 'YYYY-MM'(M)`.
  - Idempotent über das Wasserzeichen → keine Doppelbuchungen bei mehrfachem Start.
  - Aufruf in `main.dart` nach den Seedern; zusätzlich nach dem Anlegen einer
    Definition sofort einmal ausführen, damit die laufende Periode sichtbar wird.
- **QuickEntry**: Schalter „Wiederkehrend" + Tag-des-Monats-Auswahl **1–28** (bewusst kein
  29–31/„Letzter", um Monatslängen-Sonderfälle zu vermeiden). Bei aktiv: `isRecurring=true`,
  `recurringDay`, `lastPostedMonth=null`.
- **Verwaltung**: neuer Screen `/budget/recurring` (Liste der Definitionen: Betrag, Tag,
  Kategorie/Konto, Bearbeiten/Stoppen=Löschen). Eintragspunkt im ⋯-Menü der Gesamtsaldo-Card.

### Phase 4 — Vorlagen nutzbar (#Tpl)

- **QuickEntry**: horizontale Chip-Reihe oben aus `quickTemplatesProvider` (Top-Vorlagen via
  `getTopTemplates`). Tipp → füllt `type`/`categoryId`/`amount` vor (gleiche Logik wie der
  vorhandene `initialTemplate`-Pfad). Beim Speichern mit aktiver Vorlage `incrementTemplateUsage`.
  Long-press auf Chip → Vorlage löschen (Bestätigung).

### Phase 5 — Schulden-Screen (#Debt)

- Neuer `DebtsScreen` unter `/budget/debts`, Aufbau analog `SavingsScreen`:
  Liste (Gläubiger, Rest/Original, Zinssatz, Fälligkeit), Anlegen-Sheet, „Rate zahlen"
  (verringert `remainingAmount`, `isPaidOff` bei 0), als bezahlt markieren, löschen.
  Nutzt vorhandenes Debts-DAO + `allDebtsStreamProvider`.
- `Routes.debts = '/budget/debts'` + GoRoute unter `/budget`. Eintragspunkt: „Schulden"
  im ⋯-Menü der Gesamtsaldo-Card (neben Sparzielen).

### Phase 6 — Kohäsions-Politur (#9 + Verlauf-Tap)

- **#9 Kategorie-Farben:** Helper `colorForCategory(BudgetCategory cat, int index)` =
  `cat.color != null ? Color(cat.color!) : kBudgetCategoryColors[index % len]`. Haupt-Screen
  (Donut, Kategorie-Detail, Letzte Transaktionen) nutzt ihn → eine Quelle. Kategorie-Sheet
  (`_CategorySheet`) erhält einen einfachen Farb-Picker aus `kBudgetCategoryColors`, der
  `color` (int) setzt — damit gespeicherte Farben überhaupt entstehen.
- **Verlauf-Balken-Tap:** tote State-Writes entfernen; die ungenutzten Provider
  `trendBarDateRangeProvider` und `selectedCategoryNameProvider` löschen. Balken-Highlight
  (`_touchedGroupIndex`) und der Touch-Tooltip bleiben erhalten.

## Datenfluss (Überblick)

```
QuickEntry (income/expense/transfer, optional accountId/toAccountId, optional recurring)
      │ insertTransaction / Definition
      ▼
Transactions (Drift)  ──watch──▶  budget_providers (StreamProvider, reaktiv)
      │                                   │
      │                                   ├─ budgetSummary / categoryExpenses / trend (nur income/expense, ohne recurring-Defs)
      │                                   ├─ accountDerivedBalances / totalAccountBalance (Startsaldo + verknüpfte Buchungen + Transfers)
      │                                   └─ recentTransactions / dailyBalanceSpots
      ▼
RecurringPoster.runIfNeeded (main.dart): Definitionen → echte Buchungen (idempotent via lastPostedMonth)
```

## Tests

Pro Phase `flutter analyze` (0 Issues) + `flutter test` (grün). Neue Unit-Tests:

- **Abgeleiteter Saldo:** Startsaldo + Einnahmen − Ausgaben − Transfer-raus + Transfer-rein;
  Credit-Konto-Beitrag zum Gesamtsaldo; Buchung ohne `accountId` ändert keinen Stand.
- **RecurringPoster:** erzeugt fehlende Monate, idempotent (zweiter Lauf bucht nicht doppelt),
  `recurringDay`-Clamping (z. B. 31 im Februar), Definitionen erscheinen nicht in Summen.
- **Transfers:** erscheinen nicht in income/expense-Summen; bewegen beide Konten korrekt.
- **DebtsDao:** „Rate zahlen" verringert Rest, `isPaidOff` bei 0.
- Bestehende Budget-/Home-Widget-Tests müssen grün bleiben (StreamProvider-Settle-Muster).

## i18n

Neue Strings nur in `app_de.arb` + `app_en.arb` (NON-NEGOTIABLE #13): Schulden-Screen,
wiederkehrend (Schalter, Tag, Verwaltung), Transfer/Umbuchung (Typ, Von/Nach), Vorlagen-Hinweis.
Bestehende deutsche String-Literale im Budget-Modul bleiben Stil-konform akzeptabel,
neue benutzersichtbare Texte werden lokalisiert.

## Bewusst ausgeschlossen (YAGNI)

- Mehrfach-Empfänger/geteilte Transfers, Wiederholung in beliebigen Intervallen
  (nur monatlich nach Tag-des-Monats), Konto-zu-Konto-Zinsen.

## Non-Negotiables-Checkliste (Projekt)

- `withValues(alpha:)`, DM Sans, Dark-Theme, `TraumColors`-Tokens.
- Stream-first (alle neuen Lese-Provider als StreamProvider).
- Repository/DAO-Trennung; Screens mutieren via DAO/Provider.
- Schema-Bump + Migration + build_runner.
- StreamProvider-Family nur mit primitiven Parametern/Records.
- ARB de+en; Widget-Deep-Links bleiben valide.

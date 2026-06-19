# Budget-Tab Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the budget tab into a complete, cohesive tab by wiring up account-linking, transfers, recurring transactions, templates, a debts screen, and consistency polish.

**Architecture:** Drift schema 17→18 adds three nullable columns to `Transactions` (`accountId`, `toAccountId`, `lastPostedMonth`). Account balances become *derived* (opening balance + linked bookings + transfers) via Riverpod `StreamProvider`s — nothing is mutated. A `RecurringPoster` service materialises recurring definitions into real bookings idempotently. New screens (`DebtsScreen`, `RecurringScreen`) mirror the existing `SavingsScreen` pattern.

**Tech Stack:** Flutter, Drift, `flutter_riverpod` 3.x, `go_router`, `fl_chart`.

## Global Constraints

- `withValues(alpha:)` — never `withOpacity()`.
- Font family `'DMSans'`; never add `google_fonts`.
- Dark theme only; colours via `TraumColors` tokens — no hardcoded colours.
- Stream-first: new read providers are `StreamProvider`; DAOs expose `Stream`/`Future`.
- Repository/DAO separation: screens mutate via `ref.read(...DaoProvider).method()`.
- After any table/schema change: `dart run build_runner build --delete-conflicting-outputs` AND bump `schemaVersion` AND add migration in `traum_database.dart`.
- `StreamProvider.family` only with primitive/record parameters.
- ARB strings in **both** `app_de.arb` and `app_en.arb`.
- `flutter analyze` → 0 issues; `flutter test` → green before every commit.
- Version: stay on `0.7.x` until build +80; bump build counter `+nn` per release in `pubspec.yaml`.
- Commands run from project root `C:\Users\Lupus\Desktop\Traum\traum_app`.

---

## File Structure

- `lib/data/database/tables/budget_tables.dart` — +3 columns on `Transactions`.
- `lib/data/database/traum_database.dart` — `schemaVersion=18` + migration.
- `lib/data/database/daos/budget_dao.dart` — exclude recurring defs from display queries; add `watchRecurringDefinitions`, `getRecurringDefinitions`.
- `lib/data/database/daos/accounts_dao.dart` — unchanged (balance stays "opening").
- `lib/data/services/recurring_poster.dart` — **new** auto-posting service.
- `lib/features/budget/budget_providers.dart` — derived balances, cashflow line, transfer-aware summaries.
- `lib/features/budget/quick_entry_bottom_sheet.dart` — account picker, transfer type, recurring toggle, template chips.
- `lib/features/budget/widgets/accounts_card.dart` — show derived balance.
- `lib/features/budget/budget_screen.dart` — `colorForCategory`, ⋯ menu entries (Debts/Recurring), transfer rows.
- `lib/features/budget/budget_category_colors.dart` — `colorForCategory` helper.
- `lib/features/budget/budget_categories_screen.dart` — colour picker in `_CategorySheet`.
- `lib/features/budget/transaction_list_screen.dart` / `transaction_detail_screen.dart` — transfer display.
- `lib/features/budget/debts_screen.dart` — **new**.
- `lib/features/budget/recurring_screen.dart` — **new**.
- `lib/features/budget/widgets/trend_bar_chart.dart` — remove dead state writes.
- `lib/core/navigation/routes.dart` + `router.dart` — `debts`, `recurring` routes.
- `lib/main.dart` — call `RecurringPoster.runIfNeeded`.
- `lib/l10n/app_de.arb` + `app_en.arb` — new strings.

---

# PHASE 1 — Schema 18 + derived balances + #6

### Task 1: Add schema-18 columns + migration

**Files:**
- Modify: `lib/data/database/tables/budget_tables.dart:12-26`
- Modify: `lib/data/database/traum_database.dart:213` (version) and `:328-335` (migration tail)
- Test: `test/features/budget/schema18_test.dart` (create)

**Interfaces:**
- Produces: `Transactions.accountId` (`IntColumn` nullable), `Transactions.toAccountId` (nullable), `Transactions.lastPostedMonth` (`TextColumn` nullable); `TransactionsCompanion` gains these fields.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/budget/schema18_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  test('transaction persists accountId, toAccountId, lastPostedMonth', () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.budgetDao.insertTransaction(
      TransactionsCompanion.insert(
        amount: 10,
        description: 'x',
        date: DateTime(2026, 6, 5),
        accountId: const Value(7),
        toAccountId: const Value(9),
        lastPostedMonth: const Value('2026-06'),
      ),
    );
    final tx = await db.budgetDao.getTransaction(id);
    expect(tx!.accountId, 7);
    expect(tx.toAccountId, 9);
    expect(tx.lastPostedMonth, '2026-06');
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `flutter test test/features/budget/schema18_test.dart`
Expected: compile error — named params `accountId`/`toAccountId`/`lastPostedMonth` don't exist.

- [ ] **Step 3: Add columns to the table**

In `lib/data/database/tables/budget_tables.dart`, inside `class Transactions`, after `splitFromId`:

```dart
  IntColumn get accountId => integer().nullable()();
  IntColumn get toAccountId => integer().nullable()();
  TextColumn get lastPostedMonth => text().nullable()();
```

- [ ] **Step 4: Bump version + migration**

`lib/data/database/traum_database.dart`: change `int get schemaVersion => 17;` → `18`. Add inside `onUpgrade`, after the `if (from < 17)` block:

```dart
      if (from < 18) {
        await migrator.addColumn(transactions, transactions.accountId);
        await migrator.addColumn(transactions, transactions.toAccountId);
        await migrator.addColumn(transactions, transactions.lastPostedMonth);
      }
```

- [ ] **Step 5: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: completes; `traum_database.g.dart` updated.

- [ ] **Step 6: Run test, verify pass**

Run: `flutter test test/features/budget/schema18_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/data/database/ test/features/budget/schema18_test.dart
git commit -m "feat(budget): schema 18 — accountId, toAccountId, lastPostedMonth on transactions"
```

---

### Task 2: Derived account balances (incl. transfers)

**Files:**
- Modify: `lib/features/budget/budget_providers.dart` (`totalAccountBalanceProvider`; add `accountDerivedBalancesProvider`)
- Test: `test/features/budget/derived_balance_test.dart` (create)

**Interfaces:**
- Consumes: `accountsStreamProvider`, `allTransactionsStreamProvider`, `Account.balance` (opening), `Transaction.{type,amount,accountId,toAccountId}`.
- Produces: `accountDerivedBalancesProvider` → `StreamProvider.autoDispose<Map<int,double>>`; `totalAccountBalanceProvider` → `StreamProvider.autoDispose<double>` (unchanged name/type).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/budget/derived_balance_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/budget/budget_providers.dart';

void main() {
  late TraumDatabase db;
  late ProviderContainer c;
  setUp(() {
    db = TraumDatabase.forTesting(NativeDatabase.memory());
    c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
  });
  tearDown(() { c.dispose(); db.close(); });

  test('derived balance = opening + income - expense -/+ transfers', () async {
    final giro = await db.accountsDao.into(db.accounts).insert(
      AccountsCompanion.insert(name: 'Giro', type: 'checking',
          balance: 1000, updatedAt: DateTime.now()));
    final spar = await db.accountsDao.into(db.accounts).insert(
      AccountsCompanion.insert(name: 'Spar', type: 'savings',
          balance: 0, updatedAt: DateTime.now()));
    Future<void> tx(double a, String t, {int? acc, int? to}) =>
        db.budgetDao.insertTransaction(TransactionsCompanion.insert(
          amount: a, description: 't', date: DateTime(2026, 6, 5),
          type: Value(t), accountId: Value(acc), toAccountId: Value(to)));
    await tx(2000, 'income', acc: giro);
    await tx(500, 'expense', acc: giro);
    await tx(300, 'transfer', acc: giro, to: spar);

    c.listen(accountDerivedBalancesProvider, (_, _) {});
    final map = await c.read(accountDerivedBalancesProvider.future);
    expect(map[giro], 1000 + 2000 - 500 - 300); // 2200
    expect(map[spar], 0 + 300);                  // 300
  });
}
```

- [ ] **Step 2: Run test, verify fail**

Run: `flutter test test/features/budget/derived_balance_test.dart`
Expected: FAIL — `accountDerivedBalancesProvider` undefined.

- [ ] **Step 3: Implement provider**

In `lib/features/budget/budget_providers.dart`, replace the existing `totalAccountBalanceProvider` block with:

```dart
/// Konto-ID → abgeleiteter Stand (Startsaldo + verknüpfte Buchungen + Transfers).
final accountDerivedBalancesProvider =
    StreamProvider.autoDispose<Map<int, double>>((ref) {
  final accounts = ref.watch(accountsStreamProvider).value ?? const [];
  return ref.watch(budgetDaoProvider).watchAllTransactions().map((txs) {
    final m = {for (final a in accounts) a.id: a.balance};
    for (final t in txs) {
      switch (t.type) {
        case 'income':
          if (t.accountId != null) m[t.accountId!] = (m[t.accountId!] ?? 0) + t.amount;
          break;
        case 'expense':
          if (t.accountId != null) m[t.accountId!] = (m[t.accountId!] ?? 0) - t.amount;
          break;
        case 'transfer':
          if (t.accountId != null) m[t.accountId!] = (m[t.accountId!] ?? 0) - t.amount;
          if (t.toAccountId != null) m[t.toAccountId!] = (m[t.toAccountId!] ?? 0) + t.amount;
          break;
      }
    }
    return m;
  });
});

final totalAccountBalanceProvider = StreamProvider.autoDispose<double>((ref) {
  final accounts = ref.watch(accountsStreamProvider).value ?? const [];
  final typeById = {for (final a in accounts) a.id: a.type};
  return ref.watch(accountDerivedBalancesProvider.stream).map((balances) {
    var sum = 0.0;
    balances.forEach((id, bal) {
      sum += typeById[id] == 'credit' ? -bal.abs() : bal;
    });
    return sum;
  });
});
```

- [ ] **Step 4: Run test, verify pass**

Run: `flutter test test/features/budget/derived_balance_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/budget/budget_providers.dart test/features/budget/derived_balance_test.dart
git commit -m "feat(budget): derive account balances from opening + linked bookings + transfers"
```

---

### Task 3: AccountsCard shows derived balance

**Files:**
- Modify: `lib/features/budget/widgets/accounts_card.dart` (`_AccountRow` → derived value)

**Interfaces:**
- Consumes: `accountDerivedBalancesProvider`.

- [ ] **Step 1: Make `AccountsCard` pass derived balances to rows**

In `accounts_card.dart`, in `AccountsCard.build`, add after `final accountsAsync = ref.watch(accountsStreamProvider);`:

```dart
    final derived = ref.watch(accountDerivedBalancesProvider).value ?? const {};
```

Change `_AccountRow(account: list[i])` → `_AccountRow(account: list[i], balance: derived[list[i].id] ?? list[i].balance)`.

- [ ] **Step 2: Use the passed balance in `_AccountRow`**

Add `final double balance;` field + constructor param to `_AccountRow`. Replace every `account.balance` inside `_AccountRow.build` with `balance`. Keep the credit sign logic (`isCredit ? '-' : ''` + `balance.abs()`).

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/budget/widgets/accounts_card.dart`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/budget/widgets/accounts_card.dart
git commit -m "feat(budget): accounts card shows derived balance"
```

---

### Task 4: QuickEntry account picker

**Files:**
- Modify: `lib/features/budget/quick_entry_bottom_sheet.dart`

**Interfaces:**
- Consumes: `accountsStreamProvider`. Produces: saved transaction has `accountId`.

- [ ] **Step 1: Add state + default**

In `_QuickEntryBottomSheetState`, add field `int? _accountId;`. In `initState`, after the template block, leave as-is (default null → resolved to primary in build).

- [ ] **Step 2: Build the picker (only for income/expense)**

In `build`, after the date chips section and before the category grid, insert:

```dart
              Consumer(builder: (ctx, r, _) {
                final accounts = r.watch(accountsStreamProvider).value ?? const [];
                if (accounts.isEmpty || _type == 'transfer') return const SizedBox.shrink();
                final selected = _accountId ??
                    (accounts.where((a) => a.isPrimary).isNotEmpty
                        ? accounts.firstWhere((a) => a.isPrimary).id
                        : null);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _AccountChip(
                        label: 'Kein Konto',
                        selected: selected == null,
                        onTap: () => setState(() => _accountId = null),
                      ),
                      for (final a in accounts) ...[
                        const SizedBox(width: 8),
                        _AccountChip(
                          label: a.name,
                          selected: selected == a.id,
                          onTap: () => setState(() => _accountId = a.id),
                        ),
                      ],
                    ]),
                  ),
                );
              }),
```

- [ ] **Step 3: Add `_AccountChip` widget**

Append at end of file (reuse `_DateChip` styling):

```dart
class _AccountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AccountChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? TraumColors.amberGoldDim : TraumColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: selected ? Border.all(color: TraumColors.amberGold) : null,
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? TraumColors.amberGold : TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans', fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ),
      );
}
```

- [ ] **Step 4: Persist `accountId` on save**

In `_save`, compute the effective account and pass it. After `setState(() => _saving = true);` add:

```dart
      final accounts = ref.read(accountsStreamProvider).value ?? const [];
      final effectiveAccount = _accountId ??
          (accounts.where((a) => a.isPrimary).isNotEmpty
              ? accounts.firstWhere((a) => a.isPrimary).id
              : null);
```

Add `accountId: Value(effectiveAccount),` to the `TransactionsCompanion.insert(...)`.

- [ ] **Step 5: Verify**

Run: `flutter analyze lib/features/budget/quick_entry_bottom_sheet.dart`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/features/budget/quick_entry_bottom_sheet.dart
git commit -m "feat(budget): link a transaction to an account in quick entry"
```

---

### Task 5: Cashflow line — real anchor, exclude transfers, drop dead pref (#6)

**Files:**
- Modify: `lib/features/budget/budget_providers.dart` (`dailyBalanceSpotsProvider`)
- Test: `test/features/budget/cashflow_line_test.dart` (create)

**Interfaces:**
- Consumes: `accountsStreamProvider`, `allTransactionsStreamProvider`. Produces: `dailyBalanceSpotsProvider` (same signature `family<List<FlSpot>, (int,int)>`, now `StreamProvider`).

- [ ] **Step 1: Write failing test**

```dart
// test/features/budget/cashflow_line_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/budget/budget_providers.dart';

void main() {
  test('cashflow line anchors at opening + prior net, excludes transfers', () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await db.accountsDao.into(db.accounts).insert(AccountsCompanion.insert(
        name: 'A', type: 'checking', balance: 1000, updatedAt: DateTime.now()));
    Future<void> tx(double a, String t, DateTime d, {int? to}) =>
        db.budgetDao.insertTransaction(TransactionsCompanion.insert(
          amount: a, description: 't', date: d, type: Value(t), toAccountId: Value(to)));
    await tx(200, 'income', DateTime(2026, 5, 10));     // prior month
    await tx(50, 'expense', DateTime(2026, 6, 2));      // day 2
    await tx(999, 'transfer', DateTime(2026, 6, 3), to: 1); // ignored

    c.listen(dailyBalanceSpotsProvider((2026, 6)), (_, _) {});
    final spots = await c.read(dailyBalanceSpotsProvider((2026, 6)).future);
    expect(spots.first.y, 1000 + 200 - 50); // day1 anchor already includes day1? see impl
    expect(spots[1].y, 1150); // after day 2 expense: 1200 - 50
  });
}
```

- [ ] **Step 2: Run test, verify fail**

Run: `flutter test test/features/budget/cashflow_line_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement provider**

Replace `dailyBalanceSpotsProvider` in `budget_providers.dart` with:

```dart
final dailyBalanceSpotsProvider = StreamProvider.autoDispose
    .family<List<FlSpot>, (int, int)>((ref, ym) {
  final accounts = ref.watch(accountsStreamProvider).value ?? const [];
  final opening = accounts.fold<double>(0.0, (s, a) => s + a.balance);
  final monthStart = DateTime(ym.$1, ym.$2, 1);
  final daysInMonth = DateTime(ym.$1, ym.$2 + 1, 0).day;
  double net(Transaction t) =>
      t.type == 'income' ? t.amount : (t.type == 'expense' ? -t.amount : 0.0);
  return ref.watch(budgetDaoProvider).watchAllTransactions().map((all) {
    final prior = all
        .where((t) => t.date.isBefore(monthStart))
        .fold(0.0, (s, t) => s + net(t));
    final Map<int, double> daily = {};
    for (final t in all.where((t) =>
        t.date.year == ym.$1 && t.date.month == ym.$2)) {
      daily[t.date.day] = (daily[t.date.day] ?? 0) + net(t);
    }
    double cumulative = opening + prior;
    return List.generate(daysInMonth, (i) {
      cumulative += daily[i + 1] ?? 0;
      return FlSpot(i.toDouble(), cumulative);
    });
  });
});
```

Note: `spots.first.y` includes day-1 net. Adjust the test's first expectation to `1000 + 200` (no day-1 booking) → `1150` after day 2. Fix the test's first `expect` to `expect(spots.first.y, 1200)` and keep `spots[1].y == 1150`.

- [ ] **Step 4: Remove dead pref usage**

Confirm no remaining reference to `monthly_start_balance_`:
Run: `git grep -n "monthly_start_balance"`
Expected: no matches (the old provider read it; now removed). If `sharedPreferencesProvider` import is now unused in `budget_providers.dart`, remove it.

- [ ] **Step 5: Run test, verify pass**

Run: `flutter test test/features/budget/cashflow_line_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/budget/budget_providers.dart test/features/budget/cashflow_line_test.dart
git commit -m "feat(budget): cashflow line anchors at real balance, excludes transfers (#6)"
```

---

# PHASE 2 — Transfers

### Task 6: Transfer type in QuickEntry

**Files:**
- Modify: `lib/features/budget/quick_entry_bottom_sheet.dart`

**Interfaces:**
- Produces: transactions with `type='transfer'`, `accountId` (from), `toAccountId` (to).

- [ ] **Step 1: Add transfer state**

Add field `int? _toAccountId;` to the state.

- [ ] **Step 2: Add a third type button**

In the type toggle `Row`, wrap the two existing `_TypeButton`s and add a third; change the row to include:

```dart
                  Expanded(
                    child: _TypeButton(
                      label: '⇄ Umbuchung',
                      isSelected: _type == 'transfer',
                      selectedColor: TraumColors.cyanBlue,
                      isLeft: false,
                      onTap: () => setState(() => _type = 'transfer'),
                    ),
                  ),
```

(Place it as a third `Expanded`; set the existing income button `isLeft: false` only when it is the last — to keep rounded corners, give the middle button `isLeft: false` and rely on existing styling; corner cosmetics are acceptable as-is.)

- [ ] **Step 3: Show Von/Nach pickers for transfer; hide category grid**

Wrap the existing category-grid `categoriesAsync.when(...)` so it only renders when `_type != 'transfer'`. Directly above it add:

```dart
              if (_type == 'transfer')
                Consumer(builder: (ctx, r, _) {
                  final accounts = r.watch(accountsStreamProvider).value ?? const [];
                  Widget picker(String title, int? sel, ValueChanged<int?> onSel) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(
                              fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted, fontSize: 12)),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              for (final a in accounts) ...[
                                _AccountChip(label: a.name, selected: sel == a.id,
                                    onTap: () => onSel(a.id)),
                                const SizedBox(width: 8),
                              ],
                            ]),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                  return Column(children: [
                    picker('Von', _accountId, (v) => setState(() => _accountId = v)),
                    picker('Nach', _toAccountId, (v) => setState(() => _toAccountId = v)),
                  ]);
                }),
```

- [ ] **Step 4: Validate + save transfer**

At the top of `_save`, before the amount check, add:

```dart
    if (_type == 'transfer') {
      if (_accountId == null || _toAccountId == null || _accountId == _toAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Von- und Nach-Konto wählen (verschieden)')));
        return;
      }
    }
```

In the `TransactionsCompanion.insert`, add `toAccountId: Value(_type == 'transfer' ? _toAccountId : null),` and ensure `accountId` uses `effectiveAccount` (transfer uses `_accountId` as source — set `effectiveAccount = _accountId` when `_type=='transfer'`).

- [ ] **Step 5: Verify analyze**

Run: `flutter analyze lib/features/budget/quick_entry_bottom_sheet.dart`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/features/budget/quick_entry_bottom_sheet.dart
git commit -m "feat(budget): add transfer (Umbuchung) type to quick entry"
```

---

### Task 7: Transfer display in list & detail

**Files:**
- Modify: `lib/features/budget/transaction_list_screen.dart` (`_TxTile`)
- Modify: `lib/features/budget/transaction_detail_screen.dart` (guard category/edit for transfers)

**Interfaces:**
- Consumes: `accountsStreamProvider` (name lookup) in `_TxTile`.

- [ ] **Step 1: Transfer row in `_TxTile`**

In `_TxTile.build`, add `final isTransfer = transaction.type == 'transfer';` and before the income/expense branch render a transfer variant: leading icon `Icons.swap_horiz_rounded` (colour `TraumColors.cyanBlue`), title `transaction.description`, subtitle date + `'Umbuchung'`, trailing `fmtAmount(transaction.amount) + ' ' + currency` in `TraumColors.onBackgroundMuted`. Keep `onTap`/`Dismissible` wrappers.

- [ ] **Step 2: Detail screen guards**

In `transaction_detail_screen.dart`, where the category section and the split button render, wrap them in `if (tx.type != 'transfer') ...`. For transfers, show a read-only "Umbuchung"-Zeile. Delete button stays.

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/budget/transaction_list_screen.dart lib/features/budget/transaction_detail_screen.dart`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/budget/transaction_list_screen.dart lib/features/budget/transaction_detail_screen.dart
git commit -m "feat(budget): show transfers distinctly in list and detail"
```

---

# PHASE 3 — Recurring transactions + auto-posting

### Task 8: Exclude recurring definitions from display queries

**Files:**
- Modify: `lib/data/database/daos/budget_dao.dart`
- Test: `test/features/budget/recurring_exclusion_test.dart` (create)

**Interfaces:**
- Produces: `watchRecurringDefinitions()`/`getRecurringDefinitions()` (defs only); existing display queries now exclude `isRecurring=true`.

- [ ] **Step 1: Failing test**

```dart
// test/features/budget/recurring_exclusion_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  test('recurring definitions excluded from month/all queries', () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.budgetDao.insertTransaction(TransactionsCompanion.insert(
        amount: 10, description: 'real', date: DateTime(2026, 6, 5)));
    await db.budgetDao.insertTransaction(TransactionsCompanion.insert(
        amount: 99, description: 'def', date: DateTime(2026, 6, 5),
        isRecurring: const Value(true), recurringDay: const Value(5)));
    final month = await db.budgetDao.getTransactionsForMonth(2026, 6);
    expect(month.length, 1);
    expect(month.single.description, 'real');
    final defs = await db.budgetDao.getRecurringDefinitions();
    expect(defs.single.description, 'def');
  });
}
```

- [ ] **Step 2: Run, verify fail**

Run: `flutter test test/features/budget/recurring_exclusion_test.dart`
Expected: FAIL (`getRecurringDefinitions` missing; month returns 2).

- [ ] **Step 3: Implement**

In `budget_dao.dart`, add `..where((t) => t.isRecurring.equals(false))` to the selects in `watchAllTransactions`, `watchTransactionsForMonth`, `getTransactionsForMonth`, `getRecentTransactions`. (`getNetForMonth` calls `getTransactionsForMonth`, so it inherits the filter.) Add:

```dart
  Stream<List<Transaction>> watchRecurringDefinitions() =>
      (select(transactions)..where((t) => t.isRecurring.equals(true))).watch();

  Future<List<Transaction>> getRecurringDefinitions() =>
      (select(transactions)..where((t) => t.isRecurring.equals(true))).get();
```

- [ ] **Step 4: Run, verify pass**

Run: `flutter test test/features/budget/recurring_exclusion_test.dart`
Expected: PASS. Then `flutter test test/features/budget` — all green (existing tests use `isRecurring=false` default).

- [ ] **Step 5: Commit**

```bash
git add lib/data/database/daos/budget_dao.dart test/features/budget/recurring_exclusion_test.dart
git commit -m "feat(budget): treat recurring rows as definitions, exclude from display queries"
```

---

### Task 9: RecurringPoster service

**Files:**
- Create: `lib/data/services/recurring_poster.dart`
- Test: `test/features/budget/recurring_poster_test.dart` (create)

**Interfaces:**
- Produces: `class RecurringPoster { static Future<void> runIfNeeded(TraumDatabase db, {DateTime? now}); }`.

- [ ] **Step 1: Failing test**

```dart
// test/features/budget/recurring_poster_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/services/recurring_poster.dart';

void main() {
  test('posts missing months once (idempotent)', () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.budgetDao.insertTransaction(TransactionsCompanion.insert(
        amount: 50, description: 'Miete', date: DateTime(2026, 4, 1),
        type: const Value('expense'),
        isRecurring: const Value(true), recurringDay: const Value(1)));
    await RecurringPoster.runIfNeeded(db, now: DateTime(2026, 6, 15));
    var posted = await db.budgetDao.getRecentTransactions(limit: 50);
    expect(posted.where((t) => t.description == 'Miete').length, 3); // Apr,May,Jun
    await RecurringPoster.runIfNeeded(db, now: DateTime(2026, 6, 20));
    posted = await db.budgetDao.getRecentTransactions(limit: 50);
    expect(posted.where((t) => t.description == 'Miete').length, 3); // no dupes
  });
}
```

- [ ] **Step 2: Run, verify fail**

Run: `flutter test test/features/budget/recurring_poster_test.dart`
Expected: FAIL — file missing.

- [ ] **Step 3: Implement**

```dart
// lib/data/services/recurring_poster.dart
import 'package:drift/drift.dart';
import '../database/traum_database.dart';

class RecurringPoster {
  static String _key(int y, int m) => '$y-${m.toString().padLeft(2, '0')}';

  static Future<void> runIfNeeded(TraumDatabase db, {DateTime? now}) async {
    final today = now ?? DateTime.now();
    final defs = await db.budgetDao.getRecurringDefinitions();
    for (final def in defs) {
      final day = def.recurringDay ?? def.date.day;
      var cursor = def.lastPostedMonth == null
          ? DateTime(def.date.year, def.date.month, 1)
          : _nextMonth(def.lastPostedMonth!);
      var lastPosted = def.lastPostedMonth;
      while (!cursor.isAfter(DateTime(today.year, today.month, 1))) {
        final isCurrent = cursor.year == today.year && cursor.month == today.month;
        if (!isCurrent || today.day >= day) {
          final dim = DateTime(cursor.year, cursor.month + 1, 0).day;
          await db.budgetDao.insertTransaction(TransactionsCompanion.insert(
            amount: def.amount,
            description: def.description,
            date: DateTime(cursor.year, cursor.month, day > dim ? dim : day),
            type: Value(def.type),
            categoryId: Value(def.categoryId),
            accountId: Value(def.accountId),
            note: Value(def.note),
          ));
          lastPosted = _key(cursor.year, cursor.month);
        }
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      if (lastPosted != def.lastPostedMonth) {
        await db.budgetDao.updateTransaction(
            def.copyWith(lastPostedMonth: Value(lastPosted)));
      }
    }
  }

  static DateTime _nextMonth(String yyyymm) {
    final p = yyyymm.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]) + 1, 1);
  }
}
```

- [ ] **Step 4: Run, verify pass**

Run: `flutter test test/features/budget/recurring_poster_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/services/recurring_poster.dart test/features/budget/recurring_poster_test.dart
git commit -m "feat(budget): RecurringPoster materialises recurring definitions idempotently"
```

---

### Task 10: Run poster at startup

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Wire it in**

In `lib/main.dart`, add import `import 'data/services/recurring_poster.dart';`. After the `await Future.wait([... seeders ...]);` block add:

```dart
  await RecurringPoster.runIfNeeded(db);
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/main.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat(budget): post due recurring transactions on startup"
```

---

### Task 11: Recurring toggle in QuickEntry + immediate post

**Files:**
- Modify: `lib/features/budget/quick_entry_bottom_sheet.dart`

- [ ] **Step 1: Add state**

Add `bool _recurring = false; int _recurringDay = 1;`.

- [ ] **Step 2: UI (income/expense only)**

Below the "Als Vorlage speichern" row, add (only when `_type != 'transfer'`):

```dart
              if (_type != 'transfer')
                Row(children: [
                  Checkbox(
                    value: _recurring,
                    onChanged: (v) => setState(() => _recurring = v ?? false),
                    activeColor: TraumColors.amberGold,
                  ),
                  const Text('Monatlich wiederkehrend am',
                      style: TextStyle(fontFamily: 'DMSans',
                          color: TraumColors.onBackgroundMuted, fontSize: 13)),
                  const SizedBox(width: 8),
                  if (_recurring)
                    DropdownButton<int>(
                      value: _recurringDay,
                      dropdownColor: TraumColors.surfaceVariant,
                      style: const TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackground),
                      items: [for (var d = 1; d <= 28; d++)
                        DropdownMenuItem(value: d, child: Text('$d.'))],
                      onChanged: (v) => setState(() => _recurringDay = v ?? 1),
                    ),
                ]),
```

- [ ] **Step 3: Save as definition + post now**

In `_save`, when `_recurring && _type != 'transfer'`, set on the insert: `isRecurring: const Value(true), recurringDay: Value(_recurringDay), lastPostedMonth: const Value(null),`. After the insert + before `Navigator.pop`, add:

```dart
      if (_recurring && _type != 'transfer') {
        await RecurringPoster.runIfNeeded(ref.read(databaseProvider));
      }
```

Add import `import '../../data/services/recurring_poster.dart';` and ensure `databaseProvider` import present (`core/providers/database_provider.dart`, already imported).

- [ ] **Step 4: Verify + commit**

Run: `flutter analyze lib/features/budget/quick_entry_bottom_sheet.dart`
Expected: No issues found.

```bash
git add lib/features/budget/quick_entry_bottom_sheet.dart
git commit -m "feat(budget): create monthly recurring transactions from quick entry"
```

---

### Task 12: Recurring management screen + route + menu entry

**Files:**
- Create: `lib/features/budget/recurring_screen.dart`
- Modify: `lib/core/navigation/routes.dart`, `router.dart`, `lib/features/budget/budget_screen.dart` (⋯ menu)

**Interfaces:**
- Consumes: `budgetDaoProvider.watchRecurringDefinitions()` via a new `recurringDefinitionsProvider`.

- [ ] **Step 1: Provider**

In `budget_providers.dart` add:

```dart
final recurringDefinitionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) =>
        ref.watch(budgetDaoProvider).watchRecurringDefinitions());
```

- [ ] **Step 2: Screen**

```dart
// lib/features/budget/recurring_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import 'budget_helpers.dart';
import 'budget_providers.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defs = ref.watch(recurringDefinitionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        title: const Text('Wiederkehrend',
            style: TextStyle(color: TraumColors.onBackground,
                fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
      ),
      body: defs.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Keine wiederkehrenden Buchungen',
                style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: TraumColors.surfaceVariant),
                itemBuilder: (_, i) {
                  final d = list[i];
                  final income = d.type == 'income';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(d.description,
                        style: const TextStyle(color: TraumColors.onBackground,
                            fontFamily: 'DMSans', fontWeight: FontWeight.w500)),
                    subtitle: Text('Jeden ${d.recurringDay ?? d.date.day}. im Monat',
                        style: const TextStyle(color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans', fontSize: 12)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${income ? '+' : '−'}${fmtAmount(d.amount)} $currency',
                          style: TextStyle(
                              color: income ? TraumColors.mintGreen : TraumColors.roseRed,
                              fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: TraumColors.roseRed),
                        onPressed: () =>
                            ref.read(budgetDaoProvider).deleteTransaction(d.id),
                      ),
                    ]),
                  );
                },
              ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: TraumColors.amberGold)),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}
```

- [ ] **Step 3: Route**

`routes.dart`: add `static const String recurring = '/budget/recurring';`. `router.dart`: import `recurring_screen.dart`; add child route under `/budget`:

```dart
              GoRoute(path: 'recurring', builder: (_, _) => const RecurringScreen()),
```

- [ ] **Step 4: Menu entry**

In `budget_screen.dart` `_GesamtsaldoCard` popup menu `onSelected`/`itemBuilder`, add a `'recurring'` case → `context.go('/budget/recurring')` and `_menuItem('recurring', Icons.repeat_rounded, 'Wiederkehrend')`.

- [ ] **Step 5: Verify + commit**

Run: `flutter analyze lib/features/budget/recurring_screen.dart lib/core/navigation/router.dart lib/features/budget/budget_screen.dart`
Expected: No issues found.

```bash
git add lib/features/budget/recurring_screen.dart lib/features/budget/budget_providers.dart lib/core/navigation/ lib/features/budget/budget_screen.dart
git commit -m "feat(budget): recurring transactions management screen"
```

---

# PHASE 4 — Templates usable

### Task 13: Template chips in QuickEntry

**Files:**
- Modify: `lib/features/budget/quick_entry_bottom_sheet.dart`

**Interfaces:**
- Consumes: `quickTemplatesProvider`.

- [ ] **Step 1: Track selected template**

Add `QuickTemplate? _appliedTemplate;`.

- [ ] **Step 2: Chip row at top of the sheet**

Right after the drag-handle `Center(...)`, add (only when `_type != 'transfer'`):

```dart
              Consumer(builder: (ctx, r, _) {
                final tpls = r.watch(quickTemplatesProvider).value ?? const [];
                if (tpls.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final t in tpls) ...[
                        GestureDetector(
                          onTap: () => setState(() {
                            _appliedTemplate = t;
                            _type = t.type;
                            _categoryId = t.categoryId;
                            if (t.defaultAmount != null) {
                              _numpadValue = t.defaultAmount!.toStringAsFixed(2).replaceAll('.', ',');
                            }
                          }),
                          onLongPress: () => ref.read(budgetDaoProvider).deleteTemplate(t.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: TraumColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: TraumColors.amberGold.withValues(alpha: 0.4)),
                            ),
                            child: Text(t.name, style: const TextStyle(
                                fontFamily: 'DMSans', color: TraumColors.onBackground, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ]),
                  ),
                );
              }),
```

- [ ] **Step 3: Bump usage on save**

In `_save`, after a successful insert, add:

```dart
      if (_appliedTemplate != null) {
        await ref.read(budgetDaoProvider)
            .incrementTemplateUsage(_appliedTemplate!.id, amount);
      }
```

- [ ] **Step 4: Verify + commit**

Run: `flutter analyze lib/features/budget/quick_entry_bottom_sheet.dart`
Expected: No issues found.

```bash
git add lib/features/budget/quick_entry_bottom_sheet.dart
git commit -m "feat(budget): reuse saved quick templates via chips"
```

---

# PHASE 5 — Debts screen

### Task 14: DebtsScreen + route + menu entry

**Files:**
- Create: `lib/features/budget/debts_screen.dart`
- Modify: `lib/core/navigation/routes.dart`, `router.dart`, `lib/features/budget/budget_screen.dart`, `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`

**Interfaces:**
- Consumes: `allDebtsStreamProvider`, `budgetDaoProvider.{insertDebt,updateDebt,deleteDebt}`.

- [ ] **Step 1: Screen (mirror SavingsScreen)**

```dart
// lib/features/budget/debts_screen.dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import 'budget_helpers.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final debts = ref.watch(allDebtsStreamProvider);
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        title: const Text('Schulden', style: TextStyle(
            color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.roseRed,
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: debts.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Keine Schulden erfasst',
                style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: list.length,
                itemBuilder: (_, i) => _DebtCard(
                  debt: list[i], currency: currency,
                  onPay: (amt) {
                    final rem = (list[i].remainingAmount - amt).clamp(0.0, list[i].originalAmount);
                    ref.read(budgetDaoProvider).updateDebt(DebtsCompanion(
                      id: Value(list[i].id),
                      creditor: Value(list[i].creditor),
                      originalAmount: Value(list[i].originalAmount),
                      remainingAmount: Value(rem),
                      isPaidOff: Value(rem <= 0),
                    ));
                  },
                  onDelete: () => ref.read(budgetDaoProvider).deleteDebt(list[i].id),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.roseRed)),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final creditor = TextEditingController();
    final amount = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          decoration: const BoxDecoration(color: TraumColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Schuld hinzufügen', style: TextStyle(fontFamily: 'DMSans',
                fontWeight: FontWeight.w700, color: TraumColors.onBackground, fontSize: 18)),
            const SizedBox(height: 16),
            _debtField(creditor, 'Gläubiger *', 'z.B. Bank'),
            const SizedBox(height: 8),
            _debtField(amount, 'Betrag *', '0,00', number: true),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: TraumColors.roseRed,
                  foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TraumRadius.button))),
              onPressed: () {
                final c = creditor.text.trim();
                final a = double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
                if (c.isEmpty || a <= 0) return;
                ref.read(budgetDaoProvider).insertDebt(DebtsCompanion.insert(
                    creditor: c, originalAmount: a, remainingAmount: a));
                Navigator.of(ctx).pop();
              },
              child: const Text('Speichern', style: TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
            )),
          ]),
        ),
      ),
    );
  }

  static Widget _debtField(TextEditingController c, String label, String hint, {bool number = false}) =>
      TextField(controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackground, fontSize: 14),
        decoration: InputDecoration(labelText: label, hintText: hint, filled: true,
          fillColor: TraumColors.surfaceVariant,
          labelStyle: const TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final String currency;
  final void Function(double) onPay;
  final VoidCallback onDelete;
  const _DebtCard({required this.debt, required this.currency, required this.onPay, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final ratio = debt.originalAmount > 0
        ? (1 - debt.remainingAmount / debt.originalAmount).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TraumColors.surface, borderRadius: BorderRadius.circular(TraumRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(debt.creditor, style: const TextStyle(color: TraumColors.onBackground,
              fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 15))),
          IconButton(icon: const Icon(Icons.delete_outline, color: TraumColors.onBackgroundMuted),
              onPressed: onDelete),
        ]),
        Text('${fmtAmount(debt.remainingAmount)} $currency von ${fmtAmount(debt.originalAmount)} $currency offen',
            style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio, minHeight: 6,
              backgroundColor: TraumColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(TraumColors.mintGreen))),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: TextButton(
          onPressed: debt.isPaidOff ? null : () => _payDialog(context),
          child: Text(debt.isPaidOff ? 'Bezahlt' : 'Rate zahlen',
              style: TextStyle(fontFamily: 'DMSans',
                  color: debt.isPaidOff ? TraumColors.mintGreen : TraumColors.amberGold)),
        )),
      ]),
    );
  }
  void _payDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: TraumColors.surface,
      title: const Text('Rate zahlen', style: TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackground)),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true,
        style: const TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackground),
        decoration: const InputDecoration(hintText: '0,00')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
        TextButton(onPressed: () {
          final a = double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0;
          if (a > 0) onPay(a);
          Navigator.pop(ctx);
        }, child: const Text('OK')),
      ],
    ));
  }
}
```

- [ ] **Step 2: Route + menu entry**

`routes.dart`: `static const String debts = '/budget/debts';`. `router.dart`: import `debts_screen.dart`; add `GoRoute(path: 'debts', builder: (_, _) => const DebtsScreen())`. `budget_screen.dart` `_GesamtsaldoCard` popup: add `'debts'` case → `context.go('/budget/debts')` and `_menuItem('debts', Icons.credit_card_outlined, 'Schulden')`.

- [ ] **Step 3: ARB strings**

Add to `app_de.arb` and `app_en.arb`: `"debts": "Schulden"` / `"Debts"`. (Screen uses literal German strings consistent with the module; the ARB key is for any nav label reuse.)

- [ ] **Step 4: Verify + commit**

Run: `flutter analyze lib/features/budget/debts_screen.dart lib/core/navigation/router.dart lib/features/budget/budget_screen.dart`
Expected: No issues found.

```bash
git add lib/features/budget/debts_screen.dart lib/core/navigation/ lib/features/budget/budget_screen.dart lib/l10n/
git commit -m "feat(budget): debts screen with add, pay-down, delete"
```

---

# PHASE 6 — Cohesion polish

### Task 15: Unify category colours (#9) + colour picker

**Files:**
- Modify: `lib/features/budget/budget_category_colors.dart`, `budget_screen.dart`, `budget_categories_screen.dart`
- Test: `test/features/budget/category_color_test.dart` (create)

**Interfaces:**
- Produces: `Color colorForCategory(BudgetCategory cat, int index)`.

- [ ] **Step 1: Failing test**

```dart
// test/features/budget/category_color_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/budget/budget_category_colors.dart';

void main() {
  BudgetCategory cat(int? color) => BudgetCategory(
      id: 1, name: 'x', emoji: null, monthlyLimit: null, color: color, isExpense: true);
  test('stored colour wins, else palette by index', () {
    expect(colorForCategory(cat(0xFF112233), 0), const Color(0xFF112233));
    expect(colorForCategory(cat(null), 1), kBudgetCategoryColors[1]);
  });
}
```

- [ ] **Step 2: Run, verify fail**

Run: `flutter test test/features/budget/category_color_test.dart`
Expected: FAIL — `colorForCategory` undefined.

- [ ] **Step 3: Implement helper**

Append to `budget_category_colors.dart`:

```dart
Color colorForCategory(BudgetCategory cat, int index) =>
    cat.color != null ? Color(cat.color!) : categoryColor(index);
```

Add import at top: `import '../../data/database/traum_database.dart';`

- [ ] **Step 4: Use it in budget_screen**

In `budget_screen.dart` donut/category-detail/recent, where `categoryColor(cat.category.id)` is used with a real category, switch to `colorForCategory(cat.category, entry.key)` (use the list index as fallback). Keep `_catColor` for the recent-tile fallback when no category object is available.

- [ ] **Step 5: Colour picker in `_CategorySheet`**

In `budget_categories_screen.dart`, add `int? _color;` state (init from `cat.color`). After the IconPickerGrid add a palette row:

```dart
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final col in kBudgetCategoryColors)
              GestureDetector(
                onTap: () => setState(() => _color = col.toARGB32()),
                child: Container(width: 30, height: 30,
                  decoration: BoxDecoration(color: col, shape: BoxShape.circle,
                    border: _color == col.toARGB32()
                        ? Border.all(color: Colors.white, width: 2) : null)),
              ),
          ]),
```

Add import for `kBudgetCategoryColors`. In `_save`, set `color: Value(_color)` for both insert and update.

- [ ] **Step 6: Run tests + analyze**

Run: `flutter test test/features/budget/category_color_test.dart`
Expected: PASS.
Run: `flutter analyze lib/features/budget/budget_category_colors.dart lib/features/budget/budget_screen.dart lib/features/budget/budget_categories_screen.dart`
Expected: No issues found.

- [ ] **Step 7: Commit**

```bash
git add lib/features/budget/budget_category_colors.dart lib/features/budget/budget_screen.dart lib/features/budget/budget_categories_screen.dart test/features/budget/category_color_test.dart
git commit -m "feat(budget): unify category colours + colour picker (#9)"
```

---

### Task 16: Remove dead trend-tap state

**Files:**
- Modify: `lib/features/budget/widgets/trend_bar_chart.dart`, `lib/features/budget/budget_providers.dart`

- [ ] **Step 1: Drop provider writes**

In `trend_bar_chart.dart` `touchCallback`, keep `setState(() => _touchedGroupIndex = groupIndex);` and DELETE the `ref.read(trendBarDateRangeProvider...)` and `ref.read(selectedCategoryNameProvider...)` blocks (the whole `if (event is FlTapUpEvent) {...}`).

- [ ] **Step 2: Remove now-unused providers**

In `budget_providers.dart` delete `selectedCategoryNameProvider` and `trendBarDateRangeProvider`.

- [ ] **Step 3: Verify nothing else references them**

Run: `git grep -n "trendBarDateRangeProvider\|selectedCategoryNameProvider"`
Expected: no matches.

- [ ] **Step 4: Analyze + commit**

Run: `flutter analyze lib/features/budget/widgets/trend_bar_chart.dart lib/features/budget/budget_providers.dart`
Expected: No issues found.

```bash
git add lib/features/budget/widgets/trend_bar_chart.dart lib/features/budget/budget_providers.dart
git commit -m "refactor(budget): remove dead trend-bar tap state"
```

---

### Task 17: Full verification + version bump

**Files:**
- Modify: `pubspec.yaml` (build counter)

- [ ] **Step 1: Full analyze**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: All tests passed.

- [ ] **Step 3: Bump build number**

In `pubspec.yaml`, bump the `version:` build counter by 1 (stay `0.7.x`, e.g. `0.7.13+61` → `0.7.14+62`).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: bump build for budget-tab completion"
```

---

## Self-Review Notes (author)

- **Spec coverage:** #7 (Tasks 1–4), #6 (Task 5), transfers (Tasks 6–7), recurring (Tasks 8–12), templates (Task 13), debts (Task 14), #9 (Task 15), dead trend-tap (Task 16). All spec sections mapped.
- **Type consistency:** `accountDerivedBalancesProvider: Map<int,double>` used by Task 3 and `totalAccountBalanceProvider`; `getRecurringDefinitions`/`watchRecurringDefinitions` defined in Task 8, used in Tasks 9 & 12; `colorForCategory(BudgetCategory,int)` defined Task 15 and used same task.
- **Migration:** single `if (from < 18)` block; `build_runner` run in Task 1 Step 5.

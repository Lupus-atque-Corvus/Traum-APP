import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/budget/budget_helpers.dart';
import 'package:traum/features/budget/budget_providers.dart';

/// Characterization tests for the budget module (logic layer).
/// Locks in current behavior of helpers, model getters, DAO calculations
/// and the derived providers before dependency major-upgrades (Phase 4).
void main() {
  // ─── Pure helpers ──────────────────────────────────────────────────────────
  group('budget_helpers.fmtAmount', () {
    test('formats thousands with German separators', () {
      expect(fmtAmount(1234.56), '1.234,56');
      expect(fmtAmount(1000000), '1.000.000,00');
    });

    test('uses absolute value (no sign) and two decimals', () {
      expect(fmtAmount(-1234.56), '1.234,56');
      expect(fmtAmount(5), '5,00');
      expect(fmtAmount(0), '0,00');
    });

    test('rounds to two decimals', () {
      expect(fmtAmount(2.005), '2,00'); // toStringAsFixed banker-free rounding
      expect(fmtAmount(2.999), '3,00');
    });
  });

  group('budget_helpers.fmtTransactionDate', () {
    test('returns Heute for today', () {
      expect(fmtTransactionDate(DateTime.now()), 'Heute');
    });

    test('returns Gestern for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(fmtTransactionDate(yesterday), 'Gestern');
    });

    test('returns day + short month for older dates', () {
      expect(fmtTransactionDate(DateTime(2025, 3, 15)), '15. Mär');
      expect(fmtTransactionDate(DateTime(2025, 12, 1)), '1. Dez');
    });
  });

  // ─── Model getters ──────────────────────────────────────────────────────────
  group('BudgetCategoryWithSpending', () {
    BudgetCategoryWithSpending make({
      required double spent,
      required double limit,
      String? emoji = '🍔',
    }) =>
        BudgetCategoryWithSpending(
          category: BudgetCategory(
            id: 1,
            name: 'Essen',
            emoji: emoji,
            monthlyLimit: limit,
            color: null,
            isExpense: true,
          ),
          spent: spent,
          budgetLimit: limit,
        );

    test('ratio is spent/limit within [0,1]', () {
      expect(make(spent: 50, limit: 100).ratio, 0.5);
    });

    test('ratio clamps above 1.0 when overspent', () {
      expect(make(spent: 150, limit: 100).ratio, 1.0);
    });

    test('ratio is 0 when limit is 0 (no division by zero)', () {
      expect(make(spent: 50, limit: 0).ratio, 0.0);
    });

    test('isOverBudget only when limit > 0 and spent exceeds it', () {
      expect(make(spent: 150, limit: 100).isOverBudget, isTrue);
      expect(make(spent: 50, limit: 100).isOverBudget, isFalse);
      expect(make(spent: 50, limit: 0).isOverBudget, isFalse);
    });

    test('emoji falls back to 💰 when category emoji is null', () {
      expect(make(spent: 1, limit: 1, emoji: null).emoji, '💰');
      expect(make(spent: 1, limit: 1).emoji, '🍔');
    });
  });

  // ─── DAO calculations (in-memory DB) ─────────────────────────────────────────
  group('BudgetDao', () {
    late TraumDatabase db;
    setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> addTx({
      required double amount,
      required DateTime date,
      String type = 'expense',
      int? categoryId,
    }) =>
        db.budgetDao.insertTransaction(TransactionsCompanion.insert(
          amount: amount,
          description: 'tx',
          date: date,
          type: Value(type),
          categoryId: Value(categoryId),
        ));

    test('getNetForMonth = income - expenses for that month only', () async {
      await addTx(amount: 1000, date: DateTime(2026, 6, 5), type: 'income');
      await addTx(amount: 200, date: DateTime(2026, 6, 10));
      await addTx(amount: 50, date: DateTime(2026, 6, 20));
      // Other month — must be ignored.
      await addTx(amount: 999, date: DateTime(2026, 5, 30), type: 'income');

      expect(await db.budgetDao.getNetForMonth(2026, 6), 750.0);
    });

    test('getTransactionsForMonth respects month boundaries', () async {
      await addTx(amount: 1, date: DateTime(2026, 6, 1)); // first day in
      await addTx(amount: 2, date: DateTime(2026, 5, 31, 23, 59)); // out (prev)
      await addTx(amount: 3, date: DateTime(2026, 7, 1)); // out (next)

      final txs = await db.budgetDao.getTransactionsForMonth(2026, 6);
      expect(txs.map((t) => t.amount), [1]);
    });

    test('getTransactionsForMonth handles December → January rollover', () async {
      await addTx(amount: 10, date: DateTime(2025, 12, 15));
      await addTx(amount: 20, date: DateTime(2026, 1, 1)); // next year, excluded

      final dec = await db.budgetDao.getTransactionsForMonth(2025, 12);
      expect(dec.map((t) => t.amount), [10]);
    });

    test('getTransactionsForMonth is ordered newest first', () async {
      await addTx(amount: 1, date: DateTime(2026, 6, 1));
      await addTx(amount: 2, date: DateTime(2026, 6, 20));
      await addTx(amount: 3, date: DateTime(2026, 6, 10));

      final txs = await db.budgetDao.getTransactionsForMonth(2026, 6);
      expect(txs.map((t) => t.amount), [2, 3, 1]);
    });

    test('getRecentTransactions orders desc and respects limit', () async {
      for (var d = 1; d <= 8; d++) {
        await addTx(amount: d.toDouble(), date: DateTime(2026, 6, d));
      }
      final recent = await db.budgetDao.getRecentTransactions(limit: 3);
      expect(recent.map((t) => t.amount), [8, 7, 6]);
    });

    test('incrementTemplateUsage bumps count and stores last amount', () async {
      final id = await db.budgetDao.insertTemplate(
        QuickTemplatesCompanion.insert(
            name: 'Kaffee', type: 'expense', useCount: const Value(2)),
      );
      await db.budgetDao.incrementTemplateUsage(id, 3.50);

      final tpl = await db.budgetDao.getTopTemplates();
      expect(tpl.single.useCount, 3);
      expect(tpl.single.defaultAmount, 3.50);
      expect(tpl.single.lastUsed, isNotNull);
    });

    test('incrementTemplateUsage is a no-op for unknown id', () async {
      // Must not throw even though the row does not exist.
      await db.budgetDao.incrementTemplateUsage(999, 1.0);
      expect(await db.budgetDao.getTopTemplates(), isEmpty);
    });

    test('getTopTemplates orders by useCount desc and limits', () async {
      await db.budgetDao.insertTemplate(QuickTemplatesCompanion.insert(
          name: 'A', type: 'expense', useCount: const Value(1)));
      await db.budgetDao.insertTemplate(QuickTemplatesCompanion.insert(
          name: 'B', type: 'expense', useCount: const Value(9)));
      await db.budgetDao.insertTemplate(QuickTemplatesCompanion.insert(
          name: 'C', type: 'expense', useCount: const Value(5)));

      final top = await db.budgetDao.getTopTemplates(limit: 2);
      expect(top.map((t) => t.name), ['B', 'C']);
    });
  });

  // ─── Accounts total balance ──────────────────────────────────────────────────
  group('AccountsDao.getTotalBalance', () {
    late TraumDatabase db;
    setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> addAccount(String type, double balance) =>
        db.accountsDao.upsertAccount(AccountsCompanion.insert(
          name: type,
          type: type,
          balance: balance,
          updatedAt: DateTime(2026, 6, 1),
        ));

    test('sums every account\'s real balance regardless of type', () async {
      await addAccount('checking', 1000);
      await addAccount('savings', 500);
      await addAccount('credit', 200); // real value, counts as +200

      expect(await db.accountsDao.getTotalBalance(), 1700.0);
    });

    test('a negative balance lowers the total by its magnitude', () async {
      await addAccount('checking', 1000);
      await addAccount('credit', -300); // counts as -300

      expect(await db.accountsDao.getTotalBalance(), 700.0);
    });

    test('empty returns 0', () async {
      expect(await db.accountsDao.getTotalBalance(), 0.0);
    });
  });

  // ─── Derived providers (ProviderContainer + DB override) ─────────────────────
  group('budget providers', () {
    late TraumDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = TraumDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });
    tearDown(() {
      container.dispose();
      db.close();
    });

    Future<void> addTx({
      required double amount,
      String type = 'expense',
      int? categoryId,
      int day = 5,
    }) =>
        db.budgetDao.insertTransaction(TransactionsCompanion.insert(
          amount: amount,
          description: 'tx',
          date: DateTime(2026, 6, day),
          type: Value(type),
          categoryId: Value(categoryId),
        ));

    test('budgetSummaryProvider sums income, expenses and balance', () async {
      await addTx(amount: 2000, type: 'income');
      await addTx(amount: 300);
      await addTx(amount: 200);

      // StreamProvider.autoDispose: keep alive so .future resolves before dispose.
      container.listen(budgetSummaryProvider((2026, 6)), (_, _) {});
      final s = await container.read(budgetSummaryProvider((2026, 6)).future);
      expect(s.income, 2000);
      expect(s.expenses, 500);
      expect(s.balance, 1500);
    });

    test('categoryExpensesProvider groups, sorts desc and maps null → Sonstiges',
        () async {
      final foodId = await db.budgetDao.insertCategory(
          BudgetCategoriesCompanion.insert(name: 'Essen'));
      await addTx(amount: 30, categoryId: foodId);
      await addTx(amount: 20, categoryId: foodId);
      await addTx(amount: 100, categoryId: null); // uncategorized

      container.listen(categoryExpensesProvider((2026, 6)), (_, _) {});
      final list =
          await container.read(categoryExpensesProvider((2026, 6)).future);
      expect(list.first.category.name, 'Sonstiges');
      expect(list.first.amount, 100);
      expect(list[1].category.name, 'Essen');
      expect(list[1].amount, 50);
    });

    test(
        'budgetCategoriesWithSpendingProvider filters to expense categories with a limit',
        () async {
      final withLimit = await db.budgetDao.insertCategory(
          BudgetCategoriesCompanion.insert(
              name: 'Essen', monthlyLimit: const Value(100)));
      // No limit → excluded.
      await db.budgetDao.insertCategory(
          BudgetCategoriesCompanion.insert(name: 'Freizeit'));
      // Income category with a limit → excluded.
      await db.budgetDao.insertCategory(BudgetCategoriesCompanion.insert(
          name: 'Gehalt',
          monthlyLimit: const Value(100),
          isExpense: const Value(false)));

      await addTx(amount: 80, categoryId: withLimit);

      container.listen(budgetCategoriesWithSpendingProvider((2026, 6)), (_, _) {});
      final list = await container
          .read(budgetCategoriesWithSpendingProvider((2026, 6)).future);
      expect(list.length, 1);
      expect(list.single.name, 'Essen');
      expect(list.single.spent, 80);
      expect(list.single.ratio, closeTo(0.8, 1e-9));
    });

    test('recentTransactionItemsProvider defaults missing category to Sonstiges',
        () async {
      await addTx(amount: 12, categoryId: null);

      container.listen(recentTransactionItemsProvider(5), (_, _) {});
      final items =
          await container.read(recentTransactionItemsProvider(5).future);
      expect(items.single.categoryName, 'Sonstiges');
      expect(items.single.amount, 12);
    });
  });
}

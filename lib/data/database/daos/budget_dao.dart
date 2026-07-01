import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Transactions, BudgetCategories, SavingsGoals, Debts, QuickTemplates, DebtItems])
class BudgetDao extends DatabaseAccessor<TraumDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  // Transactions
  Stream<List<Transaction>> watchAllTransactions() =>
      (select(transactions)
            ..where((t) => t.isRecurring.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Stream<List<Transaction>> watchTransactionsForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end) &
              t.isRecurring.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  // BudgetCategories
  Stream<List<BudgetCategory>> watchAllCategories() =>
      select(budgetCategories).watch();

  Future<int> insertCategory(BudgetCategoriesCompanion entry) =>
      into(budgetCategories).insert(entry);

  Future<bool> updateCategory(BudgetCategoriesCompanion entry) =>
      update(budgetCategories).replace(entry);

  Future<int> deleteCategory(int id) =>
      (delete(budgetCategories)..where((t) => t.id.equals(id))).go();

  // SavingsGoals
  Stream<List<SavingsGoal>> watchAllSavingsGoals() =>
      select(savingsGoals).watch();

  /// One-shot read of all savings goals (no query stream — safe for home tiles).
  Future<List<SavingsGoal>> getAllSavingsGoals() =>
      select(savingsGoals).get();

  Future<int> insertSavingsGoal(SavingsGoalsCompanion entry) =>
      into(savingsGoals).insert(entry);

  Future<bool> updateSavingsGoal(SavingsGoalsCompanion entry) =>
      update(savingsGoals).replace(entry);

  Future<int> deleteSavingsGoal(int id) =>
      (delete(savingsGoals)..where((t) => t.id.equals(id))).go();

  // Debts
  Stream<List<Debt>> watchAllDebts() => select(debts).watch();

  Future<int> insertDebt(DebtsCompanion entry) => into(debts).insert(entry);

  Future<bool> updateDebt(DebtsCompanion entry) =>
      update(debts).replace(entry);

  Future<int> deleteDebt(int id) async {
    return transaction(() async {
      await (delete(debtItems)..where((i) => i.debtId.equals(id))).go();
      return (delete(debts)..where((t) => t.id.equals(id))).go();
    });
  }

  // Debt items (positions)
  Stream<List<DebtItem>> watchDebtItems(int debtId) =>
      (select(debtItems)
            ..where((i) => i.debtId.equals(debtId))
            ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
          .watch();

  Future<int> insertDebtItem(DebtItemsCompanion entry) async {
    return transaction(() async {
      final id = await into(debtItems).insert(entry);
      await _recomputeDebtTotals(entry.debtId.value);
      return id;
    });
  }

  Future<bool> updateDebtItem(DebtItemsCompanion entry) async {
    return transaction(() async {
      final rows = await (update(debtItems)
            ..where((i) => i.id.equals(entry.id.value)))
          .write(entry);
      final row = await (select(debtItems)
            ..where((i) => i.id.equals(entry.id.value)))
          .getSingleOrNull();
      if (row != null) await _recomputeDebtTotals(row.debtId);
      return rows > 0;
    });
  }

  Future<int> deleteDebtItem(int itemId) async {
    return transaction(() async {
      final item = await (select(debtItems)..where((i) => i.id.equals(itemId)))
          .getSingleOrNull();
      final rows =
          await (delete(debtItems)..where((i) => i.id.equals(itemId))).go();
      if (item != null) await _recomputeDebtTotals(item.debtId);
      return rows;
    });
  }

  Future<void> payDebtRate(int debtId, double amount) async {
    return transaction(() async {
      final debt = await (select(debts)..where((d) => d.id.equals(debtId)))
          .getSingleOrNull();
      if (debt == null) return;
      await (update(debts)..where((d) => d.id.equals(debtId)))
          .write(DebtsCompanion(paidAmount: Value(debt.paidAmount + amount)));
      await _recomputeDebtTotals(debtId);
    });
  }

  /// Hält originalAmount/remainingAmount/isPaidOff einer Schuld konsistent:
  /// original = Summe der Positionen, remaining = clamp(original - paidAmount).
  Future<void> _recomputeDebtTotals(int debtId) async {
    final items =
        await (select(debtItems)..where((i) => i.debtId.equals(debtId))).get();
    final total = items.fold<double>(0.0, (s, i) => s + i.amount);
    final debt = await (select(debts)..where((d) => d.id.equals(debtId)))
        .getSingleOrNull();
    if (debt == null) return;
    final remaining = (total - debt.paidAmount).clamp(0.0, total);
    await (update(debts)..where((d) => d.id.equals(debtId))).write(
      DebtsCompanion(
        originalAmount: Value(total),
        remainingAmount: Value(remaining),
        isPaidOff: Value(total > 0 && remaining <= 0),
      ),
    );
  }

  // --- New Transaction methods ---

  Future<List<Transaction>> getTransactionsForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end) &
              t.isRecurring.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<Transaction?> getTransaction(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> updateTransaction(TransactionsCompanion entry) =>
      update(transactions).replace(entry);

  Stream<List<Transaction>> watchRecurringTransactions() =>
      (select(transactions)..where((t) => t.isRecurring.equals(true))).watch();

  /// One-shot read of recurring transactions (no query stream — safe for tiles).
  Future<List<Transaction>> getRecurringTransactions() =>
      (select(transactions)..where((t) => t.isRecurring.equals(true))).get();

  Future<List<BudgetCategory>> getAllCategories() =>
      select(budgetCategories).get();

  // --- QuickTemplates ---

  Stream<List<QuickTemplate>> watchQuickTemplates() =>
      (select(quickTemplates)
            ..orderBy([(t) => OrderingTerm.desc(t.useCount)]))
          .watch();

  Future<List<QuickTemplate>> getTopTemplates({int limit = 8}) =>
      (select(quickTemplates)
            ..orderBy([(t) => OrderingTerm.desc(t.useCount)])
            ..limit(limit))
          .get();

  Future<int> insertTemplate(QuickTemplatesCompanion entry) =>
      into(quickTemplates).insert(entry);

  Future<int> deleteTemplate(int id) =>
      (delete(quickTemplates)..where((t) => t.id.equals(id))).go();

  Future<void> incrementTemplateUsage(int id, double amount) async {
    final template = await (select(quickTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (template == null) return;
    await (update(quickTemplates)..where((t) => t.id.equals(id))).write(
      QuickTemplatesCompanion(
        useCount: Value(template.useCount + 1),
        lastUsed: Value(DateTime.now()),
        defaultAmount: Value(amount),
      ),
    );
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 5}) =>
      (select(transactions)
            ..where((t) => t.isRecurring.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .get();

  Future<double> getNetForMonth(int year, int month) async {
    final txs = await getTransactionsForMonth(year, month);
    final income = txs
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final expenses = txs
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    return income - expenses;
  }

  Future<void> setLastPostedMonth(int id, String? month) =>
      (update(transactions)..where((t) => t.id.equals(id)))
          .write(TransactionsCompanion(lastPostedMonth: Value(month)));
}

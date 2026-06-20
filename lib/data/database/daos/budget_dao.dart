import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Transactions, BudgetCategories, SavingsGoals, Debts, QuickTemplates])
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

  Future<int> deleteDebt(int id) =>
      (delete(debts)..where((t) => t.id.equals(id))).go();

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
}

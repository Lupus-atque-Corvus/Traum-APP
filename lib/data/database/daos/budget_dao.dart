import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Transactions, BudgetCategories, SavingsGoals, Debts])
class BudgetDao extends DatabaseAccessor<TraumDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  // Transactions
  Stream<List<Transaction>> watchAllTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Stream<List<Transaction>> watchTransactionsForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
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
}

import '../database/traum_database.dart';

class BudgetRepository {
  final BudgetDao _dao;
  BudgetRepository(this._dao);

  Stream<List<Transaction>> watchAllTransactions() =>
      _dao.watchAllTransactions();
  Stream<List<Transaction>> watchTransactionsForMonth(int year, int month) =>
      _dao.watchTransactionsForMonth(year, month);
  Future<int> addTransaction(TransactionsCompanion e) =>
      _dao.insertTransaction(e);
  Future<int> deleteTransaction(int id) => _dao.deleteTransaction(id);

  Stream<List<BudgetCategory>> watchAllCategories() =>
      _dao.watchAllCategories();
  Future<int> addCategory(BudgetCategoriesCompanion e) =>
      _dao.insertCategory(e);
  Future<bool> updateCategory(BudgetCategoriesCompanion e) =>
      _dao.updateCategory(e);
  Future<int> deleteCategory(int id) => _dao.deleteCategory(id);

  Stream<List<SavingsGoal>> watchAllSavingsGoals() =>
      _dao.watchAllSavingsGoals();
  Future<int> addSavingsGoal(SavingsGoalsCompanion e) =>
      _dao.insertSavingsGoal(e);
  Future<bool> updateSavingsGoal(SavingsGoalsCompanion e) =>
      _dao.updateSavingsGoal(e);
  Future<int> deleteSavingsGoal(int id) => _dao.deleteSavingsGoal(id);

  Stream<List<Debt>> watchAllDebts() => _dao.watchAllDebts();
  Future<int> addDebt(DebtsCompanion e) => _dao.insertDebt(e);
  Future<bool> updateDebt(DebtsCompanion e) => _dao.updateDebt(e);
  Future<int> deleteDebt(int id) => _dao.deleteDebt(id);

  Stream<List<DebtItem>> watchDebtItems(int debtId) =>
      _dao.watchDebtItems(debtId);
  Future<int> addDebtItem(DebtItemsCompanion e) => _dao.insertDebtItem(e);
  Future<bool> updateDebtItem(DebtItemsCompanion e) => _dao.updateDebtItem(e);
  Future<int> deleteDebtItem(int id) => _dao.deleteDebtItem(id);
  Future<void> payDebtRate(int debtId, double amount) =>
      _dao.payDebtRate(debtId, amount);
}

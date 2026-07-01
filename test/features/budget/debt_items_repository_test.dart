// test/features/budget/debt_items_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/repositories/budget_repository.dart';

void main() {
  test('repository forwards debt item ops and pay-rate to the dao', () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = BudgetRepository(db.budgetDao);

    final debtId = await repo.addDebt(
      DebtsCompanion.insert(
          creditor: 'Papa', originalAmount: 0, remainingAmount: 0),
    );
    await repo.addDebtItem(
        DebtItemsCompanion.insert(debtId: debtId, description: 'X', amount: 80));
    await repo.payDebtRate(debtId, 30);

    final items = await repo.watchDebtItems(debtId).first;
    expect(items, hasLength(1));

    final debt =
        await (db.select(db.debts)..where((d) => d.id.equals(debtId)))
            .getSingle();
    expect(debt.originalAmount, 80);
    expect(debt.remainingAmount, 50);
  });
}

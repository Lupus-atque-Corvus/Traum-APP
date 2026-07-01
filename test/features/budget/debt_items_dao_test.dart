// test/features/budget/debt_items_dao_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> newDebt() => db.budgetDao.insertDebt(
        DebtsCompanion.insert(
            creditor: 'Mama', originalAmount: 0, remainingAmount: 0),
      );

  Future<Debt> readDebt(int id) =>
      (db.select(db.debts)..where((d) => d.id.equals(id))).getSingle();

  test('adding items sets originalAmount to their sum and remaining = sum',
      () async {
    final id = await newDebt();
    await db.budgetDao.insertDebtItem(
        DebtItemsCompanion.insert(debtId: id, description: 'A', amount: 60));
    await db.budgetDao.insertDebtItem(
        DebtItemsCompanion.insert(debtId: id, description: 'B', amount: 150));

    final debt = await readDebt(id);
    expect(debt.originalAmount, 210);
    expect(debt.remainingAmount, 210);
    expect(debt.isPaidOff, false);
  });

  test('paying a rate raises paidAmount and lowers remaining', () async {
    final id = await newDebt();
    await db.budgetDao.insertDebtItem(
        DebtItemsCompanion.insert(debtId: id, description: 'A', amount: 100));

    await db.budgetDao.payDebtRate(id, 40);

    final debt = await readDebt(id);
    expect(debt.paidAmount, 40);
    expect(debt.remainingAmount, 60);
    expect(debt.isPaidOff, false);
  });

  test('adding an item after a payment increases remaining by the item amount',
      () async {
    final id = await newDebt();
    await db.budgetDao.insertDebtItem(
        DebtItemsCompanion.insert(debtId: id, description: 'A', amount: 100));
    await db.budgetDao.payDebtRate(id, 100); // fully paid

    var debt = await readDebt(id);
    expect(debt.isPaidOff, true);
    expect(debt.remainingAmount, 0);

    await db.budgetDao.insertDebtItem(
        DebtItemsCompanion.insert(debtId: id, description: 'B', amount: 50));

    debt = await readDebt(id);
    expect(debt.originalAmount, 150);
    expect(debt.paidAmount, 100);
    expect(debt.remainingAmount, 50);
    expect(debt.isPaidOff, false);
  });

  test('deleting an item recomputes totals', () async {
    final id = await newDebt();
    final aId = await db.budgetDao.insertDebtItem(
        DebtItemsCompanion.insert(debtId: id, description: 'A', amount: 60));
    await db.budgetDao.insertDebtItem(
        DebtItemsCompanion.insert(debtId: id, description: 'B', amount: 40));

    await db.budgetDao.deleteDebtItem(aId);

    final debt = await readDebt(id);
    expect(debt.originalAmount, 40);
    expect(debt.remainingAmount, 40);
  });

  test('deleting a debt also removes its items', () async {
    final id = await newDebt();
    await db.budgetDao.insertDebtItem(
        DebtItemsCompanion.insert(debtId: id, description: 'A', amount: 60));
    await db.budgetDao.deleteDebt(id);
    final items =
        await (db.select(db.debtItems)..where((i) => i.debtId.equals(id))).get();
    expect(items, isEmpty);
  });
}

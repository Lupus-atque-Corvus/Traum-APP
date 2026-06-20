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
    final defs = await db.budgetDao.getRecurringTransactions();
    expect(defs.single.description, 'def');
  });
}

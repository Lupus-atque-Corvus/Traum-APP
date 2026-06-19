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

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

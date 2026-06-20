// test/features/budget/cashflow_line_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/budget/budget_providers.dart';

void main() {
  test('cashflow line anchors at opening + prior net, excludes transfers', () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await db.accountsDao.into(db.accounts).insert(AccountsCompanion.insert(
        name: 'A', type: 'checking', balance: 1000, updatedAt: DateTime.now()));
    Future<void> tx(double a, String t, DateTime d, {int? to}) =>
        db.budgetDao.insertTransaction(TransactionsCompanion.insert(
          amount: a, description: 't', date: d, type: Value(t), toAccountId: Value(to)));
    await tx(200, 'income', DateTime(2026, 5, 10));     // prior month
    await tx(50, 'expense', DateTime(2026, 6, 2));      // day 2
    await tx(999, 'transfer', DateTime(2026, 6, 3), to: 1); // ignored

    c.listen(dailyBalanceSpotsProvider((2026, 6)), (_, _) {});
    final spots = await c.read(dailyBalanceSpotsProvider((2026, 6)).future);
    expect(spots.first.y, 1200); // anchor = 1000 opening + 200 prior income; day-1 has no booking
    expect(spots[1].y, 1150);   // after day-2 expense: 1200 − 50
  });
}

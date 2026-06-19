// test/features/budget/derived_balance_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/budget/budget_providers.dart';

void main() {
  late TraumDatabase db;
  late ProviderContainer c;
  setUp(() {
    db = TraumDatabase.forTesting(NativeDatabase.memory());
    c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
  });
  tearDown(() { c.dispose(); db.close(); });

  test('derived balance = opening + income - expense -/+ transfers', () async {
    final giro = await db.accountsDao.into(db.accounts).insert(
      AccountsCompanion.insert(name: 'Giro', type: 'checking',
          balance: 1000, updatedAt: DateTime.now()));
    final spar = await db.accountsDao.into(db.accounts).insert(
      AccountsCompanion.insert(name: 'Spar', type: 'savings',
          balance: 0, updatedAt: DateTime.now()));
    Future<void> tx(double a, String t, {int? acc, int? to}) =>
        db.budgetDao.insertTransaction(TransactionsCompanion.insert(
          amount: a, description: 't', date: DateTime(2026, 6, 5),
          type: Value(t), accountId: Value(acc), toAccountId: Value(to)));
    await tx(2000, 'income', acc: giro);
    await tx(500, 'expense', acc: giro);
    await tx(300, 'transfer', acc: giro, to: spar);

    c.listen(accountDerivedBalancesProvider, (_, _) {});
    final map = await c.read(accountDerivedBalancesProvider.future);
    expect(map[giro], 1000 + 2000 - 500 - 300); // 2200
    expect(map[spar], 0 + 300);                  // 300
  });

  test('totalAccountBalanceProvider applies credit rule: checking +, credit −', () async {
    final checking = await db.accountsDao.into(db.accounts).insert(
      AccountsCompanion.insert(name: 'Checking', type: 'checking',
          balance: 1000, updatedAt: DateTime.now()));
    final credit = await db.accountsDao.into(db.accounts).insert(
      AccountsCompanion.insert(name: 'Credit', type: 'credit',
          balance: 500, updatedAt: DateTime.now()));
    Future<void> tx(double a, String t, {int? acc}) =>
        db.budgetDao.insertTransaction(TransactionsCompanion.insert(
          amount: a, description: 't', date: DateTime(2026, 6, 5),
          type: Value(t), accountId: Value(acc)));
    // checking: 1000 opening + 200 income = 1200 → contributes +1200
    await tx(200, 'income', acc: checking);
    // credit: 500 opening − 100 expense = 400 derived → contributes −400 (credit rule)
    await tx(100, 'expense', acc: credit);

    c.listen(totalAccountBalanceProvider, (_, _) {});
    final total = await c.read(totalAccountBalanceProvider.future);
    expect(total, 800.0); // 1200 + (−400) = 800
  });
}

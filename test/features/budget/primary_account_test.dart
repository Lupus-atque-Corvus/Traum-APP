// test/features/budget/primary_account_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  test('marking an account primary demotes any previous primary', () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    Future<void> add(String name, {required bool primary}) =>
        db.accountsDao.upsertAccount(AccountsCompanion.insert(
          name: name,
          type: 'checking',
          balance: 0,
          updatedAt: DateTime.now(),
          isPrimary: Value(primary),
        ));

    await add('A', primary: true);
    await add('B', primary: true); // should demote A

    final accounts = await db.accountsDao.getAll();
    final primaries = accounts.where((a) => a.isPrimary).toList();
    expect(primaries.length, 1);
    expect(primaries.single.name, 'B');
  });

  test('saving a non-primary account leaves the existing primary intact',
      () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.accountsDao.upsertAccount(AccountsCompanion.insert(
      name: 'Main',
      type: 'checking',
      balance: 0,
      updatedAt: DateTime.now(),
      isPrimary: const Value(true),
    ));
    await db.accountsDao.upsertAccount(AccountsCompanion.insert(
      name: 'Side',
      type: 'savings',
      balance: 0,
      updatedAt: DateTime.now(),
      isPrimary: const Value(false),
    ));

    final accounts = await db.accountsDao.getAll();
    final primaries = accounts.where((a) => a.isPrimary).toList();
    expect(primaries.length, 1);
    expect(primaries.single.name, 'Main');
  });
}

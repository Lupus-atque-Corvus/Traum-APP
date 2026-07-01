// test/features/budget/debt_items_schema_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  test('debt item persists and links to a debt; paidAmount defaults to 0',
      () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final debtId = await db.budgetDao.insertDebt(
      DebtsCompanion.insert(
        creditor: 'Mama',
        originalAmount: 0,
        remainingAmount: 0,
      ),
    );

    final itemId = await db.into(db.debtItems).insert(
      DebtItemsCompanion.insert(
        debtId: debtId,
        description: 'Tankfüllung',
        amount: 60,
      ),
    );

    final items =
        await (db.select(db.debtItems)..where((i) => i.debtId.equals(debtId)))
            .get();
    expect(items, hasLength(1));
    expect(items.first.id, itemId);
    expect(items.first.description, 'Tankfüllung');
    expect(items.first.amount, 60);

    final debt =
        await (db.select(db.debts)..where((d) => d.id.equals(debtId)))
            .getSingleOrNull();
    expect(debt!.paidAmount, 0);
  });
}

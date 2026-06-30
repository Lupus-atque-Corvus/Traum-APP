import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/budget/budget_helpers.dart';

void main() {
  group('fullTransactionCompanion round-trip', () {
    late TraumDatabase db;
    setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('update via full companion preserves every column', () async {
      final id = await db.budgetDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: 12.50,
          description: 'Original',
          date: DateTime(2026, 6, 24, 15, 28),
          type: const Value('expense'),
          categoryId: const Value(7),
          note: const Value('Notiz A'),
          accountId: const Value(3),
          receiptImagePath: const Value('/img/bon.jpg'),
        ),
      );
      final original = (await db.budgetDao.getTransaction(id))!;

      // Override only the note — everything else must survive.
      await db.budgetDao.updateTransaction(
        fullTransactionCompanion(original).copyWith(note: const Value('Notiz B')),
      );

      final updated = (await db.budgetDao.getTransaction(id))!;
      expect(updated.note, 'Notiz B');
      expect(updated.amount, 12.50);
      expect(updated.description, 'Original');
      expect(updated.categoryId, 7);
      expect(updated.accountId, 3); // would be wiped by an incomplete companion
      expect(updated.receiptImagePath, '/img/bon.jpg');
      expect(updated.createdAt, original.createdAt);
    });

    test('edit can change description and note independently', () async {
      final id = await db.budgetDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: 5.45,
          description: 'Haarentfernungs Creme',
          date: DateTime(2026, 6, 24),
          note: const Value('Haarentfernungs Creme'),
        ),
      );
      final original = (await db.budgetDao.getTransaction(id))!;

      await db.budgetDao.updateTransaction(
        fullTransactionCompanion(original).copyWith(
          description: const Value('Pflege Drogerie'),
          note: const Value('für Reise'),
        ),
      );

      final updated = (await db.budgetDao.getTransaction(id))!;
      expect(updated.description, 'Pflege Drogerie');
      expect(updated.note, 'für Reise');
    });
  });
}

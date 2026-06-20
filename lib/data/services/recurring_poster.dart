import 'package:drift/drift.dart';
import '../database/traum_database.dart';

class RecurringPoster {
  static String _key(int y, int m) => '$y-${m.toString().padLeft(2, '0')}';

  static Future<void> runIfNeeded(TraumDatabase db, {DateTime? now}) async {
    final today = now ?? DateTime.now();
    final defs = await db.budgetDao.getRecurringTransactions();
    for (final def in defs) {
      final day = def.recurringDay ?? def.date.day;
      var cursor = def.lastPostedMonth == null
          ? DateTime(def.date.year, def.date.month, 1)
          : _nextMonth(def.lastPostedMonth!);
      var lastPosted = def.lastPostedMonth;
      while (!cursor.isAfter(DateTime(today.year, today.month, 1))) {
        final isCurrent =
            cursor.year == today.year && cursor.month == today.month;
        if (!isCurrent || today.day >= day) {
          final dim = DateTime(cursor.year, cursor.month + 1, 0).day;
          await db.budgetDao.insertTransaction(TransactionsCompanion.insert(
            amount: def.amount,
            description: def.description,
            date: DateTime(cursor.year, cursor.month, day > dim ? dim : day),
            type: Value(def.type),
            categoryId: Value(def.categoryId),
            accountId: Value(def.accountId),
            note: Value(def.note),
          ));
          lastPosted = _key(cursor.year, cursor.month);
        }
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      if (lastPosted != def.lastPostedMonth) {
        await db.budgetDao.setLastPostedMonth(def.id, lastPosted);
      }
    }
  }

  static DateTime _nextMonth(String yyyymm) {
    final p = yyyymm.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]) + 1, 1);
  }
}

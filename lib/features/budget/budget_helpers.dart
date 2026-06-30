import 'package:drift/drift.dart' show Value;
import '../../data/database/traum_database.dart';

String fmtAmount(double amount) {
  // German number format: 1.234,56
  final str = amount.abs().toStringAsFixed(2).replaceAll('.', ',');
  final parts = str.split(',');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '$intPart,${parts[1]}';
}

String fmtTransactionDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final txDay = DateTime(date.year, date.month, date.day);
  if (txDay == today) return 'Heute';
  if (txDay == today.subtract(const Duration(days: 1))) return 'Gestern';
  return '${date.day}. ${_monthName(date.month)}';
}

String _monthName(int month) {
  const names = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];
  return names[month - 1];
}

/// Builds a complete TransactionsCompanion from an existing row — every column
/// is set explicitly so Drift's update().replace() does not reset absent
/// columns to their table defaults. Override specific fields with .copyWith().
TransactionsCompanion fullTransactionCompanion(Transaction tx) {
  return TransactionsCompanion(
    id: Value(tx.id),
    amount: Value(tx.amount),
    description: Value(tx.description),
    categoryId: Value(tx.categoryId),
    type: Value(tx.type),
    date: Value(tx.date),
    note: Value(tx.note),
    createdAt: Value(tx.createdAt),
    receiptImagePath: Value(tx.receiptImagePath),
    isRecurring: Value(tx.isRecurring),
    recurringDay: Value(tx.recurringDay),
    templateName: Value(tx.templateName),
    splitFromId: Value(tx.splitFromId),
    accountId: Value(tx.accountId),
    toAccountId: Value(tx.toAccountId),
    lastPostedMonth: Value(tx.lastPostedMonth),
  );
}

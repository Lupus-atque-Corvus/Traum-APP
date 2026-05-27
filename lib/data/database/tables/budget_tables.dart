import 'package:drift/drift.dart';

class BudgetCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get emoji => text().nullable()();
  RealColumn get monthlyLimit => real().nullable()();
  IntColumn get color => integer().nullable()();
  BoolColumn get isExpense => boolean().withDefault(const Constant(true))();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get receiptImagePath => text().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  IntColumn get recurringDay => integer().nullable()();
  TextColumn get templateName => text().nullable()();
  IntColumn get splitFromId => integer().nullable()();
}

class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get creditor => text()();
  RealColumn get originalAmount => real()();
  RealColumn get remainingAmount => real()();
  RealColumn get interestRate => real().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get isPaidOff => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class QuickTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get defaultAmount => real().nullable()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get type => text()(); // 'expense' or 'income'
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsed => dateTime().nullable()();
}

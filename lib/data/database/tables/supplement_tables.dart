import 'package:drift/drift.dart';

class Supplements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get dosageAmount => text().nullable()();
  TextColumn get dosageUnit => text().nullable()();
  TextColumn get timings => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SupplementLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplementId => integer().references(Supplements, #id)();
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get timing => text().nullable()();
}

import 'package:drift/drift.dart';

class AbstinenceTrackers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get emoji => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  TextColumn get note => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  /// Optional Kosten pro Tag der vermiedenen Gewohnheit (für "Geld gespart").
  RealColumn get costPerDay => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AbstinenceEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackerId => integer().references(AbstinenceTrackers, #id)();
  TextColumn get type => text()();
  DateTimeColumn get eventDate => dateTime()();
  TextColumn get note => text().nullable()();
}

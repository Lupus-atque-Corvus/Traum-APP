import 'package:drift/drift.dart';

class PeriodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get flowIntensity => integer().withDefault(const Constant(2))();
  TextColumn get note => text().nullable()();
}

class CycleCalculations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get periodEntryId => integer().references(PeriodEntries, #id)();
  IntColumn get cycleLength => integer()();
  DateTimeColumn get ovulationDate => dateTime().nullable()();
  DateTimeColumn get fertileStart => dateTime().nullable()();
  DateTimeColumn get fertileEnd => dateTime().nullable()();
  DateTimeColumn get nextPeriodPredicted => dateTime().nullable()();
}

class PeriodSymptoms extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get logDate => dateTime()();
  TextColumn get symptom => text()();
  IntColumn get intensity => integer().withDefault(const Constant(1))();
  TextColumn get note => text().nullable()();
}

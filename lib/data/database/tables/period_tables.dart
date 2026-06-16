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

/// One row per calendar day (date-only). Holds non-period daily tracking.
class DailyLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get logDate => dateTime()();
  IntColumn get mood => integer().nullable()();          // 1..5
  IntColumn get energy => integer().nullable()();         // 1..5
  RealColumn get bbt => real().nullable()();              // °C, e.g. 36.72
  IntColumn get cervicalMucus => integer().nullable()();  // CervicalMucus index
  IntColumn get sexEvent => integer().nullable()();       // SexEvent index
  TextColumn get note => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{logDate}];
}

/// Singleton (id == 0). Per-user cycle settings.
class CycleProfile extends Table {
  IntColumn get id => integer()(); // always 0
  DateTimeColumn get menarcheDate => dateTime().nullable()();
  IntColumn get lutealPhaseOverride => integer().nullable()(); // days; null → 14

  @override
  Set<Column> get primaryKey => {id};
}

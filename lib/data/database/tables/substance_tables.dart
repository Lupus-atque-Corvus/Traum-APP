import 'package:drift/drift.dart';

class SubstanceCaches extends Table {
  TextColumn get substanceId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get dataJson => text()();
  TextColumn get source => text()(); // 'openfda' | 'pubchem'
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {substanceId};
}

/// Persistiertes Einnahme-/Konsum-Log einer Substanz.
class SubstanceIntakeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get substanceName => text()();
  TextColumn get dosage => text().nullable()();
  TextColumn get unit => text().nullable()();
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get note => text().nullable()();
}

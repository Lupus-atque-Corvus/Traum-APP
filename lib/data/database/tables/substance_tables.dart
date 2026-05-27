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

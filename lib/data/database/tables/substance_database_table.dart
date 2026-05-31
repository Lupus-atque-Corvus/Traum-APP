import 'package:drift/drift.dart';

class SubstanceDatabaseEntries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get nameLower => text()(); // pre-lowercased for fast LIKE search
  TextColumn get type => text()(); // 'medication' | 'supplement'
  TextColumn get category => text().nullable()();
  TextColumn get mechanism => text().nullable()();
  TextColumn get commonDosage => text().nullable()();
  TextColumn get adverseEventsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get interactionsJson =>
      text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

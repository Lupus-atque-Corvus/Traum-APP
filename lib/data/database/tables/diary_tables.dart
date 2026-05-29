import 'package:drift/drift.dart';

class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get mediaPath => text()();
  TextColumn get mediaType => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

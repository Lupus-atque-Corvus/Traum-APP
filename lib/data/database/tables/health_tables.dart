import 'package:drift/drift.dart';

class WeightLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get weightKg => real()();
  DateTimeColumn get logDate => dateTime()();
  TextColumn get note => text().nullable()();
}

class BodyMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get logDate => dateTime()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get hipsCm => real().nullable()();
  RealColumn get thighCm => real().nullable()();
  RealColumn get bicepCm => real().nullable()();
  RealColumn get shoulderCm => real().nullable()();
  RealColumn get calfCm => real().nullable()();
  RealColumn get neckCm => real().nullable()();
  RealColumn get bodyFatPct => real().nullable()();
}

class SleepLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get bedtime => dateTime()();
  DateTimeColumn get wakeTime => dateTime()();
  IntColumn get qualityStars => integer().nullable()();
  TextColumn get note => text().nullable()();
}

class MoodLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get logDate => dateTime()();
  IntColumn get moodScore => integer()();
  TextColumn get note => text().nullable()();
}

class PhotoLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get logDate => dateTime()();
  TextColumn get imagePath => text()();
  TextColumn get category => text().withDefault(const Constant('front'))();
  TextColumn get note => text().nullable()();
}

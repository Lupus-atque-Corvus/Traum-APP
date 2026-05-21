import 'package:drift/drift.dart';

class WorkoutPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WorkoutDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().references(WorkoutPlans, #id)();
  TextColumn get name => text()();
  IntColumn get dayOfWeek => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  // New in v3:
  TextColumn get primaryMuscles =>
      text().withDefault(const Constant('[]'))();
  TextColumn get secondaryMuscles =>
      text().withDefault(const Constant('[]'))();
  TextColumn get difficulty => text().nullable()();
  TextColumn get mechanic => text().nullable()();
  TextColumn get force => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isBookmarked =>
      boolean().withDefault(const Constant(false))();
  // Existing:
  TextColumn get equipment => text().nullable()();
  TextColumn get instructions => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().nullable()();
  IntColumn get dayId => integer().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
}

class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setNumber => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get setType =>
      text().withDefault(const Constant('normal'))();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
}

class WorkoutDayExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayId => integer().references(WorkoutDays, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get defaultSets => integer().withDefault(const Constant(3))();
  IntColumn get defaultReps => integer().withDefault(const Constant(10))();
  // New in v3:
  TextColumn get notes => text().nullable()();
  IntColumn get defaultRestSeconds =>
      integer().withDefault(const Constant(90))();
  TextColumn get progressionType =>
      text().withDefault(const Constant('linear'))();
  IntColumn get supersetGroup => integer().nullable()();
}

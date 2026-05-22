# Blast Training Upgrade — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trainingsmodul um 7 Features aus der Blast-App-Analyse erweitern: interaktive Körperkarte, Rest-Timer, Primär/Sekundär-Muskeln, fl_chart-Fortschrittsdiagramme, Favoriten, Body-Map-Heatmap, kg/lbs-Einstellung.

**Architecture:** DB-Migration v3 als Fundament → neue Widgets (BodyMapWidget, RestTimerWidget) → Integration in bestehende Screens → Lokalisierung.

**Tech Stack:** Flutter + Drift (SQLite v3 Migration) + flutter_svg (SVG-Body-Map via String-Replacement) + fl_chart (LineChart/BarChart) + SharedPreferences (Unit-Einstellung) + Riverpod

---

## File Map

| Datei | Aktion | Beschreibung |
|---|---|---|
| `lib/data/database/tables/training_tables.dart` | Modify | Neue Spalten Exercises + WorkoutDayExercises |
| `lib/data/database/traum_database.dart` | Modify | Schema v3 Migration |
| `lib/data/database/daos/training_dao.dart` | Modify | toggleBookmark, watchBookmarked |
| `lib/features/training/widgets/body_map_svg_data.dart` | **Create** | SVG-Strings (male front/back) |
| `lib/features/training/widgets/body_map_widget.dart` | **Create** | BodyMapWidget + Muscle-Mapping |
| `lib/features/training/widgets/rest_timer_widget.dart` | **Create** | Countdown-BottomSheet |
| `lib/features/training/active_workout_screen.dart` | Modify | Rest-Timer nach Set, kg/lbs |
| `lib/features/training/exercise_library_screen.dart` | Modify | Bookmark-Toggle + Filter-Tab |
| `lib/features/training/exercise_progress_screen.dart` | Modify | fl_chart LineChart + BarChart |
| `lib/features/training/muscle_heatmap_screen.dart` | Modify | BodyMapWidget oben integrieren |
| `lib/core/providers/unit_preference_provider.dart` | **Create** | SharedPreferences kg/lbs |
| `lib/l10n/app_de.arb` | Modify | Neue DE-Strings |
| `lib/l10n/app_en.arb` | Modify | Neue EN-Strings |
| `test/data/database/training_v3_migration_test.dart` | **Create** | DB-Migrations-Tests |
| `test/features/training/widgets/body_map_widget_test.dart` | **Create** | BodyMap-Widget-Tests |
| `test/features/training/widgets/rest_timer_widget_test.dart` | **Create** | RestTimer-Tests |

---

## Task 1: DB Schema v3 Migration

**Files:**
- Modify: `traum_app/lib/data/database/tables/training_tables.dart`
- Modify: `traum_app/lib/data/database/traum_database.dart`
- Create: `traum_app/test/data/database/training_v3_migration_test.dart`

- [ ] **Step 1: Failing test schreiben**

```dart
// test/data/database/training_v3_migration_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('Exercise has isBookmarked column defaulting to false', () async {
    final id = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Bankdrücken', muscleGroup: 'Brust'),
    );
    final ex = await (db.select(db.exercises)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(ex.isBookmarked, false);
    expect(ex.primaryMuscles, '[]');
    expect(ex.secondaryMuscles, '[]');
    expect(ex.difficulty, null);
  });

  test('toggleBookmark flips isBookmarked', () async {
    final id = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Kniebeugen', muscleGroup: 'Beine'),
    );
    await db.trainingDao.toggleBookmark(id, true);
    final ex = await (db.select(db.exercises)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(ex.isBookmarked, true);
  });

  test('WorkoutDayExercise has defaultRestSeconds column defaulting to 90', () async {
    final planId = await db.trainingDao.insertPlan(
        WorkoutPlansCompanion.insert(name: 'Plan'));
    final dayId = await db.trainingDao.insertDay(
        WorkoutDaysCompanion.insert(planId: planId, name: 'Tag A'));
    final exId = await db.trainingDao.insertExercise(
        ExercisesCompanion.insert(name: 'Test', muscleGroup: 'Brust'));
    await db.trainingDao.insertDayExercise(
        WorkoutDayExercisesCompanion.insert(dayId: dayId, exerciseId: exId));
    final rows = await db.trainingDao.getDayExercises(dayId);
    expect(rows.first.defaultRestSeconds, 90);
  });
}
```

- [ ] **Step 2: Test ausführen — muss FAIL sein**

```
cd traum_app
flutter test test/data/database/training_v3_migration_test.dart
```
Erwartet: Kompilierfehler (isBookmarked / primaryMuscles existieren noch nicht).

- [ ] **Step 3: training_tables.dart erweitern**

```dart
// lib/data/database/tables/training_tables.dart
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
  // Neu in v3:
  TextColumn get primaryMuscles =>
      text().withDefault(const Constant('[]'))();
  TextColumn get secondaryMuscles =>
      text().withDefault(const Constant('[]'))();
  TextColumn get difficulty => text().nullable()(); // beginner/intermediate/advanced
  TextColumn get mechanic => text().nullable()();   // compound/isolation
  TextColumn get force => text().nullable()();      // push/pull/static
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isBookmarked =>
      boolean().withDefault(const Constant(false))();
  // Alt:
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
  // Neu in v3:
  TextColumn get notes => text().nullable()();
  IntColumn get defaultRestSeconds =>
      integer().withDefault(const Constant(90))();
  TextColumn get progressionType =>
      text().withDefault(const Constant('linear'))();
  IntColumn get supersetGroup => integer().nullable()();
}
```

- [ ] **Step 4: traum_database.dart — Migration v3 eintragen**

```dart
// lib/data/database/traum_database.dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (migrator, from, to) async {
    if (from < 2) {
      await migrator.createTable(workoutDayExercises);
    }
    if (from < 3) {
      // Neue Spalten in Exercises
      await migrator.addColumn(exercises, exercises.primaryMuscles);
      await migrator.addColumn(exercises, exercises.secondaryMuscles);
      await migrator.addColumn(exercises, exercises.difficulty);
      await migrator.addColumn(exercises, exercises.mechanic);
      await migrator.addColumn(exercises, exercises.force);
      await migrator.addColumn(exercises, exercises.imageUrl);
      await migrator.addColumn(exercises, exercises.isBookmarked);
      // Neue Spalten in WorkoutDayExercises
      await migrator.addColumn(workoutDayExercises, workoutDayExercises.notes);
      await migrator.addColumn(workoutDayExercises, workoutDayExercises.defaultRestSeconds);
      await migrator.addColumn(workoutDayExercises, workoutDayExercises.progressionType);
      await migrator.addColumn(workoutDayExercises, workoutDayExercises.supersetGroup);
    }
  },
);
```

- [ ] **Step 5: DAO — toggleBookmark + watchBookmarkedExercises hinzufügen**

In `training_dao.dart` nach `deleteExercise`:
```dart
Future<void> toggleBookmark(int exerciseId, bool value) =>
    (update(exercises)..where((t) => t.id.equals(exerciseId)))
        .write(ExercisesCompanion(isBookmarked: Value(value)));

Stream<List<Exercise>> watchBookmarkedExercises() =>
    (select(exercises)..where((t) => t.isBookmarked.equals(true))).watch();
```

- [ ] **Step 6: build_runner ausführen**

```
cd traum_app
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Test ausführen — muss PASS sein**

```
flutter test test/data/database/training_v3_migration_test.dart
```

- [ ] **Step 8: Commit**

```
git add lib/data/database/tables/training_tables.dart lib/data/database/traum_database.dart lib/data/database/daos/training_dao.dart test/data/database/training_v3_migration_test.dart
git commit -m "feat(db): schema v3 — extend Exercises + WorkoutDayExercises with blast-inspired fields"
```

---

## Task 2: BodyMapWidget

**Files:**
- Create: `lib/features/training/widgets/body_map_svg_data.dart`
- Create: `lib/features/training/widgets/body_map_widget.dart`
- Create: `test/features/training/widgets/body_map_widget_test.dart`

- [ ] **Step 1: Failing test schreiben**

```dart
// test/features/training/widgets/body_map_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:traum/features/training/widgets/body_map_widget.dart';

void main() {
  testWidgets('renders SvgPicture for front view', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BodyMapWidget(primaryMuscles: ['pectorals'], secondaryMuscles: []),
      ),
    ));
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('renders back view when showBack is true', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BodyMapWidget(
          primaryMuscles: ['lats'],
          secondaryMuscles: [],
          showBack: true,
        ),
      ),
    ));
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  test('musclesForGroup maps Brust to pectorals', () {
    expect(BodyMapWidget.musclesForGroup('Brust'), contains('pectorals'));
  });

  test('musclesForGroup maps Rücken to lats', () {
    expect(BodyMapWidget.musclesForGroup('Rücken'), contains('lats'));
  });

  test('musclesForGroup returns empty for unknown group', () {
    expect(BodyMapWidget.musclesForGroup('Unbekannt'), isEmpty);
  });
}
```

- [ ] **Step 2: Test ausführen — muss FAIL (Datei fehlt)**

```
flutter test test/features/training/widgets/body_map_widget_test.dart
```

- [ ] **Step 3: body_map_svg_data.dart erstellen**

```dart
// lib/features/training/widgets/body_map_svg_data.dart
// SVG-Daten direkt aus Blast BodyMapViewManager.java extrahiert.
// Jede Muskelgruppe hat eine eindeutige Füllfarbe für Color-Replacement.
class BodyMapSvgData {
  BodyMapSvgData._();

  static const String maleFront = r'''
<svg width="100%" height="100%" viewBox="0 0 213 524" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" xmlns:serif="http://www.serif.com/" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linecap:square;stroke-linejoin:round;stroke-miterlimit:1.5;">
    <g id="Male-Muscle-Front">
        <path id="calves" d="M69.698,392.53c-10.873,32.322 6.972,63.414 11.813,97.695c3.646,-16.375 2.77,-60.451 2.054,-92.602c0.247,-11.228 -8.531,-12.97 -13.867,-5.093Zm72.751,0c10.873,32.322 -6.972,63.414 -11.813,97.695c-3.646,-16.375 -2.77,-60.451 -2.054,-92.602c-0.246,-11.228 8.531,-12.97 13.867,-5.093Zm-45.123,5.766c-3.503,13.129 -4.736,26.197 -4.953,37.321c-0.218,11.125 0.58,20.307 1.137,25.664c9.464,-17.487 11.134,-38.312 3.816,-62.985Zm17.495,-0c3.503,13.129 4.736,26.197 4.953,37.321c0.218,11.125 -0.58,20.307 -1.137,25.664c-9.464,-17.487 -11.133,-38.312 -3.816,-62.985Z" style="fill:#9dc643;stroke:#000;stroke-width:2.08px;"/>
        <path id="quadriceps" d="M67.882,266.475l-13.259,11.746c-13.324,57.231 19.425,71.852 17.923,94.093l15.299,-6.433c-15.757,-7.643 -23.809,-38.612 -19.963,-99.406Zm76.406,0.23l13.236,11.516c13.325,57.231 -19.424,71.852 -17.923,94.093l-15.211,-6.433c15.756,-7.643 23.743,-38.382 19.898,-99.176Zm-68.153,-31.124c7.608,41.735 27.242,60.329 11.835,130.3c-15.713,-7.569 -23.802,-38.626 -19.846,-99.406c2.09,-12.503 4.914,-22.218 8.011,-30.894Zm59.877,0c-7.608,41.735 -27.241,60.329 -11.834,130.3c15.712,-7.569 23.801,-38.626 19.845,-99.406c-2.09,-12.503 -4.914,-22.218 -8.011,-30.894Z" style="fill:#36b574;stroke:#000;stroke-width:2.08px;"/>
        <path id="abductors" d="M64.979,220.727c-5.601,13.242 -10.269,33.382 -10.356,57.494l13.501,-11.746c1.652,-11.322 4.769,-21.17 8.011,-30.894l-11.156,-14.854Zm82.189,0c5.601,13.242 10.269,33.382 10.356,57.494l-13.501,-11.746c-1.652,-11.322 -4.769,-21.17 -8.011,-30.894l11.156,-14.854Z" style="fill:#78d7d0;stroke:#000;stroke-width:2.08px;"/>
        <path id="adductors" d="M87.97,365.881l11.354,3.493c5.61,-20.627 3.082,-75.174 6.582,-99.642c-10.559,-4.817 -22.153,-23.409 -29.771,-34.151c7.548,41.81 27.032,59.989 11.835,130.3Zm36.208,0l-11.355,3.493c-5.61,-20.627 -3.082,-75.174 -6.582,-99.642c10.559,-4.817 22.153,-23.409 29.771,-34.151c-7.547,41.81 -27.032,59.989 -11.834,130.3Z" style="fill:#7de0ae;stroke:#000;stroke-width:2.08px;"/>
        <path id="abdominals" d="M102.923,205.635l-18.104,-1.096c-2.93,30.395 4.517,58.496 21.163,65.227l0.054,-62.194l-3.113,-1.937Zm6.301,-0l18.104,-1.096c2.931,30.395 -4.516,58.496 -21.163,65.227l-0.054,-62.194l3.113,-1.937Zm-6.24,-22.534l-19.275,2.985c-4.262,4.449 -3.473,10.627 1.11,18.326l18.104,1.097l3.123,-2.413l-0.01,-16.414l-3.052,-3.581Zm6.179,0l19.276,2.985c4.261,4.449 3.472,10.627 -1.111,18.326l-18.104,1.097l-3.123,-2.413l0.01,-16.414l3.052,-3.581Zm0.481,-20.497l19.728,11.555c1.954,4.066 1.643,7.943 -0.933,11.828l-19.276,-3.025l-2.633,-1.642l-0.365,-14.468l3.479,-4.248Zm-7.141,-0l-19.728,11.555c-1.954,4.066 -1.642,7.943 0.934,11.828l19.275,-3.025l2.633,-1.642l0.365,-14.468l-3.479,-4.248Zm3.533,-15.659l-5.589,-3.989l-17.572,6.732c-3.433,9.958 -4.954,18.77 -0.1,24.338l23.261,-13.492l0,-13.589Zm0.075,-0l5.59,-3.989l17.572,6.732c3.432,9.958 4.953,18.77 0.099,24.338l-23.261,-13.492l-0,-13.589Z" style="fill:#5a8fc3;stroke:#000;stroke-width:2.08px;"/>
        <path id="obliques" d="M68.039,191.697c-0.18,-4.981 -0.575,-10.425 -1.223,-16.402l0,0c-0.493,-23.153 5.581,-28.481 6.388,-29.977l9.671,4.37c-4.014,11.705 -4.355,20.136 -0.1,24.471c-2.386,4.556 -1,9.151 0.934,11.927c-4.939,4.519 -2.654,13.071 1.11,18.453c-2.416,24.896 1.94,47.041 12.053,58.522c1.048,1.116 2.071,2.122 3.064,2.999c1.878,1.569 3.912,2.816 6.1,3.706c-1.873,-0.476 -3.917,-1.779 -6.1,-3.706c-1.073,-0.897 -2.094,-1.898 -3.064,-2.999c-9.333,-9.939 -20.698,-28.594 -31.893,-42.334c1.348,-5.573 2.85,-13.936 3.076,-28.55l-0.016,-0.48Zm59.289,12.842c3.764,-5.382 6.049,-13.934 1.111,-18.453c1.933,-2.776 3.32,-7.371 0.933,-11.927c4.255,-4.335 3.915,-12.766 -0.099,-24.471l10.48,-4.37c-0,-0 5.624,6.814 5.578,29.977l-0,-0c-0.669,6.17 -1.068,11.771 -1.239,16.882l0.011,0.681c0.262,14.193 1.739,22.383 3.065,27.869c-11.195,13.74 -22.559,32.395 -31.893,42.334c-0.969,1.1 -1.991,2.102 -3.064,2.999c-2.183,1.927 -4.227,3.23 -6.1,3.706c2.188,-0.89 4.222,-2.137 6.1,-3.706c0.993,-0.877 2.015,-1.882 3.064,-2.999c10.113,-11.481 14.469,-33.626 12.053,-58.522Z" style="fill:#215d97;stroke:#000;stroke-width:2.08px;"/>
        <path id="serratus" d="M66.816,175.295c-3.94,-9.024 -6.03,-19.94 -9.141,-25.607c0.863,-9.057 1.37,-16.113 1.838,-22.944c0.465,6.377 1.715,13.513 1.715,13.513l11.976,5.061c-0,-0 -6.909,7.006 -6.388,29.977Zm78.515,0c3.94,-9.024 6.03,-19.94 9.141,-25.607c-0.862,-9.057 -1.37,-16.113 -1.838,-22.944c-0.464,6.377 -1.715,13.513 -1.715,13.513l-11.166,5.061c-0,-0 5.549,6.889 5.578,29.977Z" style="fill:#404bb4;stroke:#000;stroke-width:2.08px;"/>
        <path id="forearms" d="M21.305,176.04c0,-0 -7.499,21.911 -9.473,33.314c-1.974,11.403 -2.414,25.244 -2.113,28.17c0.302,2.926 6.318,15.137 14.88,12.944c-1.365,-13.397 3.735,-22.78 6.574,-27.069c4.446,-6.717 15.08,-19.141 16.186,-28.85c0.777,-6.814 -2.485,-9.858 -2.485,-9.858l-23.569,-8.651Zm169.537,-0c-0,-0 7.499,21.911 9.473,33.314c1.974,11.403 2.414,25.244 2.113,28.17c-0.301,2.926 -6.317,15.137 -14.88,12.944c1.366,-13.397 -3.735,-22.78 -6.573,-27.069c-4.446,-6.717 -15.081,-19.141 -16.187,-28.85c-0.776,-6.814 2.485,-9.858 2.485,-9.858l23.569,-8.651Z" style="fill:#f5ef73;stroke:#000;stroke-width:2.08px;"/>
        <path id="biceps" d="M34.004,128.675c0,0 -10.913,19.909 -12.923,31.955c-2.235,13.397 0.224,15.41 0.224,15.41l23.569,8.651l4.283,-2.631c-0,0 6.473,-20.113 8.087,-29.459c1.379,-7.983 2.269,-25.857 2.269,-25.857l-19.684,16.212l-5.825,-14.281Zm144.139,0c-0,0 10.913,19.909 12.923,31.955c2.235,13.397 -0.224,15.41 -0.224,15.41l-23.569,8.651l-4.282,-2.631c-0,0 -6.473,-20.113 -8.088,-29.459c-1.379,-7.983 -2.269,-25.857 -2.269,-25.857l19.684,16.212l5.825,-14.281Z" style="fill:#ffd34c;stroke:#000;stroke-width:2.08px;"/>
        <path id="deltoids" d="M75.106,97.567c0,-0 -24.341,-7.413 -36.496,5.871c-12.125,13.252 -2.615,31.87 1.219,39.518c0,-0 14.684,-9.423 19.81,-16.38c3.454,-4.688 2.368,-8.911 5.69,-15.208c3.323,-6.298 9.777,-13.801 9.777,-13.801Zm61.935,-0c-0,-0 24.342,-7.413 36.496,5.871c12.125,13.252 2.616,31.87 -1.219,39.518c-0,-0 -14.684,-9.423 -19.81,-16.38c-3.454,-4.688 -2.368,-8.911 -5.69,-15.208c-3.323,-6.298 -9.777,-13.801 -9.777,-13.801Z" style="fill:#e96325;stroke:#000;stroke-width:2.08px;"/>
        <path id="pectorals" d="M75.106,97.567l17.628,-0.123l13.266,4.078l0.036,39.292l-23.161,8.874l-21.647,-9.431l-1.715,-13.513c0,0 3.071,-10.883 6.41,-16.457c3.338,-5.574 9.183,-12.72 9.183,-12.72Zm61.935,-0l-17.628,-0.123l-13.266,4.078l-0.036,39.292l23.162,8.874l21.646,-9.431l1.715,-13.513c-0,0 -3.071,-10.883 -6.409,-16.457c-3.339,-5.574 -9.184,-12.72 -9.184,-12.72Z" style="fill:#e9252f;stroke:#000;stroke-width:2.08px;"/>
        <path id="trapezes" d="M57.675,95.57c10.64,-7.508 20.527,-13.636 32.228,-18.51l1.118,20.384l-15.915,0.123c-5.184,-1.557 -12.134,-2.242 -17.431,-1.997Zm96.797,-0c-10.64,-7.508 -20.526,-13.636 -32.228,-18.51l-1.118,20.384l15.915,0.123c5.184,-1.557 12.134,-2.242 17.431,-1.997Z" style="fill:#9f4b9f;stroke:#000;stroke-width:2.08px;"/>
        <path id="head" d="M98.178,70.272l-12.67,-13.28l-0,-10.152c-6.307,-1.421 -9.953,-17.843 -2.733,-14.309l-0,-14.431c-0,0 3.236,-17.058 23.336,-17.058c20.1,-0 23.336,17.058 23.336,17.058l-0,14.431c6.963,-5.199 4.278,13.037 -2.733,14.309l-0,10.152l-12.67,13.28l-15.866,-0Z" style="fill:none;stroke:#000;stroke-width:2.08px;"/>
        <path id="neck" d="M106.074,101.522c5.483,-8.075 7.045,-19.571 7.883,-31.25l-15.779,-0c0.849,11.679 2.25,22.939 7.896,31.25Z" style="fill:none;stroke:#000;stroke-width:2.08px;"/>
    </g>
</svg>''';

  static const String maleBack = r'''
<svg width="100%" height="100%" viewBox="0 0 212 524" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" xmlns:serif="http://www.serif.com/" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linecap:square;stroke-linejoin:round;stroke-miterlimit:1.5;">
    <g id="Male-Muscle-Back">
        <path id="trapezes" d="M105.812,77.06l0,103.074c10.543,-1.009 13.512,-19.619 25.869,-34.575c0.343,-9.849 1.273,-22.317 2.551,-36.91c8.525,-6.041 14.371,-10.514 18.914,-13.144c-13.197,-8.733 -23.627,-14.634 -32.015,-18.445l-15.319,-0Zm-0.125,-0l0,103.074c-10.542,-1.009 -13.761,-19.619 -26.118,-34.575c-0.343,-9.849 -1.273,-22.317 -2.552,-36.91c-8.524,-6.041 -14.37,-10.514 -18.913,-13.144c13.196,-8.733 23.626,-14.634 32.015,-18.445l15.568,-0Z" style="fill:#9f4b9f;stroke:#000;stroke-width:2.08px;"/>
        <path id="lower-back" d="M105.687,180.134l0,67.154l-5.736,-0.042l-24.369,-28.03c7.221,-5.758 8.169,-8.016 8.541,-21.835l16.186,-19.671c1.51,1.307 3.244,2.143 5.378,2.424Zm0.125,0l0,67.153l5.487,-0.041l24.369,-28.03c-7.221,-5.758 -8.169,-8.016 -8.541,-21.835l-16.186,-19.671c-1.51,1.307 -2.995,2.143 -5.129,2.424Z" style="fill:#8b8ddf;stroke:#000;stroke-width:2.08px;"/>
        <path id="glutes" d="M105.755,247.288l0,21.492l18.025,6.227l19.946,-0.139l11.924,-17.609l-10.223,-43.874l-9.759,5.831l-24.369,28.03l-5.544,0.042Zm0,0.002l0,21.49l-18.285,6.227l-19.946,-0.139l-11.925,-17.609l10.223,-43.874l9.76,5.831l24.369,28.03l5.804,0.044Z" style="fill:#309f97;stroke:#000;stroke-width:2.08px;"/>
        <path id="abduc" d="M155.65,257.259l-11.924,17.609c9.519,12.011 14.737,26.353 13.382,42.796c1.96,-17.569 1.825,-44.917 -1.458,-60.405Zm-100.051,0l11.925,17.609c-9.519,12.011 -14.737,26.353 -13.382,42.796c-1.96,-17.569 -1.825,-44.917 1.457,-60.405Z" style="fill:#78d7d0;stroke:#000;stroke-width:2.08px;"/>
        <path id="hamstrings" d="M123.683,275.599c0.031,-0.196 0.064,-0.393 0.097,-0.592l19.946,-0.139c17.137,21.83 19.592,48.846 -1.028,79.32c-15.623,-16.027 -24.978,-33.963 -19.967,-72.141l-0.037,0.243c-4.976,38.131 4.46,56.036 20.004,72.063c0,-0 -8.497,22.987 -11.158,10.65c-2.661,-12.336 -18.045,13.084 -18.045,13.084c-3.376,-11.665 2.921,-53.726 9.199,-95.797c0.283,-2.167 0.612,-4.395 0.989,-6.691Zm-35.164,6.448c5.01,38.178 -4.344,56.114 -19.967,72.141c-20.62,-30.474 -18.165,-57.49 -1.028,-79.32l19.946,0.139c0.033,0.199 0.065,0.396 0.097,0.592c0.377,2.296 0.706,4.524 0.989,6.691c6.278,42.071 12.575,84.132 9.199,95.797c-0,0 -15.384,-25.42 -18.045,-13.084c-2.661,12.337 -11.158,-10.65 -11.158,-10.65c15.544,-16.027 24.98,-33.932 20.004,-72.063l-0.037,-0.243Z" style="fill:#51ac7e;stroke:#000;stroke-width:2.08px;"/>
        <path id="calves" d="M139.375,361.978c-3.31,14.576 10.272,46.45 5.189,60.305c-3.225,8.793 -12.809,13.233 -16.939,-1.558c-4.075,-14.591 -2.165,-44.653 -3.099,-56.885c-0,-0 5.541,-6.09 7.23,2.041c1.688,8.132 7.619,-3.903 7.619,-3.903Zm-67.5,0c3.31,14.576 -10.272,46.45 -5.19,60.305c3.226,8.793 12.809,13.233 16.94,-1.558c4.075,-14.591 2.165,-44.653 3.099,-56.885c0,-0 -5.541,-6.09 -7.23,2.041c-1.689,8.132 -7.619,-3.903 -7.619,-3.903Z" style="fill:#9dc643;stroke:#000;stroke-width:2.08px;"/>
        <path id="adduc" d="M105.744,268.862l18.036,6.145c-5.657,37.386 -11.22,75.043 -11.22,94.367c-6.184,-6.953 -0.945,-10.856 -6.935,-98.773c-5.99,87.917 -0.751,91.82 -6.935,98.773c0,-19.324 -5.563,-56.981 -11.22,-94.367l18.036,-6.145Z" style="fill:#7de0ae;stroke:#000;stroke-width:2.08px;"/>
        <path id="lats" d="M145.427,213.385l-3.593,-33.251l7.939,-37.178l-18.092,2.603c-9.457,11.462 -13.221,24.917 -20.74,32.151l16.186,19.671c0.177,10.831 0.625,16.07 8.541,21.835l9.759,-5.831Zm-79.605,0l3.594,-33.251l-7.939,-37.178l18.092,2.603c9.457,11.462 13.221,24.917 20.74,32.151l-16.186,19.671c-0.178,10.831 -0.625,16.07 -8.541,21.835l-9.76,-5.831Z" style="fill:#404bb4;stroke:#000;stroke-width:2.08px;"/>
        <path id="romboids" d="M149.773,142.956l-18.092,2.603l2.551,-36.91l16.826,14.917l-1.285,19.39Zm-88.296,-0l18.092,2.603l-2.552,-36.91l-16.826,14.917l1.286,19.39Z" style="fill:#67368e;stroke:#000;stroke-width:2.08px;"/>
        <path id="deltoids" d="M134.232,108.649l18.914,-13.144c23.345,2.679 29.839,17.37 20.5,43.346c-5.758,-8.733 -13.471,-13.451 -22.588,-15.285l-16.826,-14.917Zm-57.215,0l-18.913,-13.144c-23.345,2.679 -29.839,17.37 -20.5,43.346c5.758,-8.733 13.471,-13.451 22.587,-15.285l16.826,-14.917Z" style="fill:#e96325;stroke:#000;stroke-width:2.08px;"/>
        <path id="triceps" d="M177.003,126.744l13.621,45.847l-6.751,8.495l-17.735,3.605c-5.414,-5.344 -10.886,-22.727 -16.365,-41.735l1.285,-19.39c10.152,2.081 17.601,7.269 22.588,15.285c1.546,-3.78 2.672,-7.812 3.357,-12.107Zm-142.756,0l-13.621,45.847l6.751,8.495l17.734,3.605c5.415,-5.344 10.886,-22.727 16.366,-41.735l-1.286,-19.39c-10.151,2.081 -17.6,7.269 -22.587,15.285c-1.546,-3.78 -2.672,-7.812 -3.357,-12.107Z" style="fill:#fff74c;stroke:#000;stroke-width:2.08px;"/>
        <path id="forearms" d="M189.378,174.159c7.607,8.811 9.706,34.793 12.23,63.358c-2.599,8.87 -7.297,13.59 -14.574,13.213c0.15,-23.186 -15.973,-37.842 -21.045,-50.228c-0.582,-6.178 -0.623,-11.111 0.149,-15.811l17.735,-3.605l5.505,-6.927Zm-167.506,-0c-7.607,8.811 -9.706,34.793 -12.23,63.358c2.599,8.87 7.297,13.59 14.574,13.213c-0.15,-23.186 15.973,-37.842 21.045,-50.228c0.582,-6.178 0.623,-11.111 -0.15,-15.811l-17.734,-3.605l-5.505,-6.927Z" style="fill:#f5ef73;stroke:#000;stroke-width:2.08px;"/>
        <path id="head" d="M89.85,61.969l-4.748,-4.977l-0,-10.152c-6.307,-1.421 -9.953,-17.843 -2.733,-14.309l-0,-14.431c-0,0 3.236,-17.058 23.336,-17.058c20.1,-0 23.336,17.058 23.336,17.058l-0,14.431c6.963,-5.199 4.277,13.037 -2.733,14.309l-0,10.152l-4.911,5.148Z" style="fill:none;stroke:#000;stroke-width:2.08px;"/>
        <path id="neck" d="M121.131,77.06l-31.012,-0l-0.359,-20.164l12.223,-6.551l3.517,1.402l3.767,-1.402l12.223,6.551l-0.359,20.164Z" style="fill:none;stroke:#000;stroke-width:2.08px;"/>
    </g>
</svg>''';
}
```

- [ ] **Step 4: body_map_widget.dart erstellen**

```dart
// lib/features/training/widgets/body_map_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'body_map_svg_data.dart';

class BodyMapWidget extends StatelessWidget {
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final bool showBack;
  final double height;

  static const Color _primaryColor = Color(0xFFFF4D4D);
  static const Color _secondaryColor = Color(0xFFFFD34C);
  static const Color _inactiveColor = Color(0xFF2A2A3D);

  // Eindeutige Standardfarbe jeder Muskelgruppe im SVG (wie in Blast)
  static const Map<String, String> _muscleDefaultColors = {
    'pectorals':     '#e9252f',
    'lower_back':    '#8b8ddf',
    'rhomboids':     '#67368e',
    'lats':          '#404bb4',
    'trapezes':      '#9f4b9f',
    'deltoids':      '#e96325',
    'triceps':       '#fff74c',
    'biceps':        '#ffd34c',
    'forearms':      '#f5ef73',
    'abdominals':    '#5a8fc3',
    'obliques':      '#215d97',
    'glutes':        '#309f97',
    'quadriceps':    '#36b574',
    'hip_adductors': '#7de0ae',
    'hip_abductors': '#78d7d0',
    'hamstrings':    '#51ac7e',
    'calves':        '#9dc643',
  };

  static const List<String> allMuscles = [
    'pectorals', 'lower_back', 'rhomboids', 'lats', 'trapezes',
    'deltoids', 'triceps', 'biceps', 'forearms', 'abdominals',
    'obliques', 'glutes', 'quadriceps', 'hip_adductors',
    'hip_abductors', 'hamstrings', 'calves',
  ];

  const BodyMapWidget({
    super.key,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.showBack = false,
    this.height = 260,
  });

  /// Mapping von deutschen Muskelgruppen-Namen auf Blast-Muscle-IDs.
  static List<String> musclesForGroup(String group) {
    switch (group.toLowerCase().trim()) {
      case 'brust':      return ['pectorals'];
      case 'rücken':     return ['lats', 'rhomboids', 'lower_back', 'trapezes'];
      case 'schulter':   return ['deltoids'];
      case 'bizeps':     return ['biceps'];
      case 'trizeps':    return ['triceps'];
      case 'bauch':      return ['abdominals', 'obliques'];
      case 'beine':      return ['quadriceps', 'hamstrings', 'hip_adductors', 'hip_abductors'];
      case 'gesäß':      return ['glutes'];
      case 'waden':      return ['calves'];
      case 'unterarme':  return ['forearms'];
      case 'ganzkörper': return allMuscles;
      default:           return [];
    }
  }

  String _buildSvg() {
    var svg = showBack ? BodyMapSvgData.maleBack : BodyMapSvgData.maleFront;

    for (final entry in _muscleDefaultColors.entries) {
      final muscle = entry.key;
      final defaultHex = entry.value;
      final String targetHex;
      if (primaryMuscles.contains(muscle)) {
        targetHex = '#FF4D4D';
      } else if (secondaryMuscles.contains(muscle)) {
        targetHex = '#FFD34C';
      } else {
        targetHex = '#2A2A3D';
      }
      svg = svg.replaceAll('fill:$defaultHex', 'fill:$targetHex');
    }
    return svg;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SvgPicture.string(
        _buildSvg(),
        fit: BoxFit.contain,
      ),
    );
  }
}
```

- [ ] **Step 5: Test ausführen — muss PASS sein**

```
flutter test test/features/training/widgets/body_map_widget_test.dart
```

- [ ] **Step 6: Commit**

```
git add lib/features/training/widgets/body_map_svg_data.dart lib/features/training/widgets/body_map_widget.dart test/features/training/widgets/body_map_widget_test.dart
git commit -m "feat(training): add BodyMapWidget with Blast-SVG muscle highlighting"
```

---

## Task 3: Rest-Timer nach Satz

**Files:**
- Create: `lib/features/training/widgets/rest_timer_widget.dart`
- Modify: `lib/features/training/active_workout_screen.dart`
- Create: `test/features/training/widgets/rest_timer_widget_test.dart`

- [ ] **Step 1: Failing test**

```dart
// test/features/training/widgets/rest_timer_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/training/widgets/rest_timer_widget.dart';

void main() {
  testWidgets('RestTimerWidget shows duration and skip button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RestTimerWidget(
          durationSeconds: 90,
          onFinished: () {},
          onSkip: () {},
        ),
      ),
    ));
    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('RestTimerWidget calls onSkip when Skip pressed', (tester) async {
    bool skipped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RestTimerWidget(
          durationSeconds: 90,
          onFinished: () {},
          onSkip: () => skipped = true,
        ),
      ),
    ));
    await tester.tap(find.text('Skip'));
    expect(skipped, true);
  });
}
```

- [ ] **Step 2: Test ausführen — muss FAIL**

```
flutter test test/features/training/widgets/rest_timer_widget_test.dart
```

- [ ] **Step 3: rest_timer_widget.dart erstellen**

```dart
// lib/features/training/widgets/rest_timer_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class RestTimerWidget extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onFinished;
  final VoidCallback onSkip;

  const RestTimerWidget({
    super.key,
    required this.durationSeconds,
    required this.onFinished,
    required this.onSkip,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  late int _remaining;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _timer.cancel();
        widget.onFinished();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _formatted {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _remaining / widget.durationSeconds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 4, height: 4,
          decoration: BoxDecoration(
            color: TraumColors.onBackgroundSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text('Pause', style: const TextStyle(
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
          fontSize: 13,
        )),
        const SizedBox(height: 8),
        Text(_formatted, style: const TextStyle(
          color: TraumColors.mintGreen,
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w700,
          fontSize: 48,
        )),
        const SizedBox(height: 12),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: TraumColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(TraumColors.mintGreen),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: widget.onSkip,
          child: const Text('Skip', style: TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          )),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
```

- [ ] **Step 4: active_workout_screen.dart — Rest-Timer nach "Hinzufügen"**

In `_showAddSetDialog`, nach `Navigator.pop(ctx)` im Bestätigen-Button:
```dart
onPressed: () {
  if (selectedExerciseId == null) return;
  setState(() {
    _sets.add(_SetEntry(
      exerciseId: selectedExerciseId!,
      setNumber: _sets.length + 1,
      weightKg: double.tryParse(weightCtrl.text.replaceAll(',', '.')),
      reps: int.tryParse(repsCtrl.text),
    ));
  });
  Navigator.pop(ctx);
  // Rest-Timer anzeigen
  _showRestTimer(context);
},
```

Neue Methode in `_ActiveWorkoutScreenState`:
```dart
int _restSeconds = 90;

void _showRestTimer(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => RestTimerWidget(
      durationSeconds: _restSeconds,
      onFinished: () => Navigator.pop(context),
      onSkip: () => Navigator.pop(context),
    ),
  );
}
```

Import hinzufügen:
```dart
import 'widgets/rest_timer_widget.dart';
```

- [ ] **Step 5: Test ausführen — muss PASS**

```
flutter test test/features/training/widgets/rest_timer_widget_test.dart
```

- [ ] **Step 6: Commit**

```
git add lib/features/training/widgets/rest_timer_widget.dart lib/features/training/active_workout_screen.dart test/features/training/widgets/rest_timer_widget_test.dart
git commit -m "feat(training): add rest timer bottom sheet after each logged set"
```

---

## Task 4: Übungen Favorisieren (Bookmark)

**Files:**
- Modify: `lib/features/training/exercise_library_screen.dart`

- [ ] **Step 1: ExerciseLibraryScreen — Bookmark-Toggle + Tab hinzufügen**

Zustand erweitern (in `_ExerciseLibraryScreenState`):
```dart
bool _showBookmarkedOnly = false;
```

Im `_muscleGroups`-Filter-Row ein "Gespeichert"-Chip am Anfang einfügen:
```dart
FilterChip(
  label: const Text('Gespeichert'),
  selected: _showBookmarkedOnly,
  onSelected: (v) => setState(() {
    _showBookmarkedOnly = v;
    if (v) _muscleFilter = null;
  }),
  selectedColor: TraumColors.coralDim,
  checkmarkColor: TraumColors.coralOrange,
  labelStyle: TextStyle(
    color: _showBookmarkedOnly
        ? TraumColors.coralOrange
        : TraumColors.onBackgroundMuted,
    fontFamily: 'DMSans',
    fontSize: 12,
  ),
  backgroundColor: TraumColors.surface,
  side: BorderSide(
    color: _showBookmarkedOnly
        ? TraumColors.coralOrange
        : TraumColors.surfaceVariant,
  ),
),
```

In der Übungsliste filtern, bevor Karten gerendert werden:
```dart
final filtered = exercises.where((e) {
  if (_showBookmarkedOnly && !e.isBookmarked) return false;
  if (_muscleFilter != null && e.muscleGroup != _muscleFilter) return false;
  if (_search.isNotEmpty &&
      !e.name.toLowerCase().contains(_search.toLowerCase())) return false;
  return true;
}).toList();
```

Bookmark-Icon in jede Übungskarte eintragen (trailing):
```dart
IconButton(
  icon: Icon(
    e.isBookmarked
        ? Icons.bookmark_rounded
        : Icons.bookmark_border_rounded,
    color: e.isBookmarked
        ? TraumColors.coralOrange
        : TraumColors.onBackgroundSubtle,
  ),
  onPressed: () => ref
      .read(trainingDaoProvider)
      .toggleBookmark(e.id, !e.isBookmarked),
),
```

- [ ] **Step 2: flutter analyze ausführen (kein Test für UI-Only-Change)**

```
flutter analyze lib/features/training/exercise_library_screen.dart
```
Erwartet: keine Fehler.

- [ ] **Step 3: Commit**

```
git add lib/features/training/exercise_library_screen.dart
git commit -m "feat(training): add exercise bookmarking with filter chip in library"
```

---

## Task 5: fl_chart Fortschrittsdiagramme

**Files:**
- Modify: `lib/features/training/exercise_progress_screen.dart`

- [ ] **Step 1: 1RM-Epley-Berechnung und LineChart integrieren**

Import hinzufügen:
```dart
import 'package:fl_chart/fl_chart.dart';
```

Hilfsfunktion im Widget-File (außerhalb der Klasse):
```dart
/// Epley-Formel: geschätzter 1RM = weight × (1 + reps / 30)
double _epley1RM(double weight, int reps) =>
    reps == 1 ? weight : weight * (1 + reps / 30);
```

Im `data`-Block nach den vorhandenen PR-Karten einen 1RM-LineChart einfügen:

```dart
// 1RM-Datenpunkte berechnen
final oneRMPoints = sets
    .where((s) => s.weightKg != null && s.reps != null && s.reps! > 0)
    .toList();

if (oneRMPoints.length > 1) ...[
  const SizedBox(height: 16),
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: TraumColors.surface,
      borderRadius: BorderRadius.circular(TraumRadius.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geschätzter 1RM (Epley)',
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: TraumColors.surfaceVariant,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()} kg',
                      style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: oneRMPoints.asMap().entries.map((e) {
                    final rm = _epley1RM(
                        e.value.weightKg!, e.value.reps!);
                    return FlSpot(e.key.toDouble(), rm);
                  }).toList(),
                  isCurved: true,
                  color: TraumColors.coralOrange,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: TraumColors.coralOrange.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
],
```

- [ ] **Step 2: Altes manuelles Volume-Chart durch fl_chart BarChart ersetzen**

Den bestehenden `if (volumeData.length > 1)` Block ersetzen mit:

```dart
if (volumeData.length > 1) ...[
  const SizedBox(height: 16),
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: TraumColors.surface,
      borderRadius: BorderRadius.circular(TraumRadius.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.volumeLast90Days,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: volumeData.asMap().entries.map((e) =>
                BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: TraumColors.mintGreen,
                      width: 8,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ).toList(),
            ),
          ),
        ),
      ],
    ),
  ),
],
```

- [ ] **Step 3: flutter analyze**

```
flutter analyze lib/features/training/exercise_progress_screen.dart
```

- [ ] **Step 4: Commit**

```
git add lib/features/training/exercise_progress_screen.dart
git commit -m "feat(training): replace manual charts with fl_chart LineChart (1RM) and BarChart (volume)"
```

---

## Task 6: BodyMap in MuscleHeatmapScreen

**Files:**
- Modify: `lib/features/training/muscle_heatmap_screen.dart`

- [ ] **Step 1: Import + BodyMapWidget am Listenanfang einfügen**

Import hinzufügen:
```dart
import 'widgets/body_map_widget.dart';
```

Im `data` Block, vor `..._muscleGroups.map(...)`, die Heatmap-Muskeln berechnen und das Widget einfügen:

```dart
// Trainierte Muskeln → Blast IDs
final trainedMuscles = <String>{};
final strongMuscles = <String>{};
for (final entry in setsPerMuscle.entries) {
  final muscleIds = BodyMapWidget.musclesForGroup(entry.key);
  final ratio = maxSets > 0 ? entry.value / maxSets : 0.0;
  if (ratio > 0.5) {
    strongMuscles.addAll(muscleIds); // primär = viel trainiert
  } else if (ratio > 0) {
    trainedMuscles.addAll(muscleIds); // sekundär = wenig trainiert
  }
}

// Body-Map Widget
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    BodyMapWidget(
      primaryMuscles: strongMuscles.toList(),
      secondaryMuscles: trainedMuscles.difference(strongMuscles).toList(),
      height: 200,
    ),
    const SizedBox(width: 16),
    BodyMapWidget(
      primaryMuscles: strongMuscles.toList(),
      secondaryMuscles: trainedMuscles.difference(strongMuscles).toList(),
      showBack: true,
      height: 200,
    ),
  ],
),
const SizedBox(height: 20),
// Legende
Row(mainAxisAlignment: MainAxisAlignment.center, children: [
  _LegendDot(color: const Color(0xFFFF4D4D), label: 'Stark trainiert'),
  const SizedBox(width: 16),
  _LegendDot(color: const Color(0xFFFFD34C), label: 'Leicht trainiert'),
  const SizedBox(width: 16),
  _LegendDot(color: const Color(0xFF2A2A3D), label: 'Nicht trainiert'),
]),
const SizedBox(height: 20),
```

Neue private Klasse am Ende der Datei:
```dart
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
        color: TraumColors.onBackgroundMuted,
        fontFamily: 'DMSans',
        fontSize: 11,
      )),
    ]);
  }
}
```

- [ ] **Step 2: flutter analyze**

```
flutter analyze lib/features/training/muscle_heatmap_screen.dart
```

- [ ] **Step 3: Commit**

```
git add lib/features/training/muscle_heatmap_screen.dart
git commit -m "feat(training): integrate BodyMapWidget as visual heatmap in MuscleHeatmapScreen"
```

---

## Task 7: kg/lbs Einheiten-Einstellung

**Files:**
- Create: `lib/core/providers/unit_preference_provider.dart`
- Modify: `lib/features/training/active_workout_screen.dart`
- Modify: `lib/features/training/exercise_progress_screen.dart`

- [ ] **Step 1: unit_preference_provider.dart erstellen**

```dart
// lib/core/providers/unit_preference_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUnitKey = 'weight_unit';

final unitPreferenceProvider =
    StateNotifierProvider<UnitPreferenceNotifier, bool>((ref) {
  return UnitPreferenceNotifier();
});

/// true = lbs, false = kg (default)
class UnitPreferenceNotifier extends StateNotifier<bool> {
  UnitPreferenceNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kUnitKey) ?? false;
  }

  Future<void> setUseLbs(bool useLbs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUnitKey, useLbs);
    state = useLbs;
  }
}

extension WeightUnit on double {
  /// Konvertiert kg → angezeigte Einheit.
  double toDisplayUnit(bool useLbs) => useLbs ? this * 2.20462 : this;
  String unitLabel(bool useLbs) => useLbs ? 'lbs' : 'kg';
}
```

- [ ] **Step 2: active_workout_screen.dart — Einheit im Gewichts-TextField-Label**

Import hinzufügen:
```dart
import '../../core/providers/unit_preference_provider.dart';
```

Das `weightCtrl`-Label dynamisch machen:
```dart
final useLbs = ref.watch(unitPreferenceProvider);
// ...
labelText: useLbs
    ? AppLocalizations.of(context)!.weightLbs
    : AppLocalizations.of(context)!.weightKg,
```

Im Set-Eintrag beim Speichern Konvertierung einbauen:
```dart
final rawWeight = double.tryParse(weightCtrl.text.replaceAll(',', '.'));
final weightInKg = (rawWeight != null && useLbs)
    ? rawWeight / 2.20462
    : rawWeight;
_sets.add(_SetEntry(
  exerciseId: selectedExerciseId!,
  setNumber: _sets.length + 1,
  weightKg: weightInKg,
  reps: int.tryParse(repsCtrl.text),
));
```

- [ ] **Step 3: exercise_progress_screen.dart — Einheit bei PR-Karten**

Import:
```dart
import '../../core/providers/unit_preference_provider.dart';
```

In der `build`-Methode:
```dart
final useLbs = ref.watch(unitPreferenceProvider);
```

Max-Gewicht-Anzeige:
```dart
value: '${maxWeight.toDisplayUnit(useLbs).toStringAsFixed(1)} ${maxWeight.unitLabel(useLbs)}',
```

- [ ] **Step 4: flutter analyze beider Dateien**

```
flutter analyze lib/core/providers/unit_preference_provider.dart lib/features/training/active_workout_screen.dart lib/features/training/exercise_progress_screen.dart
```

- [ ] **Step 5: Commit**

```
git add lib/core/providers/unit_preference_provider.dart lib/features/training/active_workout_screen.dart lib/features/training/exercise_progress_screen.dart
git commit -m "feat(training): add kg/lbs unit preference provider with display conversion"
```

---

## Task 8: Lokalisierung

**Files:**
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: app_de.arb — neue Strings eintragen**

Folgende Keys hinzufügen (vor dem letzten `}`):
```json
"restTimer": "Pause",
"restTimerSkip": "Überspringen",
"weightLbs": "Gewicht (lbs)",
"bookmarked": "Gespeichert",
"bookmarkExercise": "Übung speichern",
"estimated1RM": "Geschätzter 1RM (Epley)",
"heavilyTrained": "Stark trainiert",
"lightlyTrained": "Leicht trainiert",
"notTrainedHeatmap": "Nicht trainiert"
```

- [ ] **Step 2: app_en.arb — neue Strings eintragen**

```json
"restTimer": "Rest",
"restTimerSkip": "Skip",
"weightLbs": "Weight (lbs)",
"bookmarked": "Bookmarked",
"bookmarkExercise": "Bookmark exercise",
"estimated1RM": "Estimated 1RM (Epley)",
"heavilyTrained": "Heavily trained",
"lightlyTrained": "Lightly trained",
"notTrainedHeatmap": "Not trained"
```

- [ ] **Step 3: Generierung prüfen**

```
flutter gen-l10n
flutter analyze lib/l10n
```

- [ ] **Step 4: Commit**

```
git add lib/l10n/app_de.arb lib/l10n/app_en.arb
git commit -m "feat(l10n): add DE+EN strings for rest timer, bookmarks, 1RM, heatmap labels"
```

---

## Self-Review Checklist

- [x] Spec coverage: Alle 7 Blast-Features (Körperkarte, Rest-Timer, Primär/Sekundär-DB, fl_chart, Bookmark, Heatmap, kg/lbs) haben Tasks
- [x] Keine Placeholder: alle Tasks haben vollständigen Code
- [x] Typen konsistent: `BodyMapWidget.musclesForGroup()`, `toggleBookmark()`, `_epley1RM()` — alle in frühen Tasks definiert und in späteren verwendet
- [x] Migration: v3 nach v2, addColumn für alle neuen Felder, bestehende Daten sicher
- [x] build_runner läuft nach DB-Änderung (Task 1 Step 6)

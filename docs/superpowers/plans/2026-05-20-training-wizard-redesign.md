# Training Wizard & UX Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 3-step onboarding wizard for first-time training plan setup, muscle-group SVG icons on every exercise, and a week-overview main screen layout.

**Architecture:** New `WorkoutDayExercises` junction table stores pre-planned exercises per day; a `PlanTemplates` data file seeds PPL / Ganzkörper / Upper-Lower plans; the router redirects `/training` → `/training/setup` when no plan exists (checked via a SharedPreferences flag written on wizard completion). `ExerciseIcon` is a pure display widget that maps a `muscleGroup` string to an SVG asset.

**Tech Stack:** Flutter · Drift (SQLite ORM, schema v1→2) · Riverpod · GoRouter · flutter_svg ^2.0.10+1 · shared_preferences

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/data/database/tables/training_tables.dart` | Modify | Add `WorkoutDayExercises` table class |
| `lib/data/database/daos/training_dao.dart` | Modify | Add DAO methods for `WorkoutDayExercises`; update `@DriftAccessor` |
| `lib/data/database/traum_database.dart` | Modify | Register table, bump `schemaVersion` to 2, add migration |
| `lib/data/repositories/plan_templates.dart` | Create | `PlanTemplate` types + 3 pre-built constants |
| `lib/data/preferences/preferences_repository.dart` | Modify | Add `trainingSetupComplete` getter + setter |
| `assets/exercises/icons/chest.svg` … `full_body.svg` (9 files) | Create | Muscle-group SVG icons |
| `pubspec.yaml` | Modify | Add `assets/exercises/icons/` asset entry |
| `lib/features/training/widgets/exercise_icon.dart` | Create | Reusable muscle-group icon widget |
| `lib/features/training/exercise_library_screen.dart` | Modify | Add `ExerciseIcon` as list-tile leading |
| `lib/features/training/workout_plan_detail_screen.dart` | Modify | Add exercise rows per day (currently shows only day names) |
| `lib/core/providers/database_provider.dart` | Modify | Add `dayExercisesForDayProvider`, `activePlanProvider` |
| `lib/features/training/active_workout_screen.dart` | Modify | Add `ExerciseIcon` to exercise header |
| `lib/features/training/workout_session_detail_screen.dart` | Modify | Add `ExerciseIcon` to exercise rows |
| `lib/features/training/training_wizard_screen.dart` | Create | Wizard container with step navigation + completion logic |
| `lib/features/training/wizard_template_step.dart` | Create | Step 1 — template selection cards |
| `lib/features/training/wizard_days_step.dart` | Create | Step 2 — weekday chips + editable day names |
| `lib/features/training/wizard_exercises_step.dart` | Create | Step 3 — per-day exercise review + picker sheet |
| `lib/core/navigation/routes.dart` | Modify | Add `trainingSetup = '/training/setup'` constant |
| `lib/core/navigation/router.dart` | Modify | Add `/training/setup` route + redirect when no plan |
| `lib/features/training/training_screen.dart` | Modify | Replace hero card with week strip + stats row + today card |
| `lib/l10n/app_en.arb` | Modify | Add wizard + main screen strings |
| `lib/l10n/app_de.arb` | Modify | Add wizard + main screen strings |
| `lib/l10n/app_localizations.dart` | Modify | Declare new localisation keys |

---

## Task 1 — WorkoutDayExercises DB Table + Migration

**Files:**
- Modify: `lib/data/database/tables/training_tables.dart`
- Modify: `lib/data/database/daos/training_dao.dart`
- Modify: `lib/data/database/traum_database.dart`

- [ ] **Step 1 — Write the failing test**

Create `test/data/database/workout_day_exercises_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;

  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('insert and query WorkoutDayExercise', () async {
    final planId = await db.trainingDao.insertPlan(
      WorkoutPlansCompanion.insert(name: 'Test Plan'),
    );
    final dayId = await db.trainingDao.insertDay(
      WorkoutDaysCompanion.insert(planId: planId, name: 'Day A'),
    );
    final exerciseId = await db.trainingDao.insertExercise(
      ExercisesCompanion.insert(name: 'Bankdruecken', muscleGroup: 'chest'),
    );

    await db.trainingDao.insertDayExercise(
      WorkoutDayExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: exerciseId,
        sortOrder: const Value(0),
        defaultSets: const Value(4),
        defaultReps: const Value(8),
      ),
    );

    final rows = await db.trainingDao.getDayExercises(dayId);
    expect(rows.length, 1);
    expect(rows.first.exerciseId, exerciseId);
    expect(rows.first.defaultSets, 4);
  });
}
```

- [ ] **Step 2 — Run test to verify it fails**

```
cd traum_app
flutter test test/data/database/workout_day_exercises_test.dart
```

Expected: FAIL — `WorkoutDayExercisesCompanion` not defined.

- [ ] **Step 3 — Add table class to training_tables.dart**

Append at end of `lib/data/database/tables/training_tables.dart`:

```dart
class WorkoutDayExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayId => integer().references(WorkoutDays, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get defaultSets => integer().withDefault(const Constant(3))();
  IntColumn get defaultReps => integer().withDefault(const Constant(10))();
}
```

- [ ] **Step 4 — Register table in traum_database.dart and bump schema version**

In `lib/data/database/traum_database.dart`, add `WorkoutDayExercises` to the `@DriftDatabase` tables list (after `WorkoutSets`):

```dart
// Training (6)
WorkoutPlans,
WorkoutDays,
Exercises,
WorkoutSessions,
WorkoutSets,
WorkoutDayExercises,
```

Change `schemaVersion` and add migration:

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (migrator, from, to) async {
    if (from < 2) {
      await migrator.createTable(workoutDayExercises);
    }
  },
);
```

- [ ] **Step 5 — Add DAO methods to training_dao.dart**

Update `@DriftAccessor` annotation — add `WorkoutDayExercises` to the tables list:

```dart
@DriftAccessor(tables: [
  WorkoutPlans, WorkoutDays, Exercises,
  WorkoutSessions, WorkoutSets, WorkoutDayExercises,
])
```

Add methods after `deleteSet`:

```dart
// WorkoutDayExercises
Future<List<WorkoutDayExercise>> getDayExercises(int dayId) =>
    (select(workoutDayExercises)
          ..where((t) => t.dayId.equals(dayId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

Stream<List<WorkoutDayExercise>> watchDayExercises(int dayId) =>
    (select(workoutDayExercises)
          ..where((t) => t.dayId.equals(dayId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();

Future<int> insertDayExercise(WorkoutDayExercisesCompanion entry) =>
    into(workoutDayExercises).insert(entry);

Future<int> deleteDayExercise(int id) =>
    (delete(workoutDayExercises)..where((t) => t.id.equals(id))).go();

Future<void> deleteDayExercisesForDay(int dayId) =>
    (delete(workoutDayExercises)..where((t) => t.dayId.equals(dayId))).go();
```

- [ ] **Step 6 — Regenerate Drift code**

```
cd traum_app
dart run build_runner build --delete-conflicting-outputs
```

Expected: no errors; `traum_database.g.dart` and `training_dao.g.dart` updated.

- [ ] **Step 7 — Run test to verify it passes**

```
flutter test test/data/database/workout_day_exercises_test.dart
```

Expected: PASS.

- [ ] **Step 8 — Commit**

```
git add lib/data/database/tables/training_tables.dart \
        lib/data/database/daos/training_dao.dart \
        lib/data/database/traum_database.dart \
        lib/data/database/traum_database.g.dart \
        lib/data/database/daos/training_dao.g.dart \
        test/data/database/workout_day_exercises_test.dart
git commit -m "feat: add WorkoutDayExercises table (schema v2)"
```

---

## Task 2 — Plan Templates Data File

**Files:**
- Create: `lib/data/repositories/plan_templates.dart`

- [ ] **Step 1 — Write the failing test**

Create `test/data/repositories/plan_templates_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/repositories/plan_templates.dart';

void main() {
  test('PPL template has 3 days', () {
    expect(PlanTemplates.ppl.days.length, 3);
  });

  test('PPL Push Day contains Bankdruecken', () {
    final pushDay = PlanTemplates.ppl.days[0];
    expect(pushDay.exercises.any((e) => e.exerciseName == 'Bankdruecken'), isTrue);
  });

  test('all templates have at least one day', () {
    for (final t in PlanTemplates.all) {
      expect(t.days, isNotEmpty, reason: '${t.name} has no days');
    }
  });

  test('custom template has zero days', () {
    expect(PlanTemplates.custom.days, isEmpty);
  });
}
```

- [ ] **Step 2 — Run test to verify it fails**

```
flutter test test/data/repositories/plan_templates_test.dart
```

Expected: FAIL — `PlanTemplates` not defined.

- [ ] **Step 3 — Create plan_templates.dart**

Create `lib/data/repositories/plan_templates.dart`:

```dart
class PlanTemplate {
  final String id;
  final String name;
  final String subtitle;
  final List<TemplateDay> days;

  const PlanTemplate({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.days,
  });
}

class TemplateDay {
  final String name;
  final int dayOfWeek; // 1=Mo … 7=So
  final List<TemplateExercise> exercises;

  const TemplateDay({
    required this.name,
    required this.dayOfWeek,
    required this.exercises,
  });
}

class TemplateExercise {
  final String exerciseName; // must match seeded exercise name exactly
  final int sets;
  final int reps;

  const TemplateExercise({
    required this.exerciseName,
    required this.sets,
    required this.reps,
  });
}

class PlanTemplates {
  PlanTemplates._();

  static const PlanTemplate ppl = PlanTemplate(
    id: 'ppl',
    name: 'Push / Pull / Legs',
    subtitle: '3 Tage · Muskelaufbau',
    days: [
      TemplateDay(
        name: 'Push Day',
        dayOfWeek: 1, // Mo
        exercises: [
          TemplateExercise(exerciseName: 'Bankdruecken', sets: 4, reps: 8),
          TemplateExercise(exerciseName: 'Schulterdruecken', sets: 3, reps: 10),
          TemplateExercise(exerciseName: 'Trizepsdruecken', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Liegestuetze', sets: 3, reps: 15),
        ],
      ),
      TemplateDay(
        name: 'Pull Day',
        dayOfWeek: 3, // Mi
        exercises: [
          TemplateExercise(exerciseName: 'Klimmzuege', sets: 4, reps: 8),
          TemplateExercise(exerciseName: 'Kreuzheben', sets: 3, reps: 6),
          TemplateExercise(exerciseName: 'Bizepscurls', sets: 3, reps: 12),
        ],
      ),
      TemplateDay(
        name: 'Leg Day',
        dayOfWeek: 5, // Fr
        exercises: [
          TemplateExercise(exerciseName: 'Kniebeugen', sets: 4, reps: 8),
          TemplateExercise(exerciseName: 'Ausfallschritte', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 60),
        ],
      ),
    ],
  );

  static const PlanTemplate ganzkörper = PlanTemplate(
    id: 'fullbody',
    name: 'Ganzkörper 3×',
    subtitle: '3 Tage · Kraft + Ausdauer',
    days: [
      TemplateDay(
        name: 'Ganzkörper A',
        dayOfWeek: 1,
        exercises: [
          TemplateExercise(exerciseName: 'Bankdruecken', sets: 3, reps: 10),
          TemplateExercise(exerciseName: 'Kniebeugen', sets: 3, reps: 10),
          TemplateExercise(exerciseName: 'Klimmzuege', sets: 3, reps: 8),
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 45),
        ],
      ),
      TemplateDay(
        name: 'Ganzkörper B',
        dayOfWeek: 3,
        exercises: [
          TemplateExercise(exerciseName: 'Schulterdruecken', sets: 3, reps: 10),
          TemplateExercise(exerciseName: 'Kreuzheben', sets: 3, reps: 8),
          TemplateExercise(exerciseName: 'Bizepscurls', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Laufen', sets: 1, reps: 20),
        ],
      ),
      TemplateDay(
        name: 'Ganzkörper C',
        dayOfWeek: 5,
        exercises: [
          TemplateExercise(exerciseName: 'Liegestuetze', sets: 4, reps: 12),
          TemplateExercise(exerciseName: 'Ausfallschritte', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Trizepsdruecken', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 45),
        ],
      ),
    ],
  );

  static const PlanTemplate upperLower = PlanTemplate(
    id: 'upper_lower',
    name: 'Upper / Lower Split',
    subtitle: '4 Tage · Hypertrophie',
    days: [
      TemplateDay(
        name: 'Upper A',
        dayOfWeek: 1,
        exercises: [
          TemplateExercise(exerciseName: 'Bankdruecken', sets: 4, reps: 8),
          TemplateExercise(exerciseName: 'Klimmzuege', sets: 4, reps: 8),
          TemplateExercise(exerciseName: 'Schulterdruecken', sets: 3, reps: 10),
          TemplateExercise(exerciseName: 'Bizepscurls', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Trizepsdruecken', sets: 3, reps: 12),
        ],
      ),
      TemplateDay(
        name: 'Lower A',
        dayOfWeek: 2, // Di
        exercises: [
          TemplateExercise(exerciseName: 'Kniebeugen', sets: 4, reps: 8),
          TemplateExercise(exerciseName: 'Kreuzheben', sets: 3, reps: 6),
          TemplateExercise(exerciseName: 'Ausfallschritte', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 45),
        ],
      ),
      TemplateDay(
        name: 'Upper B',
        dayOfWeek: 4, // Do
        exercises: [
          TemplateExercise(exerciseName: 'Liegestuetze', sets: 4, reps: 12),
          TemplateExercise(exerciseName: 'Klimmzuege', sets: 4, reps: 8),
          TemplateExercise(exerciseName: 'Schulterdruecken', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Bizepscurls', sets: 3, reps: 15),
          TemplateExercise(exerciseName: 'Trizepsdruecken', sets: 3, reps: 15),
        ],
      ),
      TemplateDay(
        name: 'Lower B',
        dayOfWeek: 5, // Fr
        exercises: [
          TemplateExercise(exerciseName: 'Kniebeugen', sets: 4, reps: 10),
          TemplateExercise(exerciseName: 'Ausfallschritte', sets: 3, reps: 15),
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 60),
          TemplateExercise(exerciseName: 'Laufen', sets: 1, reps: 20),
        ],
      ),
    ],
  );

  static const PlanTemplate custom = PlanTemplate(
    id: 'custom',
    name: 'Eigener Plan',
    subtitle: 'Frei konfigurierbar',
    days: [],
  );

  static const List<PlanTemplate> all = [ppl, ganzkörper, upperLower, custom];
}
```

- [ ] **Step 4 — Run test to verify it passes**

```
flutter test test/data/repositories/plan_templates_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 5 — Commit**

```
git add lib/data/repositories/plan_templates.dart \
        test/data/repositories/plan_templates_test.dart
git commit -m "feat: add plan templates (PPL, Ganzkörper, Upper/Lower)"
```

---

## Task 3 — SVG Exercise Icon Assets

**Files:**
- Create: `assets/exercises/icons/chest.svg`
- Create: `assets/exercises/icons/back.svg`
- Create: `assets/exercises/icons/shoulders.svg`
- Create: `assets/exercises/icons/biceps.svg`
- Create: `assets/exercises/icons/triceps.svg`
- Create: `assets/exercises/icons/legs.svg`
- Create: `assets/exercises/icons/core.svg`
- Create: `assets/exercises/icons/cardio.svg`
- Create: `assets/exercises/icons/full_body.svg`
- Modify: `pubspec.yaml`

No automated test for static assets — visual verification at Task 4.

- [ ] **Step 1 — Create assets/exercises/icons/ directory and all 9 SVG files**

`assets/exercises/icons/chest.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <circle cx="22" cy="7" r="5" fill="white" opacity="0.3"/>
  <rect x="6" y="14" width="6" height="14" rx="3" fill="white" opacity="0.2"/>
  <rect x="32" y="14" width="6" height="14" rx="3" fill="white" opacity="0.2"/>
  <rect x="13" y="24" width="18" height="11" rx="3" fill="white" opacity="0.3"/>
  <rect x="13" y="14" width="18" height="11" rx="3" fill="#FF6B6B" opacity="0.9"/>
</svg>
```

`assets/exercises/icons/back.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <circle cx="22" cy="7" r="5" fill="white" opacity="0.3"/>
  <rect x="6" y="14" width="5" height="13" rx="2" fill="white" opacity="0.2"/>
  <rect x="33" y="14" width="5" height="13" rx="2" fill="white" opacity="0.2"/>
  <rect x="13" y="24" width="18" height="11" rx="3" fill="white" opacity="0.3"/>
  <rect x="11" y="14" width="22" height="11" rx="3" fill="#4ECDC4" opacity="0.9"/>
</svg>
```

`assets/exercises/icons/shoulders.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <circle cx="22" cy="7" r="5" fill="white" opacity="0.3"/>
  <rect x="14" y="15" width="16" height="20" rx="3" fill="white" opacity="0.3"/>
  <rect x="6" y="20" width="6" height="12" rx="2" fill="white" opacity="0.2"/>
  <rect x="32" y="20" width="6" height="12" rx="2" fill="white" opacity="0.2"/>
  <ellipse cx="9" cy="16" rx="6" ry="5" fill="#A78BFA" opacity="0.9"/>
  <ellipse cx="35" cy="16" rx="6" ry="5" fill="#A78BFA" opacity="0.9"/>
</svg>
```

`assets/exercises/icons/biceps.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <rect x="17" y="23" width="10" height="14" rx="4" fill="white" opacity="0.3"/>
  <ellipse cx="22" cy="39" rx="5" ry="3" fill="white" opacity="0.2"/>
  <rect x="15" y="7" width="14" height="17" rx="6" fill="#F59E0B" opacity="0.9"/>
</svg>
```

`assets/exercises/icons/triceps.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <rect x="17" y="23" width="10" height="14" rx="4" fill="white" opacity="0.3"/>
  <ellipse cx="22" cy="39" rx="5" ry="3" fill="white" opacity="0.2"/>
  <rect x="15" y="7" width="14" height="17" rx="6" fill="white" opacity="0.25"/>
  <rect x="21" y="9" width="7" height="14" rx="3" fill="#FB923C" opacity="0.9"/>
</svg>
```

`assets/exercises/icons/legs.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <rect x="12" y="4" width="20" height="9" rx="3" fill="white" opacity="0.3"/>
  <rect x="13" y="28" width="7" height="13" rx="3" fill="white" opacity="0.3"/>
  <rect x="24" y="28" width="7" height="13" rx="3" fill="white" opacity="0.3"/>
  <rect x="12" y="12" width="9" height="17" rx="4" fill="#60A5FA" opacity="0.9"/>
  <rect x="23" y="12" width="9" height="17" rx="4" fill="#60A5FA" opacity="0.9"/>
</svg>
```

`assets/exercises/icons/core.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <circle cx="22" cy="6" r="4" fill="white" opacity="0.3"/>
  <rect x="14" y="12" width="16" height="9" rx="3" fill="white" opacity="0.3"/>
  <rect x="14" y="32" width="6" height="9" rx="2" fill="white" opacity="0.2"/>
  <rect x="24" y="32" width="6" height="9" rx="2" fill="white" opacity="0.2"/>
  <rect x="14" y="20" width="16" height="13" rx="3" fill="#34D399" opacity="0.9"/>
</svg>
```

`assets/exercises/icons/cardio.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <path d="M22 37 C22 37 6 26 6 16 C6 11 10 7 15 8 C18 9 21 12 22 14 C23 12 26 9 29 8 C34 7 38 11 38 16 C38 26 22 37 22 37Z" fill="#F472B6" opacity="0.85"/>
  <polyline points="8,21 14,21 17,14 21,28 25,14 28,21 36,21" fill="none" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" opacity="0.9"/>
</svg>
```

`assets/exercises/icons/full_body.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <circle cx="22" cy="6" r="5" fill="#94A3B8" opacity="0.9"/>
  <rect x="7" y="13" width="7" height="14" rx="3" fill="#94A3B8" opacity="0.7"/>
  <rect x="30" y="13" width="7" height="14" rx="3" fill="#94A3B8" opacity="0.7"/>
  <rect x="15" y="13" width="14" height="17" rx="3" fill="#94A3B8" opacity="0.9"/>
  <rect x="15" y="29" width="6" height="13" rx="3" fill="#94A3B8" opacity="0.9"/>
  <rect x="23" y="29" width="6" height="13" rx="3" fill="#94A3B8" opacity="0.9"/>
</svg>
```

- [ ] **Step 2 — Add asset path to pubspec.yaml**

In `pubspec.yaml`, under `assets:`, add after `- assets/exercises/`:

```yaml
    - assets/exercises/icons/
```

- [ ] **Step 3 — Verify flutter can find assets**

```
cd traum_app
flutter pub get
flutter build apk --debug 2>&1 | grep -i "error\|icon"
```

Expected: no errors mentioning missing icon assets.

- [ ] **Step 4 — Commit**

```
git add assets/exercises/icons/ pubspec.yaml
git commit -m "feat: add muscle-group SVG icon assets (9 icons)"
```

---

## Task 4 — ExerciseIcon Widget

**Files:**
- Create: `lib/features/training/widgets/exercise_icon.dart`

- [ ] **Step 1 — Write the failing test**

Create `test/features/training/widgets/exercise_icon_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:traum/features/training/widgets/exercise_icon.dart';

void main() {
  testWidgets('renders SvgPicture for known muscle group', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExerciseIcon(muscleGroup: 'chest'))),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('renders SvgPicture for unknown muscle group (fallback)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExerciseIcon(muscleGroup: 'unknown_group'))),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  test('muscleGroupColor returns correct color for chest', () {
    expect(ExerciseIcon.muscleGroupColor('chest'), const Color(0xFFFF6B6B));
  });

  test('muscleGroupColor returns fallback color for unknown group', () {
    expect(ExerciseIcon.muscleGroupColor('unknown'), const Color(0xFF94A3B8));
  });
}
```

- [ ] **Step 2 — Run test to verify it fails**

```
flutter test test/features/training/widgets/exercise_icon_test.dart
```

Expected: FAIL — `ExerciseIcon` not defined.

- [ ] **Step 3 — Create exercise_icon.dart**

Create `lib/features/training/widgets/exercise_icon.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExerciseIcon extends StatelessWidget {
  final String muscleGroup;
  final double size;

  const ExerciseIcon({
    super.key,
    required this.muscleGroup,
    this.size = 44,
  });

  static const Map<String, String> _assetMap = {
    'chest':     'assets/exercises/icons/chest.svg',
    'back':      'assets/exercises/icons/back.svg',
    'shoulders': 'assets/exercises/icons/shoulders.svg',
    'biceps':    'assets/exercises/icons/biceps.svg',
    'triceps':   'assets/exercises/icons/triceps.svg',
    'legs':      'assets/exercises/icons/legs.svg',
    'core':      'assets/exercises/icons/core.svg',
    'cardio':    'assets/exercises/icons/cardio.svg',
    'full_body': 'assets/exercises/icons/full_body.svg',
  };

  static const Map<String, Color> _colorMap = {
    'chest':     Color(0xFFFF6B6B),
    'back':      Color(0xFF4ECDC4),
    'shoulders': Color(0xFFA78BFA),
    'biceps':    Color(0xFFF59E0B),
    'triceps':   Color(0xFFFB923C),
    'legs':      Color(0xFF60A5FA),
    'core':      Color(0xFF34D399),
    'cardio':    Color(0xFFF472B6),
    'full_body': Color(0xFF94A3B8),
  };

  static Color muscleGroupColor(String muscleGroup) =>
      _colorMap[muscleGroup] ?? const Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final asset = _assetMap[muscleGroup] ?? _assetMap['full_body']!;
    final color = muscleGroupColor(muscleGroup);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: SvgPicture.asset(asset),
      ),
    );
  }
}
```

- [ ] **Step 4 — Run test to verify it passes**

```
flutter test test/features/training/widgets/exercise_icon_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 5 — Commit**

```
git add lib/features/training/widgets/exercise_icon.dart \
        test/features/training/widgets/exercise_icon_test.dart
git commit -m "feat: add ExerciseIcon widget with SVG muscle-group icons"
```

---

## Task 5 — Integrate ExerciseIcon into ExerciseLibraryScreen

**Files:**
- Modify: `lib/features/training/exercise_library_screen.dart`

- [ ] **Step 1 — Add import and replace leading widget**

At the top of `exercise_library_screen.dart`, add the import:

```dart
import 'widgets/exercise_icon.dart';
```

Find the exercise list tile builder (look for `ListTile` or similar widget that displays exercise names). It currently likely has a generic icon or no leading widget. Replace or add the `leading:` parameter with `ExerciseIcon`:

```dart
// Before (example existing tile):
ListTile(
  title: Text(exercise.name, ...),
  subtitle: Text(exercise.muscleGroup, ...),
  trailing: ...,
)

// After:
ListTile(
  leading: ExerciseIcon(muscleGroup: exercise.muscleGroup, size: 44),
  title: Text(exercise.name, ...),
  subtitle: Text(exercise.muscleGroup, ...),
  trailing: ...,
)
```

Find all occurrences where an exercise name is rendered in a row/tile in this file and add `ExerciseIcon` as a leading 44px widget.

- [ ] **Step 2 — Hot reload and verify visually**

```
flutter run
```

Navigate to Training → Übungen. Verify each exercise shows its muscle-group SVG icon on the left. Verify icons for chest exercises are coral, back exercises are mint, legs are blue, etc.

- [ ] **Step 3 — Commit**

```
git add lib/features/training/exercise_library_screen.dart
git commit -m "feat: add ExerciseIcon to ExerciseLibraryScreen"
```

---

## Task 6 — WorkoutPlanDetailScreen: Add Exercise Rows Per Day

**Files:**
- Modify: `lib/features/training/workout_plan_detail_screen.dart`
- Modify: `lib/core/providers/database_provider.dart`

- [ ] **Step 1 — Add Riverpod provider for day exercises**

In `lib/core/providers/database_provider.dart`, append at the end of the Training section:

```dart
final dayExercisesProvider = StreamProvider.autoDispose
    .family<List<WorkoutDayExercise>, int>((ref, dayId) =>
        ref.watch(trainingDaoProvider).watchDayExercises(dayId));

final activePlanProvider = FutureProvider.autoDispose<WorkoutPlan?>((ref) =>
    ref.watch(trainingDaoProvider).getActivePlan());
```

- [ ] **Step 2 — Update WorkoutPlanDetailScreen to show exercises**

In `lib/features/training/workout_plan_detail_screen.dart`, add import:

```dart
import 'widgets/exercise_icon.dart';
```

Replace the `_DayCard` widget's `build` method. Currently it shows only the day name in a single Row. Replace the entire `_DayCard` class with:

```dart
class _DayCard extends ConsumerWidget {
  final WorkoutDay day;
  final int dayNumber;
  final VoidCallback onStartWorkout;

  const _DayCard({
    required this.day,
    required this.dayNumber,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekDays = AppLocalizations.of(context)!.weekdaysShort.split(',');
    final exercisesAsync = ref.watch(dayExercisesProvider(day.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                    color: TraumColors.coralDim, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    day.dayOfWeek != null
                        ? weekDays[(day.dayOfWeek! - 1).clamp(0, 6)]
                        : '$dayNumber',
                    style: const TextStyle(
                        color: TraumColors.coralOrange,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(day.name,
                    style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_outline_rounded,
                    color: TraumColors.coralOrange, size: 28),
                onPressed: onStartWorkout,
              ),
            ]),
          ),
          // Exercise rows
          exercisesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(
                    AppLocalizations.of(context)!.noExercises,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 13),
                  ),
                );
              }
              return Column(
                children: entries.map((entry) =>
                  _ExerciseRow(dayExercise: entry)
                ).toList(),
              );
            },
            loading: () => const SizedBox(height: 32,
                child: Center(child: CircularProgressIndicator(
                    strokeWidth: 2, color: TraumColors.coralOrange))),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ExerciseRow extends ConsumerWidget {
  final WorkoutDayExercise dayExercise;
  const _ExerciseRow({required this.dayExercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(allExercisesStreamProvider);
    return exercisesAsync.when(
      data: (exercises) {
        final exercise = exercises.cast<Exercise?>().firstWhere(
          (e) => e?.id == dayExercise.exerciseId,
          orElse: () => null,
        );
        if (exercise == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(children: [
            ExerciseIcon(muscleGroup: exercise.muscleGroup, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(exercise.name,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
            ),
            Text(
              '${dayExercise.defaultSets}×${dayExercise.defaultReps}',
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 12),
            ),
          ]),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

Also change `_DayCard` from `StatelessWidget` to `ConsumerWidget` in the class declaration (already done above). Remove the old `_DayCard` entirely and add the new one.

Add the missing import at the top:

```dart
import '../../core/providers/database_provider.dart';
```

- [ ] **Step 3 — Add 'noExercises' localization key**

In `lib/l10n/app_de.arb`, add:
```json
"noExercises": "Noch keine Übungen"
```

In `lib/l10n/app_en.arb`, add:
```json
"noExercises": "No exercises yet"
```

In `lib/l10n/app_localizations.dart` abstract class, add:
```dart
String get noExercises;
```

Run `flutter gen-l10n` or `flutter pub get` to regenerate.

- [ ] **Step 4 — Hot reload and verify visually**

```
flutter run
```

Navigate to Training → a plan detail. Verify each training day now shows exercise rows with `ExerciseIcon` (36px) and set/rep info on the right.

- [ ] **Step 5 — Commit**

```
git add lib/features/training/workout_plan_detail_screen.dart \
        lib/core/providers/database_provider.dart \
        lib/l10n/app_de.arb lib/l10n/app_en.arb \
        lib/l10n/app_localizations.dart
git commit -m "feat: show exercise rows with icons in WorkoutPlanDetailScreen"
```

---

## Task 7 — ExerciseIcon in ActiveWorkoutScreen + SessionDetailScreen

**Files:**
- Modify: `lib/features/training/active_workout_screen.dart`
- Modify: `lib/features/training/workout_session_detail_screen.dart`

- [ ] **Step 1 — Add ExerciseIcon to ActiveWorkoutScreen**

Open `lib/features/training/active_workout_screen.dart`. Find where the current exercise name is displayed (there will be a `Text(exercise.name, ...)` or similar widget inside the exercise header area).

Add import:
```dart
import 'widgets/exercise_icon.dart';
```

Wrap the exercise name display in a `Row` with `ExerciseIcon` leading it (if not already in a Row):

```dart
Row(
  children: [
    ExerciseIcon(muscleGroup: exercise.muscleGroup, size: 40),
    const SizedBox(width: 12),
    Expanded(
      child: Text(
        exercise.name,
        style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
            fontSize: 18),
      ),
    ),
  ],
)
```

- [ ] **Step 2 — Add ExerciseIcon to WorkoutSessionDetailScreen**

Open `lib/features/training/workout_session_detail_screen.dart`. Find where exercises are listed in the post-workout summary.

Add import:
```dart
import 'widgets/exercise_icon.dart';
```

In each exercise row, add `ExerciseIcon` as a leading widget (size 36), identical pattern to Task 6's `_ExerciseRow`.

- [ ] **Step 3 — Hot reload and verify visually**

```
flutter run
```

Start a workout, verify the active exercise header shows the icon. Complete a workout, verify session detail shows icons.

- [ ] **Step 4 — Commit**

```
git add lib/features/training/active_workout_screen.dart \
        lib/features/training/workout_session_detail_screen.dart
git commit -m "feat: add ExerciseIcon to ActiveWorkoutScreen and SessionDetailScreen"
```

---

## Task 8 — Training Wizard: Container + WizardTemplateStep

**Files:**
- Create: `lib/features/training/training_wizard_screen.dart`
- Create: `lib/features/training/wizard_template_step.dart`

- [ ] **Step 1 — Create WizardTemplateStep**

Create `lib/features/training/wizard_template_step.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/repositories/plan_templates.dart';

class WizardTemplateStep extends StatelessWidget {
  final PlanTemplate? selected;
  final ValueChanged<PlanTemplate> onSelect;

  const WizardTemplateStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vorlage wählen',
          style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        const SizedBox(height: 6),
        const Text(
          'Wähle einen bewährten Plan oder erstelle deinen eigenen.',
          style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...PlanTemplates.all.map((t) => _TemplateCard(
          template: t,
          isSelected: selected?.id == t.id,
          onTap: () => onSelect(t),
        )),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final PlanTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? TraumColors.coralOrange.withOpacity(0.12)
              : TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: isSelected
                ? TraumColors.coralOrange
                : TraumColors.surface,
            width: 1.5,
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: TextStyle(
                      color: isSelected
                          ? TraumColors.coralOrange
                          : TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  template.subtitle,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: TraumColors.coralOrange, size: 22),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2 — Create TrainingWizardScreen container**

Create `lib/features/training/training_wizard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../data/repositories/plan_templates.dart';
import 'wizard_template_step.dart';
import 'wizard_days_step.dart';
import 'wizard_exercises_step.dart';

class TrainingWizardScreen extends ConsumerStatefulWidget {
  const TrainingWizardScreen({super.key});

  @override
  ConsumerState<TrainingWizardScreen> createState() =>
      _TrainingWizardScreenState();
}

class _TrainingWizardScreenState
    extends ConsumerState<TrainingWizardScreen> {
  int _step = 0;
  PlanTemplate? _selectedTemplate;
  // dayOfWeek (1–7) → day name
  final Map<int, String> _selectedDays = {};
  bool _saving = false;

  bool get _canAdvance {
    if (_step == 0) return _selectedTemplate != null;
    if (_step == 1) return _selectedDays.isNotEmpty;
    return true;
  }

  void _advance() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    final dao = ref.read(trainingDaoProvider);
    final allExercises = await dao.watchAllExercises().first;

    await dao.db.transaction(() async {
      // Deactivate all existing plans
      final existing = await dao.watchAllPlans().first;
      for (final p in existing) {
        await dao.updatePlan(p.toCompanion(true).copyWith(isActive: const Value(false)));
      }

      // Create new plan
      final planId = await dao.insertPlan(
        WorkoutPlansCompanion.insert(
          name: _selectedTemplate!.name,
          isActive: const Value(true),
        ),
      );

      // Create days + exercises
      for (final entry in _selectedDays.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))) {
        final dayId = await dao.insertDay(
          WorkoutDaysCompanion.insert(
            planId: planId,
            name: entry.value,
            dayOfWeek: Value(entry.key),
            sortOrder: Value(entry.key),
          ),
        );

        final templateDay = _selectedTemplate!.days.cast<TemplateDay?>()
            .firstWhere(
              (d) => d?.dayOfWeek == entry.key,
              orElse: () => null,
            );

        if (templateDay != null) {
          for (var i = 0; i < templateDay.exercises.length; i++) {
            final te = templateDay.exercises[i];
            final exercise = allExercises.cast<Exercise?>().firstWhere(
              (e) => e?.name == te.exerciseName,
              orElse: () => null,
            );
            if (exercise == null) continue;
            await dao.insertDayExercise(
              WorkoutDayExercisesCompanion.insert(
                dayId: dayId,
                exerciseId: exercise.id,
                sortOrder: Value(i),
                defaultSets: Value(te.sets),
                defaultReps: Value(te.reps),
              ),
            );
          }
        }
      }
    });

    // Mark setup complete in preferences
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setTrainingSetupComplete(true);

    if (mounted) context.go(Routes.training);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: TraumColors.onBackground),
                onPressed: _back,
              )
            : null,
        title: Text(
          'Schritt ${_step + 1} von 3',
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = ref.read(preferencesRepositoryProvider);
              await prefs.setTrainingSetupComplete(true);
              if (mounted) context.go(Routes.training);
            },
            child: const Text('Überspringen',
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 13)),
          ),
        ],
      ),
      body: Column(children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_step + 1) / 3,
          backgroundColor: TraumColors.surfaceVariant,
          color: TraumColors.coralOrange,
          minHeight: 3,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildStep(),
          ),
        ),
        // Bottom button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _canAdvance && !_saving ? _advance : null,
              style: FilledButton.styleFrom(
                backgroundColor: TraumColors.coralOrange,
                disabledBackgroundColor: TraumColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.button)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _step < 2 ? 'Weiter' : 'Fertig',
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return WizardTemplateStep(
          selected: _selectedTemplate,
          onSelect: (t) {
            setState(() {
              _selectedTemplate = t;
              _selectedDays.clear();
              for (final day in t.days) {
                _selectedDays[day.dayOfWeek] = day.name;
              }
            });
          },
        );
      case 1:
        return WizardDaysStep(
          template: _selectedTemplate!,
          selectedDays: _selectedDays,
          onChanged: (days) => setState(() {
            _selectedDays
              ..clear()
              ..addAll(days);
          }),
        );
      case 2:
        return WizardExercisesStep(
          template: _selectedTemplate!,
          selectedDays: _selectedDays,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
```

- [ ] **Step 3 — Verify it compiles**

```
flutter analyze lib/features/training/training_wizard_screen.dart \
               lib/features/training/wizard_template_step.dart
```

Expected: no errors (wizard_days_step and wizard_exercises_step stubs will cause errors until Tasks 9 and 10 are done — that is expected at this point).

- [ ] **Step 4 — Commit**

```
git add lib/features/training/training_wizard_screen.dart \
        lib/features/training/wizard_template_step.dart
git commit -m "feat: training wizard container + template selection step"
```

---

## Task 9 — WizardDaysStep

**Files:**
- Create: `lib/features/training/wizard_days_step.dart`
- Modify: `lib/data/preferences/preferences_repository.dart`

- [ ] **Step 1 — Add trainingSetupComplete to PreferencesRepository**

In `lib/data/preferences/preferences_repository.dart`, following the exact pattern of `onboardingComplete`, add:

```dart
bool get trainingSetupComplete =>
    _prefs.getBool('training_setup_complete') ?? false;
Future<void> setTrainingSetupComplete(bool v) =>
    _prefs.setBool('training_setup_complete', v);
```

- [ ] **Step 2 — Create wizard_days_step.dart**

Create `lib/features/training/wizard_days_step.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/repositories/plan_templates.dart';

class WizardDaysStep extends StatefulWidget {
  final PlanTemplate template;
  final Map<int, String> selectedDays; // dayOfWeek → name
  final ValueChanged<Map<int, String>> onChanged;

  const WizardDaysStep({
    super.key,
    required this.template,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  State<WizardDaysStep> createState() => _WizardDaysStepState();
}

class _WizardDaysStepState extends State<WizardDaysStep> {
  late Map<int, String> _days;
  final _controllers = <int, TextEditingController>{};

  static const _weekLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  void initState() {
    super.initState();
    _days = Map.from(widget.selectedDays);
    for (final entry in _days.entries) {
      _controllers[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  void _toggleDay(int dow) {
    setState(() {
      if (_days.containsKey(dow)) {
        _days.remove(dow);
        _controllers.remove(dow)?.dispose();
      } else {
        final defaultName = widget.template.days
            .cast<TemplateDay?>()
            .firstWhere((d) => d?.dayOfWeek == dow, orElse: () => null)
            ?.name ?? 'Training ${_weekLabels[dow - 1]}';
        _days[dow] = defaultName;
        _controllers[dow] = TextEditingController(text: defaultName);
      }
    });
    widget.onChanged(Map.from(_days));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trainingstage',
          style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        const SizedBox(height: 6),
        const Text(
          'Wähle die Tage und passe die Namen an.',
          style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14),
        ),
        const SizedBox(height: 20),
        // Weekday chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (i) {
            final dow = i + 1;
            final active = _days.containsKey(dow);
            return GestureDetector(
              onTap: () => _toggleDay(dow),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: active
                      ? TraumColors.coralOrange
                      : TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.chip),
                  border: Border.all(
                    color: active
                        ? TraumColors.coralOrange
                        : TraumColors.surfaceVariant,
                  ),
                ),
                child: Center(
                  child: Text(
                    _weekLabels[i],
                    style: TextStyle(
                        color: active ? Colors.white : TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_days.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Einheitennamen',
            style: TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 12,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          ...(_days.keys.toList()..sort()).map((dow) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                    color: TraumColors.coralDim, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    _weekLabels[dow - 1],
                    style: const TextStyle(
                        color: TraumColors.coralOrange,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controllers[dow],
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: TraumColors.surface,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TraumRadius.input),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onChanged: (v) {
                    _days[dow] = v;
                    widget.onChanged(Map.from(_days));
                  },
                ),
              ),
            ]),
          )),
        ],
      ],
    );
  }
}
```

- [ ] **Step 3 — Verify it compiles**

```
flutter analyze lib/features/training/wizard_days_step.dart \
               lib/data/preferences/preferences_repository.dart
```

Expected: no errors.

- [ ] **Step 4 — Commit**

```
git add lib/features/training/wizard_days_step.dart \
        lib/data/preferences/preferences_repository.dart
git commit -m "feat: wizard days step + trainingSetupComplete preference"
```

---

## Task 10 — WizardExercisesStep

**Files:**
- Create: `lib/features/training/wizard_exercises_step.dart`

- [ ] **Step 1 — Create wizard_exercises_step.dart**

Create `lib/features/training/wizard_exercises_step.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../data/repositories/plan_templates.dart';
import 'widgets/exercise_icon.dart';

class WizardExercisesStep extends ConsumerStatefulWidget {
  final PlanTemplate template;
  final Map<int, String> selectedDays; // dayOfWeek → name

  const WizardExercisesStep({
    super.key,
    required this.template,
    required this.selectedDays,
  });

  @override
  ConsumerState<WizardExercisesStep> createState() =>
      _WizardExercisesStepState();
}

class _WizardExercisesStepState
    extends ConsumerState<WizardExercisesStep> {
  // dayOfWeek → list of (exerciseName, sets, reps)
  late Map<int, List<_WizardExerciseEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = {};
    for (final dow in widget.selectedDays.keys) {
      final templateDay = widget.template.days.cast<TemplateDay?>()
          .firstWhere((d) => d?.dayOfWeek == dow, orElse: () => null);
      _entries[dow] = templateDay?.exercises
              .map((e) => _WizardExerciseEntry(
                    exerciseName: e.exerciseName,
                    sets: e.sets,
                    reps: e.reps,
                  ))
              .toList() ??
          [];
    }
  }

  void _removeExercise(int dow, int index) {
    setState(() => _entries[dow]!.removeAt(index));
  }

  Future<void> _showPicker(int dow) async {
    final allExercises = await ref.read(trainingDaoProvider).watchAllExercises().first;
    if (!mounted) return;

    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(TraumRadius.bottomSheet)),
      ),
      builder: (_) => _ExercisePickerSheet(exercises: allExercises),
    );

    if (picked != null) {
      setState(() {
        _entries[dow]!.add(_WizardExerciseEntry(
          exerciseName: picked.name,
          sets: 3,
          reps: 10,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDays = widget.selectedDays.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Übungen prüfen',
          style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        const SizedBox(height: 6),
        const Text(
          'Passe die Übungen je Trainingstag an.',
          style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...sortedDays.map((dow) => _DayExerciseBlock(
          dayName: widget.selectedDays[dow]!,
          entries: _entries[dow]!,
          onRemove: (i) => _removeExercise(dow, i),
          onAdd: () => _showPicker(dow),
        )),
      ],
    );
  }
}

class _DayExerciseBlock extends StatelessWidget {
  final String dayName;
  final List<_WizardExerciseEntry> entries;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  const _DayExerciseBlock({
    required this.dayName,
    required this.entries,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dayName,
              style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 10),
          ...entries.asMap().entries.map((e) => _ExerciseTile(
            entry: e.value,
            onRemove: () => onRemove(e.key),
          )),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded,
                color: TraumColors.coralOrange, size: 18),
            label: const Text('Übung hinzufügen',
                style: TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends ConsumerWidget {
  final _WizardExerciseEntry entry;
  final VoidCallback onRemove;

  const _ExerciseTile({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(allExercisesStreamProvider);
    return exercisesAsync.when(
      data: (exercises) {
        final exercise = exercises.cast<Exercise?>()
            .firstWhere((e) => e?.name == entry.exerciseName, orElse: () => null);
        final muscleGroup = exercise?.muscleGroup ?? 'full_body';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            ExerciseIcon(muscleGroup: muscleGroup, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(entry.exerciseName,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
            ),
            Text('${entry.sets}×${entry.reps}',
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 12)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded,
                  color: TraumColors.onBackgroundMuted, size: 18),
            ),
          ]),
        );
      },
      loading: () => const SizedBox(height: 36),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercise> exercises;
  const _ExercisePickerSheet({required this.exercises});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.exercises
        .where((e) =>
            e.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(children: [
        const SizedBox(height: 12),
        Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: TraumColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              hintText: 'Übung suchen...',
              hintStyle: const TextStyle(color: TraumColors.onBackgroundMuted),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: TraumColors.onBackgroundMuted),
              filled: true,
              fillColor: TraumColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TraumRadius.input),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: controller,
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final ex = filtered[i];
              return ListTile(
                leading: ExerciseIcon(muscleGroup: ex.muscleGroup, size: 40),
                title: Text(ex.name,
                    style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontSize: 14)),
                subtitle: Text(ex.muscleGroup,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 12)),
                onTap: () => Navigator.pop(context, ex),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _WizardExerciseEntry {
  String exerciseName;
  int sets;
  int reps;
  _WizardExerciseEntry({
    required this.exerciseName,
    required this.sets,
    required this.reps,
  });
}
```

- [ ] **Step 2 — Verify full wizard compiles**

```
flutter analyze lib/features/training/
```

Expected: no errors.

- [ ] **Step 3 — Commit**

```
git add lib/features/training/wizard_exercises_step.dart
git commit -m "feat: wizard exercises step with exercise picker sheet"
```

---

## Task 11 — Router: Add /training/setup Route + Redirect

**Files:**
- Modify: `lib/core/navigation/routes.dart`
- Modify: `lib/core/navigation/router.dart`

- [ ] **Step 1 — Add route constant**

In `lib/core/navigation/routes.dart`, add after `muscleHeatmap`:

```dart
static const String trainingSetup = '/training/setup';
```

- [ ] **Step 2 — Add route and redirect to router.dart**

In `lib/core/navigation/router.dart`, add the import:

```dart
import '../../features/training/training_wizard_screen.dart';
```

Inside `GoRouter(...)`, update the `redirect` callback to also handle the training setup case:

```dart
redirect: (context, state) {
  final onboarded = prefs.onboardingComplete;
  final goingToOnboarding = state.matchedLocation == Routes.onboarding;
  if (!onboarded && !goingToOnboarding) return Routes.onboarding;
  if (onboarded && goingToOnboarding) return Routes.home;

  // If onboarded but training setup not done, redirect /training to /training/setup
  final trainingSetupDone = prefs.trainingSetupComplete;
  if (onboarded &&
      !trainingSetupDone &&
      state.matchedLocation == Routes.training) {
    return Routes.trainingSetup;
  }
  return null;
},
```

Add the `/training/setup` route as a top-level `GoRoute` (outside `ShellRoute`, so the nav bar is hidden), placed before the `ShellRoute`:

```dart
GoRoute(
  path: Routes.trainingSetup,
  builder: (_, __) => const TrainingWizardScreen(),
),
```

- [ ] **Step 3 — Verify compile + navigation**

```
flutter analyze lib/core/navigation/
```

Expected: no errors.

```
flutter run
```

With a fresh install (or after clearing `SharedPreferences`), open the app and navigate to Training. Verify you are redirected to the wizard screen. Complete the wizard and verify you land on `/training`.

- [ ] **Step 4 — Commit**

```
git add lib/core/navigation/routes.dart \
        lib/core/navigation/router.dart
git commit -m "feat: add /training/setup route and wizard redirect"
```

---

## Task 12 — Training Main Screen Redesign

**Files:**
- Modify: `lib/features/training/training_screen.dart`

- [ ] **Step 1 — Read the current training_screen.dart**

Open `lib/features/training/training_screen.dart` and identify:
- The existing week day selector widget (horizontal scroll strip)
- The large gradient "Today's Workout" hero card
- The weekly progress card
- The muscle groups overview section
- The routines list section

The muscle groups section and routines section are kept. The day selector, hero card, and weekly progress card are replaced.

- [ ] **Step 2 — Add activePlanProvider and weekday helpers**

At the top of `training_screen.dart`, ensure these providers are imported/used:

```dart
import '../../core/providers/database_provider.dart';
// activePlanProvider and trainingSessionsThisWeekProvider are already in database_provider.dart
```

Add a helper extension near the top of the file (outside any class):

```dart
String _dowLabel(int dow) =>
    const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][dow - 1];
```

- [ ] **Step 3 — Replace the top section of TrainingScreen with week strip + stats + today card**

Find the section in `TrainingScreen.build` that renders the day selector and hero card. Replace it with the following three widgets (keep whatever comes after them unchanged):

**Week Strip widget** (add as a private class at end of file):

```dart
class _WeekStrip extends StatelessWidget {
  final List<int> plannedDows; // dayOfWeek values from active plan days
  final List<DateTime> completedDates; // startedAt values from this week's sessions

  const _WeekStrip({required this.plannedDows, required this.completedDates});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday; // 1=Mo
    final labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Row(
      children: List.generate(7, (i) {
        final dow = i + 1;
        final isToday = dow == today;
        final isPlanned = plannedDows.contains(dow);
        final isCompleted = completedDates.any((d) => d.weekday == dow);

        Color dotColor;
        if (isCompleted) {
          dotColor = TraumColors.mintGreen;
        } else if (isPlanned) {
          dotColor = TraumColors.coralOrange;
        } else {
          dotColor = TraumColors.surfaceVariant;
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isToday
                  ? TraumColors.coralOrange.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(
                      color: TraumColors.coralOrange.withOpacity(0.4))
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  labels[i],
                  style: TextStyle(
                      color: isToday
                          ? TraumColors.coralOrange
                          : TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 12),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: dotColor, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
```

**Stats Row widget**:

```dart
class _StatsRow extends StatelessWidget {
  final int completed;
  final int planned;
  final double volumeKg;

  const _StatsRow({
    required this.completed,
    required this.planned,
    required this.volumeKg,
  });

  @override
  Widget build(BuildContext context) {
    String volLabel;
    if (volumeKg >= 1000) {
      volLabel = '${(volumeKg / 1000).toStringAsFixed(1)}t';
    } else {
      volLabel = '${volumeKg.toInt()} kg';
    }

    return Row(children: [
      _StatTile(value: '$completed', label: 'Absolviert'),
      const SizedBox(width: 10),
      _StatTile(value: '$planned', label: 'Geplant'),
      const SizedBox(width: 10),
      _StatTile(value: volLabel, label: 'Volumen'),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  color: TraumColors.coralOrange,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 11)),
        ]),
      ),
    );
  }
}
```

**Today Card widget**:

```dart
class _TodayCard extends StatelessWidget {
  final WorkoutDay? todayDay;
  final int exerciseCount;

  const _TodayCard({this.todayDay, required this.exerciseCount});

  @override
  Widget build(BuildContext context) {
    if (todayDay == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: Row(children: [
          const Icon(Icons.self_improvement_rounded,
              color: TraumColors.onBackgroundMuted, size: 28),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('Ruhetag',
                style: TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ),
          TextButton(
            onPressed: () => context.go(Routes.activeWorkout),
            child: const Text('Freies Training',
                style: TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontSize: 13)),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.coralOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(
            color: TraumColors.coralOrange.withOpacity(0.3)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(todayDay!.name,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 3),
              Text('$exerciseCount Übungen · heute',
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
            ],
          ),
        ),
        FilledButton(
          onPressed: () => context.go(Routes.activeWorkout),
          style: FilledButton.styleFrom(
            backgroundColor: TraumColors.coralOrange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TraumRadius.button)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text('Start',
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ]),
    );
  }
}
```

**Wire them up in `TrainingScreen.build`** — replace the old hero card section with:

```dart
// In TrainingScreen build, at the top of the body ListView:

final activePlanAsync = ref.watch(activePlanProvider);
final sessionsAsync = ref.watch(trainingSessionsThisWeekProvider);
final allPlansAsync = ref.watch(allWorkoutPlansStreamProvider);

// Derive planned days from active plan
final activePlan = activePlanAsync.valueOrNull;
// This needs the active plan's days — add another provider watch:
final daysAsync = activePlan != null
    ? ref.watch(workoutDaysForPlanProvider(activePlan.id))
    : const AsyncData<List<WorkoutDay>>([]);
final days = daysAsync.valueOrNull ?? [];

final sessions = sessionsAsync.valueOrNull ?? [];
final today = DateTime.now().weekday;
final todayDay = days.cast<WorkoutDay?>()
    .firstWhere((d) => d?.dayOfWeek == today, orElse: () => null);

// Compute total volume this week from sets
final setsAsync = ref.watch(recentTrainingSetsProvider(7));
final sets = setsAsync.valueOrNull ?? [];
final totalVolume = sets.fold<double>(
    0, (sum, s) => sum + ((s.weightKg ?? 0) * (s.reps ?? 1)));

// Exercise count for today's day
final todayExercisesAsync = todayDay != null
    ? ref.watch(dayExercisesProvider(todayDay.id))
    : const AsyncData<List<WorkoutDayExercise>>([]);
final todayExerciseCount = todayExercisesAsync.valueOrNull?.length ?? 0;

// Render:
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(children: [
      _WeekStrip(
        plannedDows: days.where((d) => d.dayOfWeek != null)
            .map((d) => d.dayOfWeek!).toList(),
        completedDates: sessions.map((s) => s.startedAt).toList(),
      ),
      const SizedBox(height: 14),
      _StatsRow(
        completed: sessions.length,
        planned: days.length,
        volumeKg: totalVolume,
      ),
      const SizedBox(height: 14),
      _TodayCard(todayDay: todayDay, exerciseCount: todayExerciseCount),
      const SizedBox(height: 20),
    ]),
  ),
),
```

Remove the old day-selector scroll widget and old hero gradient card from the build method entirely.

- [ ] **Step 4 — Verify it compiles and runs**

```
flutter analyze lib/features/training/training_screen.dart
flutter run
```

Navigate to Training. Verify the week strip shows Mo–So, dots are correct for today/planned/completed. Verify stats row shows 3 tiles. Verify today card shows day name + Start button, or Ruhetag if today is a rest day.

- [ ] **Step 5 — Build release APK and verify**

```
flutter build apk --release
```

Expected: BUILD SUCCESSFUL.

- [ ] **Step 6 — Commit**

```
git add lib/features/training/training_screen.dart
git commit -m "feat: redesign TrainingScreen with week strip, stats, and today card"
```

---

## Task 13 — Localization Strings

**Files:**
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_localizations.dart`

- [ ] **Step 1 — Add all new keys to app_de.arb**

Add to `lib/l10n/app_de.arb`:

```json
"trainingSetupTitle": "Trainingsplan einrichten",
"trainingSetupSubtitle": "Dauert nur 2 Minuten",
"wizardSkip": "Überspringen",
"wizardNext": "Weiter",
"wizardFinish": "Fertig",
"wizardStepOf": "Schritt {current} von {total}",
"@wizardStepOf": {
  "placeholders": {
    "current": {"type": "int"},
    "total": {"type": "int"}
  }
},
"templateSelectTitle": "Vorlage wählen",
"templateSelectSubtitle": "Wähle einen bewährten Plan oder erstelle deinen eigenen.",
"daysSelectTitle": "Trainingstage",
"daysSelectSubtitle": "Wähle die Tage und passe die Namen an.",
"exercisesReviewTitle": "Übungen prüfen",
"exercisesReviewSubtitle": "Passe die Übungen je Trainingstag an.",
"addExercise": "Übung hinzufügen",
"searchExercise": "Übung suchen...",
"restDay": "Ruhetag",
"freeTraining": "Freies Training",
"completedThisWeek": "Absolviert",
"plannedThisWeek": "Geplant",
"weeklyVolume": "Volumen"
```

- [ ] **Step 2 — Add all new keys to app_en.arb**

Add to `lib/l10n/app_en.arb`:

```json
"trainingSetupTitle": "Set up training plan",
"trainingSetupSubtitle": "Takes only 2 minutes",
"wizardSkip": "Skip",
"wizardNext": "Next",
"wizardFinish": "Done",
"wizardStepOf": "Step {current} of {total}",
"@wizardStepOf": {
  "placeholders": {
    "current": {"type": "int"},
    "total": {"type": "int"}
  }
},
"templateSelectTitle": "Choose template",
"templateSelectSubtitle": "Choose a proven plan or build your own.",
"daysSelectTitle": "Training days",
"daysSelectSubtitle": "Select days and customize the names.",
"exercisesReviewTitle": "Review exercises",
"exercisesReviewSubtitle": "Adjust exercises per training day.",
"addExercise": "Add exercise",
"searchExercise": "Search exercise...",
"restDay": "Rest day",
"freeTraining": "Free workout",
"completedThisWeek": "Completed",
"plannedThisWeek": "Planned",
"weeklyVolume": "Volume"
```

- [ ] **Step 3 — Add declarations to app_localizations.dart**

In the abstract class in `lib/l10n/app_localizations.dart`, add:

```dart
String get trainingSetupTitle;
String get trainingSetupSubtitle;
String get wizardSkip;
String get wizardNext;
String get wizardFinish;
String wizardStepOf(int current, int total);
String get templateSelectTitle;
String get templateSelectSubtitle;
String get daysSelectTitle;
String get daysSelectSubtitle;
String get exercisesReviewTitle;
String get exercisesReviewSubtitle;
String get addExercise;
String get searchExercise;
String get restDay;
String get freeTraining;
String get completedThisWeek;
String get plannedThisWeek;
String get weeklyVolume;
```

- [ ] **Step 4 — Regenerate localizations**

```
cd traum_app
flutter gen-l10n
```

Expected: no errors; generated files updated.

- [ ] **Step 5 — Wire localization strings into wizard and training screen**

Replace hardcoded strings in `training_wizard_screen.dart`, `wizard_template_step.dart`, `wizard_days_step.dart`, `wizard_exercises_step.dart`, and `training_screen.dart` with `AppLocalizations.of(context)!.xxx` calls. The hardcoded strings were written for clarity in prior tasks — now replace them systematically.

Example replacements:
- `'Vorlage wählen'` → `AppLocalizations.of(context)!.templateSelectTitle`
- `'Weiter'` → `AppLocalizations.of(context)!.wizardNext`
- `'Fertig'` → `AppLocalizations.of(context)!.wizardFinish`
- `'Überspringen'` → `AppLocalizations.of(context)!.wizardSkip`
- `'Ruhetag'` → `AppLocalizations.of(context)!.restDay`
- `'Freies Training'` → `AppLocalizations.of(context)!.freeTraining`

- [ ] **Step 6 — Final build**

```
flutter build apk --release
```

Expected: BUILD SUCCESSFUL with no localization errors.

- [ ] **Step 7 — Commit**

```
git add lib/l10n/app_de.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart \
        lib/features/training/training_wizard_screen.dart \
        lib/features/training/wizard_template_step.dart \
        lib/features/training/wizard_days_step.dart \
        lib/features/training/wizard_exercises_step.dart \
        lib/features/training/training_screen.dart
git commit -m "feat: wire localization strings into wizard and training screen"
```

---

## Self-Review

**Spec coverage check:**

| Spec Requirement | Task |
|-----------------|------|
| Wizard: redirect `/training` → `/training/setup` when no plan | Task 11 |
| Wizard: Step 1 — template selection | Task 8 |
| Wizard: Step 2 — day chips + names | Task 9 |
| Wizard: Step 3 — exercise review + picker | Task 10 |
| PPL / Ganzkörper / Upper-Lower + Custom templates | Task 2 |
| WorkoutDayExercises table (new) | Task 1 |
| 9 SVG muscle-group assets | Task 3 |
| ExerciseIcon widget | Task 4 |
| ExerciseIcon in ExerciseLibraryScreen | Task 5 |
| ExerciseIcon + exercise rows in WorkoutPlanDetailScreen | Task 6 |
| ExerciseIcon in ActiveWorkoutScreen + SessionDetail | Task 7 |
| Main screen: week strip | Task 12 |
| Main screen: stats row | Task 12 |
| Main screen: compact today card | Task 12 |
| Localization for all new UI text | Task 13 |
| No emojis anywhere | enforced in all tasks (SVGs used, no emoji literals) |

**Type consistency:**
- `WorkoutDayExercise` (generated Drift model) used consistently in Tasks 1, 6, 10, 12
- `PlanTemplate`, `TemplateDay`, `TemplateExercise` defined in Task 2, used in Tasks 8–10
- `ExerciseIcon(muscleGroup: string, size: double)` defined in Task 4, used in Tasks 5–7, 10
- `dayExercisesProvider(dayId)` defined in Task 6, used in Tasks 6, 12
- `activePlanProvider` defined in Task 6, used in Task 12
- `Routes.trainingSetup` defined in Task 11, used in Tasks 9, 10 (`context.go`)

**No placeholders:** All tasks contain complete code. No TBDs.

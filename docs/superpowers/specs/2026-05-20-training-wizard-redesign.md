# Training Wizard & UX Redesign

**Date:** 2026-05-20
**Status:** Approved

---

## Overview

Overhaul the training section of the Traum app with three goals:

1. **Onboarding wizard** — first-time users build their training plan before they can access the training tab
2. **Exercise icons** — every exercise gets a small SVG muscle-group icon (no emojis anywhere)
3. **Main screen redesign** — replace the large gradient card with a week-overview layout

---

## Constraint

**No emojis anywhere in the UI.** All visual elements are SVG assets, text, or standard Flutter widgets.

---

## 1. Onboarding Wizard

### Trigger

When the user opens the Training tab and no `WorkoutPlan` exists in the database, the router redirects to `/training/setup`. The wizard cannot be dismissed without either completing it or explicitly tapping "Überspringen" (which is visible but de-emphasized).

### Route

```
/training/setup   →   TrainingWizardScreen
```

Added to `routes.dart` as a sibling of `/training`. The shell navigation bar is hidden on this route.

### Three Steps

#### Step 1 — Template Selection

Four selectable cards, displayed as a vertical list:

| Template | Tage | Beschreibung |
|----------|------|--------------|
| Push / Pull / Legs | 3 | Klassisch · Muskelaufbau |
| Ganzkörper 3× | 3 | Anfänger · Kraft + Ausdauer |
| Upper / Lower Split | 4 | Fortgeschritten · Hypertrophie |
| Eigener Plan | frei | Komplett selbst zusammenstellen |

Each card shows: name, day count badge, short description. Selecting one highlights it; tapping "Weiter" advances to Step 2.

#### Step 2 — Trainingstage zuweisen

- Seven day-chips (Mo–So) displayed as a horizontal wrap.
- Pre-selected based on chosen template (e.g. PPL → Mo/Mi/Fr).
- "Eigener Plan" starts with nothing selected.
- Each selected day gets an auto-generated name from the template (e.g. "Push Day", "Pull Day", "Leg Day"). Names are shown below the chips as editable `TextField` tiles — one per selected day.
- Minimum 1 day required to advance.

#### Step 3 — Übungen prüfen & anpassen

- Horizontal `PageView`, one page per selected training day.
- Each page shows the day name as header and a list of pre-filled exercises (from the template), each with:
  - `ExerciseIcon` (44×44 px, see section 2)
  - Exercise name
  - Default set/rep scheme (e.g. "4 × 8")
  - Delete icon to remove
- Floating "+" button opens the existing `ExerciseLibraryScreen` in a modal bottom sheet for adding exercises.
- "Fertig" button (bottom, full-width, coral):
  - Creates the `WorkoutPlan` in the database
  - Creates one `WorkoutDay` per selected day
  - Inserts the `WorkoutDayExercise` rows
  - Marks the plan as active (`isActive = true`)
  - Navigates to `/training`

### Plan Templates

New file: `lib/data/repositories/plan_templates.dart`

```dart
class PlanTemplate {
  final String name;
  final List<TemplateDay> days;
}

class TemplateDay {
  final String name;          // e.g. "Push Day"
  final int? defaultDayOfWeek; // 1=Mo, null=unassigned
  final List<TemplateExercise> exercises;
}

class TemplateExercise {
  final String exerciseName;  // must match seeded exercise name
  final int sets;
  final int reps;
}
```

Three pre-built `PlanTemplate` constants for PPL, Ganzkörper, Upper/Lower. Templates reference exercises by name — resolved against the seeded `Exercises` table during wizard completion.

### Database

No schema changes required. The wizard uses existing tables: `WorkoutPlans`, `WorkoutDays`, `WorkoutSets`. A new junction table `WorkoutDayExercises` is needed to store the exercise-to-day assignment with default set/rep targets:

```
WorkoutDayExercises
├─ id
├─ dayId        (FK → WorkoutDays)
├─ exerciseId   (FK → Exercises)
├─ sortOrder
├─ defaultSets  (int)
└─ defaultReps  (int)
```

This table is currently missing — it must be added as a new Drift table and migration.

---

## 2. Exercise Icons (SVG)

### Assets

9 SVG files in `assets/exercises/icons/`:

| File | Muskelgruppe | Akzentfarbe |
|------|-------------|-------------|
| `chest.svg` | Brust | `#FF6B6B` (coralOrange) |
| `back.svg` | Rücken | `#4ECDC4` (mintGreen) |
| `shoulders.svg` | Schultern | `#A78BFA` (violet) |
| `biceps.svg` | Bizeps | `#F59E0B` (amber) |
| `triceps.svg` | Trizeps | `#FB923C` (orange) |
| `legs.svg` | Beine | `#60A5FA` (blue) |
| `core.svg` | Core | `#34D399` (emerald) |
| `cardio.svg` | Cardio | `#F472B6` (pink) |
| `full_body.svg` | Ganzkörper | `#94A3B8` (slate) |

Each SVG: 44×44 viewBox, white body silhouette outline on transparent background, target muscle filled with the accent color. Style: flat, minimal, no gradients.

`pubspec.yaml` gets a new asset entry: `assets/exercises/icons/`.

### ExerciseIcon Widget

New file: `lib/features/training/widgets/exercise_icon.dart`

```dart
class ExerciseIcon extends StatelessWidget {
  final String muscleGroup;   // "chest", "back", etc.
  final double size;          // default 44
}
```

- Renders a rounded square container (radius 10) with a semi-transparent background in the muscle group's accent color (20% opacity).
- Inside: the SVG loaded via `flutter_svg` package (already a dependency or added).
- Falls back to a generic dumbbell SVG (`full_body.svg`) if `muscleGroup` is unrecognized.

### Integration Points

`ExerciseIcon` is added to:

- `ExerciseLibraryScreen` — each exercise list tile gets a leading `ExerciseIcon`
- `WorkoutPlanDetailScreen` — each exercise row in a day card
- `ActiveWorkoutScreen` — exercise header during live session
- `WorkoutSessionDetailScreen` — exercise rows in the post-workout summary
- `wizard_exercises_step.dart` — exercise rows in Step 3 of the wizard

---

## 3. Training Main Screen Redesign

File: `lib/features/training/training_screen.dart`

The existing large gradient "Today's Workout" hero card is removed. Replaced with:

### New Layout (top to bottom)

1. **Wochenstreifen** — 7 day columns (Mo–So), each showing:
   - Day abbreviation
   - Dot indicator: filled coral = training day in active plan, filled mint = completed session, filled coral + ring = today's training day, empty = rest day
   - Today's column is highlighted with a coral border

2. **Stats-Zeile** — three equal-width tiles in a row:
   - Absolviert (sessions completed this week)
   - Geplant (sessions in plan this week)
   - Volumen (total kg lifted this week, formatted as "4.2t" or "840 kg")

3. **Heute-Karte** — compact card showing:
   - Plan day name (e.g. "Push Day")
   - Exercise count and scheduled weekday
   - "Training starten" button (coral, full-width)
   - If today is a rest day: shows "Ruhetag" with an option to start a free session

4. **Muskelgruppen-Übersicht** — unchanged from current implementation

5. **Meine Routinen** — unchanged from current implementation

The week strip replaces the existing day-selector scroll widget. The `TrainingScreen` state reads from `trainingSessionsThisWeekProvider` and the active plan's `WorkoutDays` to compute dot states.

---

## Files Affected

### New Files

| Path | Purpose |
|------|---------|
| `lib/features/training/training_wizard_screen.dart` | Wizard container with step navigation |
| `lib/features/training/wizard_template_step.dart` | Step 1: template selection |
| `lib/features/training/wizard_days_step.dart` | Step 2: day + name assignment |
| `lib/features/training/wizard_exercises_step.dart` | Step 3: exercise review per day |
| `lib/features/training/widgets/exercise_icon.dart` | Reusable SVG icon widget |
| `lib/data/repositories/plan_templates.dart` | Pre-built template data |
| `assets/exercises/icons/*.svg` (9 files) | Muscle group SVG icons (requires own `pubspec.yaml` asset entry — `assets/exercises/` does not cover subdirectories in Flutter) |

### Modified Files

| Path | Change |
|------|--------|
| `lib/data/database/tables/training_tables.dart` | Add `WorkoutDayExercises` table |
| `lib/data/database/daos/training_dao.dart` | Add CRUD for `WorkoutDayExercises` |
| `lib/data/database/traum_database.dart` | Register new table, bump schema version |
| `lib/core/navigation/routes.dart` | Add `/training/setup` route |
| `lib/core/navigation/router.dart` | Redirect logic: no plan → `/training/setup` |
| `lib/features/training/training_screen.dart` | New week-overview layout |
| `lib/features/training/exercise_library_screen.dart` | Add `ExerciseIcon` to list tiles |
| `lib/features/training/workout_plan_detail_screen.dart` | Add exercise rows per day (currently shows only day names); add `ExerciseIcon` |
| `lib/features/training/active_workout_screen.dart` | Add `ExerciseIcon` to exercise header |
| `lib/features/training/workout_session_detail_screen.dart` | Add `ExerciseIcon` to exercise rows |
| `pubspec.yaml` | Add `assets/exercises/icons/` entry (`flutter_svg ^2.0.10+1` already present) |

---

## Out of Scope

- Animated GIFs or video demos for exercises
- AI-generated workout recommendations
- Syncing plans across devices
- Editing a plan after wizard completion (uses existing `WorkoutPlanDetailScreen`)

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
  final int dayOfWeek; // 1=Mo ... 7=So
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
  final String unit; // 'reps' | 'seconds'

  const TemplateExercise({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.unit = 'reps',
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
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 60, unit: 'seconds'),
        ],
      ),
    ],
  );

  static const PlanTemplate ganzkoerper = PlanTemplate(
    id: 'ganzkoerper',
    name: 'Ganzkoerper 3x',
    subtitle: '3 Tage · Kraft + Ausdauer',
    days: [
      TemplateDay(
        name: 'Ganzkoerper A',
        dayOfWeek: 1,
        exercises: [
          TemplateExercise(exerciseName: 'Bankdruecken', sets: 3, reps: 10),
          TemplateExercise(exerciseName: 'Kniebeugen', sets: 3, reps: 10),
          TemplateExercise(exerciseName: 'Klimmzuege', sets: 3, reps: 8),
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 45, unit: 'seconds'),
        ],
      ),
      TemplateDay(
        name: 'Ganzkoerper B',
        dayOfWeek: 3,
        exercises: [
          TemplateExercise(exerciseName: 'Schulterdruecken', sets: 3, reps: 10),
          TemplateExercise(exerciseName: 'Kreuzheben', sets: 3, reps: 8),
          TemplateExercise(exerciseName: 'Bizepscurls', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Laufen', sets: 1, reps: 20, unit: 'seconds'),
        ],
      ),
      TemplateDay(
        name: 'Ganzkoerper C',
        dayOfWeek: 5,
        exercises: [
          TemplateExercise(exerciseName: 'Liegestuetze', sets: 4, reps: 12),
          TemplateExercise(exerciseName: 'Ausfallschritte', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Trizepsdruecken', sets: 3, reps: 12),
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 45, unit: 'seconds'),
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
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 45, unit: 'seconds'),
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
          TemplateExercise(exerciseName: 'Plank', sets: 3, reps: 60, unit: 'seconds'),
          TemplateExercise(exerciseName: 'Laufen', sets: 1, reps: 20, unit: 'seconds'),
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

  static const List<PlanTemplate> all = [ppl, ganzkoerper, upperLower, custom];
}

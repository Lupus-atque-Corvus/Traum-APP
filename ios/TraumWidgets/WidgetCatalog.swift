struct WidgetSlotDef { let label: String; let valueKey: String; let goalKey: String? }
struct WidgetCatalogDef {
    let key: String
    let title: String
    let groupLabel: String
    let accentHex: String
    let template: String
    let route: String
    let slots: [WidgetSlotDef]
}

enum WidgetCatalogSwift {
    static let tabs: [WidgetCatalogDef] = [
        WidgetCatalogDef(
            key: "overview",
            title: "Übersicht",
            groupLabel: "Allgemein",
            accentHex: "#FF6B3D",
            template: "overview",
            route: "/home",
            slots: [
            WidgetSlotDef(label: "Schritte", valueKey: "health.steps", goalKey: "health.stepsGoal"),
            WidgetSlotDef(label: "Kalorien", valueKey: "nutrition.kcal", goalKey: "nutrition.kcalGoal"),
            WidgetSlotDef(label: "Wasser", valueKey: "nutrition.waterMl", goalKey: "nutrition.waterGoalMl"),
            WidgetSlotDef(label: "Aufgabe", valueKey: "planning.nextTodo", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "health",
            title: "Gesundheit",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "overview",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Score", valueKey: "health.score", goalKey: nil),
            WidgetSlotDef(label: "Schlaf", valueKey: "health.sleepHours", goalKey: nil),
            WidgetSlotDef(label: "Puls", valueKey: "health.heartRate", goalKey: nil),
            WidgetSlotDef(label: "Aktiv", valueKey: "health.activeMinutes", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "nutrition",
            title: "Ernährung",
            groupLabel: "Ernährung",
            accentHex: "#3DD68C",
            template: "overview",
            route: "/nutrition",
            slots: [
            WidgetSlotDef(label: "Kalorien", valueKey: "nutrition.kcal", goalKey: "nutrition.kcalGoal"),
            WidgetSlotDef(label: "Protein", valueKey: "nutrition.protein", goalKey: "nutrition.proteinGoal"),
            WidgetSlotDef(label: "Wasser", valueKey: "nutrition.waterMl", goalKey: "nutrition.waterGoalMl"),
            WidgetSlotDef(label: "Mahlzeit", valueKey: "nutrition.lastMeal", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "training",
            title: "Training",
            groupLabel: "Training",
            accentHex: "#5B6CF9",
            template: "overview",
            route: "/training",
            slots: [
            WidgetSlotDef(label: "Nächstes", valueKey: "training.nextWorkout", goalKey: nil),
            WidgetSlotDef(label: "Volumen", valueKey: "training.weeklyVolume", goalKey: nil),
            WidgetSlotDef(label: "Streak", valueKey: "training.streak", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "planning",
            title: "Planung",
            groupLabel: "Planung",
            accentHex: "#F5A623",
            template: "overview",
            route: "/planning",
            slots: [
            WidgetSlotDef(label: "Offen", valueKey: "planning.openTodos", goalKey: nil),
            WidgetSlotDef(label: "Termin", valueKey: "planning.nextAppointment", goalKey: nil),
            WidgetSlotDef(label: "Habits", valueKey: "planning.habitsDone", goalKey: "planning.habitsTotal"),
            WidgetSlotDef(label: "Medis", valueKey: "planning.medsDone", goalKey: "planning.medsTotal"),
            ]
        ),
        WidgetCatalogDef(
            key: "budget",
            title: "Budget",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "overview",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Saldo", valueKey: "budget.balanceMonth", goalKey: nil),
            WidgetSlotDef(label: "Ausgaben", valueKey: "budget.spent", goalKey: "budget.limit"),
            WidgetSlotDef(label: "Einnahmen", valueKey: "budget.income", goalKey: nil),
            WidgetSlotDef(label: "Top", valueKey: "budget.topCategory", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "diary",
            title: "Tagebuch",
            groupLabel: "Tagebuch",
            accentHex: "#9B8EC4",
            template: "overview",
            route: "/diary",
            slots: [
            WidgetSlotDef(label: "Streak", valueKey: "diary.writeStreak", goalKey: nil),
            WidgetSlotDef(label: "Letzter", valueKey: "diary.lastEntry", goalKey: nil),
            WidgetSlotDef(label: "Monat", valueKey: "diary.entriesThisMonth", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "abstinence",
            title: "Abstinenz",
            groupLabel: "Abstinenz",
            accentHex: "#FFAA55",
            template: "overview",
            route: "/abstinence",
            slots: [
            WidgetSlotDef(label: "Titel", valueKey: "abstinence.title", goalKey: nil),
            WidgetSlotDef(label: "Dauer", valueKey: "abstinence.duration", goalKey: nil),
            WidgetSlotDef(label: "Gespart", valueKey: "abstinence.moneySaved", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "substances",
            title: "Mittel",
            groupLabel: "Mittel",
            accentHex: "#0099BB",
            template: "overview",
            route: "/substances",
            slots: [
            WidgetSlotDef(label: "Zuletzt", valueKey: "substances.lastIntake", goalKey: nil),
            WidgetSlotDef(label: "Heute", valueKey: "substances.takenToday", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "period",
            title: "Zyklus",
            groupLabel: "Zyklus",
            accentHex: "#FF8FAB",
            template: "overview",
            route: "/period",
            slots: [
            WidgetSlotDef(label: "Zyklustag", valueKey: "period.cycleDay", goalKey: nil),
            WidgetSlotDef(label: "Phase", valueKey: "period.phase", goalKey: nil),
            WidgetSlotDef(label: "Nächste", valueKey: "period.nextDays", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "notes",
            title: "Notizen",
            groupLabel: "Notizen",
            accentHex: "#9B8EC4",
            template: "overview",
            route: "/notes",
            slots: [
            WidgetSlotDef(label: "Notizen", valueKey: "notes.count", goalKey: nil),
            WidgetSlotDef(label: "Letzte", valueKey: "notes.lastNote", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "map",
            title: "Karte",
            groupLabel: "Karte",
            accentHex: "#3DD68C",
            template: "overview",
            route: "/graffitimap",
            slots: [
            WidgetSlotDef(label: "Orte", valueKey: "map.placesCount", goalKey: nil),
            WidgetSlotDef(label: "Foto", valueKey: "map.lastPhoto", goalKey: nil),
            ]
        ),
    ]
    static let functions: [WidgetCatalogDef] = [
        WidgetCatalogDef(
            key: "clockDate",
            title: "Uhr",
            groupLabel: "Allgemein",
            accentHex: "#FF6B3D",
            template: "stat",
            route: "/home",
            slots: [
            WidgetSlotDef(label: "Datum", valueKey: "general.clockDate", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "weatherNow",
            title: "Wetter",
            groupLabel: "Allgemein",
            accentHex: "#FF6B3D",
            template: "stat",
            route: "/home",
            slots: [
            WidgetSlotDef(label: "Temperatur", valueKey: "general.weatherTemp", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "weatherForecast",
            title: "Wetter",
            groupLabel: "Allgemein",
            accentHex: "#FF6B3D",
            template: "stat",
            route: "/home",
            slots: [
            WidgetSlotDef(label: "Vorhersage", valueKey: "general.weatherForecast", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "appFavorites",
            title: "Apps",
            groupLabel: "Allgemein",
            accentHex: "#FF6B3D",
            template: "list",
            route: "/home",
            slots: [
            WidgetSlotDef(label: "Favoriten", valueKey: "general.appFavorites", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "quickActions",
            title: "Schnellzugriff",
            groupLabel: "Allgemein",
            accentHex: "#FF6B3D",
            template: "list",
            route: "/home",
            slots: [
            WidgetSlotDef(label: "Aktionen", valueKey: "general.quickActions", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "dailyScore",
            title: "Tagesübersicht",
            groupLabel: "Allgemein",
            accentHex: "#FF6B3D",
            template: "stat",
            route: "/home",
            slots: [
            WidgetSlotDef(label: "Score", valueKey: "health.score", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "miniCalendar",
            title: "Kalender",
            groupLabel: "Allgemein",
            accentHex: "#FF6B3D",
            template: "list",
            route: "/home",
            slots: [
            WidgetSlotDef(label: "Termin", valueKey: "planning.nextAppointment", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "steps",
            title: "Schritte",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "progress",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Schritte", valueKey: "health.steps", goalKey: "health.stepsGoal"),
            ]
        ),
        WidgetCatalogDef(
            key: "sleep",
            title: "Schlaf",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Stunden", valueKey: "health.sleepHours", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "heartRate",
            title: "Herzfrequenz",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Puls", valueKey: "health.heartRate", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "moodToday",
            title: "Stimmung",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Stimmung", valueKey: "health.mood", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "weightTrend",
            title: "Gewicht",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Gewicht", valueKey: "health.weightKg", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "healthScore",
            title: "Score",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Score", valueKey: "health.score", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "healthSnapshot",
            title: "Gesundheit",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Score", valueKey: "health.score", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "activeMinutes",
            title: "Aktive Min.",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Minuten", valueKey: "health.activeMinutes", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "caloriesBurned",
            title: "Verbrannt",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "kcal", valueKey: "health.caloriesBurned", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "stepsWeekChart",
            title: "Schritte-Woche",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Ø Schritte", valueKey: "health.stepsWeekAvg", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "weightChart",
            title: "Gewichtsverlauf",
            groupLabel: "Gesundheit",
            accentHex: "#F43F5E",
            template: "stat",
            route: "/health",
            slots: [
            WidgetSlotDef(label: "Gewicht", valueKey: "health.weightKg", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "caloriesRing",
            title: "Kalorien",
            groupLabel: "Ernährung",
            accentHex: "#3DD68C",
            template: "progress",
            route: "/nutrition",
            slots: [
            WidgetSlotDef(label: "Kalorien", valueKey: "nutrition.kcal", goalKey: "nutrition.kcalGoal"),
            ]
        ),
        WidgetCatalogDef(
            key: "macros",
            title: "Makros",
            groupLabel: "Ernährung",
            accentHex: "#3DD68C",
            template: "dualStat",
            route: "/nutrition",
            slots: [
            WidgetSlotDef(label: "Protein", valueKey: "nutrition.protein", goalKey: nil),
            WidgetSlotDef(label: "Kohlenhydrate", valueKey: "nutrition.carbs", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "water",
            title: "Wasser",
            groupLabel: "Ernährung",
            accentHex: "#3DD68C",
            template: "progress",
            route: "/nutrition",
            slots: [
            WidgetSlotDef(label: "Wasser", valueKey: "nutrition.waterMl", goalKey: "nutrition.waterGoalMl"),
            ]
        ),
        WidgetCatalogDef(
            key: "lastMeal",
            title: "Letzte Mahlzeit",
            groupLabel: "Ernährung",
            accentHex: "#3DD68C",
            template: "stat",
            route: "/nutrition",
            slots: [
            WidgetSlotDef(label: "Mahlzeit", valueKey: "nutrition.lastMeal", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "remainingCalories",
            title: "Rest-kcal",
            groupLabel: "Ernährung",
            accentHex: "#3DD68C",
            template: "progress",
            route: "/nutrition",
            slots: [
            WidgetSlotDef(label: "Rest", valueKey: "nutrition.kcal", goalKey: "nutrition.kcalGoal"),
            ]
        ),
        WidgetCatalogDef(
            key: "supplementsToday",
            title: "Supplements",
            groupLabel: "Ernährung",
            accentHex: "#3DD68C",
            template: "stat",
            route: "/nutrition",
            slots: [
            WidgetSlotDef(label: "Supplements", valueKey: "nutrition.supplementsToday", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "mealsToday",
            title: "Mahlzeiten",
            groupLabel: "Ernährung",
            accentHex: "#3DD68C",
            template: "stat",
            route: "/nutrition",
            slots: [
            WidgetSlotDef(label: "Mahlzeiten", valueKey: "nutrition.mealsToday", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "nextWorkout",
            title: "Nächstes Workout",
            groupLabel: "Training",
            accentHex: "#5B6CF9",
            template: "stat",
            route: "/training",
            slots: [
            WidgetSlotDef(label: "Workout", valueKey: "training.nextWorkout", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "weeklyVolume",
            title: "Wochen-Volumen",
            groupLabel: "Training",
            accentHex: "#5B6CF9",
            template: "stat",
            route: "/training",
            slots: [
            WidgetSlotDef(label: "Sets", valueKey: "training.weeklyVolume", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "muscleHeatmap",
            title: "Muskeln",
            groupLabel: "Training",
            accentHex: "#5B6CF9",
            template: "stat",
            route: "/training",
            slots: [
            WidgetSlotDef(label: "Muskeln", valueKey: "training.muscleHeatmap", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "lastWorkout",
            title: "Letztes Workout",
            groupLabel: "Training",
            accentHex: "#5B6CF9",
            template: "stat",
            route: "/training",
            slots: [
            WidgetSlotDef(label: "Workout", valueKey: "training.lastWorkout", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "trainingStreak",
            title: "Trainings-Streak",
            groupLabel: "Training",
            accentHex: "#5B6CF9",
            template: "stat",
            route: "/training",
            slots: [
            WidgetSlotDef(label: "Wochen", valueKey: "training.streak", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "weeklyWorkouts",
            title: "Wochen-Workouts",
            groupLabel: "Training",
            accentHex: "#5B6CF9",
            template: "stat",
            route: "/training",
            slots: [
            WidgetSlotDef(label: "Workouts", valueKey: "training.weeklyWorkouts", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "personalRecords",
            title: "Rekorde",
            groupLabel: "Training",
            accentHex: "#5B6CF9",
            template: "stat",
            route: "/training",
            slots: [
            WidgetSlotDef(label: "Rekorde", valueKey: "training.personalRecords", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "restTimerQuick",
            title: "Rest-Timer",
            groupLabel: "Training",
            accentHex: "#5B6CF9",
            template: "stat",
            route: "/training",
            slots: [
            WidgetSlotDef(label: "Timer", valueKey: "training.restTimer", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "openTodos",
            title: "Offene Todos",
            groupLabel: "Planung",
            accentHex: "#F5A623",
            template: "stat",
            route: "/planning",
            slots: [
            WidgetSlotDef(label: "Offen", valueKey: "planning.openTodos", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "todayAppointments",
            title: "Heute",
            groupLabel: "Planung",
            accentHex: "#F5A623",
            template: "list",
            route: "/planning",
            slots: [
            WidgetSlotDef(label: "Termin", valueKey: "planning.nextAppointment", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "habitsToday",
            title: "Gewohnheiten",
            groupLabel: "Planung",
            accentHex: "#F5A623",
            template: "progress",
            route: "/planning",
            slots: [
            WidgetSlotDef(label: "Habits", valueKey: "planning.habitsDone", goalKey: "planning.habitsTotal"),
            ]
        ),
        WidgetCatalogDef(
            key: "medicationsToday",
            title: "Medikamente",
            groupLabel: "Planung",
            accentHex: "#F5A623",
            template: "progress",
            route: "/planning",
            slots: [
            WidgetSlotDef(label: "Medis", valueKey: "planning.medsDone", goalKey: "planning.medsTotal"),
            ]
        ),
        WidgetCatalogDef(
            key: "nextAppointmentCountdown",
            title: "Nächster Termin",
            groupLabel: "Planung",
            accentHex: "#F5A623",
            template: "stat",
            route: "/planning",
            slots: [
            WidgetSlotDef(label: "Termin", valueKey: "planning.nextAppointment", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "overdueTodos",
            title: "Überfällig",
            groupLabel: "Planung",
            accentHex: "#F5A623",
            template: "stat",
            route: "/planning",
            slots: [
            WidgetSlotDef(label: "Überfällig", valueKey: "planning.overdueTodos", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "bestHabitStreak",
            title: "Beste Serie",
            groupLabel: "Planung",
            accentHex: "#F5A623",
            template: "stat",
            route: "/planning",
            slots: [
            WidgetSlotDef(label: "Tage", valueKey: "planning.bestHabitStreak", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "balanceMonth",
            title: "Saldo",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "stat",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Saldo", valueKey: "budget.balanceMonth", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "incomeExpense",
            title: "Ein/Aus",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "dualStat",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Einnahmen", valueKey: "budget.income", goalKey: nil),
            WidgetSlotDef(label: "Ausgaben", valueKey: "budget.expense", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "budgetProgress",
            title: "Budget",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "progress",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Budget", valueKey: "budget.spent", goalKey: "budget.limit"),
            ]
        ),
        WidgetCatalogDef(
            key: "accountsOverview",
            title: "Konten",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "stat",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Konten", valueKey: "budget.accountsOverview", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "topCategory",
            title: "Top-Ausgabe",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "stat",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Kategorie", valueKey: "budget.topCategory", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "recentTransactions",
            title: "Letzte",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "stat",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Transaktion", valueKey: "budget.recentTransaction", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "savingsGoal",
            title: "Sparziel",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "stat",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Ziel", valueKey: "budget.savingsGoal", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "recurringDue",
            title: "Wiederkehrend",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "stat",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Fällig", valueKey: "budget.recurringDue", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "monthTrend",
            title: "Monats-Trend",
            groupLabel: "Budget",
            accentHex: "#00D4D4",
            template: "stat",
            route: "/budget",
            slots: [
            WidgetSlotDef(label: "Trend", valueKey: "budget.monthTrend", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "writeStreak",
            title: "Schreib-Streak",
            groupLabel: "Tagebuch",
            accentHex: "#9B8EC4",
            template: "stat",
            route: "/diary",
            slots: [
            WidgetSlotDef(label: "Tage", valueKey: "diary.writeStreak", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "lastEntry",
            title: "Letzter Eintrag",
            groupLabel: "Tagebuch",
            accentHex: "#9B8EC4",
            template: "stat",
            route: "/diary",
            slots: [
            WidgetSlotDef(label: "Eintrag", valueKey: "diary.lastEntry", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "yearHeatmap",
            title: "Jahres-Heatmap",
            groupLabel: "Tagebuch",
            accentHex: "#9B8EC4",
            template: "stat",
            route: "/diary",
            slots: [
            WidgetSlotDef(label: "Einträge", valueKey: "diary.yearHeatmap", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "moodCalendar",
            title: "Stimmungs-Kalender",
            groupLabel: "Tagebuch",
            accentHex: "#9B8EC4",
            template: "stat",
            route: "/diary",
            slots: [
            WidgetSlotDef(label: "Stimmung", valueKey: "diary.moodCalendar", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "entriesThisMonth",
            title: "Einträge/Monat",
            groupLabel: "Tagebuch",
            accentHex: "#9B8EC4",
            template: "stat",
            route: "/diary",
            slots: [
            WidgetSlotDef(label: "Einträge", valueKey: "diary.entriesThisMonth", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "currentStreak",
            title: "Aktueller Streak",
            groupLabel: "Abstinenz",
            accentHex: "#FFAA55",
            template: "stat",
            route: "/abstinence",
            slots: [
            WidgetSlotDef(label: "Dauer", valueKey: "abstinence.duration", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "longestStreak",
            title: "Längster Streak",
            groupLabel: "Abstinenz",
            accentHex: "#FFAA55",
            template: "stat",
            route: "/abstinence",
            slots: [
            WidgetSlotDef(label: "Tage", valueKey: "abstinence.longestStreak", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "moneySaved",
            title: "Gespart",
            groupLabel: "Abstinenz",
            accentHex: "#FFAA55",
            template: "stat",
            route: "/abstinence",
            slots: [
            WidgetSlotDef(label: "Gespart", valueKey: "abstinence.moneySaved", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "allCounters",
            title: "Alle Counter",
            groupLabel: "Abstinenz",
            accentHex: "#FFAA55",
            template: "stat",
            route: "/abstinence",
            slots: [
            WidgetSlotDef(label: "Counter", valueKey: "abstinence.allCounters", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "lastIntake",
            title: "Letzte Einnahme",
            groupLabel: "Mittel",
            accentHex: "#0099BB",
            template: "stat",
            route: "/substances",
            slots: [
            WidgetSlotDef(label: "Zuletzt", valueKey: "substances.lastIntake", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "takenToday",
            title: "Heute",
            groupLabel: "Mittel",
            accentHex: "#0099BB",
            template: "stat",
            route: "/substances",
            slots: [
            WidgetSlotDef(label: "Heute", valueKey: "substances.takenToday", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "cycleDay",
            title: "Zyklustag",
            groupLabel: "Zyklus",
            accentHex: "#FF8FAB",
            template: "stat",
            route: "/period",
            slots: [
            WidgetSlotDef(label: "Tag", valueKey: "period.cycleDay", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "nextPeriod",
            title: "Nächste Periode",
            groupLabel: "Zyklus",
            accentHex: "#FF8FAB",
            template: "stat",
            route: "/period",
            slots: [
            WidgetSlotDef(label: "Tage", valueKey: "period.nextDays", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "notesCount",
            title: "Notizen",
            groupLabel: "Notizen",
            accentHex: "#9B8EC4",
            template: "stat",
            route: "/notes",
            slots: [
            WidgetSlotDef(label: "Notizen", valueKey: "notes.count", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "lastNote",
            title: "Letzte Notiz",
            groupLabel: "Notizen",
            accentHex: "#9B8EC4",
            template: "stat",
            route: "/notes",
            slots: [
            WidgetSlotDef(label: "Notiz", valueKey: "notes.lastNote", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "pinnedNote",
            title: "Angepinnt",
            groupLabel: "Notizen",
            accentHex: "#9B8EC4",
            template: "stat",
            route: "/notes",
            slots: [
            WidgetSlotDef(label: "Notiz", valueKey: "notes.pinnedNote", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "placesCount",
            title: "Orte",
            groupLabel: "Karte",
            accentHex: "#3DD68C",
            template: "stat",
            route: "/graffitimap",
            slots: [
            WidgetSlotDef(label: "Orte", valueKey: "map.placesCount", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "lastPhoto",
            title: "Letztes Foto",
            groupLabel: "Karte",
            accentHex: "#3DD68C",
            template: "stat",
            route: "/graffitimap",
            slots: [
            WidgetSlotDef(label: "Foto", valueKey: "map.lastPhoto", goalKey: nil),
            ]
        ),
        WidgetCatalogDef(
            key: "mapPreview",
            title: "Karte",
            groupLabel: "Karte",
            accentHex: "#3DD68C",
            template: "stat",
            route: "/graffitimap",
            slots: [
            WidgetSlotDef(label: "Orte", valueKey: "map.mapPreview", goalKey: nil),
            ]
        ),
    ]
    static func byKey(_ k: String) -> WidgetCatalogDef? {
        (tabs + functions).first { $0.key == k }
    }
}

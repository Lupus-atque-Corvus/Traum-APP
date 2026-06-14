import WidgetKit
import SwiftUI

// MARK: - Color helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

private let traumBackground = Color(hex: "1A1A2E")
private let traumAccent = Color(hex: "FF6B3D")
private let traumText = Color.white
private let traumMuted = Color(hex: "8888AA")
private let traumBlue = Color(hex: "64B5F6")
private let traumGreen = Color(hex: "66BB6A")
private let traumRed = Color(hex: "EF5350")
private let traumYellow = Color(hex: "FFCC80")

// MARK: - Shared Entry

struct TraumEntry: TimelineEntry {
    let date: Date
    let values: [String: String]   // namespaced key -> string value
    func v(_ key: String) -> String {
        let s = values[key] ?? ""
        return s.isEmpty ? "—" : s
    }
}

// MARK: - Timeline Provider

struct TraumTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TraumEntry {
        TraumEntry(date: Date(), values: [:])
    }
    func getSnapshot(in context: Context, completion: @escaping (TraumEntry) -> Void) {
        completion(makeEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TraumEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    private func makeEntry() -> TraumEntry {
        let d = UserDefaults(suiteName: "group.de.traum.widgets")
        let keys = [
            "health.steps", "health.stepsGoal", "health.sleepHours", "health.heartRate", "health.mood",
            "health.score", "health.weightKg", "health.activeMinutes",
            "nutrition.kcal", "nutrition.kcalGoal", "nutrition.waterMl", "nutrition.waterGoalMl",
            "nutrition.protein", "nutrition.proteinGoal", "nutrition.carbs", "nutrition.fat", "nutrition.lastMeal",
            "training.nextWorkout", "training.weeklyVolume", "training.streak",
            "planning.nextTodo", "planning.openTodos", "planning.nextAppointment",
            "planning.habitsDone", "planning.habitsTotal", "planning.medsDone", "planning.medsTotal",
            "budget.balanceMonth", "budget.income", "budget.expense", "budget.spent", "budget.limit", "budget.topCategory",
            "diary.writeStreak", "diary.lastEntry", "diary.entriesThisMonth",
            "abstinence.title", "abstinence.duration", "abstinence.moneySaved",
            "substances.lastIntake", "substances.takenToday",
            "period.cycleDay", "period.phase", "period.nextDays",
            "notes.count", "notes.lastNote", "map.placesCount", "map.lastPhoto",
        ]
        var values: [String: String] = [:]
        for k in keys { if let s = d?.string(forKey: k) { values[k] = s } }
        return TraumEntry(date: Date(), values: values)
    }
}

// MARK: - Generic slot model + overview view

struct OverviewSlot {
    let label: String
    let key: String
    let suffix: String
    init(_ label: String, _ key: String, _ suffix: String = "") {
        self.label = label; self.key = key; self.suffix = suffix
    }
}

struct OverviewWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: TraumEntry
    let title: String
    let accentHex: String
    let slots: [OverviewSlot]

    private func text(_ s: OverviewSlot) -> String { entry.v(s.key) + s.suffix }

    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: accentHex)).textCase(.uppercase)
                if let p = slots.first {
                    Text(text(p)).font(.system(size: 22, weight: .bold)).foregroundColor(traumText)
                    Text(p.label).font(.caption2).foregroundColor(traumMuted)
                }
                if family != .systemSmall, slots.count > 1 {
                    HStack {
                        ForEach(Array(slots.dropFirst().prefix(2).enumerated()), id: \.offset) { _, s in
                            VStack(alignment: .leading, spacing: 1) {
                                Text(text(s)).font(.system(size: 13, weight: .bold)).foregroundColor(traumText)
                                Text(s.label).font(.caption2).foregroundColor(traumMuted)
                            }
                            Spacer()
                        }
                    }.padding(.top, 6)
                }
                if family == .systemLarge, slots.count > 3 {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(text(slots[3])).font(.system(size: 13, weight: .bold)).foregroundColor(traumText)
                        Text(slots[3].label).font(.caption2).foregroundColor(traumMuted)
                    }.padding(.top, 6)
                }
                Spacer(minLength: 0)
            }.padding(12)
        }
    }
}

// MARK: - Generic template views (stat / progress / dualStat / list)

struct StatWidgetView: View {
    let entry: TraumEntry; let title: String; let accentHex: String
    let valueKey: String; let label: String; let suffix: String
    var body: some View {
        ZStack { traumBackground.ignoresSafeArea()
            VStack(spacing: 4) {
                Text(title).font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: accentHex)).textCase(.uppercase)
                Text(entry.v(valueKey) + suffix).font(.system(size: 28, weight: .bold)).foregroundColor(traumText)
                Text(label).font(.caption2).foregroundColor(traumMuted)
            }.padding(12)
        }
    }
}

struct ProgressWidgetView: View {
    let entry: TraumEntry; let title: String; let accentHex: String
    let valueKey: String; let goalKey: String; let label: String
    var ratio: Double {
        let v = Double(entry.v(valueKey)) ?? 0, g = Double(entry.v(goalKey)) ?? 0
        return g > 0 ? min(v / g, 1.0) : 0
    }
    var body: some View {
        ZStack { traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: accentHex)).textCase(.uppercase)
                Text(entry.v(valueKey)).font(.system(size: 22, weight: .bold)).foregroundColor(traumText)
                Text(label).font(.caption2).foregroundColor(traumMuted)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color(hex: "333355")).frame(height: 8)
                        RoundedRectangle(cornerRadius: 4).fill(Color(hex: accentHex))
                            .frame(width: geo.size.width * ratio, height: 8)
                    }
                }.frame(height: 8)
            }.padding(12)
        }
    }
}

struct DualStatWidgetView: View {
    let entry: TraumEntry; let title: String; let accentHex: String
    let aKey: String; let aLabel: String; let bKey: String; let bLabel: String
    var body: some View {
        ZStack { traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: accentHex)).textCase(.uppercase)
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.v(aKey)).font(.system(size: 18, weight: .bold)).foregroundColor(traumText)
                        Text(aLabel).font(.caption2).foregroundColor(traumMuted)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(entry.v(bKey)).font(.system(size: 18, weight: .bold)).foregroundColor(traumText)
                        Text(bLabel).font(.caption2).foregroundColor(traumMuted)
                    }
                }.padding(.top, 6)
            }.padding(12)
        }
    }
}

struct ListWidgetView: View {
    let entry: TraumEntry; let title: String; let accentHex: String; let rowKeys: [String]
    var body: some View {
        ZStack { traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: accentHex)).textCase(.uppercase)
                ForEach(Array(rowKeys.prefix(3).enumerated()), id: \.offset) { _, k in
                    Text(entry.v(k)).font(.caption).foregroundColor(traumText).lineLimit(1)
                }
                Spacer(minLength: 0)
            }.padding(12)
        }
    }
}

// MARK: - 1. Overview Widget

struct TraumOverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumOverviewWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Übersicht", accentHex: "#FF6B3D", slots: [
                OverviewSlot("Schritte", "health.steps"),
                OverviewSlot("Kalorien", "nutrition.kcal", " kcal"),
                OverviewSlot("Wasser", "nutrition.waterMl", " ml"),
                OverviewSlot("Aufgabe", "planning.nextTodo"),
            ])
        }
        .configurationDisplayName("TRAUM Übersicht")
        .description("Schritte, Kalorien und Wasser auf einen Blick")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 2. Health Widget

struct TraumHealthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumHealthWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Gesundheit", accentHex: "#F43F5E", slots: [
                OverviewSlot("Score", "health.score"),
                OverviewSlot("Schlaf", "health.sleepHours", " h"),
                OverviewSlot("Puls", "health.heartRate", " bpm"),
                OverviewSlot("Aktiv", "health.activeMinutes", " min"),
            ])
        }
        .configurationDisplayName("TRAUM Gesundheit")
        .description("Gesundheit auf einen Blick")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 3. Nutrition Widget

struct TraumNutritionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumNutritionWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Ernährung", accentHex: "#3DD68C", slots: [
                OverviewSlot("Kalorien", "nutrition.kcal", " kcal"),
                OverviewSlot("Protein", "nutrition.protein", " g"),
                OverviewSlot("Wasser", "nutrition.waterMl", " ml"),
                OverviewSlot("Mahlzeit", "nutrition.lastMeal"),
            ])
        }
        .configurationDisplayName("TRAUM Ernährung")
        .description("Kalorien, Protein und Wasser im Überblick")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 4. Training Widget

struct TraumTrainingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumTrainingWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Training", accentHex: "#5B6CF9", slots: [
                OverviewSlot("Nächstes", "training.nextWorkout"),
                OverviewSlot("Volumen", "training.weeklyVolume"),
                OverviewSlot("Streak", "training.streak"),
            ])
        }
        .configurationDisplayName("TRAUM Training")
        .description("Nächstes Workout, Wochenvolumen und Streak")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 5. Planning Widget

struct TraumPlanningWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumPlanningWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Planung", accentHex: "#F5A623", slots: [
                OverviewSlot("Offen", "planning.openTodos"),
                OverviewSlot("Termin", "planning.nextAppointment"),
                OverviewSlot("Habits", "planning.habitsDone"),
                OverviewSlot("Medis", "planning.medsDone"),
            ])
        }
        .configurationDisplayName("TRAUM Planung")
        .description("Offene Aufgaben, Termine und Habits")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 6. Budget Widget

struct TraumBudgetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumBudgetWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Budget", accentHex: "#00D4D4", slots: [
                OverviewSlot("Saldo", "budget.balanceMonth", " €"),
                OverviewSlot("Ausgaben", "budget.spent", " €"),
                OverviewSlot("Einnahmen", "budget.income", " €"),
                OverviewSlot("Top", "budget.topCategory"),
            ])
        }
        .configurationDisplayName("TRAUM Budget")
        .description("Monatssaldo, Ausgaben und Einnahmen")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 7. Diary Widget

struct TraumDiaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumDiaryWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Tagebuch", accentHex: "#9B8EC4", slots: [
                OverviewSlot("Streak", "diary.writeStreak"),
                OverviewSlot("Letzter", "diary.lastEntry"),
                OverviewSlot("Monat", "diary.entriesThisMonth"),
            ])
        }
        .configurationDisplayName("TRAUM Tagebuch")
        .description("Schreibstreak und Einträge diesen Monat")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 8. Abstinence Widget

struct TraumAbstinenceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumAbstinenceWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Abstinenz", accentHex: "#FFAA55", slots: [
                OverviewSlot("Titel", "abstinence.title"),
                OverviewSlot("Dauer", "abstinence.duration"),
                OverviewSlot("Gespart", "abstinence.moneySaved", " €"),
            ])
        }
        .configurationDisplayName("TRAUM Abstinenz")
        .description("Abstinenz-Titel, Dauer und gesparte Kosten")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 9. Substances Widget

struct TraumSubstancesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumSubstancesWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Mittel", accentHex: "#0099BB", slots: [
                OverviewSlot("Zuletzt", "substances.lastIntake"),
                OverviewSlot("Heute", "substances.takenToday"),
            ])
        }
        .configurationDisplayName("TRAUM Mittel")
        .description("Letzte Einnahme und heutige Mittel")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 10. Period Widget

struct TraumPeriodWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumPeriodWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Zyklus", accentHex: "#FF8FAB", slots: [
                OverviewSlot("Zyklustag", "period.cycleDay"),
                OverviewSlot("Phase", "period.phase"),
                OverviewSlot("Nächste", "period.nextDays", " T"),
            ])
        }
        .configurationDisplayName("TRAUM Zyklus")
        .description("Zyklustag, Phase und Tage bis zur nächsten Periode")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 11. Notes Widget

struct TraumNotesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumNotesWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Notizen", accentHex: "#9B8EC4", slots: [
                OverviewSlot("Notizen", "notes.count"),
                OverviewSlot("Letzte", "notes.lastNote"),
            ])
        }
        .configurationDisplayName("TRAUM Notizen")
        .description("Anzahl Notizen und letzte Notiz")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 12. Map Widget

struct TraumMapWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumMapWidget", provider: TraumTimelineProvider()) { e in
            OverviewWidgetView(entry: e, title: "Karte", accentHex: "#3DD68C", slots: [
                OverviewSlot("Orte", "map.placesCount"),
                OverviewSlot("Foto", "map.lastPhoto"),
            ])
        }
        .configurationDisplayName("TRAUM Karte")
        .description("Gespeicherte Orte und letztes Foto")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct TraumWidgetBundle: WidgetBundle {
    var body: some Widget {
        TraumOverviewWidget(); TraumHealthWidget(); TraumNutritionWidget()
        TraumTrainingWidget(); TraumPlanningWidget(); TraumBudgetWidget()
        TraumDiaryWidget(); TraumAbstinenceWidget(); TraumSubstancesWidget()
        TraumPeriodWidget(); TraumNotesWidget(); TraumMapWidget()
    }
}

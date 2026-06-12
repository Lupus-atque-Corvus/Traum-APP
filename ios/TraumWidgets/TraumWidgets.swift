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
    let steps: String
    let stepsGoal: String
    let calories: String
    let caloriesGoal: String
    let kcal: String
    let kcalGoal: String
    let waterMl: String
    let waterGoalMl: String
    let protein: String
    let proteinGoal: String
    let sleepHours: String
    let nextTodo: String
    let abstinenceTitle: String
    let abstinenceDuration: String
    let periodDaysLabel: String
    let budgetSpent: String
    let budgetLimit: String
    let habitsCompleted: String
    let habitsTotal: String
    let medsTaken: String
    let medsTotal: String
    let nextAppointment: String
    let heartRate: String
    let mood: String
}

// MARK: - Timeline Provider

struct TraumTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TraumEntry {
        TraumEntry(
            date: Date(),
            steps: "—", stepsGoal: "10000",
            calories: "—", caloriesGoal: "2000",
            kcal: "—", kcalGoal: "2000",
            waterMl: "—", waterGoalMl: "2000",
            protein: "—", proteinGoal: "150",
            sleepHours: "—",
            nextTodo: "—",
            abstinenceTitle: "—", abstinenceDuration: "—",
            periodDaysLabel: "—",
            budgetSpent: "—", budgetLimit: "—",
            habitsCompleted: "—", habitsTotal: "—",
            medsTaken: "—", medsTotal: "—",
            nextAppointment: "—",
            heartRate: "—",
            mood: "—"
        )
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
        return TraumEntry(
            date: Date(),
            steps: d?.string(forKey: "health.steps") ?? "—",
            stepsGoal: d?.string(forKey: "stepsGoal") ?? "10000",
            calories: d?.string(forKey: "calories") ?? "—",
            caloriesGoal: d?.string(forKey: "caloriesGoal") ?? "2000",
            kcal: d?.string(forKey: "nutrition.kcal") ?? "—",
            kcalGoal: d?.string(forKey: "kcalGoal") ?? "2000",
            waterMl: d?.string(forKey: "nutrition.waterMl") ?? "—",
            waterGoalMl: d?.string(forKey: "waterGoalMl") ?? "2000",
            protein: d?.string(forKey: "protein") ?? "—",
            proteinGoal: d?.string(forKey: "proteinGoal") ?? "150",
            sleepHours: d?.string(forKey: "sleepHours") ?? "—",
            nextTodo: d?.string(forKey: "planning.nextTodo") ?? "—",
            abstinenceTitle: d?.string(forKey: "abstinenceTitle") ?? "—",
            abstinenceDuration: d?.string(forKey: "abstinenceDuration") ?? "—",
            periodDaysLabel: d?.string(forKey: "periodDaysLabel") ?? "—",
            budgetSpent: d?.string(forKey: "budgetSpent") ?? "—",
            budgetLimit: d?.string(forKey: "budgetLimit") ?? "—",
            habitsCompleted: d?.string(forKey: "habitsCompleted") ?? "—",
            habitsTotal: d?.string(forKey: "habitsTotal") ?? "—",
            medsTaken: d?.string(forKey: "medsTaken") ?? "—",
            medsTotal: d?.string(forKey: "medsTotal") ?? "—",
            nextAppointment: d?.string(forKey: "nextAppointment") ?? "—",
            heartRate: d?.string(forKey: "heartRate") ?? "—",
            mood: d?.string(forKey: "mood") ?? "—"
        )
    }
}

// MARK: - Shared header view

private struct WidgetHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(traumAccent)
            .textCase(.uppercase)
    }
}

// MARK: - 1. Overview Widget

struct TraumOverviewWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TraumEntry
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: "Übersicht")
                Text(entry.steps).font(.system(size: 22, weight: .bold)).foregroundColor(traumText)
                Text("Schritte").font(.caption2).foregroundColor(traumMuted)
                if family != .systemSmall {
                    HStack {
                        Text("\(entry.kcal) kcal").font(.caption).foregroundColor(traumText)
                        Spacer()
                        Text("\(entry.waterMl) ml").font(.caption).foregroundColor(traumBlue)
                    }.padding(.top, 6)
                }
                if family == .systemLarge {
                    Text(entry.nextTodo).font(.caption).foregroundColor(traumMuted)
                        .lineLimit(2).padding(.top, 6)
                }
                Spacer(minLength: 0)
            }.padding(12)
        }
    }
}

struct TraumOverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumOverviewWidget", provider: TraumTimelineProvider()) {
            TraumOverviewWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Übersicht")
        .description("Schritte, Kalorien und Wasser im Überblick")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 2. Todo Widget

struct TraumTodoWidgetEntryView: View {
    let entry: TraumEntry
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: "Aufgaben")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nächste Aufgabe")
                        .font(.caption2)
                        .foregroundColor(traumMuted)
                    Text(entry.nextTodo)
                        .font(.caption)
                        .foregroundColor(traumText)
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nächster Termin")
                        .font(.caption2)
                        .foregroundColor(traumMuted)
                    Text(entry.nextAppointment)
                        .font(.caption)
                        .foregroundColor(traumText)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
        }
    }
}

struct TraumTodoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumTodoWidget", provider: TraumTimelineProvider()) {
            TraumTodoWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Aufgaben")
        .description("Nächste Aufgabe und Termin")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 3. Steps Widget

struct TraumStepsWidgetEntryView: View {
    let entry: TraumEntry
    var progressValue: Double {
        let s = Double(entry.steps) ?? 0
        let g = Double(entry.stepsGoal) ?? 10000
        guard g > 0 else { return 0 }
        return min(s / g, 1.0)
    }
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: "Schritte")
                Text(entry.steps)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(traumText)
                Text("Ziel: \(entry.stepsGoal)")
                    .font(.caption2)
                    .foregroundColor(traumMuted)
                Spacer(minLength: 4)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "333355"))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(traumAccent)
                            .frame(width: geo.size.width * progressValue, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(12)
        }
    }
}

struct TraumStepsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumStepsWidget", provider: TraumTimelineProvider()) {
            TraumStepsWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Schritte")
        .description("Schritte und Fortschritt zum Tagesziel")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 4. Abstinence Widget

struct TraumAbstinenceWidgetEntryView: View {
    let entry: TraumEntry
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .center, spacing: 6) {
                WidgetHeader(title: "Abstinenz")
                Text(entry.abstinenceTitle)
                    .font(.caption)
                    .foregroundColor(traumMuted)
                    .lineLimit(1)
                Text(entry.abstinenceDuration)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(traumText)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
        }
    }
}

struct TraumAbstinenceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumAbstinenceWidget", provider: TraumTimelineProvider()) {
            TraumAbstinenceWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Abstinenz")
        .description("Abstinenz-Titel und -Dauer")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 5. Period Widget

struct TraumPeriodWidgetEntryView: View {
    let entry: TraumEntry
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .center, spacing: 6) {
                WidgetHeader(title: "Zyklus")
                Text("Zyklusphase")
                    .font(.caption2)
                    .foregroundColor(traumMuted)
                Text(entry.periodDaysLabel)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(traumText)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
        }
    }
}

struct TraumPeriodWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumPeriodWidget", provider: TraumTimelineProvider()) {
            TraumPeriodWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Zyklus")
        .description("Aktuelle Zyklusphase")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 6. Health Widget

struct TraumHealthWidgetEntryView: View {
    let entry: TraumEntry
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: "Gesundheit")
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.sleepHours) h")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(traumText)
                        Text("Schlaf")
                            .font(.caption2)
                            .foregroundColor(traumMuted)
                    }
                    Spacer()
                    VStack(alignment: .center, spacing: 2) {
                        Text(entry.heartRate)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(traumRed)
                        Text("bpm")
                            .font(.caption2)
                            .foregroundColor(traumMuted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.mood)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(traumYellow)
                        Text("Stimmung")
                            .font(.caption2)
                            .foregroundColor(traumMuted)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
        }
    }
}

struct TraumHealthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumHealthWidget", provider: TraumTimelineProvider()) {
            TraumHealthWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Gesundheit")
        .description("Schlaf, Herzrate und Stimmung")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 7. Calendar Widget

struct TraumCalendarWidgetEntryView: View {
    let entry: TraumEntry
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: "Kalender")
                Text("Nächster Termin")
                    .font(.caption2)
                    .foregroundColor(traumMuted)
                Text(entry.nextAppointment)
                    .font(.caption)
                    .foregroundColor(traumText)
                    .lineLimit(4)
                Spacer(minLength: 0)
            }
            .padding(12)
        }
    }
}

struct TraumCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumCalendarWidget", provider: TraumTimelineProvider()) {
            TraumCalendarWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Kalender")
        .description("Nächster Termin auf einen Blick")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 8. Budget Widget

struct TraumBudgetWidgetEntryView: View {
    let entry: TraumEntry
    var progressValue: Double {
        let s = Double(entry.budgetSpent) ?? 0
        let l = Double(entry.budgetLimit) ?? 1
        guard l > 0 else { return 0 }
        return min(s / l, 1.0)
    }
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: "Budget")
                Text("\(entry.budgetSpent) €")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(traumText)
                Text("von \(entry.budgetLimit) €")
                    .font(.caption2)
                    .foregroundColor(traumMuted)
                Spacer(minLength: 4)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "333355"))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(traumAccent)
                            .frame(width: geo.size.width * progressValue, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(12)
        }
    }
}

struct TraumBudgetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumBudgetWidget", provider: TraumTimelineProvider()) {
            TraumBudgetWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Budget")
        .description("Ausgaben und Budgetlimit")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 9. Nutrition Widget

struct TraumNutritionWidgetEntryView: View {
    let entry: TraumEntry
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: "Ernährung")
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.kcal) / \(entry.kcalGoal)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(traumText)
                        Text("Kalorien")
                            .font(.caption2)
                            .foregroundColor(traumMuted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(entry.protein) g")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(traumText)
                        Text("Protein")
                            .font(.caption2)
                            .foregroundColor(traumMuted)
                        Text("\(entry.waterMl) ml")
                            .font(.caption2)
                            .foregroundColor(traumBlue)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
        }
    }
}

struct TraumNutritionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumNutritionWidget", provider: TraumTimelineProvider()) {
            TraumNutritionWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Ernährung")
        .description("Kalorien, Protein und Wasser")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 10. Habits Widget

struct TraumHabitsWidgetEntryView: View {
    let entry: TraumEntry
    var progressValue: Double {
        let c = Double(entry.habitsCompleted) ?? 0
        let t = Double(entry.habitsTotal) ?? 1
        guard t > 0 else { return 0 }
        return min(c / t, 1.0)
    }
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: "Gewohnheiten")
                Text("\(entry.habitsCompleted) / \(entry.habitsTotal)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(traumText)
                Text("Gewohnheiten heute")
                    .font(.caption2)
                    .foregroundColor(traumMuted)
                Spacer(minLength: 4)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "333355"))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(traumGreen)
                            .frame(width: geo.size.width * progressValue, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(12)
        }
    }
}

struct TraumHabitsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumHabitsWidget", provider: TraumTimelineProvider()) {
            TraumHabitsWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Gewohnheiten")
        .description("Abgeschlossene Gewohnheiten und Fortschritt")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 11. Medication Widget

struct TraumMedicationWidgetEntryView: View {
    let entry: TraumEntry
    var progressValue: Double {
        let t = Double(entry.medsTaken) ?? 0
        let total = Double(entry.medsTotal) ?? 1
        guard total > 0 else { return 0 }
        return min(t / total, 1.0)
    }
    var body: some View {
        ZStack {
            traumBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: "Medikamente")
                Text("\(entry.medsTaken) / \(entry.medsTotal)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(traumText)
                Text("Medikamente heute")
                    .font(.caption2)
                    .foregroundColor(traumMuted)
                Spacer(minLength: 4)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "333355"))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(traumBlue)
                            .frame(width: geo.size.width * progressValue, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(12)
        }
    }
}

struct TraumMedicationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TraumMedicationWidget", provider: TraumTimelineProvider()) {
            TraumMedicationWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("TRAUM Medikamente")
        .description("Eingenommene Medikamente und Fortschritt")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct TraumWidgetBundle: WidgetBundle {
    var body: some Widget {
        TraumOverviewWidget()
        TraumTodoWidget()
        TraumStepsWidget()
        TraumAbstinenceWidget()
        TraumPeriodWidget()
        TraumHealthWidget()
        TraumCalendarWidget()
        TraumBudgetWidget()
        TraumNutritionWidget()
        TraumHabitsWidget()
        TraumMedicationWidget()
    }
}

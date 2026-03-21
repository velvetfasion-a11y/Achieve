import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    @Published private(set) var notes: [Note] = []
    @Published private(set) var photos: [JournalPhoto] = []
    @Published private(set) var coachMessages: [ChatMessage] = []
    @Published private(set) var completionHistory: [String: Double] = [:]

    @Published var accentHex: String = "#3F2A6B" {
        didSet { save(accentHex, key: Keys.accentHex) }
    }

    @Published var settings: AppSettings = .init() {
        didSet { save(settings, key: Keys.settings) }
    }

    let suggestedHabits = [
        "Wake up at 6 AM",
        "Exercise 30 min",
        "Meditate 10 min",
        "Pray",
        "Song production",
        "Read 20 pages"
    ]

    let leaderboard: [LeaderboardEntry] = [
        .init(alias: "EmpireNomad", score: 98),
        .init(alias: "FocusPhoenix", score: 94),
        .init(alias: "SoulBuilder", score: 91),
        .init(alias: "RitualWave", score: 88),
        .init(alias: "CalmForge", score: 85)
    ]

    var accentColor: Color {
        Color(hex: accentHex)
    }

    var todayFrequency: Double {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter(\.isCompleted).count
        return Double(completed) / Double(habits.count)
    }

    var lifetimeFrequencyScore: Int {
        let values = completionHistory.values
        guard !values.isEmpty else {
            return Int((todayFrequency * 100).rounded())
        }
        let average = values.reduce(0, +) / Double(values.count)
        return Int((average * 100).rounded())
    }

    var streakCount: Int {
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        while true {
            let key = Self.dayFormatter.string(from: currentDate)
            let completion = completionHistory[key] ?? 0
            if completion >= settings.streakThreshold {
                streak += 1
            } else {
                break
            }
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previous
        }

        return streak
    }

    init(previewData: Bool = false) {
        if previewData {
            seedPreview()
        } else {
            loadFromDisk()
            ensureCoachGreeting()
            recordTodayProgress()
        }
    }

    static var preview: AppStore {
        AppStore(previewData: true)
    }

    func addHabit(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        habits.append(Habit(title: trimmed))
        persistHabits()
        recordTodayProgress()
    }

    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isCompleted.toggle()
        persistHabits()
        recordTodayProgress()
    }

    func removeHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        persistHabits()
        recordTodayProgress()
    }

    func addNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.insert(Note(text: trimmed), at: 0)
        save(notes, key: Keys.notes)
    }

    func generatedAffirmation() -> String {
        let seed = notes.first?.text ?? "I choose one sincere step today."
        return "I recalibrate with purpose. \(seed)"
    }

    func messages(for mode: CoachMode) -> [ChatMessage] {
        coachMessages.filter { $0.mode == mode }
    }

    func sendCoachMessage(_ text: String, mode: CoachMode) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        coachMessages.append(.init(role: .user, mode: mode, text: trimmed))
        save(coachMessages, key: Keys.coachMessages)

        try? await Task.sleep(nanoseconds: 650_000_000)
        let reply = generateCoachReply(for: trimmed, mode: mode)
        coachMessages.append(.init(role: .assistant, mode: mode, text: reply))
        save(coachMessages, key: Keys.coachMessages)
    }

    func addPhoto(data: Data) throws {
        let fileName = "journal-\(UUID().uuidString).jpg"
        let url = Self.documentsDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: [.atomic])
        photos.insert(JournalPhoto(fileName: fileName), at: 0)
        save(photos, key: Keys.photos)
    }

    func image(for photo: JournalPhoto) -> UIImage? {
        UIImage(contentsOfFile: photoURL(for: photo).path)
    }

    func photoURL(for photo: JournalPhoto) -> URL {
        Self.documentsDirectory.appendingPathComponent(photo.fileName)
    }

    func exportData() throws -> Data {
        let payload = ExportPayload(
            exportedAt: Date(),
            accentHex: accentHex,
            habits: habits,
            notes: notes,
            photos: photos,
            coachMessages: coachMessages,
            completionHistory: completionHistory,
            settings: settings
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    func resetAllData() {
        habits = []
        notes = []
        photos.forEach { try? FileManager.default.removeItem(at: photoURL(for: $0)) }
        photos = []
        coachMessages = []
        completionHistory = [:]
        accentHex = "#3F2A6B"
        settings = .init()

        UserDefaults.standard.removeObject(forKey: Keys.habits)
        UserDefaults.standard.removeObject(forKey: Keys.notes)
        UserDefaults.standard.removeObject(forKey: Keys.photos)
        UserDefaults.standard.removeObject(forKey: Keys.coachMessages)
        UserDefaults.standard.removeObject(forKey: Keys.completionHistory)
        UserDefaults.standard.removeObject(forKey: Keys.accentHex)
        UserDefaults.standard.removeObject(forKey: Keys.settings)

        ensureCoachGreeting()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        if let savedHabits: [Habit] = load(key: Keys.habits, as: [Habit].self) {
            habits = savedHabits
        }
        if let savedNotes: [Note] = load(key: Keys.notes, as: [Note].self) {
            notes = savedNotes
        }
        if let savedPhotos: [JournalPhoto] = load(key: Keys.photos, as: [JournalPhoto].self) {
            photos = savedPhotos
        }
        if let savedMessages: [ChatMessage] = load(key: Keys.coachMessages, as: [ChatMessage].self) {
            coachMessages = savedMessages
        }
        if let savedHistory: [String: Double] = load(key: Keys.completionHistory, as: [String: Double].self) {
            completionHistory = savedHistory
        }
        if let savedAccent: String = load(key: Keys.accentHex, as: String.self) {
            accentHex = savedAccent
        }
        if let savedSettings: AppSettings = load(key: Keys.settings, as: AppSettings.self) {
            settings = savedSettings
        }
    }

    private func persistHabits() {
        save(habits, key: Keys.habits)
    }

    private func recordTodayProgress() {
        let key = Self.dayFormatter.string(from: Date())
        completionHistory[key] = todayFrequency
        save(completionHistory, key: Keys.completionHistory)
    }

    private func ensureCoachGreeting() {
        for mode in CoachMode.allCases where messages(for: mode).isEmpty {
            coachMessages.append(
                .init(
                    role: .assistant,
                    mode: mode,
                    text: greeting(for: mode)
                )
            )
        }
        save(coachMessages, key: Keys.coachMessages)
    }

    private func greeting(for mode: CoachMode) -> String {
        switch mode {
        case .motivation:
            return "You do not need a 100% day. You need a sincere day."
        case .routines:
            return "Start small. One aligned routine is stronger than ten forced tasks."
        case .energy:
            return "If your energy drops, pause and reconnect to your Why."
        }
    }

    private func generateCoachReply(for input: String, mode: CoachMode) -> String {
        let source: [String]
        switch mode {
        case .motivation:
            source = [
                "This is not doing nothing; it is recalibrating your instrument.",
                "Forgive your failed checklist. You are already enough to start again.",
                "One sincere hour in purpose beats eight resentful hours."
            ]
        case .routines:
            source = [
                "Pick one anchor habit for tomorrow and protect it like a meeting.",
                "Stack your habit after an existing ritual to reduce friction.",
                "Done with peace is better than perfect with burnout."
            ]
        case .energy:
            source = [
                "Sit in silence for five minutes and ask: who am I without the noise?",
                "Energy follows meaning. Reconnect your task to your Why.",
                "Breathe, release pressure, and continue with one intentional step."
            ]
        }

        if input.lowercased().contains("why") {
            return "A surgeon can finish a 14-hour shift exhausted yet peaceful because purpose was clear. If you feel low, revisit your Why and simplify your next step."
        }
        return source.randomElement() ?? "One sincere step at a time."
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed saving key \(key): \(error.localizedDescription)")
        }
    }

    private func load<T: Decodable>(key: String, as type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func seedPreview() {
        habits = [
            Habit(title: "Meditate 10 min", isCompleted: true),
            Habit(title: "Exercise 30 min", isCompleted: true),
            Habit(title: "Read 20 pages", isCompleted: false)
        ]
        notes = [
            Note(text: "I build from sincerity, not pressure."),
            Note(text: "Today I choose one focused creative block.")
        ]
        accentHex = "#3F2A6B"
        settings = .init()
        completionHistory = [
            Self.dayFormatter.string(from: Date()): 0.67
        ]
        coachMessages = [
            .init(role: .assistant, mode: .motivation, text: "You need a sincere day, not a perfect day."),
            .init(role: .user, mode: .motivation, text: "I feel behind."),
            .init(role: .assistant, mode: .motivation, text: "Then shrink the day to one meaningful action.")
        ]
    }

    private enum Keys {
        static let habits = "achieve.habits"
        static let notes = "achieve.notes"
        static let photos = "achieve.photos"
        static let coachMessages = "achieve.coachMessages"
        static let completionHistory = "achieve.completionHistory"
        static let accentHex = "achieve.accentHex"
        static let settings = "achieve.settings"
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

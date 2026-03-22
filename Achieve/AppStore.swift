import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var accentHex: String = "#3F2A6B" { didSet { persistAccent() } }
    @Published var habits: [Habit] = [] { didSet { persistHabits() } }
    @Published var notes: [NoteEntry] = [] { didSet { persistNotes() } }
    @Published var journalPhotos: [JournalPhoto] = [] { didSet { persistPhotos() } }
    @Published var coachMessages: [CoachMessage] = [] { didSet { persistMessages() } }
    @Published var selectedCoachMode: CoachMode = .motivation
    @Published var settings: AppSettings = .init() { didSet { persistSettings() } }

    let habitSuggestions = [
        "Wake up at 6 AM",
        "Exercise 30 min",
        "Meditate 10 min",
        "Pray",
        "Song production",
        "Read 20 pages"
    ]

    let accentPresets = ["#3F2A6B", "#E8B923", "#C84B6F", "#10B981", "#1E3A8A"]

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let isPreview: Bool

    init(defaults: UserDefaults = .standard, isPreview: Bool = false) {
        self.defaults = defaults
        self.isPreview = isPreview
        if isPreview {
            loadPreviewData()
        } else {
            load()
        }
    }

    var accentColor: Color { Color(hex: accentHex) }

    var completionRate: Double {
        guard !habits.isEmpty else { return 0 }
        return Double(habits.filter(\.completed).count) / Double(habits.count)
    }

    var lifetimeFrequencyScore: Int {
        Int((completionRate * 100).rounded())
    }

    func addHabit(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        habits.append(Habit(title: trimmed))
    }

    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].completed.toggle()
    }

    func addNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.insert(NoteEntry(text: trimmed), at: 0)
    }

    func addUserMessage(_ text: String, mode: CoachMode) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        coachMessages.append(CoachMessage(text: trimmed, isUser: true, mode: mode))
    }

    func addCoachReply(for mode: CoachMode) {
        let reply = coachReplies[mode]?.randomElement()
            ?? "You don't need a perfect day. You need an aligned day."
        coachMessages.append(CoachMessage(text: reply, isUser: false, mode: mode))
    }

    func photoURL(for photo: JournalPhoto) -> URL {
        documentsDirectory.appendingPathComponent(photo.fileName)
    }

    func addPhotoData(_ data: Data) {
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            journalPhotos.insert(JournalPhoto(fileName: fileName), at: 0)
        } catch {
            print("Failed to write photo data: \(error.localizedDescription)")
        }
    }

    func resetAllData() {
        habits = []
        notes = []
        coachMessages = [Self.welcomeMessage]
        settings = .init()
        accentHex = "#3F2A6B"

        for photo in journalPhotos {
            try? FileManager.default.removeItem(at: photoURL(for: photo))
        }
        journalPhotos = []
    }

    private func load() {
        accentHex = defaults.string(forKey: Keys.accentHex) ?? "#3F2A6B"
        habits = decode([Habit].self, forKey: Keys.habits) ?? []
        notes = decode([NoteEntry].self, forKey: Keys.notes) ?? []
        journalPhotos = decode([JournalPhoto].self, forKey: Keys.photos) ?? []
        coachMessages = decode([CoachMessage].self, forKey: Keys.messages) ?? [Self.welcomeMessage]
        settings = decode(AppSettings.self, forKey: Keys.settings) ?? .init()
    }

    private func loadPreviewData() {
        accentHex = "#3F2A6B"
        habits = [
            Habit(title: "Meditate 10 min", completed: true),
            Habit(title: "Exercise 30 min", completed: false),
            Habit(title: "Read 20 pages", completed: true)
        ]
        notes = [
            NoteEntry(text: "One sincere day > 100% burnout."),
            NoteEntry(text: "Align with why before output.")
        ]
        coachMessages = [
            Self.welcomeMessage,
            CoachMessage(
                text: "I feel low after a productive day.",
                isUser: true,
                mode: .motivation
            ),
            CoachMessage(
                text: "You are not broken, you are misaligned. Reconnect to your why.",
                isUser: false,
                mode: .motivation
            )
        ]
        journalPhotos = []
        settings = .init()
    }

    private func persistAccent() {
        guard !isPreview else { return }
        defaults.set(accentHex, forKey: Keys.accentHex)
    }

    private func persistHabits() {
        guard !isPreview else { return }
        encode(habits, forKey: Keys.habits)
    }

    private func persistNotes() {
        guard !isPreview else { return }
        encode(notes, forKey: Keys.notes)
    }

    private func persistPhotos() {
        guard !isPreview else { return }
        encode(journalPhotos, forKey: Keys.photos)
    }

    private func persistMessages() {
        guard !isPreview else { return }
        encode(coachMessages, forKey: Keys.messages)
    }

    private func persistSettings() {
        guard !isPreview else { return }
        encode(settings, forKey: Keys.settings)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        do {
            defaults.set(try encoder.encode(value), forKey: key)
        } catch {
            print("Failed to encode \(key): \(error.localizedDescription)")
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("Failed to decode \(key): \(error.localizedDescription)")
            return nil
        }
    }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static let coachReplies: [CoachMode: [String]] = [
        .motivation: [
            "This is not doing nothing; it is recalibrating your instrument.",
            "You don't need a 100% day. You need a sincere day.",
            "Forgive your failed checklist. You are already enough."
        ],
        .routines: [
            "Small repeatable actions beat intense burnout. Choose one sincere routine.",
            "A clean routine starts with one non-negotiable block of focused time.",
            "Design your day around your why, then attach habits to that anchor."
        ],
        .energy: [
            "A surgeon can work 14 hours and still feel peace when aligned with purpose.",
            "Sit in silence for five minutes and ask: who am I when not working?",
            "One sincere prayer has higher frequency than eight hours of resentment."
        ]
    ]

    private static let welcomeMessage = CoachMessage(
        text: "Hello. This is not doing nothing; it is recalibrating your instrument.",
        isUser: false,
        mode: .motivation
    )

    static var preview: AppStore {
        AppStore(isPreview: true)
    }
}

private enum Keys {
    static let accentHex = "achieve.accentHex"
    static let habits = "achieve.habits"
    static let notes = "achieve.notes"
    static let photos = "achieve.photos"
    static let messages = "achieve.messages"
    static let settings = "achieve.settings"
}

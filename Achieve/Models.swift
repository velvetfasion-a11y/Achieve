import Foundation

struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var completed: Bool

    init(id: UUID = UUID(), title: String, completed: Bool = false) {
        self.id = id
        self.title = title
        self.completed = completed
    }
}

struct NoteEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    let createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

struct JournalPhoto: Identifiable, Codable, Hashable {
    let id: UUID
    let fileName: String
    let createdAt: Date

    init(id: UUID = UUID(), fileName: String, createdAt: Date = .now) {
        self.id = id
        self.fileName = fileName
        self.createdAt = createdAt
    }
}

enum CoachMode: String, CaseIterable, Codable, Identifiable {
    case motivation
    case routines
    case energy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .motivation: return "Motivation"
        case .routines: return "Routines"
        case .energy: return "Energy"
        }
    }
}

struct CoachMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let isUser: Bool
    let mode: CoachMode
    let createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        isUser: Bool,
        mode: CoachMode,
        createdAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.mode = mode
        self.createdAt = createdAt
    }
}

enum ReminderFrequency: String, CaseIterable, Codable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}

enum NotificationStyle: String, CaseIterable, Codable, Identifiable {
    case subtle = "Subtle"
    case focused = "Focused"
    case intense = "Intense"

    var id: String { rawValue }
}

enum ExportFormat: String, CaseIterable, Codable, Identifiable {
    case json = "JSON"
    case txt = "TXT"

    var id: String { rawValue }
}

struct AppSettings: Codable, Hashable {
    var reminderFrequency: ReminderFrequency = .medium
    var notificationStyle: NotificationStyle = .subtle
    var exportFormat: ExportFormat = .json
    var currentStreak: Int = 14
}

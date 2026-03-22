import Foundation

struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var completedDayKeys: Set<String>

    init(id: UUID = UUID(), title: String, completedDayKeys: Set<String> = []) {
        self.id = id
        self.title = title
        self.completedDayKeys = completedDayKeys
    }
}

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

struct JournalPhoto: Identifiable, Codable, Hashable {
    let id: UUID
    var fileName: String
    var comment: String
    var createdAt: Date

    init(id: UUID = UUID(), fileName: String, comment: String, createdAt: Date = Date()) {
        self.id = id
        self.fileName = fileName
        self.comment = comment
        self.createdAt = createdAt
    }
}

enum AppSection: String, CaseIterable, Codable, Identifiable {
    case habits
    case coach
    case journal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .habits:
            return "Habits"
        case .coach:
            return "AI Coach"
        case .journal:
            return "Journal"
        }
    }

    var icon: String {
        switch self {
        case .habits:
            return "target"
        case .coach:
            return "sparkles"
        case .journal:
            return "book.closed"
        }
    }
}

enum CoachRole: String, Codable, Hashable {
    case user
    case assistant
}

enum CoachMode: String, CaseIterable, Codable, Hashable, Identifiable {
    case motivation
    case routines
    case energy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .motivation:
            return "Motivation"
        case .routines:
            return "Routines"
        case .energy:
            return "Energy"
        }
    }
}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var role: CoachRole
    var mode: CoachMode
    var text: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        role: CoachRole,
        mode: CoachMode,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.mode = mode
        self.text = text
        self.createdAt = createdAt
    }
}

enum ReminderFrequency: String, CaseIterable, Codable, Identifiable {
    case off
    case daily
    case twiceDaily
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off:
            return "Off"
        case .daily:
            return "Daily"
        case .twiceDaily:
            return "Twice Daily"
        case .custom:
            return "Custom"
        }
    }
}

enum NotificationStyle: String, CaseIterable, Codable, Identifiable {
    case softChime
    case minimal
    case silent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .softChime:
            return "Soft Chime"
        case .minimal:
            return "Minimal"
        case .silent:
            return "Silent"
        }
    }
}

enum ExportFormat: String, CaseIterable, Codable, Identifiable {
    case json
    case csv

    var id: String { rawValue }

    var title: String {
        rawValue.uppercased()
    }
}

struct AppSettings: Codable, Hashable {
    var reminderFrequency: ReminderFrequency = .daily
    var notificationStyle: NotificationStyle = .softChime
    var exportFormat: ExportFormat = .json
    var preferredHabitCategories: Set<String> = ["Mind", "Body", "Spirit"]
    var cloudSyncEnabled: Bool = false
    var streakThreshold: Double = 0.6

    static let allCategories = [
        "Mind",
        "Body",
        "Spirit",
        "Creativity",
        "Focus",
        "Career"
    ]
}

struct LeaderboardEntry: Identifiable, Hashable {
    let id = UUID()
    let alias: String
    let score: Int
}

enum AuthProvider: String, Codable, CaseIterable, Identifiable {
    case apple
    case google
    case email

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        case .email:
            return "Email"
        }
    }
}

struct UserSession: Codable, Hashable {
    var provider: AuthProvider
    var displayName: String
    var email: String?
    var createdAt: Date = Date()
}

struct ExportPayload: Codable {
    let exportedAt: Date
    let accentHex: String
    let habits: [Habit]
    let notes: [Note]
    let photos: [JournalPhoto]
    let coachMessages: [ChatMessage]
    let settings: AppSettings
    let userSession: UserSession?
}

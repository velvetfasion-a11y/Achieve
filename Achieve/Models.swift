import Foundation

// MARK: - Calendar Models

enum EventCategory: String, CaseIterable, Codable, Identifiable {
    case work, plan, growth, personal, health, learning, rest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:     return "WORK"
        case .plan:     return "PLAN"
        case .growth:   return "GROWTH"
        case .personal: return "PERSONAL"
        case .health:   return "HEALTH"
        case .learning: return "LEARNING"
        case .rest:     return "REST"
        }
    }

    var symbol: String {
        switch self {
        case .work:     return "♦"
        case .plan:     return "◆"
        case .growth:   return "✦"
        case .personal: return "⊙"
        case .health:   return "○"
        case .learning: return "◇"
        case .rest:     return "◌"
        }
    }

    var sfSymbol: String {
        switch self {
        case .work:     return "briefcase.fill"
        case .plan:     return "list.bullet.clipboard.fill"
        case .growth:   return "chart.line.uptrend.xyaxis"
        case .personal: return "person.fill"
        case .health:   return "heart.fill"
        case .learning: return "book.fill"
        case .rest:     return "moon.fill"
        }
    }
}

enum EventDuration: String, CaseIterable, Codable, Identifiable {
    case halfHour    = "30m"
    case oneHour     = "1h"
    case oneHalfHour = "1.5h"
    case twoHours    = "2h"
    case threeHours  = "3h"
    case allDay      = "All Day"

    var id: String { rawValue }

    var minutes: Int {
        switch self {
        case .halfHour:    return 30
        case .oneHour:     return 60
        case .oneHalfHour: return 90
        case .twoHours:    return 120
        case .threeHours:  return 180
        case .allDay:      return 1440
        }
    }
}

struct CalendarEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var startHour: Int
    var startMinute: Int
    var duration: EventDuration
    var category: EventCategory
    var isImportant: Bool
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        startHour: Int = 9,
        startMinute: Int = 0,
        duration: EventDuration = .oneHour,
        category: EventCategory = .work,
        isImportant: Bool = false,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = Calendar.current.startOfDay(for: date)
        self.startHour = startHour
        self.startMinute = startMinute
        self.duration = duration
        self.category = category
        self.isImportant = isImportant
        self.isPinned = isPinned
    }

    var startDate: Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = startHour
        comps.minute = startMinute
        return Calendar.current.date(from: comps) ?? date
    }

    var notificationFireDate: Date {
        startDate.addingTimeInterval(-3600)
    }
}

// MARK: - Habits

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
    case calendar
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .habits:   return "Habits"
        case .coach:    return "AI Coach"
        case .journal:  return "Journal"
        case .calendar: return "Schedule"
        case .profile:  return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .habits:   return "target"
        case .coach:    return "sparkles"
        case .journal:  return "book.closed"
        case .calendar: return "calendar"
        case .profile:  return "person.fill"
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
    let calendarEvents: [CalendarEvent]
    let settings: AppSettings
    let userSession: UserSession?
}

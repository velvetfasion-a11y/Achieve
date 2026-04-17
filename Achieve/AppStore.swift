import Foundation
import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    @Published private(set) var notes: [Note] = []
    @Published private(set) var photos: [JournalPhoto] = []
    @Published private(set) var coachMessages: [ChatMessage] = []
    @Published private(set) var calendarEvents: [CalendarEvent] = []
    @Published var userSession: UserSession? {
        didSet {
            save(userSession, key: Keys.userSession)
            if shouldSyncToCloud {
                pushAllSyncableDataToCloud()
            }
        }
    }

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

    var accentColor: Color {
        Color(hex: accentHex)
    }

    var isLoggedIn: Bool {
        userSession != nil
    }

    var profileName: String {
        userSession?.displayName ?? "Guest"
    }

    var loginStateText: String {
        guard let session = userSession else { return "Not signed in" }
        return "Signed in with \(session.provider.title)"
    }

    var lifetimeFrequencyScore: Int {
        let keys = allTrackedDayKeys
        guard !keys.isEmpty else { return Int((progress(for: Date()) * 100).rounded()) }
        let average = keys
            .map { progress(forKey: $0) }
            .reduce(0, +) / Double(keys.count)
        return Int((average * 100).rounded())
    }

    var streakCount: Int {
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        while true {
            let completion = progress(for: currentDate)
            if completion >= settings.streakThreshold {
                streak += 1
            } else {
                break
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previous
        }

        return streak
    }

    init(previewData: Bool = false) {
        setupCloudObserver()

        if previewData {
            seedPreview()
        } else {
            loadFromDisk()
            ensureCoachGreeting()
            if shouldSyncToCloud {
                hydrateFromCloudIfAvailable()
            }
        }
    }

    static var preview: AppStore {
        AppStore(previewData: true)
    }

    func weekDays(reference: Date = Date()) -> [Date] {
        let weekStart = startOfWeek(for: reference)
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }
    }

    func progress(for day: Date) -> Double {
        progress(forKey: dayKey(for: day))
    }

    func isHabitCompleted(_ habit: Habit, on day: Date) -> Bool {
        habit.completedDayKeys.contains(dayKey(for: day))
    }

    func addHabit(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        habits.append(Habit(title: trimmed))
        persistHabits()
    }

    func updateHabitTitle(id: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[index].title = trimmed
        persistHabits()
    }

    func toggleHabit(_ habit: Habit, on day: Date) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = dayKey(for: day)
        if habits[index].completedDayKeys.contains(key) {
            habits[index].completedDayKeys.remove(key)
        } else {
            habits[index].completedDayKeys.insert(key)
        }
        persistHabits()
    }

    func removeHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        persistHabits()
    }

    func moveHabits(fromOffsets: IndexSet, toOffset: Int) {
        habits.move(fromOffsets: fromOffsets, toOffset: toOffset)
        persistHabits()
    }

    // MARK: - Calendar Events

    func addEvent(_ event: CalendarEvent) {
        calendarEvents.append(event)
        persistEvents()
        scheduleNotification(for: event)
    }

    func updateEvent(_ event: CalendarEvent) {
        guard let index = calendarEvents.firstIndex(where: { $0.id == event.id }) else { return }
        cancelNotification(for: calendarEvents[index])
        calendarEvents[index] = event
        persistEvents()
        scheduleNotification(for: event)
    }

    func deleteEvent(_ event: CalendarEvent) {
        cancelNotification(for: event)
        calendarEvents.removeAll { $0.id == event.id }
        persistEvents()
    }

    func eventsFor(date: Date) -> [CalendarEvent] {
        let key = dayKey(for: date)
        return calendarEvents
            .filter { dayKey(for: $0.date) == key }
            .sorted {
                if $0.startHour != $1.startHour { return $0.startHour < $1.startHour }
                return $0.startMinute < $1.startMinute
            }
    }

    func eventsFor(month: Int, year: Int) -> [CalendarEvent] {
        calendarEvents.filter { event in
            let comps = calendar.dateComponents([.month, .year], from: event.date)
            return comps.month == month && comps.year == year
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleNotification(for event: CalendarEvent) {
        guard event.duration != .allDay else { return }
        let fireDate = event.notificationFireDate
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming: \(event.title)"
        content.body = "\(event.category.title) starts in 1 hour"
        content.sound = .default
        content.categoryIdentifier = "CALENDAR_EVENT"
        content.userInfo = ["eventID": event.id.uuidString]

        let triggerComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        let request = UNNotificationRequest(identifier: "event-\(event.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancelNotification(for event: CalendarEvent) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["event-\(event.id.uuidString)"]
        )
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let snoozeIDs = requests
                .filter { $0.identifier.hasPrefix("event-snooze-\(event.id.uuidString)-") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: snoozeIDs)
        }
    }

    func addNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.insert(Note(text: trimmed), at: 0)
        save(notes, key: Keys.notes)
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
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

    func addPhoto(data: Data, comment: String) throws {
        let fileName = "journal-\(UUID().uuidString).jpg"
        let url = Self.documentsDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: [.atomic])
        photos.insert(JournalPhoto(fileName: fileName, comment: comment), at: 0)
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
            calendarEvents: calendarEvents,
            settings: settings,
            userSession: userSession
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
        calendarEvents = []
        accentHex = "#3F2A6B"
        settings = .init()
        userSession = nil

        UserDefaults.standard.removeObject(forKey: Keys.habits)
        UserDefaults.standard.removeObject(forKey: Keys.notes)
        UserDefaults.standard.removeObject(forKey: Keys.photos)
        UserDefaults.standard.removeObject(forKey: Keys.coachMessages)
        UserDefaults.standard.removeObject(forKey: Keys.calendarEvents)
        UserDefaults.standard.removeObject(forKey: Keys.accentHex)
        UserDefaults.standard.removeObject(forKey: Keys.settings)
        UserDefaults.standard.removeObject(forKey: Keys.userSession)

        habits = [Habit(title: "Drink water")]
        persistHabits()
        ensureCoachGreeting()
    }

    func signInWithGoogle(displayName: String = "Google User") {
        userSession = UserSession(provider: .google, displayName: displayName)
    }

    func signInWithEmail(displayName: String, email: String) {
        userSession = UserSession(provider: .email, displayName: displayName, email: email)
    }

    func signInWithApple(displayName: String, email: String?) {
        userSession = UserSession(provider: .apple, displayName: displayName, email: email)
    }

    func signOut() {
        userSession = nil
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        if let savedSession: UserSession = load(key: Keys.userSession, as: UserSession.self) {
            userSession = savedSession
        }
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
        if let savedAccent: String = load(key: Keys.accentHex, as: String.self) {
            accentHex = savedAccent
        }
        if let savedSettings: AppSettings = load(key: Keys.settings, as: AppSettings.self) {
            settings = savedSettings
        }
        if let savedEvents: [CalendarEvent] = load(key: Keys.calendarEvents, as: [CalendarEvent].self) {
            calendarEvents = savedEvents
        }

        if UserDefaults.standard.object(forKey: Keys.habits) == nil {
            habits = [Habit(title: "Drink water")]
            persistHabits()
        }
    }

    private func persistHabits() {
        save(habits, key: Keys.habits)
    }

    private func persistEvents() {
        save(calendarEvents, key: Keys.calendarEvents)
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

    private func progress(forKey dayKey: String) -> Double {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { $0.completedDayKeys.contains(dayKey) }.count
        return Double(completed) / Double(habits.count)
    }

    private var allTrackedDayKeys: Set<String> {
        habits.reduce(into: Set<String>()) { partial, habit in
            partial.formUnion(habit.completedDayKeys)
        }
    }

    private func dayKey(for date: Date) -> String {
        Self.dayFormatter.string(from: calendar.startOfDay(for: date))
    }

    private func startOfWeek(for date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components).map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: date)
    }

    private var shouldSyncToCloud: Bool {
        userSession != nil
    }

    private func setupCloudObserver() {
        cloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.hydrateFromCloudIfAvailable()
            }
        }
    }

    private func pushAllSyncableDataToCloud() {
        guard shouldSyncToCloud else { return }
        save(habits, key: Keys.habits)
        save(notes, key: Keys.notes)
        save(coachMessages, key: Keys.coachMessages)
        save(calendarEvents, key: Keys.calendarEvents)
        save(accentHex, key: Keys.accentHex)
        save(settings, key: Keys.settings)
        save(userSession, key: Keys.userSession)
    }

    private func hydrateFromCloudIfAvailable() {
        guard shouldSyncToCloud else { return }
        isApplyingCloudChange = true
        defer { isApplyingCloudChange = false }

        if let cloudHabits: [Habit] = loadFromCloud(key: Keys.habits, as: [Habit].self) {
            habits = cloudHabits
        }
        if let cloudNotes: [Note] = loadFromCloud(key: Keys.notes, as: [Note].self) {
            notes = cloudNotes
        }
        if let cloudMessages: [ChatMessage] = loadFromCloud(key: Keys.coachMessages, as: [ChatMessage].self) {
            coachMessages = cloudMessages
        }
        if let cloudAccent: String = loadFromCloud(key: Keys.accentHex, as: String.self) {
            accentHex = cloudAccent
        }
        if let cloudSettings: AppSettings = loadFromCloud(key: Keys.settings, as: AppSettings.self) {
            settings = cloudSettings
        }
        if let cloudEvents: [CalendarEvent] = loadFromCloud(key: Keys.calendarEvents, as: [CalendarEvent].self) {
            calendarEvents = cloudEvents
        }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: key)
            if shouldSyncToCloud, !isApplyingCloudChange {
                cloudStore.set(data, forKey: cloudKey(for: key))
                cloudStore.synchronize()
            }
        } catch {
            print("Failed saving key \(key): \(error.localizedDescription)")
        }
    }

    private func load<T: Decodable>(key: String, as type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func loadFromCloud<T: Decodable>(key: String, as type: T.Type) -> T? {
        guard let data = cloudStore.data(forKey: cloudKey(for: key)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func cloudKey(for key: String) -> String {
        "cloud.\(key)"
    }

    private func seedPreview() {
        let today = dayKey(for: Date())
        let yesterday = dayKey(for: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        habits = [
            Habit(title: "Drink water", completedDayKeys: [today, yesterday]),
            Habit(title: "Meditate 10 min", completedDayKeys: [today]),
            Habit(title: "Exercise 30 min", completedDayKeys: [])
        ]
        notes = [
            Note(text: "I build from sincerity, not pressure."),
            Note(text: "Today I choose one focused creative block.")
        ]
        accentHex = "#3F2A6B"
        settings = .init()
        userSession = UserSession(provider: .apple, displayName: "Preview User", email: "preview@achieve.app")
        coachMessages = [
            .init(role: .assistant, mode: .motivation, text: "You need a sincere day, not a perfect day."),
            .init(role: .user, mode: .motivation, text: "I feel behind."),
            .init(role: .assistant, mode: .motivation, text: "Then shrink the day to one meaningful action.")
        ]
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        calendarEvents = [
            CalendarEvent(title: "Team Standup", date: Date(), startHour: 9, startMinute: 0, duration: .halfHour, category: .work, isImportant: true),
            CalendarEvent(title: "Deep Work Block", date: Date(), startHour: 10, startMinute: 0, duration: .twoHours, category: .growth),
            CalendarEvent(title: "Gym Session", date: tomorrow, startHour: 7, startMinute: 0, duration: .oneHour, category: .health, isPinned: true)
        ]
    }

    private enum Keys {
        static let habits = "achieve.habits"
        static let notes = "achieve.notes"
        static let photos = "achieve.photos"
        static let coachMessages = "achieve.coachMessages"
        static let calendarEvents = "achieve.calendarEvents"
        static let accentHex = "achieve.accentHex"
        static let settings = "achieve.settings"
        static let userSession = "achieve.userSession"
    }

    private var cloudObserver: NSObjectProtocol?
    private var isApplyingCloudChange = false
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
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

    deinit {
        if let cloudObserver {
            NotificationCenter.default.removeObserver(cloudObserver)
        }
    }
}

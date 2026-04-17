import SwiftUI
import UserNotifications

@main
struct AchieveApp: App {
    private let notificationDelegate = CalendarNotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 5 min",
            options: []
        )
        let stopAction = UNNotificationAction(
            identifier: "STOP",
            title: "Stop",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: "CALENDAR_EVENT",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Notification Delegate

final class CalendarNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let eventIDString = userInfo["eventID"] as? String ?? ""

        switch response.actionIdentifier {
        case "SNOOZE":
            scheduleSnooze(eventIDString: eventIDString, originalContent: response.notification.request.content)
        case "STOP":
            cancelAllSnoozes(for: eventIDString)
        default:
            break
        }
        completionHandler()
    }

    private func scheduleSnooze(eventIDString: String, originalContent: UNNotificationContent) {
        guard !eventIDString.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = originalContent.title
        content.body = "Snoozed — starts soon"
        content.sound = .default
        content.categoryIdentifier = "CALENDAR_EVENT"
        content.userInfo = originalContent.userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        let identifier = "event-snooze-\(eventIDString)-\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func cancelAllSnoozes(for eventIDString: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix("event-snooze-\(eventIDString)-") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}

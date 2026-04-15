import Foundation
import UserNotifications

@MainActor
protocol ReminderScheduling {
    func requestAuthorization() async throws
    func scheduleDailyReminder(hour: Int, minute: Int) async throws
    func cancelReminder() async
}

enum ReminderSchedulerError: LocalizedError {
    case authorizationDenied

    var errorDescription: String? {
        "Notification permission was not granted."
    }
}

@MainActor
struct ReminderScheduler: ReminderScheduling {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws {
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        if !granted {
            throw ReminderSchedulerError.authorizationDenied
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        await cancelReminder()

        let content = UNMutableNotificationContent()
        content.title = "Today's checklist"
        content.body = "Open Daily Checklist and finish today's tasks."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.reminderRequestIdentifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func cancelReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [AppConstants.reminderRequestIdentifier])
    }
}

private extension UNUserNotificationCenter {
    @MainActor
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            requestAuthorization(options: options) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    @MainActor
    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

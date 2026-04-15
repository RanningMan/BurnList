import Foundation

struct AppConfiguration: Codable, Equatable {
    var sheetURLString: String
    var remindersEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int

    static let `default` = AppConfiguration(
        sheetURLString: "",
        remindersEnabled: false,
        reminderHour: AppConstants.defaultReminderHour,
        reminderMinute: AppConstants.defaultReminderMinute
    )
}

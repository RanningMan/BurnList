import Foundation

struct DailyChecklistSnapshot: Codable, Equatable {
    let dateID: String
    var tasks: [DailyTask]
    let refreshedAt: Date
    let lastErrorMessage: String?
}

import Foundation

struct DailyTask: Codable, Hashable, Identifiable {
    let dateID: String
    let taskID: String
    let title: String
    let sortOrder: Int
    var isCompleted: Bool

    var id: String {
        "\(dateID)|\(taskID)"
    }
}

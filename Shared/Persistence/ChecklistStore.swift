import Foundation

final class ChecklistStore {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard) {
        self.userDefaults = userDefaults
    }

    func loadConfiguration() -> AppConfiguration {
        guard
            let data = userDefaults.data(forKey: AppConstants.configurationKey),
            let configuration = try? decoder.decode(AppConfiguration.self, from: data)
        else {
            return .default
        }

        return configuration
    }

    func saveConfiguration(_ configuration: AppConfiguration) {
        guard let data = try? encoder.encode(configuration) else {
            return
        }

        userDefaults.set(data, forKey: AppConstants.configurationKey)
    }

    func loadSnapshot() -> DailyChecklistSnapshot? {
        guard
            let data = userDefaults.data(forKey: AppConstants.snapshotKey),
            let snapshot = try? decoder.decode(DailyChecklistSnapshot.self, from: data)
        else {
            return nil
        }

        return snapshot
    }

    func saveSnapshot(_ snapshot: DailyChecklistSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        clearStaleCompletionData(keeping: snapshot.dateID)
        userDefaults.set(data, forKey: AppConstants.snapshotKey)
    }

    func loadTasks(for dateID: String) -> [DailyTask] {
        guard let snapshot = loadSnapshot(), snapshot.dateID == dateID else {
            return []
        }

        let completionMap = loadCompletionMap()
        return snapshot.tasks
            .map { task in
                var updatedTask = task
                updatedTask.isCompleted = completionMap[completionKey(for: task.taskID, dateID: dateID)] ?? false
                return updatedTask
            }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    @discardableResult
    func toggleTask(taskID: String, dateID: String) -> Bool {
        var completionMap = loadCompletionMap()
        let key = completionKey(for: taskID, dateID: dateID)
        let newValue = !(completionMap[key] ?? false)
        completionMap[key] = newValue
        clearStaleCompletionData(in: &completionMap, keeping: dateID)
        saveCompletionMap(completionMap)
        return newValue
    }

    private func loadCompletionMap() -> [String: Bool] {
        guard
            let data = userDefaults.data(forKey: AppConstants.completionMapKey),
            let completionMap = try? decoder.decode([String: Bool].self, from: data)
        else {
            return [:]
        }

        return completionMap
    }

    private func saveCompletionMap(_ completionMap: [String: Bool]) {
        guard let data = try? encoder.encode(completionMap) else {
            return
        }

        userDefaults.set(data, forKey: AppConstants.completionMapKey)
    }

    private func clearStaleCompletionData(keeping dateID: String) {
        var completionMap = loadCompletionMap()
        clearStaleCompletionData(in: &completionMap, keeping: dateID)
        saveCompletionMap(completionMap)
    }

    private func clearStaleCompletionData(in completionMap: inout [String: Bool], keeping dateID: String) {
        completionMap = completionMap.filter { key, _ in
            key.hasPrefix("\(dateID)|")
        }
    }

    private func completionKey(for taskID: String, dateID: String) -> String {
        "\(dateID)|\(taskID)"
    }
}

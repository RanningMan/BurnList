import Foundation

@MainActor
protocol NetworkSession {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}

enum TaskSyncServiceError: LocalizedError {
    case invalidSourceURL
    case unexpectedResponse(Int)

    var errorDescription: String? {
        switch self {
        case .invalidSourceURL:
            return "Enter a valid published Google Sheet CSV URL."
        case let .unexpectedResponse(statusCode):
            return "The sheet request failed with status \(statusCode)."
        }
    }
}

@MainActor
struct TaskSyncService {
    private let store: ChecklistStore
    private let parser: TaskSheetParser
    private let session: NetworkSession

    init(
        store: ChecklistStore,
        parser: TaskSheetParser = TaskSheetParser(),
        session: NetworkSession = URLSession.shared
    ) {
        self.store = store
        self.parser = parser
        self.session = session
    }

    func refresh(configuration: AppConfiguration, now: Date = .now) async throws -> DailyChecklistSnapshot {
        let trimmedURL = configuration.sheetURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedURL), !trimmedURL.isEmpty else {
            throw TaskSyncServiceError.invalidSourceURL
        }

        let (data, response) = try await session.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, !(200 ..< 300).contains(httpResponse.statusCode) {
            throw TaskSyncServiceError.unexpectedResponse(httpResponse.statusCode)
        }

        let csv = String(decoding: data, as: UTF8.self)
        let tasks = try parser.parseTodayTasks(from: csv, now: now)
        let snapshot = DailyChecklistSnapshot(
            dateID: DateFormatting.dayID(from: now),
            tasks: tasks,
            refreshedAt: now,
            lastErrorMessage: nil
        )
        store.saveSnapshot(snapshot)
        return snapshot
    }

    func refreshPreservingCache(configuration: AppConfiguration, now: Date = .now) async -> DailyChecklistSnapshot {
        do {
            return try await refresh(configuration: configuration, now: now)
        } catch {
            let todayID = DateFormatting.dayID(from: now)
            let existingSnapshot = store.loadSnapshot()
            let snapshot = DailyChecklistSnapshot(
                dateID: todayID,
                tasks: existingSnapshot?.dateID == todayID ? existingSnapshot?.tasks ?? [] : [],
                refreshedAt: existingSnapshot?.refreshedAt ?? now,
                lastErrorMessage: error.localizedDescription
            )
            store.saveSnapshot(snapshot)
            return snapshot
        }
    }
}

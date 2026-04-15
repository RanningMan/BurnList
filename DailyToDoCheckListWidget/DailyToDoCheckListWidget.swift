import AppIntents
import WidgetKit
import SwiftUI

struct DailyChecklistEntry: TimelineEntry {
    let date: Date
    let tasks: [DailyTask]
    let lastUpdated: Date?
    let lastErrorMessage: String?
}

struct DailyChecklistProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyChecklistEntry {
        DailyChecklistEntry(
            date: .now,
            tasks: [
                DailyTask(dateID: DateFormatting.dayID(from: .now), taskID: "dsa-30m-day", title: "DSA (30m/day)", sortOrder: 0, isCompleted: false),
                DailyTask(dateID: DateFormatting.dayID(from: .now), taskID: "fe-coding-30m-day", title: "FE coding (30m/day)", sortOrder: 1, isCompleted: true)
            ],
            lastUpdated: .now,
            lastErrorMessage: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyChecklistEntry) -> Void) {
        completion(makeEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyChecklistEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(for: now)
        let nextRefresh = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)

        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func makeEntry(for date: Date) -> DailyChecklistEntry {
        let store = ChecklistStore()
        let dateID = DateFormatting.dayID(from: date)
        let snapshot = store.loadSnapshot()
        let shouldShowSnapshotState = snapshot?.dateID == dateID

        return DailyChecklistEntry(
            date: date,
            tasks: store.loadTasks(for: dateID),
            lastUpdated: shouldShowSnapshotState ? snapshot?.refreshedAt : nil,
            lastErrorMessage: shouldShowSnapshotState ? snapshot?.lastErrorMessage : nil
        )
    }
}

struct DailyChecklistWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: DailyChecklistProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.date, format: .dateTime.weekday(.abbreviated).month().day())
                .font(.headline)

            if entry.tasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No tasks today")
                        .font(.subheadline.weight(.medium))
                    Text("Open the app to refresh or update your sheet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(Array(entry.tasks.prefix(maxTasks).enumerated()), id: \.element.id) { _, task in
                    Button(intent: ToggleTaskIntent(taskID: task.taskID, dateID: task.dateID)) {
                        HStack(spacing: 8) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isCompleted ? Color.green : Color.secondary)
                            Text(task.title)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .strikethrough(task.isCompleted, color: .secondary)
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if entry.tasks.count > maxTasks {
                    Text("+\(entry.tasks.count - maxTasks) more in app")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if entry.lastErrorMessage != nil {
                Text("Using last cached tasks")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "dailychecklist://today"))
    }

    private var maxTasks: Int {
        switch family {
        case .systemSmall:
            3
        case .systemMedium:
            6
        default:
            10
        }
    }
}

@main
struct DailyToDoCheckListWidget: Widget {
    let kind: String = AppConstants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyChecklistProvider()) { entry in
            DailyChecklistWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Checklist")
        .description("Shows today's tasks and lets you check them off.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

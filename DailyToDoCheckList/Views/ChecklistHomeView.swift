import SwiftUI

struct ChecklistHomeView: View {
    @ObservedObject var model: AppModel
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                            .font(.title2.weight(.semibold))
                        Text(model.syncStatusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)

                if model.tasks.isEmpty {
                    ContentUnavailableView(
                        "No Tasks Today",
                        systemImage: "checklist",
                        description: Text(emptyStateCopy)
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(model.tasks) { task in
                        Button {
                            model.toggle(task)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(task.isCompleted ? Color.green : Color.secondary)

                                Text(task.title)
                                    .foregroundStyle(.primary)
                                    .strikethrough(task.isCompleted, color: .secondary)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Daily Checklist")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if model.isRefreshing {
                        ProgressView()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .refreshable {
                await model.refreshIfConfigured()
            }
            .task {
                await model.refreshIfConfigured()
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    SettingsView(model: model)
                }
            }
        }
    }

    private var emptyStateCopy: String {
        if model.configuration.sheetURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add your published Google Sheet URL in Settings to start syncing."
        }

        return "The current date row does not contain any planned task cells."
    }
}

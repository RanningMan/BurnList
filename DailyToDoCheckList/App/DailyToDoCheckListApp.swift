import SwiftUI

@main
struct DailyToDoCheckListApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model: AppModel

    init() {
        _model = StateObject(wrappedValue: AppModel())
    }

    var body: some Scene {
        WindowGroup {
            ChecklistHomeView(model: model)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await model.refreshIfConfigured()
            }
        }
    }
}

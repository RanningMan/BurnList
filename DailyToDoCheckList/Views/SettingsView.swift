import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var sheetURLString = ""
    @State private var remindersEnabled = false
    @State private var reminderDate = Date.now

    var body: some View {
        Form {
            Section("Google Sheet") {
                TextField("Published worksheet CSV URL", text: $sheetURLString, axis: .vertical)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Save Source URL") {
                    model.saveSheetURL(sheetURLString)
                }

                Button("Refresh Now") {
                    Task {
                        await model.refreshIfConfigured()
                    }
                }
                .disabled(model.configuration.sheetURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Reminder") {
                Toggle("Daily reminder", isOn: $remindersEnabled)
                    .onChange(of: remindersEnabled) { _, newValue in
                        Task {
                            await model.setRemindersEnabled(newValue)
                            remindersEnabled = model.configuration.remindersEnabled
                        }
                    }

                DatePicker("Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                    .disabled(!remindersEnabled)
                    .onChange(of: reminderDate) { _, newValue in
                        Task {
                            await model.setReminderTime(newValue)
                            reminderDate = model.reminderDate
                        }
                    }
            }

            Section("Status") {
                Text(model.syncStatusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            sheetURLString = model.configuration.sheetURLString
            remindersEnabled = model.configuration.remindersEnabled
            reminderDate = model.reminderDate
        }
    }
}

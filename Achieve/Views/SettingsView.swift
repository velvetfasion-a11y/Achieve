import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Form {
            Section("Reminders") {
                Picker("Frequency", selection: $store.settings.reminderFrequency) {
                    ForEach(ReminderFrequency.allCases) { frequency in
                        Text(frequency.title).tag(frequency)
                    }
                }

                Picker("Notification Style", selection: $store.settings.notificationStyle) {
                    ForEach(NotificationStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Streak Threshold \(Int(store.settings.streakThreshold * 100))%")
                    Slider(value: $store.settings.streakThreshold, in: 0.3...1.0, step: 0.05)
                }
            }

            Section("Habit Categories") {
                ForEach(AppSettings.allCategories, id: \.self) { category in
                    Toggle(category, isOn: categoryBinding(category))
                }
            }

            Section("Data") {
                Picker("Export Format", selection: $store.settings.exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }

                Toggle("Enable Optional Cloud Sync", isOn: $store.settings.cloudSyncEnabled)
            }
        }
        .navigationTitle("Settings")
    }

    private func categoryBinding(_ category: String) -> Binding<Bool> {
        Binding(
            get: { store.settings.preferredHabitCategories.contains(category) },
            set: { isOn in
                if isOn {
                    store.settings.preferredHabitCategories.insert(category)
                } else {
                    store.settings.preferredHabitCategories.remove(category)
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppStore.preview)
    }
}

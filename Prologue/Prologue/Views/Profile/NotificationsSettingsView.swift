import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("friendRequestAlerts") private var friendRequestAlerts: Bool = true
    @AppStorage("reviewAlerts") private var reviewAlerts: Bool = true
    @AppStorage("readingReminders") private var readingReminders: Bool = false

    var body: some View {
        Form {
            Section {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, enabled in
                        guard enabled else { return }
                        Task { await requestOrOpenSettings() }
                    }
            }

            Section("Social Alerts") {
                Toggle("Friend Requests", isOn: $friendRequestAlerts)
                Toggle("New Reviews", isOn: $reviewAlerts)
            }
            .disabled(!notificationsEnabled)

            Section("Reminders") {
                Toggle("Daily Reading Reminder", isOn: $readingReminders)
            }
            .disabled(!notificationsEnabled)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func requestOrOpenSettings() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            if !granted { await MainActor.run { notificationsEnabled = false } }
        case .denied:
            await MainActor.run {
                notificationsEnabled = false
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        default:
            break
        }
    }
}

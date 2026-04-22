import SwiftUI

struct PrivacySettingsView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var visibility: ProfileVisibility = .public
    @State private var activitySharing: Bool = true

    var body: some View {
        Form {
            Section {
                Picker("Profile Visibility", selection: $visibility) {
                    ForEach(ProfileVisibility.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                Toggle("Activity Sharing", isOn: $activitySharing)
            } footer: {
                Text("Activity Sharing broadcasts when you start or finish a book to your friends' feeds.")
            }

            Section {
                NavigationLink("Blocked Users") {
                    BlockedUsersView()
                        .environment(authVM)
                }
            }

            if let error = authVM.error {
                Section {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(authVM.isSaving ? "Saving…" : "Save") {
                    Task {
                        await authVM.updatePrivacySettings(
                            visibility: visibility,
                            activitySharing: activitySharing
                        )
                        if authVM.error == nil { dismiss() }
                    }
                }
                .disabled(authVM.isSaving)
            }
        }
        .onAppear {
            visibility      = authVM.profile?.visibility ?? .public
            activitySharing = authVM.profile?.activitySharing ?? true
        }
    }
}

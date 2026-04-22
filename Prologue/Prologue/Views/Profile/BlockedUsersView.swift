import SwiftUI

struct BlockedUsersView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        List {
            if authVM.blockedUsers.isEmpty && !authVM.isLoadingBlocked {
                ContentUnavailableView(
                    "No Blocked Users",
                    systemImage: "person.crop.circle.badge.checkmark",
                    description: Text("People you block will appear here.")
                )
            } else {
                ForEach(authVM.blockedUsers) { blocked in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(blocked.displayName ?? blocked.username)
                                .font(.headline)
                            Text("@\(blocked.username)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Unblock") {
                            Task { try? await authVM.unblockUser(blocked) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if authVM.isLoadingBlocked && authVM.blockedUsers.isEmpty {
                ProgressView()
            }
        }
        .task { await authVM.loadBlockedUsers() }
    }
}

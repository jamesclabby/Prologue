import SwiftUI
import Auth

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(SocialViewModel.self) private var socialVM
    @Environment(LibraryViewModel.self) private var libraryVM

    @State private var showAvatarPicker = false
    @State private var selectedAvatarImage: UIImage?
    @State private var isUploadingAvatar = false
    @State private var showDeleteStep1 = false
    @State private var showDeleteStep2 = false
    @State private var deleteError: String?
    @State private var showEditProfile = false

    private var displayedName: String {
        authVM.profile?.displayName ?? authVM.profile?.username ?? "—"
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Identity Header
                Section {
                    VStack(spacing: 12) {
                        Button { showAvatarPicker = true } label: {
                            avatarView
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 4) {
                            Text(displayedName)
                                .font(.title2.bold())
                            Text("@\(authVM.profile?.username ?? "")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        NavigationLink {
                            ProfileFriendsView()
                                .environment(socialVM)
                                .environment(authVM)
                        } label: {
                            Text("\(socialVM.friends.count) Friends")
                                .font(.subheadline)
                        }

                        Button {
                            showEditProfile = true
                        } label: {
                            Text("Edit Profile")
                                .font(.subheadline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 6)
                                .background(.quaternary, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // MARK: Account
                Section("Account") {
                    LabeledContent("Email", value: authVM.currentUser?.email ?? "—")
                    // Biometric toggle: Stage 2
                }

                // MARK: Notifications — Stage 2
                // MARK: Appearance — Stage 2
                // MARK: Privacy — Stage 3
                // MARK: Support & Legal — Stage 3

                // MARK: Danger Zone
                Section {
                    Button("Sign Out", role: .destructive) {
                        Task { await authVM.signOut() }
                    }
                    Button("Delete Account", role: .destructive) {
                        showDeleteStep1 = true
                    }
                }

                if let deleteError {
                    Section {
                        Text(deleteError)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                if let authError = authVM.error {
                    Section {
                        Text(authError.localizedDescription)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationDestination(isPresented: $showEditProfile) {
                EditProfileView()
                    .environment(authVM)
            }
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerRepresentable { image in
                selectedAvatarImage = image
                showAvatarPicker = false
                Task { await uploadSelectedAvatar(image) }
            }
            .ignoresSafeArea()
        }
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showDeleteStep1,
            titleVisibility: .visible
        ) {
            Button("Continue", role: .destructive) { showDeleteStep2 = true }
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "This cannot be undone",
            isPresented: $showDeleteStep2
        ) {
            Button("Delete My Account", role: .destructive) {
                Task {
                    do {
                        try await authVM.deleteAccount()
                    } catch {
                        deleteError = error.localizedDescription
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All your books, reviews, and friendships will be permanently deleted.")
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let localImage = selectedAvatarImage {
                    Image(uiImage: localImage)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } else if let urlString = authVM.profile?.avatarURL,
                          let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(1, contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 88, height: 88)
            .clipShape(Circle())
            .overlay(Circle().stroke(.quaternary, lineWidth: 1))

            if isUploadingAvatar {
                ProgressView()
                    .frame(width: 24, height: 24)
                    .background(.regularMaterial, in: Circle())
            } else {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, Color.accentColor)
                    .background(Circle().fill(.background))
            }
        }
    }

    private func uploadSelectedAvatar(_ image: UIImage) async {
        isUploadingAvatar = true
        let resized = image.resizedAndCropped(to: 400)
        if let data = resized.jpegData(compressionQuality: 0.8) {
            await authVM.updateProfile(
                displayName: authVM.profile?.displayName,
                username: authVM.profile?.username ?? "",
                favoriteGenre: authVM.profile?.favoriteGenre,
                avatarData: data
            )
        }
        isUploadingAvatar = false
    }
}

// MARK: - ProfileFriendsView

struct ProfileFriendsView: View {
    @Environment(SocialViewModel.self) private var socialVM
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        List {
            if !socialVM.pendingRequests.isEmpty {
                Section("Pending Requests") {
                    ForEach(socialVM.pendingRequests) { profile in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(profile.username).font(.headline)
                            }
                            Spacer()
                            Button("Accept") {
                                guard let myID = authVM.userID else { return }
                                Task { try? await socialVM.acceptRequest(from: profile, userID: myID) }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
            }
            Section("Friends") {
                if socialVM.friends.isEmpty {
                    Text("No friends yet.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(socialVM.friends) { friend in
                        NavigationLink(destination: FriendProfileView(profile: friend)) {
                            FriendRow(profile: friend)
                        }
                    }
                }
            }
        }
        .navigationTitle("Friends")
    }
}

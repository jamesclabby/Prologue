import SwiftUI

struct SocialView: View {
    @Environment(SocialViewModel.self) private var socialVM
    @Environment(AuthViewModel.self) private var authVM
    @State private var searchQuery = ""
    @State private var selectedFriend: Profile?

    var body: some View {
        NavigationStack {
            @Bindable var vm = socialVM

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
                        Text("No friends yet. Search for readers above.")
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

                if !socialVM.searchResults.isEmpty {
                    Section("Search Results") {
                        ForEach(socialVM.searchResults) { profile in
                            HStack {
                                Text(profile.username).font(.headline)
                                Spacer()
                                if !socialVM.friends.contains(where: { $0.id == profile.id }) {
                                    Button("Add") {
                                        guard let myID = authVM.userID else { return }
                                        Task { try? await socialVM.sendRequest(to: profile, from: myID) }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                } else {
                                    Text("Friends").foregroundStyle(.secondary).font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .searchable(text: $searchQuery, prompt: "Search readers…")
            .onChange(of: searchQuery) { _, new in
                Task { await socialVM.searchUsers(query: new) }
            }
            .task {
                guard let userID = authVM.userID else { return }
                await socialVM.loadFriends(userID: userID)
            }
        }
    }
}

struct FriendRow: View {
    let profile: Profile

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text(profile.username).font(.headline)
                if let genre = profile.favoriteGenre {
                    Text(genre).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

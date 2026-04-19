import Foundation
import Supabase
import Observation

@Observable
final class SocialViewModel {
    var friends: [Profile] = []
    var pendingRequests: [Profile] = []
    var searchResults: [Profile] = []
    var friendBooks: [String: [UserBook]] = [:]
    var isLoading = false
    var error: Error?

    private let supabase = SupabaseManager.shared.client

    @MainActor
    func loadFriends(userID: UUID) async {
        isLoading = true
        error = nil
        do {
            let accepted: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .eq("status", value: "accepted")
                .or("requester_id.eq.\(userID),receiver_id.eq.\(userID)")
                .execute()
                .value

            let friendIDs = accepted.map { friendship -> UUID in
                friendship.requesterID == userID ? friendship.receiverID : friendship.requesterID
            }

            if friendIDs.isEmpty {
                friends = []
            } else {
                friends = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: friendIDs.map(\.uuidString))
                    .execute()
                    .value
            }

            let pending: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .eq("receiver_id", value: userID)
                .eq("status", value: "pending")
                .execute()
                .value

            let requesterIDs = pending.map(\.requesterID.uuidString)
            if requesterIDs.isEmpty {
                pendingRequests = []
            } else {
                pendingRequests = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: requesterIDs)
                    .execute()
                    .value
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    @MainActor
    func searchUsers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        do {
            searchResults = try await supabase
                .from("profiles")
                .select()
                .ilike("username", pattern: "%\(query)%")
                .limit(20)
                .execute()
                .value
        } catch {
            self.error = error
        }
    }

    @MainActor
    func sendRequest(to profile: Profile, from userID: UUID) async throws {
        let insert: [String: String] = [
            "requester_id": userID.uuidString,
            "receiver_id": profile.id.uuidString,
            "status": "pending"
        ]
        try await supabase.from("friendships").insert(insert).execute()
    }

    @MainActor
    func acceptRequest(from profile: Profile, userID: UUID) async throws {
        try await supabase
            .from("friendships")
            .update(["status": "accepted"])
            .eq("requester_id", value: profile.id)
            .eq("receiver_id", value: userID)
            .execute()
        pendingRequests.removeAll { $0.id == profile.id }
        friends.append(profile)
    }

    @MainActor
    func loadFriendBooks(friendID: UUID) async throws -> [UserBook] {
        if let cached = friendBooks[friendID.uuidString] { return cached }
        let books: [UserBook] = try await supabase
            .from("user_books")
            .select()
            .eq("user_id", value: friendID)
            .eq("is_private", value: false)
            .execute()
            .value
        friendBooks[friendID.uuidString] = books
        return books
    }
}

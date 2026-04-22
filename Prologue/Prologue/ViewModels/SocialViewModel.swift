import Foundation
import Supabase
import Observation

@Observable
final class SocialViewModel {
    var friends: [Profile] = []
    var pendingRequests: [Profile] = []
    var searchResults: [Profile] = []
    var friendBooks: [String: [UserBook]] = [:]
    var friendBookCache: [String: Book] = [:]
    var isLoading = false
    var error: Error?

    private let supabase = SupabaseManager.shared.client
    private let bookSearchService: BookSearchServiceProtocol

    init(bookSearchService: BookSearchServiceProtocol = BookSearchService()) {
        self.bookSearchService = bookSearchService
    }

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
    func searchUsers(query: String, blockedIDs: Set<UUID> = []) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        do {
            let results: [Profile] = try await supabase
                .from("profiles")
                .select()
                .ilike("username", pattern: "%\(query)%")
                .limit(20)
                .execute()
                .value
            searchResults = results.filter { !blockedIDs.contains($0.id) }
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
        await cacheBookMetadata(for: books)
        return books
    }

    @MainActor
    func cacheBookMetadata(for userBooks: [UserBook]) async {
        for userBook in userBooks where friendBookCache[userBook.googleBooksID] == nil {
            if let metadata = try? await bookSearchService.fetchByID(userBook.googleBooksID) {
                friendBookCache[userBook.googleBooksID] = metadata
            }
        }
    }

    @MainActor
    func bookMetadata(for googleBooksID: String) async -> Book? {
        if let cached = friendBookCache[googleBooksID] { return cached }
        if let fetched = try? await bookSearchService.fetchByID(googleBooksID) {
            friendBookCache[googleBooksID] = fetched
            return fetched
        }
        return nil
    }

    @MainActor
    func loadFriendReviews(for googleBooksID: String) async -> [FriendReview] {
        let friendIDs = friends.map(\.id)
        guard !friendIDs.isEmpty else { return [] }
        do {
            let userBooks: [UserBook] = try await supabase
                .from("user_books")
                .select()
                .eq("google_books_id", value: googleBooksID)
                .in("user_id", values: friendIDs.map(\.uuidString))
                .eq("is_private", value: false)
                .execute()
                .value
            return userBooks
                .filter { $0.rating != nil || $0.reviewText != nil }
                .compactMap { ub in
                    guard let profile = friends.first(where: { $0.id == ub.userID }) else { return nil }
                    return FriendReview(id: ub.id, profile: profile, userBook: ub)
                }
        } catch {
            return []
        }
    }
}

struct FriendReview: Identifiable {
    let id: UUID
    let profile: Profile
    let userBook: UserBook
}

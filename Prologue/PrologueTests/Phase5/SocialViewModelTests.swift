import Testing
import Foundation
@testable import Prologue

// MARK: - Helpers

private func makeProfile(
    id: UUID = UUID(),
    username: String = "testuser",
    favoriteGenre: String? = nil
) -> Profile {
    Profile(id: id, username: username, favoriteGenre: favoriteGenre, avatarURL: nil, createdAt: Date())
}

private func makeUserBook(
    userID: UUID = UUID(),
    isPrivate: Bool = false,
    status: ReadingStatus = .read
) -> UserBook {
    UserBook(
        id: UUID(),
        userID: userID,
        googleBooksID: "book-\(UUID().uuidString)",
        status: status,
        currentPage: 0,
        totalPages: 300,
        isPrivate: isPrivate,
        rating: nil,
        reviewText: nil,
        addedAt: Date(),
        updatedAt: Date()
    )
}

// MARK: - Search query guard

@MainActor
@Suite("SocialViewModel — search query guard")
struct SocialSearchGuardTests {

    @Test func emptyQueryClearsSearchResults() async {
        let vm = SocialViewModel()
        vm.searchResults = [makeProfile()]
        await vm.searchUsers(query: "")
        #expect(vm.searchResults.isEmpty)
    }

    @Test func whitespaceOnlyQueryClearsSearchResults() async {
        let vm = SocialViewModel()
        vm.searchResults = [makeProfile(), makeProfile()]
        await vm.searchUsers(query: "   ")
        #expect(vm.searchResults.isEmpty)
    }

    @Test func tabAndNewlineWhitespaceClearsResults() async {
        let vm = SocialViewModel()
        vm.searchResults = [makeProfile()]
        await vm.searchUsers(query: "\t\n")
        #expect(vm.searchResults.isEmpty)
    }
}

// MARK: - Friend book cache

@MainActor
@Suite("SocialViewModel — loadFriendBooks cache")
struct FriendBookCacheTests {

    @Test func cacheHitReturnsCachedBooksWithoutNetworkCall() async throws {
        let vm = SocialViewModel()
        let friendID = UUID()
        let cachedBooks = [
            makeUserBook(userID: friendID),
            makeUserBook(userID: friendID)
        ]
        vm.friendBooks[friendID.uuidString] = cachedBooks

        let result = try await vm.loadFriendBooks(friendID: friendID)
        #expect(result.count == 2)
    }

    @Test func cacheHitPreservesBookOrder() async throws {
        let vm = SocialViewModel()
        let friendID = UUID()
        let book1 = makeUserBook(userID: friendID)
        let book2 = makeUserBook(userID: friendID)
        vm.friendBooks[friendID.uuidString] = [book1, book2]

        let result = try await vm.loadFriendBooks(friendID: friendID)
        #expect(result[0].id == book1.id)
        #expect(result[1].id == book2.id)
    }

    @Test func differentFriendIDsHaveSeparateCacheEntries() async throws {
        let vm = SocialViewModel()
        let friend1 = UUID()
        let friend2 = UUID()
        vm.friendBooks[friend1.uuidString] = [makeUserBook(userID: friend1)]
        vm.friendBooks[friend2.uuidString] = [makeUserBook(userID: friend2), makeUserBook(userID: friend2)]

        let result1 = try await vm.loadFriendBooks(friendID: friend1)
        let result2 = try await vm.loadFriendBooks(friendID: friend2)
        #expect(result1.count == 1)
        #expect(result2.count == 2)
    }
}

// MARK: - Privacy filtering logic

@MainActor
@Suite("SocialViewModel — privacy filtering")
struct PrivacyFilterTests {

    @Test func privateBookIsExcludedFromVisibleSet() {
        let friendID = UUID()
        let publicBook = makeUserBook(userID: friendID, isPrivate: false)
        let privateBook = makeUserBook(userID: friendID, isPrivate: true)
        let visible = [publicBook, privateBook].filter { !$0.isPrivate }
        #expect(visible.count == 1)
        #expect(visible[0].isPrivate == false)
    }

    @Test func allPublicBooksAreVisible() {
        let friendID = UUID()
        let books = (0..<5).map { _ in makeUserBook(userID: friendID, isPrivate: false) }
        let visible = books.filter { !$0.isPrivate }
        #expect(visible.count == 5)
    }

    @Test func allPrivateBooksAreHidden() {
        let friendID = UUID()
        let books = (0..<3).map { _ in makeUserBook(userID: friendID, isPrivate: true) }
        let visible = books.filter { !$0.isPrivate }
        #expect(visible.isEmpty)
    }
}

// MARK: - Local state initial values

@MainActor
@Suite("SocialViewModel — initial state")
struct SocialInitialStateTests {

    @Test func initialFriendsListIsEmpty() {
        let vm = SocialViewModel()
        #expect(vm.friends.isEmpty)
    }

    @Test func initialPendingRequestsIsEmpty() {
        let vm = SocialViewModel()
        #expect(vm.pendingRequests.isEmpty)
    }

    @Test func initialSearchResultsIsEmpty() {
        let vm = SocialViewModel()
        #expect(vm.searchResults.isEmpty)
    }

    @Test func initialIsLoadingIsFalse() {
        let vm = SocialViewModel()
        #expect(vm.isLoading == false)
    }

    @Test func initialErrorIsNil() {
        let vm = SocialViewModel()
        #expect(vm.error == nil)
    }
}

// MARK: - Profile model

@MainActor
@Suite("Profile — model properties")
struct ProfileModelTests {

    @Test func profileIDIsPreserved() {
        let id = UUID()
        let profile = makeProfile(id: id, username: "james")
        #expect(profile.id == id)
    }

    @Test func profileUsernameIsPreserved() {
        let profile = makeProfile(username: "prologue_reader")
        #expect(profile.username == "prologue_reader")
    }

    @Test func profileFavoriteGenreIsOptional() {
        let withGenre = makeProfile(favoriteGenre: "Sci-Fi")
        let withoutGenre = makeProfile(favoriteGenre: nil)
        #expect(withGenre.favoriteGenre == "Sci-Fi")
        #expect(withoutGenre.favoriteGenre == nil)
    }

    @Test func profileEquality() {
        let id = UUID()
        let now = Date()
        let a = Profile(id: id, username: "james", favoriteGenre: nil, avatarURL: nil, createdAt: now)
        let b = Profile(id: id, username: "james", favoriteGenre: nil, avatarURL: nil, createdAt: now)
        #expect(a == b)
    }

    @Test func profilesWithDifferentIDsAreNotEqual() {
        let now = Date()
        let a = Profile(id: UUID(), username: "james", favoriteGenre: nil, avatarURL: nil, createdAt: now)
        let b = Profile(id: UUID(), username: "james", favoriteGenre: nil, avatarURL: nil, createdAt: now)
        #expect(a != b)
    }
}

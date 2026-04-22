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
    googleBooksID: String = "book-\(UUID().uuidString)",
    isPrivate: Bool = false,
    status: ReadingStatus = .read,
    rating: Int? = nil
) -> UserBook {
    UserBook(
        id: UUID(),
        userID: userID,
        googleBooksID: googleBooksID,
        status: status,
        currentPage: 0,
        totalPages: 300,
        isPrivate: isPrivate,
        rating: rating,
        reviewText: nil,
        addedAt: Date(),
        updatedAt: Date()
    )
}

private func makeBook(id: String, title: String = "Test Book") -> Book {
    Book(id: id, title: title, authors: ["Author"],
         description: nil, pageCount: 200, coverURL: nil,
         isbn: nil, publishedDate: nil, publisher: nil)
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

// MARK: - loadFriendReviews

@MainActor
@Suite("SocialViewModel — loadFriendReviews")
struct FriendReviewsTests {

    @Test func returnsEmptyWhenFriendsListIsEmpty() async {
        let vm = SocialViewModel(bookSearchService: MockBookSearchService())
        let reviews = await vm.loadFriendReviews(for: "any-book-id")
        #expect(reviews.isEmpty)
    }

    @Test func friendReviewIDEqualsUserBookID() {
        let profile = makeProfile()
        let ub = makeUserBook(userID: profile.id, rating: 4)
        let review = FriendReview(id: ub.id, profile: profile, userBook: ub)
        #expect(review.id == ub.id)
    }

    @Test func friendReviewPreservesProfileAndUserBook() {
        let profile = makeProfile(username: "alice")
        let ub = makeUserBook(userID: profile.id, rating: 5)
        let review = FriendReview(id: ub.id, profile: profile, userBook: ub)
        #expect(review.profile.username == "alice")
        #expect(review.userBook.rating == 5)
    }
}

// MARK: - bookMetadata

@MainActor
@Suite("SocialViewModel — bookMetadata")
struct BookMetadataTests {

    @Test func bookMetadataReturnsCachedValueWithoutFetch() async {
        let mock = MockBookSearchService()
        mock.stubbedIDResult = makeBook(id: "cached-id", title: "Cached")
        let vm = SocialViewModel(bookSearchService: mock)
        vm.friendBookCache["cached-id"] = makeBook(id: "cached-id", title: "Already Here")
        let result = await vm.bookMetadata(for: "cached-id")
        #expect(result?.title == "Already Here")
    }

    @Test func bookMetadataFetchesAndCachesOnMiss() async {
        let mock = MockBookSearchService()
        mock.stubbedIDResult = makeBook(id: "new-id", title: "Fetched")
        let vm = SocialViewModel(bookSearchService: mock)
        let result = await vm.bookMetadata(for: "new-id")
        #expect(result?.title == "Fetched")
        #expect(vm.friendBookCache["new-id"]?.title == "Fetched")
    }

    @Test func bookMetadataReturnsNilOnFetchFailure() async {
        let mock = MockBookSearchService()
        mock.shouldThrow = true
        let vm = SocialViewModel(bookSearchService: mock)
        let result = await vm.bookMetadata(for: "bad-id")
        #expect(result == nil)
    }
}

// MARK: - friendBookCache metadata

@MainActor
@Suite("SocialViewModel — friendBookCache metadata")
struct FriendBookMetadataCacheTests {

    @Test func initialFriendBookCacheIsEmpty() {
        let vm = SocialViewModel(bookSearchService: MockBookSearchService())
        #expect(vm.friendBookCache.isEmpty)
    }

    @Test func cacheBookMetadataPopulatesCache() async {
        let mock = MockBookSearchService()
        mock.stubbedIDResult = makeBook(id: "gbooks-1", title: "Dune")
        let vm = SocialViewModel(bookSearchService: mock)
        let userBook = makeUserBook(googleBooksID: "gbooks-1")
        await vm.cacheBookMetadata(for: [userBook])
        #expect(vm.friendBookCache["gbooks-1"]?.title == "Dune")
    }

    @Test func cacheBookMetadataSkipsAlreadyCachedIDs() async {
        let mock = MockBookSearchService()
        let existing = makeBook(id: "gbooks-2", title: "Original")
        mock.stubbedIDResult = makeBook(id: "gbooks-2", title: "Replacement")
        let vm = SocialViewModel(bookSearchService: mock)
        vm.friendBookCache["gbooks-2"] = existing
        let userBook = makeUserBook(googleBooksID: "gbooks-2")
        await vm.cacheBookMetadata(for: [userBook])
        #expect(vm.friendBookCache["gbooks-2"]?.title == "Original")
    }

    @Test func cacheBookMetadataHandlesMultipleBooks() async {
        let mock = MockBookSearchService()
        mock.stubbedIDResult = makeBook(id: "any", title: "Some Book")
        let vm = SocialViewModel(bookSearchService: mock)
        let books = ["id-a", "id-b", "id-c"].map { makeUserBook(googleBooksID: $0) }
        await vm.cacheBookMetadata(for: books)
        #expect(vm.friendBookCache.count == 3)
    }

    @Test func cacheBookMetadataToleratesNilResult() async {
        let mock = MockBookSearchService()
        mock.stubbedIDResult = nil
        let vm = SocialViewModel(bookSearchService: mock)
        let userBook = makeUserBook(googleBooksID: "unknown-id")
        await vm.cacheBookMetadata(for: [userBook])
        #expect(vm.friendBookCache.isEmpty)
    }

    @Test func cacheBookMetadataToleratesServiceError() async {
        let mock = MockBookSearchService()
        mock.shouldThrow = true
        let vm = SocialViewModel(bookSearchService: mock)
        let userBook = makeUserBook(googleBooksID: "error-id")
        await vm.cacheBookMetadata(for: [userBook])
        #expect(vm.friendBookCache.isEmpty)
    }
}

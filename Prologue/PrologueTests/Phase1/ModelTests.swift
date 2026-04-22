import Testing
import Foundation
@testable import Prologue

// MARK: - ReadingStatus

@Suite("ReadingStatus")
struct ReadingStatusTests {

    @Test func rawValuesMatchDatabase() {
        #expect(ReadingStatus.wantToRead.rawValue == "want_to_read")
        #expect(ReadingStatus.inProgress.rawValue == "in_progress")
        #expect(ReadingStatus.read.rawValue == "read")
        #expect(ReadingStatus.dnf.rawValue == "dnf")
    }

    @Test func allCasesCount() {
        #expect(ReadingStatus.allCases.count == 4)
    }

    @Test func displayNames() {
        #expect(ReadingStatus.wantToRead.displayName == "Want to Read")
        #expect(ReadingStatus.inProgress.displayName == "In Progress")
        #expect(ReadingStatus.read.displayName == "Read")
        #expect(ReadingStatus.dnf.displayName == "Did Not Finish")
    }

    @Test func roundTripsFromRawValue() throws {
        for status in ReadingStatus.allCases {
            let recovered = try #require(ReadingStatus(rawValue: status.rawValue))
            #expect(recovered == status)
        }
    }
}

// MARK: - UserBook computed properties

@Suite("UserBook computed properties")
struct UserBookComputedTests {

    private func makeUserBook(currentPage: Int, totalPages: Int?) -> UserBook {
        UserBook(
            id: UUID(),
            userID: UUID(),
            googleBooksID: "abc123",
            status: .inProgress,
            currentPage: currentPage,
            totalPages: totalPages,
            isPrivate: false,
            rating: nil,
            reviewText: nil,
            addedAt: Date(),
            updatedAt: Date()
        )
    }

    @Test func progressPercentMidway() {
        let book = makeUserBook(currentPage: 150, totalPages: 300)
        #expect(book.progressPercent == 50.0)
    }

    @Test func progressPercentComplete() {
        let book = makeUserBook(currentPage: 300, totalPages: 300)
        #expect(book.progressPercent == 100.0)
    }

    @Test func progressPercentNoPages() {
        let book = makeUserBook(currentPage: 0, totalPages: nil)
        #expect(book.progressPercent == 0.0)
    }

    @Test func progressPercentZeroTotalGuardsAgainstDivision() {
        let book = makeUserBook(currentPage: 10, totalPages: 0)
        #expect(book.progressPercent == 0.0)
    }

    @Test func estimatedWordsRead() {
        let book = makeUserBook(currentPage: 100, totalPages: 300)
        #expect(book.estimatedWordsRead == 27_500)
    }

    @Test func estimatedTotalWords() {
        let book = makeUserBook(currentPage: 0, totalPages: 400)
        #expect(book.estimatedTotalWords == 110_000)
    }

    @Test func estimatedTotalWordsNilPages() {
        let book = makeUserBook(currentPage: 0, totalPages: nil)
        #expect(book.estimatedTotalWords == 0)
    }
}

// MARK: - UserBook JSON decoding (simulates Supabase response)

@Suite("UserBook JSON decoding")
struct UserBookDecodingTests {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    @Test func decodesFullRecord() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "user_id": "22222222-2222-2222-2222-222222222222",
          "google_books_id": "zyTCAlFPjgYC",
          "status": "in_progress",
          "current_page": 42,
          "total_pages": 310,
          "is_private": false,
          "rating": 4,
          "review_text": "Great so far",
          "added_at": "2026-01-01T00:00:00Z",
          "updated_at": "2026-04-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let book = try decoder.decode(UserBook.self, from: json)
        #expect(book.googleBooksID == "zyTCAlFPjgYC")
        #expect(book.status == .inProgress)
        #expect(book.currentPage == 42)
        #expect(book.totalPages == 310)
        #expect(book.isPrivate == false)
        #expect(book.rating == 4)
        #expect(book.reviewText == "Great so far")
    }

    @Test func decodesNullableFields() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "user_id": "22222222-2222-2222-2222-222222222222",
          "google_books_id": "zyTCAlFPjgYC",
          "status": "want_to_read",
          "current_page": 0,
          "total_pages": null,
          "is_private": true,
          "rating": null,
          "review_text": null,
          "added_at": "2026-01-01T00:00:00Z",
          "updated_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let book = try decoder.decode(UserBook.self, from: json)
        #expect(book.totalPages == nil)
        #expect(book.rating == nil)
        #expect(book.reviewText == nil)
        #expect(book.isPrivate == true)
    }
}

// MARK: - Profile JSON decoding

@Suite("Profile JSON decoding")
struct ProfileDecodingTests {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    @Test func decodesFullProfile() throws {
        let json = """
        {
          "id": "33333333-3333-3333-3333-333333333333",
          "username": "jamesclabby",
          "favorite_genre": "Science Fiction",
          "avatar_url": "https://example.com/avatar.png",
          "created_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let profile = try decoder.decode(Profile.self, from: json)
        #expect(profile.username == "jamesclabby")
        #expect(profile.favoriteGenre == "Science Fiction")
        #expect(profile.avatarURL == "https://example.com/avatar.png")
    }

    @Test func decodesOptionalFields() throws {
        let json = """
        {
          "id": "33333333-3333-3333-3333-333333333333",
          "username": "reader",
          "favorite_genre": null,
          "avatar_url": null,
          "created_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let profile = try decoder.decode(Profile.self, from: json)
        #expect(profile.favoriteGenre == nil)
        #expect(profile.avatarURL == nil)
    }
}

// MARK: - Book model

@Suite("Book model")
struct BookModelTests {

    @Test func estimatedWordCount() {
        let book = Book(
            id: "abc", title: "Dune", authors: ["Frank Herbert"],
            description: nil, pageCount: 412,
            coverURL: nil, isbn: nil, publishedDate: nil, publisher: nil
        )
        #expect(book.estimatedWordCount == 412 * 275)
    }

    @Test func estimatedWordCountNilPages() {
        let book = Book(
            id: "abc", title: "Unknown", authors: [],
            description: nil, pageCount: nil,
            coverURL: nil, isbn: nil, publishedDate: nil, publisher: nil
        )
        #expect(book.estimatedWordCount == 0)
    }

    @Test func authorsDisplay() {
        let book = Book(
            id: "abc", title: "Good Omens",
            authors: ["Terry Pratchett", "Neil Gaiman"],
            description: nil, pageCount: nil,
            coverURL: nil, isbn: nil, publishedDate: nil, publisher: nil
        )
        #expect(book.authorsDisplay == "Terry Pratchett, Neil Gaiman")
    }

    @Test func mapsFromGoogleBookItem() {
        let item = GoogleBookItem(
            id: "zyTCAlFPjgYC",
            volumeInfo: VolumeInfo(
                title: "The Hobbit",
                authors: ["J.R.R. Tolkien"],
                description: "A fantasy novel",
                pageCount: 310,
                imageLinks: ImageLinks(
                    thumbnail: "http://books.google.com/thumbnail.jpg",
                    smallThumbnail: nil
                ),
                industryIdentifiers: [
                    IndustryIdentifier(type: "ISBN_13", identifier: "9780261102217")
                ],
                publishedDate: "1937",
                publisher: "George Allen & Unwin",
                categories: nil
            )
        )

        let book = Book(from: item)
        #expect(book.id == "zyTCAlFPjgYC")
        #expect(book.title == "The Hobbit")
        #expect(book.authors == ["J.R.R. Tolkien"])
        #expect(book.pageCount == 310)
        #expect(book.isbn == "9780261102217")
        // http thumbnail must be upgraded to https
        #expect(book.coverURL?.scheme == "https")
    }

    @Test func prefersISBN13OverISBN10() {
        let item = GoogleBookItem(
            id: "x",
            volumeInfo: VolumeInfo(
                title: "Test", authors: nil, description: nil, pageCount: nil,
                imageLinks: nil,
                industryIdentifiers: [
                    IndustryIdentifier(type: "ISBN_10", identifier: "0261102214"),
                    IndustryIdentifier(type: "ISBN_13", identifier: "9780261102217")
                ],
                publishedDate: nil, publisher: nil,
                categories: nil
            )
        )
        #expect(Book(from: item).isbn == "9780261102217")
    }
}

// MARK: - Friendship

@Suite("Friendship JSON decoding")
struct FriendshipDecodingTests {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    @Test func decodesAcceptedFriendship() throws {
        let json = """
        {
          "id": "44444444-4444-4444-4444-444444444444",
          "requester_id": "11111111-1111-1111-1111-111111111111",
          "receiver_id": "22222222-2222-2222-2222-222222222222",
          "status": "accepted",
          "created_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let f = try decoder.decode(Friendship.self, from: json)
        #expect(f.status == .accepted)
    }

    @Test func decodesPendingFriendship() throws {
        let json = """
        {
          "id": "44444444-4444-4444-4444-444444444444",
          "requester_id": "11111111-1111-1111-1111-111111111111",
          "receiver_id": "22222222-2222-2222-2222-222222222222",
          "status": "pending",
          "created_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let f = try decoder.decode(Friendship.self, from: json)
        #expect(f.status == .pending)
    }
}

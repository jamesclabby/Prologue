import Foundation
import Supabase
import Observation

@Observable
final class LibraryViewModel {
    var userBooks: [UserBook] = []
    var bookCache: [String: Book] = [:]
    var isLoading = false
    var error: Error?

    private let supabase = SupabaseManager.shared.client
    private let searchService: BookSearchServiceProtocol

    init(searchService: BookSearchServiceProtocol = BookSearchService()) {
        self.searchService = searchService
    }

    func books(for status: ReadingStatus) -> [UserBook] {
        userBooks.filter { $0.status == status }
    }

    @MainActor
    func loadLibrary(userID: UUID) async {
        isLoading = true
        error = nil
        do {
            let fetched: [UserBook] = try await supabase
                .from("user_books")
                .select()
                .eq("user_id", value: userID)
                .order("updated_at", ascending: false)
                .execute()
                .value
            userBooks = fetched
            await fetchMissingBookMetadata()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    @MainActor
    func addBook(_ book: Book, status: ReadingStatus, userID: UUID) async throws {
        let insert = UserBookInsert(
            userID: userID,
            googleBooksID: book.id,
            status: status,
            totalPages: book.pageCount
        )
        let created: UserBook = try await supabase
            .from("user_books")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        userBooks.insert(created, at: 0)
        bookCache[book.id] = book
    }

    @MainActor
    func updateProgress(userBook: UserBook) async throws {
        let update = UserBookUpdate(
            status: userBook.status,
            currentPage: userBook.currentPage,
            isPrivate: userBook.isPrivate,
            rating: userBook.rating,
            reviewText: userBook.reviewText,
            updatedAt: Date()
        )
        try await supabase
            .from("user_books")
            .update(update)
            .eq("id", value: userBook.id)
            .execute()

        if let idx = userBooks.firstIndex(where: { $0.id == userBook.id }) {
            userBooks[idx] = userBook
        }
    }

    @MainActor
    func removeBook(userBook: UserBook) async throws {
        try await supabase
            .from("user_books")
            .delete()
            .eq("id", value: userBook.id)
            .execute()
        userBooks.removeAll { $0.id == userBook.id }
    }

    private func fetchMissingBookMetadata() async {
        let missing = userBooks
            .map(\.googleBooksID)
            .filter { bookCache[$0] == nil }
        // Fetch in small batches to avoid rate limits
        for id in missing.prefix(20) {
            guard let book = try? await searchService.fetchByID(id) else { continue }
            bookCache[id] = book
        }
    }
}

private struct UserBookUpdate: Encodable {
    let status: ReadingStatus
    let currentPage: Int
    let isPrivate: Bool
    let rating: Int?
    let reviewText: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case status
        case currentPage = "current_page"
        case isPrivate = "is_private"
        case rating
        case reviewText = "review_text"
        case updatedAt = "updated_at"
    }
}

private struct UserBookInsert: Encodable {
    let userID: UUID
    let googleBooksID: String
    let status: ReadingStatus
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case googleBooksID = "google_books_id"
        case status
        case totalPages = "total_pages"
    }
}

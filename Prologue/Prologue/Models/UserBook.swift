import Foundation

enum ReadingStatus: String, Codable, CaseIterable {
    case wantToRead = "want_to_read"
    case inProgress = "in_progress"
    case read = "read"
    case dnf = "dnf"

    var displayName: String {
        switch self {
        case .wantToRead: return "Want to Read"
        case .inProgress: return "In Progress"
        case .read: return "Read"
        case .dnf: return "Did Not Finish"
        }
    }
}

struct UserBook: Codable, Identifiable, Equatable {
    let id: UUID
    let userID: UUID
    let googleBooksID: String
    var status: ReadingStatus
    var currentPage: Int
    var totalPages: Int?
    var isPrivate: Bool
    var rating: Int?
    var reviewText: String?
    let addedAt: Date
    var updatedAt: Date

    var progressPercent: Double {
        guard let total = totalPages, total > 0 else { return 0 }
        return Double(currentPage) / Double(total) * 100
    }

    var estimatedWordsRead: Int {
        currentPage * 275
    }

    var estimatedTotalWords: Int {
        (totalPages ?? 0) * 275
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case googleBooksID = "google_books_id"
        case status
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case isPrivate = "is_private"
        case rating
        case reviewText = "review_text"
        case addedAt = "added_at"
        case updatedAt = "updated_at"
    }
}

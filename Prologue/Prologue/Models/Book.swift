import Foundation

struct Book: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let authors: [String]
    let description: String?
    let pageCount: Int?
    let coverURL: URL?
    let isbn: String?
    let publishedDate: String?
    let publisher: String?

    var estimatedWordCount: Int {
        (pageCount ?? 0) * 275
    }

    var authorsDisplay: String {
        authors.joined(separator: ", ")
    }
}

// MARK: - Google Books API Response Mapping

struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
    let publishedDate: String?
    let publisher: String?
}

struct ImageLinks: Codable {
    let thumbnail: String?
    let smallThumbnail: String?
}

struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

extension Book {
    init(from item: GoogleBookItem) {
        let info = item.volumeInfo
        let isbn = info.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
            ?? info.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier

        // Google Books returns http thumbnails — force https
        let thumbnailString = info.imageLinks?.thumbnail?.replacingOccurrences(of: "http://", with: "https://")
        let coverURL = thumbnailString.flatMap { URL(string: $0) }

        self.init(
            id: item.id,
            title: info.title,
            authors: info.authors ?? [],
            description: info.description,
            pageCount: info.pageCount,
            coverURL: coverURL,
            isbn: isbn,
            publishedDate: info.publishedDate,
            publisher: info.publisher
        )
    }
}

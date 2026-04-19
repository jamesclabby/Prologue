import Foundation

final class BookSearchService: BookSearchServiceProtocol {
    private let session: URLSession
    private let apiKey: String
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"

    init(session: URLSession = .shared, apiKey: String = Config.googleBooksAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    func search(query: String) async throws -> [Book] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "20"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        return response.items?.map(Book.init) ?? []
    }

    func fetchByISBN(_ isbn: String) async throws -> Book? {
        try await search(query: "isbn:\(isbn)").first
    }

    func fetchByID(_ googleBooksID: String) async throws -> Book? {
        let url = URL(string: "\(baseURL)/\(googleBooksID)?key=\(apiKey)")!
        let (data, _) = try await session.data(from: url)
        let item = try JSONDecoder().decode(GoogleBookItem.self, from: data)
        return Book(from: item)
    }
}

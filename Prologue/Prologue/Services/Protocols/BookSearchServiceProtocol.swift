import Foundation

protocol BookSearchServiceProtocol {
    func search(query: String) async throws -> [Book]
    func fetchByISBN(_ isbn: String) async throws -> Book?
    func fetchByID(_ googleBooksID: String) async throws -> Book?
}

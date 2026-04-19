import Foundation
@testable import Prologue

final class MockBookSearchService: BookSearchServiceProtocol {
    var stubbedResults: [Book] = []
    var stubbedISBNResult: Book? = nil
    var stubbedIDResult: Book? = nil
    var shouldThrow = false

    private(set) var lastSearchQuery: String?
    private(set) var lastISBNQuery: String?
    private(set) var searchCallCount = 0
    private(set) var isbnCallCount = 0

    func search(query: String) async throws -> [Book] {
        searchCallCount += 1
        lastSearchQuery = query
        if shouldThrow { throw MockError.intentional }
        return stubbedResults
    }

    func fetchByISBN(_ isbn: String) async throws -> Book? {
        isbnCallCount += 1
        lastISBNQuery = isbn
        if shouldThrow { throw MockError.intentional }
        return stubbedISBNResult
    }

    func fetchByID(_ googleBooksID: String) async throws -> Book? {
        if shouldThrow { throw MockError.intentional }
        return stubbedIDResult
    }
}

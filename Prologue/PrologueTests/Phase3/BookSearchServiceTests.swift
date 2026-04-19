import Testing
import Foundation
@testable import Prologue

// MARK: - Fixtures

private let singleBookJSON = """
{
  "items": [
    {
      "id": "zyTCAlFPjgYC",
      "volumeInfo": {
        "title": "The Hobbit",
        "authors": ["J.R.R. Tolkien"],
        "description": "A fantasy classic.",
        "pageCount": 310,
        "publishedDate": "1937",
        "publisher": "George Allen & Unwin",
        "imageLinks": {
          "thumbnail": "http://books.google.com/books/content?id=zyTCAlFPjgYC&zoom=1",
          "smallThumbnail": "http://books.google.com/books/content?id=zyTCAlFPjgYC&zoom=5"
        },
        "industryIdentifiers": [
          { "type": "ISBN_13", "identifier": "9780261102217" },
          { "type": "ISBN_10", "identifier": "0261102214" }
        ]
      }
    }
  ]
}
"""

private let emptyResponseJSON = """
{ "totalItems": 0 }
"""

private let multiBookJSON = """
{
  "items": [
    {
      "id": "book1",
      "volumeInfo": { "title": "Book One", "authors": ["Author A"], "pageCount": 200, "industryIdentifiers": [] }
    },
    {
      "id": "book2",
      "volumeInfo": { "title": "Book Two", "authors": ["Author B"], "pageCount": 350, "industryIdentifiers": [] }
    }
  ]
}
"""

// MARK: - URL capture helper
// Local `var` can't safely be mutated across actor boundaries from URLProtocol's thread.
// A class reference is shared by value and mutation is visible across contexts.
private final class URLCapture: @unchecked Sendable {
    var url: URL?
}

// MARK: - BookSearchService tests
// .serialized prevents parallel execution, which matters because MockURLProtocol.requestHandler
// is a static var shared across all tests in this process.
@Suite("BookSearchService", .serialized)
struct BookSearchServiceTests {

    private func makeService() -> BookSearchService {
        BookSearchService(session: MockURLProtocol.makeSession(), apiKey: "test-key")
    }

    // MARK: search(query:)

    @Test func searchReturnsParsedBooks() async throws {
        MockURLProtocol.stub(json: singleBookJSON)
        let results = try await makeService().search(query: "Hobbit")
        #expect(results.count == 1)
        #expect(results[0].title == "The Hobbit")
        #expect(results[0].authors == ["J.R.R. Tolkien"])
        #expect(results[0].pageCount == 310)
        #expect(results[0].isbn == "9780261102217")
    }

    @Test func searchReturnsEmptyForNoItems() async throws {
        MockURLProtocol.stub(json: emptyResponseJSON)
        let results = try await makeService().search(query: "xyzzy")
        #expect(results.isEmpty)
    }

    @Test func searchReturnsMultipleResults() async throws {
        MockURLProtocol.stub(json: multiBookJSON)
        let results = try await makeService().search(query: "book")
        #expect(results.count == 2)
    }

    @Test func searchReturnsEmptyForBlankQuery() async throws {
        let results = try await makeService().search(query: "   ")
        #expect(results.isEmpty)
    }

    @Test func searchUpgradesCoverURLToHTTPS() async throws {
        MockURLProtocol.stub(json: singleBookJSON)
        let results = try await makeService().search(query: "Hobbit")
        let url = try #require(results[0].coverURL)
        #expect(url.scheme == "https")
    }

    @Test func searchIncludesQueryInURL() async throws {
        let capture = URLCapture()
        MockURLProtocol.requestHandler = { request in
            capture.url = request.url
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(singleBookJSON.utf8))
        }
        _ = try await makeService().search(query: "Tolkien")
        let urlString = try #require(capture.url?.absoluteString)
        #expect(urlString.contains("Tolkien"))
        #expect(urlString.contains("key=test-key"))
    }

    @Test func searchThrowsOnNetworkError() async {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        await #expect(throws: URLError.self) {
            try await makeService().search(query: "anything")
        }
    }

    // MARK: fetchByISBN

    @Test func fetchByISBNReturnsSingleBook() async throws {
        MockURLProtocol.stub(json: singleBookJSON)
        let book = try await makeService().fetchByISBN("9780261102217")
        #expect(book?.title == "The Hobbit")
    }

    @Test func fetchByISBNReturnsNilForNoResults() async throws {
        MockURLProtocol.stub(json: emptyResponseJSON)
        let book = try await makeService().fetchByISBN("0000000000000")
        #expect(book == nil)
    }

    @Test func fetchByISBNPassesISBNAsQuery() async throws {
        let capture = URLCapture()
        MockURLProtocol.requestHandler = { request in
            capture.url = request.url
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(emptyResponseJSON.utf8))
        }
        _ = try await makeService().fetchByISBN("9780261102217")
        let urlString = try #require(capture.url?.absoluteString)
        #expect(urlString.contains("isbn:9780261102217"))
    }

    // MARK: Word count

    @Test func estimatedWordCountIsPageCountTimes275() async throws {
        MockURLProtocol.stub(json: singleBookJSON)
        let results = try await makeService().search(query: "Hobbit")
        let book = try #require(results.first)
        #expect(book.estimatedWordCount == 310 * 275)
    }
}

// MARK: - SearchViewModel

@Suite("SearchViewModel")
struct SearchViewModelTests {

    @Test func initialStateIsEmpty() {
        let vm = SearchViewModel(searchService: MockBookSearchService())
        #expect(vm.results.isEmpty)
        #expect(vm.query == "")
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test func searchPopulatesResults() async {
        let mock = MockBookSearchService()
        mock.stubbedResults = [
            Book(id: "1", title: "Dune", authors: ["Frank Herbert"],
                 description: nil, pageCount: 412, coverURL: nil,
                 isbn: nil, publishedDate: nil, publisher: nil)
        ]
        let vm = SearchViewModel(searchService: mock)
        await vm.search(query: "Dune")
        #expect(vm.results.count == 1)
        #expect(vm.results[0].title == "Dune")
    }

    @Test func searchClearsErrorOnNewAttempt() async {
        let mock = MockBookSearchService()
        mock.shouldThrow = true
        let vm = SearchViewModel(searchService: mock)
        await vm.search(query: "anything")
        #expect(vm.error != nil)

        mock.shouldThrow = false
        mock.stubbedResults = []
        await vm.search(query: "anything")
        #expect(vm.error == nil)
    }

    @Test func searchStoresErrorOnFailure() async {
        let mock = MockBookSearchService()
        mock.shouldThrow = true
        let vm = SearchViewModel(searchService: mock)
        await vm.search(query: "fail")
        #expect(vm.error != nil)
        #expect(vm.results.isEmpty)
    }

    @Test func isLoadingFalseAfterSearchCompletes() async {
        let mock = MockBookSearchService()
        let vm = SearchViewModel(searchService: mock)
        await vm.search(query: "test")
        #expect(vm.isLoading == false)
    }

    @Test func fetchByISBNPopulatesResults() async {
        let mock = MockBookSearchService()
        mock.stubbedISBNResult = Book(
            id: "isbn-book", title: "Found By ISBN", authors: ["Author"],
            description: nil, pageCount: 200, coverURL: nil,
            isbn: "9780261102217", publishedDate: nil, publisher: nil
        )
        let vm = SearchViewModel(searchService: mock)
        await vm.fetchByISBN("9780261102217")
        #expect(vm.results.count == 1)
        #expect(vm.results[0].title == "Found By ISBN")
        #expect(mock.lastISBNQuery == "9780261102217")
    }

    @Test func onQueryChangedWithEmptyStringClearsResults() async {
        let mock = MockBookSearchService()
        mock.stubbedResults = [
            Book(id: "1", title: "Test", authors: [], description: nil,
                 pageCount: nil, coverURL: nil, isbn: nil, publishedDate: nil, publisher: nil)
        ]
        let vm = SearchViewModel(searchService: mock)
        await vm.search(query: "test")
        #expect(vm.results.count == 1)
        vm.onQueryChanged("")
        #expect(vm.results.isEmpty)
    }
}

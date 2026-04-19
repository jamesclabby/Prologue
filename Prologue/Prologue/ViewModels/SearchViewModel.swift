import Foundation
import Observation

@Observable
final class SearchViewModel {
    var query = ""
    var results: [Book] = []
    var isLoading = false
    var error: Error?

    private let searchService: BookSearchServiceProtocol
    private var searchTask: Task<Void, Never>?

    init(searchService: BookSearchServiceProtocol = BookSearchService()) {
        self.searchService = searchService
    }

    func onQueryChanged(_ newQuery: String) {
        searchTask?.cancel()
        guard !newQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await search(query: newQuery)
        }
    }

    @MainActor
    func search(query: String) async {
        isLoading = true
        error = nil
        do {
            results = try await searchService.search(query: query)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    @MainActor
    func fetchByISBN(_ isbn: String) async {
        isLoading = true
        error = nil
        do {
            if let book = try await searchService.fetchByISBN(isbn) {
                results = [book]
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

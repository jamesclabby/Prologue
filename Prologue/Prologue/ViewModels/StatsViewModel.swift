import Foundation
import Observation
import Supabase

@Observable
final class StatsViewModel {
    var readBooks: [UserBook] = []
    var annualGoal: Int {
        get { UserDefaults.standard.integer(forKey: "annualGoal") == 0 ? 12 : UserDefaults.standard.integer(forKey: "annualGoal") }
        set { UserDefaults.standard.set(newValue, forKey: "annualGoal") }
    }
    var isLoading = false
    var error: Error?

    private let supabase = SupabaseManager.shared.client

    var totalBooksRead: Int { readBooks.count }

    var totalWordsRead: Int {
        // For completed books use total pages (not current page) — a book marked "read"
        // may have been moved from in-progress at any page count.
        readBooks.reduce(0) { sum, book in
            sum + (book.estimatedTotalWords > 0 ? book.estimatedTotalWords : book.estimatedWordsRead)
        }
    }

    var annualProgress: Double {
        guard annualGoal > 0 else { return 0 }
        let thisYear = Calendar.current.component(.year, from: Date())
        let count = readBooks.filter {
            Calendar.current.component(.year, from: $0.updatedAt) == thisYear
        }.count
        return min(Double(count) / Double(annualGoal), 1.0)
    }

    func booksRead(in component: Calendar.Component) -> [(key: Date, value: Int)] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: readBooks) { book -> Date in
            let comps = cal.dateComponents([.year, .month, .weekOfYear], from: book.updatedAt)
            return cal.date(from: comps) ?? book.updatedAt
        }
        return grouped.map { (key: $0.key, value: $0.value.count) }
            .sorted { $0.key < $1.key }
    }

    @MainActor
    func loadStats(userID: UUID) async {
        isLoading = true
        error = nil
        do {
            readBooks = try await supabase
                .from("user_books")
                .select()
                .eq("user_id", value: userID)
                .eq("status", value: "read")
                .execute()
                .value
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

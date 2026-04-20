import Testing
import Foundation
@testable import Prologue

// MARK: - Helpers

private func makeReadBook(
    totalPages: Int? = 300,
    currentPage: Int = 0,
    updatedAt: Date = Date()
) -> UserBook {
    UserBook(
        id: UUID(),
        userID: UUID(),
        googleBooksID: "book-\(UUID().uuidString)",
        status: .read,
        currentPage: currentPage,
        totalPages: totalPages,
        isPrivate: false,
        rating: nil,
        reviewText: nil,
        addedAt: Date(),
        updatedAt: updatedAt
    )
}

private func dateInYear(_ year: Int) -> Date {
    var comps = DateComponents()
    comps.year = year
    comps.month = 6
    comps.day = 1
    return Calendar.current.date(from: comps)!
}

private func dateInMonth(year: Int, month: Int) -> Date {
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = 15
    return Calendar.current.date(from: comps)!
}

// All Phase 6 tests are serialized because annualGoal uses UserDefaults.standard,
// which is global state shared across the test process.
@MainActor
@Suite("StatsViewModel", .serialized)
struct StatsViewModelTests {

    // MARK: - totalBooksRead

    @Suite("totalBooksRead")
    struct TotalBooksReadTests {

        @Test func zeroWhenNoBooksRead() {
            let vm = StatsViewModel()
            vm.readBooks = []
            #expect(vm.totalBooksRead == 0)
        }

        @Test func countMatchesReadBooksArray() {
            let vm = StatsViewModel()
            vm.readBooks = [makeReadBook(), makeReadBook(), makeReadBook()]
            #expect(vm.totalBooksRead == 3)
        }

        @Test func singleBook() {
            let vm = StatsViewModel()
            vm.readBooks = [makeReadBook()]
            #expect(vm.totalBooksRead == 1)
        }
    }

    // MARK: - totalWordsRead

    @Suite("totalWordsRead")
    struct TotalWordsReadTests {

        @Test func usesTotalPagesForCompletedBooks() {
            let vm = StatsViewModel()
            // 300 pages × 275 words/page = 82,500
            vm.readBooks = [makeReadBook(totalPages: 300, currentPage: 50)]
            #expect(vm.totalWordsRead == 82500)
        }

        @Test func fallsBackToCurrentPageWhenNoTotalPages() {
            let vm = StatsViewModel()
            // totalPages nil → estimatedTotalWords = 0 → falls back to estimatedWordsRead
            // currentPage 100 × 275 = 27,500
            vm.readBooks = [makeReadBook(totalPages: nil, currentPage: 100)]
            #expect(vm.totalWordsRead == 27500)
        }

        @Test func sumAcrossMultipleBooks() {
            let vm = StatsViewModel()
            // 200 + 400 = 600 pages × 275 = 165,000
            vm.readBooks = [makeReadBook(totalPages: 200), makeReadBook(totalPages: 400)]
            #expect(vm.totalWordsRead == 165000)
        }

        @Test func zeroWhenNoBooksRead() {
            let vm = StatsViewModel()
            vm.readBooks = []
            #expect(vm.totalWordsRead == 0)
        }

        @Test func mixedTotalPagesAndNil() {
            let vm = StatsViewModel()
            // Book A: 300 total → 82,500; Book B: nil total, 100 current → 27,500
            vm.readBooks = [
                makeReadBook(totalPages: 300, currentPage: 0),
                makeReadBook(totalPages: nil, currentPage: 100)
            ]
            #expect(vm.totalWordsRead == 110000)
        }
    }

    // MARK: - annualProgress

    @Suite("annualProgress")
    struct AnnualProgressTests {

        @Test func progressIsProportionOfGoal() {
            UserDefaults.standard.removeObject(forKey: "annualGoal")
            let vm = StatsViewModel()
            vm.annualGoal = 12
            vm.readBooks = (0..<6).map { _ in makeReadBook(updatedAt: Date()) }
            #expect(vm.annualProgress == 0.5)
            UserDefaults.standard.removeObject(forKey: "annualGoal")
        }

        @Test func progressCappedAtOneWhenGoalExceeded() {
            UserDefaults.standard.removeObject(forKey: "annualGoal")
            let vm = StatsViewModel()
            vm.annualGoal = 5
            vm.readBooks = (0..<10).map { _ in makeReadBook(updatedAt: Date()) }
            #expect(vm.annualProgress == 1.0)
            UserDefaults.standard.removeObject(forKey: "annualGoal")
        }

        @Test func progressIsZeroWithNoBooks() {
            UserDefaults.standard.removeObject(forKey: "annualGoal")
            let vm = StatsViewModel()
            vm.annualGoal = 12
            vm.readBooks = []
            #expect(vm.annualProgress == 0)
            UserDefaults.standard.removeObject(forKey: "annualGoal")
        }

        @Test func booksFromPriorYearDontCountTowardProgress() {
            UserDefaults.standard.removeObject(forKey: "annualGoal")
            let vm = StatsViewModel()
            vm.annualGoal = 10
            let lastYear = dateInYear(Calendar.current.component(.year, from: Date()) - 1)
            vm.readBooks = (0..<5).map { _ in makeReadBook(updatedAt: lastYear) }
            #expect(vm.annualProgress == 0)
            UserDefaults.standard.removeObject(forKey: "annualGoal")
        }

        @Test func onlyCurrentYearBooksCountTowardProgress() {
            UserDefaults.standard.removeObject(forKey: "annualGoal")
            let vm = StatsViewModel()
            vm.annualGoal = 4
            let thisYear = Date()
            let lastYear = dateInYear(Calendar.current.component(.year, from: Date()) - 1)
            vm.readBooks = [
                makeReadBook(updatedAt: thisYear),
                makeReadBook(updatedAt: thisYear),
                makeReadBook(updatedAt: lastYear)
            ]
            #expect(vm.annualProgress == 0.5)
            UserDefaults.standard.removeObject(forKey: "annualGoal")
        }
    }

    // MARK: - booksRead(in:)

    @Suite("booksRead grouping")
    struct BooksReadGroupingTests {

        @Test func groupsByMonthCorrectly() {
            let vm = StatsViewModel()
            let jan = dateInMonth(year: 2026, month: 1)
            let feb = dateInMonth(year: 2026, month: 2)
            vm.readBooks = [
                makeReadBook(updatedAt: jan),
                makeReadBook(updatedAt: jan),
                makeReadBook(updatedAt: feb)
            ]
            let result = vm.booksRead(in: .month)
            #expect(result.count == 2)
            #expect(result.reduce(0) { $0 + $1.value } == 3)
        }

        @Test func groupsByYearCorrectly() {
            let vm = StatsViewModel()
            vm.readBooks = [
                makeReadBook(updatedAt: dateInYear(2025)),
                makeReadBook(updatedAt: dateInYear(2026)),
                makeReadBook(updatedAt: dateInYear(2026))
            ]
            let result = vm.booksRead(in: .year)
            #expect(result.count == 2)
        }

        @Test func resultIsSortedAscendingByDate() {
            let vm = StatsViewModel()
            vm.readBooks = [
                makeReadBook(updatedAt: dateInMonth(year: 2026, month: 3)),
                makeReadBook(updatedAt: dateInMonth(year: 2026, month: 1))
            ]
            let result = vm.booksRead(in: .month)
            #expect(result.first!.key < result.last!.key)
        }

        @Test func emptyLibraryProducesEmptyGrouping() {
            let vm = StatsViewModel()
            vm.readBooks = []
            #expect(vm.booksRead(in: .month).isEmpty)
        }

        @Test func singleBookProducesOneGroup() {
            let vm = StatsViewModel()
            vm.readBooks = [makeReadBook(updatedAt: Date())]
            let result = vm.booksRead(in: .month)
            #expect(result.count == 1)
            #expect(result[0].value == 1)
        }
    }

    // MARK: - annualGoal UserDefaults persistence

    @Suite("annualGoal persistence")
    struct AnnualGoalTests {

        @Test func defaultGoalIsTwelve() {
            UserDefaults.standard.removeObject(forKey: "annualGoal")
            let vm = StatsViewModel()
            #expect(vm.annualGoal == 12)
        }

        @Test func setGoalPersistsToUserDefaults() {
            UserDefaults.standard.removeObject(forKey: "annualGoal")
            let vm = StatsViewModel()
            vm.annualGoal = 24
            #expect(UserDefaults.standard.integer(forKey: "annualGoal") == 24)
            UserDefaults.standard.removeObject(forKey: "annualGoal")
        }

        @Test func newViewModelReadsPersistedGoal() {
            UserDefaults.standard.set(20, forKey: "annualGoal")
            let vm = StatsViewModel()
            #expect(vm.annualGoal == 20)
            UserDefaults.standard.removeObject(forKey: "annualGoal")
        }
    }

    // MARK: - Initial state

    @Suite("initial state")
    struct StatsInitialStateTests {

        @Test func initialReadBooksIsEmpty() {
            let vm = StatsViewModel()
            #expect(vm.readBooks.isEmpty)
        }

        @Test func initialIsLoadingIsFalse() {
            let vm = StatsViewModel()
            #expect(vm.isLoading == false)
        }

        @Test func initialErrorIsNil() {
            let vm = StatsViewModel()
            #expect(vm.error == nil)
        }
    }
}

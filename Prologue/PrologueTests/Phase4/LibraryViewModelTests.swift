import Testing
import Foundation
@testable import Prologue

// MARK: - Helpers

private func makeUserBook(
    id: UUID = UUID(),
    userID: UUID = UUID(),
    googleBooksID: String = "book-id",
    status: ReadingStatus,
    currentPage: Int = 0,
    totalPages: Int? = nil,
    isPrivate: Bool = false,
    rating: Int? = nil,
    reviewText: String? = nil,
    updatedAt: Date = Date()
) -> UserBook {
    UserBook(
        id: id,
        userID: userID,
        googleBooksID: googleBooksID,
        status: status,
        currentPage: currentPage,
        totalPages: totalPages,
        isPrivate: isPrivate,
        rating: rating,
        reviewText: reviewText,
        addedAt: Date(),
        updatedAt: updatedAt
    )
}

// MARK: - Library filtering

@MainActor
@Suite("LibraryViewModel — status filtering")
struct LibraryStatusFilterTests {

    @Test func filterByWantToRead() {
        let vm = LibraryViewModel()
        vm.userBooks = [
            makeUserBook(status: .wantToRead),
            makeUserBook(status: .inProgress),
            makeUserBook(status: .read)
        ]
        #expect(vm.books(for: .wantToRead).count == 1)
    }

    @Test func filterByInProgressReturnsMultiple() {
        let vm = LibraryViewModel()
        vm.userBooks = [
            makeUserBook(status: .inProgress),
            makeUserBook(status: .inProgress),
            makeUserBook(status: .read)
        ]
        #expect(vm.books(for: .inProgress).count == 2)
    }

    @Test func filterByReadExcludesOthers() {
        let vm = LibraryViewModel()
        vm.userBooks = [
            makeUserBook(status: .read),
            makeUserBook(status: .wantToRead),
            makeUserBook(status: .dnf)
        ]
        let result = vm.books(for: .read)
        #expect(result.count == 1)
        #expect(result[0].status == .read)
    }

    @Test func filterByDNF() {
        let vm = LibraryViewModel()
        vm.userBooks = [makeUserBook(status: .dnf), makeUserBook(status: .dnf)]
        #expect(vm.books(for: .dnf).count == 2)
    }

    @Test func filterReturnsEmptyWhenNoMatch() {
        let vm = LibraryViewModel()
        vm.userBooks = [makeUserBook(status: .wantToRead)]
        #expect(vm.books(for: .read).isEmpty)
    }

    @Test func emptyLibraryReturnsEmptyForAllStatuses() {
        let vm = LibraryViewModel()
        for status in ReadingStatus.allCases {
            #expect(vm.books(for: status).isEmpty)
        }
    }

    @Test func allStatusesRepresentedInFilter() {
        let vm = LibraryViewModel()
        vm.userBooks = ReadingStatus.allCases.map { makeUserBook(status: $0) }
        for status in ReadingStatus.allCases {
            #expect(vm.books(for: status).count == 1)
        }
    }
}

// MARK: - UserBook progress calculations

@MainActor
@Suite("UserBook — progress and word counts")
struct UserBookProgressTests {

    @Test func progressPercentQuarterWay() {
        let book = makeUserBook(status: .inProgress, currentPage: 50, totalPages: 200)
        #expect(book.progressPercent == 25.0)
    }

    @Test func progressPercentHalfWay() {
        let book = makeUserBook(status: .inProgress, currentPage: 150, totalPages: 300)
        #expect(book.progressPercent == 50.0)
    }

    @Test func progressPercentFullBook() {
        let book = makeUserBook(status: .read, currentPage: 300, totalPages: 300)
        #expect(book.progressPercent == 100.0)
    }

    @Test func progressPercentNilTotalPagesIsZero() {
        let book = makeUserBook(status: .inProgress, currentPage: 50, totalPages: nil)
        #expect(book.progressPercent == 0)
    }

    @Test func progressPercentZeroTotalPagesIsZero() {
        let book = makeUserBook(status: .inProgress, currentPage: 0, totalPages: 0)
        #expect(book.progressPercent == 0)
    }

    @Test func progressPercentAtPageZeroIsZero() {
        let book = makeUserBook(status: .inProgress, currentPage: 0, totalPages: 200)
        #expect(book.progressPercent == 0)
    }

    @Test func estimatedWordsReadAt275PerPage() {
        let book = makeUserBook(status: .inProgress, currentPage: 100)
        #expect(book.estimatedWordsRead == 27500)
    }

    @Test func estimatedWordsReadAtZeroPages() {
        let book = makeUserBook(status: .wantToRead, currentPage: 0)
        #expect(book.estimatedWordsRead == 0)
    }

    @Test func estimatedTotalWordsFromTotalPages() {
        let book = makeUserBook(status: .inProgress, currentPage: 50, totalPages: 400)
        #expect(book.estimatedTotalWords == 110000)
    }

    @Test func estimatedTotalWordsNilTotalPagesIsZero() {
        let book = makeUserBook(status: .inProgress, currentPage: 50, totalPages: nil)
        #expect(book.estimatedTotalWords == 0)
    }

    @Test func estimatedTotalWordsZeroTotalPagesIsZero() {
        let book = makeUserBook(status: .inProgress, currentPage: 0, totalPages: 0)
        #expect(book.estimatedTotalWords == 0)
    }
}

// MARK: - ReadingStatus display names

@MainActor
@Suite("ReadingStatus — display names and coding")
struct ReadingStatusDisplayTests {

    @Test func displayNamesMatchSpec() {
        #expect(ReadingStatus.wantToRead.displayName == "Want to Read")
        #expect(ReadingStatus.inProgress.displayName == "In Progress")
        #expect(ReadingStatus.read.displayName == "Read")
        #expect(ReadingStatus.dnf.displayName == "Did Not Finish")
    }

    @Test func rawValuesMatchDatabaseEnum() {
        #expect(ReadingStatus.wantToRead.rawValue == "want_to_read")
        #expect(ReadingStatus.inProgress.rawValue == "in_progress")
        #expect(ReadingStatus.read.rawValue == "read")
        #expect(ReadingStatus.dnf.rawValue == "dnf")
    }

    @Test func allCasesHasFourValues() {
        #expect(ReadingStatus.allCases.count == 4)
    }
}

// MARK: - UserBook equality

@MainActor
@Suite("UserBook — Equatable")
struct UserBookEqualityTests {

    @Test func identicalBooksAreEqual() {
        let id = UUID()
        let userID = UUID()
        let now = Date()
        let a = makeUserBook(id: id, userID: userID, status: .read, updatedAt: now)
        let b = makeUserBook(id: id, userID: userID, status: .read, updatedAt: now)
        #expect(a == b)
    }

    @Test func differentCurrentPageIsNotEqual() {
        let id = UUID()
        let userID = UUID()
        let now = Date()
        var a = makeUserBook(id: id, userID: userID, status: .inProgress, currentPage: 0, updatedAt: now)
        var b = a
        b.currentPage = 100
        #expect(a != b)
    }

    @Test func differentStatusIsNotEqual() {
        let id = UUID()
        let userID = UUID()
        let now = Date()
        let a = makeUserBook(id: id, userID: userID, status: .inProgress, updatedAt: now)
        var b = a
        b.status = .read
        #expect(a != b)
    }

    @Test func differentRatingIsNotEqual() {
        let id = UUID()
        let userID = UUID()
        let now = Date()
        let a = makeUserBook(id: id, userID: userID, status: .read, rating: nil, updatedAt: now)
        var b = a
        b.rating = 5
        #expect(a != b)
    }

    @Test func isPrivateToggleIsNotEqual() {
        let id = UUID()
        let userID = UUID()
        let now = Date()
        let a = makeUserBook(id: id, userID: userID, status: .read, isPrivate: false, updatedAt: now)
        var b = a
        b.isPrivate = true
        #expect(a != b)
    }
}

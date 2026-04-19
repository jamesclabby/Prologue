import Foundation
import Supabase
@testable import Prologue

final class MockAuthService: AuthServiceProtocol {
    // Configure these before each test
    var stubbedUser: User?
    var stubbedProfile: Profile?
    var shouldThrowOnSignIn = false
    var shouldThrowOnSignOut = false

    private(set) var signInCallCount = 0
    private(set) var signOutCallCount = 0
    private(set) var fetchProfileCallCount = 0
    private(set) var createProfileCallCount = 0
    private(set) var lastCreatedUsername: String?

    var currentUser: User? { stubbedUser }

    func signInWithGoogle() async throws {
        signInCallCount += 1
        if shouldThrowOnSignIn { throw MockError.intentional }
    }

    func signOut() async throws {
        signOutCallCount += 1
        if shouldThrowOnSignOut { throw MockError.intentional }
        stubbedUser = nil
    }

    func fetchProfile(userID: UUID) async throws -> Profile {
        fetchProfileCallCount += 1
        guard let profile = stubbedProfile else { throw MockError.notFound }
        return profile
    }

    func createProfile(userID: UUID, username: String) async throws -> Profile {
        createProfileCallCount += 1
        lastCreatedUsername = username
        let profile = Profile(
            id: userID,
            username: username,
            favoriteGenre: nil,
            avatarURL: nil,
            createdAt: Date()
        )
        stubbedProfile = profile
        return profile
    }
}

enum MockError: Error {
    case intentional
    case notFound
}

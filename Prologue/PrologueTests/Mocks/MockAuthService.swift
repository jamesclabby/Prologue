import Foundation
import Supabase
@testable import Prologue

final class MockAuthService: AuthServiceProtocol {
    // Configure these before each test
    var stubbedUser: User?
    var stubbedProfile: Profile?
    var stubbedUpdatedProfile: Profile?
    var stubbedAvatarURL = "https://example.com/avatar.jpg"
    var shouldThrowOnSignIn = false
    var shouldThrowOnSignOut = false
    var shouldThrowOnUpdateProfile = false
    var shouldThrowOnDeleteAccount = false

    private(set) var signInCallCount = 0
    private(set) var signOutCallCount = 0
    private(set) var fetchProfileCallCount = 0
    private(set) var createProfileCallCount = 0
    private(set) var updateProfileCallCount = 0
    private(set) var uploadAvatarCallCount = 0
    private(set) var deleteAccountCallCount = 0
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
        let profile = Profile(id: userID, username: username, createdAt: Date())
        stubbedProfile = profile
        return profile
    }

    func updateProfile(userID: UUID, displayName: String?, username: String,
                       favoriteGenre: String?, avatarURL: String?) async throws -> Profile {
        updateProfileCallCount += 1
        if shouldThrowOnUpdateProfile { throw MockError.intentional }
        let updated = stubbedUpdatedProfile ?? Profile(
            id: userID, username: username, displayName: displayName,
            favoriteGenre: favoriteGenre, avatarURL: avatarURL, createdAt: Date()
        )
        stubbedProfile = updated
        return updated
    }

    func uploadAvatar(userID: UUID, imageData: Data) async throws -> String {
        uploadAvatarCallCount += 1
        if shouldThrowOnUpdateProfile { throw MockError.intentional }
        return stubbedAvatarURL
    }

    func deleteAccount() async throws {
        deleteAccountCallCount += 1
        if shouldThrowOnDeleteAccount { throw MockError.intentional }
        stubbedUser = nil
        stubbedProfile = nil
    }
}

enum MockError: Error {
    case intentional
    case notFound
}

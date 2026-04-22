import Foundation
import Supabase
@testable import Prologue

final class MockAuthService: AuthServiceProtocol {
    // Configure these before each test
    var stubbedUser: User?
    var stubbedProfile: Profile?
    var stubbedUpdatedProfile: Profile?
    var stubbedAvatarURL = "https://example.com/avatar.jpg"
    var stubbedBlockedUsers: [Profile] = []
    var shouldThrowOnSignIn = false
    var shouldThrowOnSignOut = false
    var shouldThrowOnUpdateProfile = false
    var shouldThrowOnDeleteAccount = false
    var shouldThrowOnUpdatePrivacy = false
    var shouldThrowOnBlock = false
    var shouldThrowOnUnblock = false
    var shouldThrowOnFetchBlocked = false

    private(set) var signInCallCount = 0
    private(set) var signOutCallCount = 0
    private(set) var fetchProfileCallCount = 0
    private(set) var createProfileCallCount = 0
    private(set) var updateProfileCallCount = 0
    private(set) var uploadAvatarCallCount = 0
    private(set) var deleteAccountCallCount = 0
    private(set) var updatePrivacyCallCount = 0
    private(set) var fetchBlockedUsersCallCount = 0
    private(set) var blockUserCallCount = 0
    private(set) var unblockUserCallCount = 0
    private(set) var lastCreatedUsername: String?
    private(set) var lastBlockedID: UUID?
    private(set) var lastUnblockedID: UUID?

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

    func updatePrivacySettings(userID: UUID, visibility: ProfileVisibility,
                               activitySharing: Bool) async throws -> Profile {
        updatePrivacyCallCount += 1
        if shouldThrowOnUpdatePrivacy { throw MockError.intentional }
        let base = stubbedProfile ?? Profile(id: userID, username: "mock", createdAt: Date())
        let updated = Profile(
            id: base.id, username: base.username, displayName: base.displayName,
            favoriteGenre: base.favoriteGenre, avatarURL: base.avatarURL,
            visibility: visibility, activitySharing: activitySharing,
            createdAt: base.createdAt
        )
        stubbedProfile = updated
        return updated
    }

    func fetchBlockedUsers(userID: UUID) async throws -> [Profile] {
        fetchBlockedUsersCallCount += 1
        if shouldThrowOnFetchBlocked { throw MockError.intentional }
        return stubbedBlockedUsers
    }

    func blockUser(blockerID: UUID, blockedID: UUID) async throws {
        blockUserCallCount += 1
        lastBlockedID = blockedID
        if shouldThrowOnBlock { throw MockError.intentional }
    }

    func unblockUser(blockerID: UUID, blockedID: UUID) async throws {
        unblockUserCallCount += 1
        lastUnblockedID = blockedID
        if shouldThrowOnUnblock { throw MockError.intentional }
        stubbedBlockedUsers.removeAll { $0.id == blockedID }
    }
}

enum MockError: Error {
    case intentional
    case notFound
}

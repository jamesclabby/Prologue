import Foundation
import Supabase

protocol AuthServiceProtocol {
    var currentUser: User? { get }
    func signInWithGoogle() async throws
    func signOut() async throws
    func fetchProfile(userID: UUID) async throws -> Profile
    func createProfile(userID: UUID, username: String) async throws -> Profile
    func updateProfile(userID: UUID, displayName: String?, username: String,
                       favoriteGenre: String?, avatarURL: String?) async throws -> Profile
    func uploadAvatar(userID: UUID, imageData: Data) async throws -> String
    func deleteAccount() async throws

    func updatePrivacySettings(userID: UUID, visibility: ProfileVisibility,
                               activitySharing: Bool) async throws -> Profile
    func fetchBlockedUsers(userID: UUID) async throws -> [Profile]
    func blockUser(blockerID: UUID, blockedID: UUID) async throws
    func unblockUser(blockerID: UUID, blockedID: UUID) async throws
}

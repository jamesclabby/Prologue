import Foundation
import Supabase
import Observation

@Observable
final class AuthViewModel {
    var currentUser: User?
    var profile: Profile?
    var isLoading = false
    var error: Error?
    var blockedUsers: [Profile] = []
    var isLoadingBlocked = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    var isSaving = false

    var isSignedIn: Bool { currentUser != nil }
    var userID: UUID? { currentUser?.id ?? profile?.id }

    @MainActor
    func signIn() async {
        isLoading = true
        error = nil
        do {
            try await authService.signInWithGoogle()
            await refreshSession()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    @MainActor
    func signOut() async {
        do {
            try await authService.signOut()
            currentUser = nil
            profile = nil
        } catch {
            self.error = error
        }
    }

    @MainActor
    func refreshSession() async {
        await (authService as? AuthService)?.loadSession()
        guard let user = authService.currentUser else {
            currentUser = nil
            return
        }
        currentUser = user
        await loadOrCreateProfile(for: user)
    }

    @MainActor
    func updateProfile(displayName: String?, username: String,
                       favoriteGenre: String?, avatarData: Data? = nil) async {
        guard let userID else { return }
        isSaving = true
        error = nil
        do {
            var avatarURL = profile?.avatarURL
            if let avatarData {
                avatarURL = try await authService.uploadAvatar(userID: userID, imageData: avatarData)
            }
            profile = try await authService.updateProfile(
                userID: userID,
                displayName: displayName,
                username: username,
                favoriteGenre: favoriteGenre,
                avatarURL: avatarURL
            )
        } catch {
            self.error = error
        }
        isSaving = false
    }

    @MainActor
    func deleteAccount() async throws {
        try await authService.deleteAccount()
        currentUser = nil
        profile = nil
    }

    @MainActor
    func updatePrivacySettings(visibility: ProfileVisibility, activitySharing: Bool) async {
        guard let userID else { return }
        isSaving = true
        error = nil
        do {
            profile = try await authService.updatePrivacySettings(
                userID: userID,
                visibility: visibility,
                activitySharing: activitySharing
            )
        } catch {
            self.error = error
        }
        isSaving = false
    }

    @MainActor
    func loadBlockedUsers() async {
        guard let userID else { return }
        isLoadingBlocked = true
        error = nil
        do {
            blockedUsers = try await authService.fetchBlockedUsers(userID: userID)
        } catch {
            self.error = error
        }
        isLoadingBlocked = false
    }

    @MainActor
    func blockUser(_ profileToBlock: Profile) async throws {
        guard let userID else { return }
        try await authService.blockUser(blockerID: userID, blockedID: profileToBlock.id)
        if !blockedUsers.contains(where: { $0.id == profileToBlock.id }) {
            blockedUsers.append(profileToBlock)
        }
    }

    @MainActor
    func unblockUser(_ profileToUnblock: Profile) async throws {
        guard let userID else { return }
        try await authService.unblockUser(blockerID: userID, blockedID: profileToUnblock.id)
        blockedUsers.removeAll { $0.id == profileToUnblock.id }
    }

    @MainActor
    private func loadOrCreateProfile(for user: User) async {
        do {
            profile = try await authService.fetchProfile(userID: user.id)
        } catch {
            // Profile doesn't exist yet — create one from email prefix
            let username = user.email?.components(separatedBy: "@").first ?? "reader"
            profile = try? await authService.createProfile(userID: user.id, username: username)
        }
    }
}

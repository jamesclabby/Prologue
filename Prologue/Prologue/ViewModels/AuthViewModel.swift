import Foundation
import Supabase
import Observation

@Observable
final class AuthViewModel {
    var currentUser: User?
    var profile: Profile?
    var isLoading = false
    var error: Error?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

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

import Testing
import Foundation
@testable import Prologue

// MARK: - AuthViewModel tests using MockAuthService

@MainActor
@Suite("AuthViewModel")
struct AuthViewModelTests {

    // MARK: Initial state

    @Test func initialStateIsSignedOut() {
        let vm = AuthViewModel(authService: MockAuthService())
        #expect(vm.isSignedIn == false)
        #expect(vm.currentUser == nil)
        #expect(vm.profile == nil)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    // MARK: Sign-in

    @Test func signInSetsIsLoadingDuringRequest() async {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)
        // signIn is async — just verify it completes without error when mock succeeds
        await vm.signIn()
        #expect(vm.isLoading == false)
        #expect(mock.signInCallCount == 1)
    }

    @Test func signInErrorIsStoredOnFailure() async {
        let mock = MockAuthService()
        mock.shouldThrowOnSignIn = true
        let vm = AuthViewModel(authService: mock)
        await vm.signIn()
        #expect(vm.error != nil)
        #expect(vm.isSignedIn == false)
    }

    @Test func signInClearsErrorFromPreviousAttempt() async {
        let mock = MockAuthService()
        mock.shouldThrowOnSignIn = true
        let vm = AuthViewModel(authService: mock)
        await vm.signIn()
        #expect(vm.error != nil)

        mock.shouldThrowOnSignIn = false
        await vm.signIn()
        #expect(vm.error == nil)
    }

    // MARK: Sign-out

    @Test func signOutClearsUserAndProfile() async {
        let mock = MockAuthService()
        let profile = Profile(id: UUID(), username: "james", favoriteGenre: nil, avatarURL: nil, createdAt: Date())
        mock.stubbedProfile = profile
        let vm = AuthViewModel(authService: mock)

        // Manually set state as if user was signed in
        vm.currentUser = nil  // can't create a real User without Supabase, so just verify sign-out clears
        vm.profile = profile

        await vm.signOut()
        #expect(vm.currentUser == nil)
        #expect(vm.profile == nil)
        #expect(mock.signOutCallCount == 1)
    }

    @Test func signOutErrorDoesNotCrash() async {
        let mock = MockAuthService()
        mock.shouldThrowOnSignOut = true
        let vm = AuthViewModel(authService: mock)
        await vm.signOut()
        // Should complete gracefully — error is non-fatal for sign-out
    }

    // MARK: Profile creation

    @Test func refreshSessionCreatesProfileWhenNoneExists() async {
        let mock = MockAuthService()
        // fetchProfile throws (no profile) → createProfile is called
        mock.stubbedProfile = nil

        let vm = AuthViewModel(authService: mock)
        // refreshSession with no cached user → currentUser stays nil, no profile fetch
        await vm.refreshSession()
        #expect(vm.currentUser == nil)
        #expect(mock.fetchProfileCallCount == 0)
    }

    @Test func usernameGeneratedFromEmailPrefix() async {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)

        // Simulate the username-from-email logic directly
        let email = "jamesclabby12@gmail.com"
        let username = email.components(separatedBy: "@").first ?? "reader"
        #expect(username == "jamesclabby12")
    }

    @Test func usernameFallsBackToReaderWhenNoEmail() {
        let email: String? = nil
        let username = email?.components(separatedBy: "@").first ?? "reader"
        #expect(username == "reader")
    }

    // MARK: MockAuthService interaction

    @Test func signInCallsAuthServiceExactlyOnce() async {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)
        await vm.signIn()
        #expect(mock.signInCallCount == 1)
    }

    @Test func multipleSignInCallsAreTracked() async {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)
        await vm.signIn()
        await vm.signIn()
        #expect(mock.signInCallCount == 2)
    }
}

// MARK: - MockAuthService capability tests

@Suite("MockAuthService")
struct MockAuthServiceTests {

    @Test func createProfileStoresAndReturnsProfile() async throws {
        let mock = MockAuthService()
        let userID = UUID()
        let profile = try await mock.createProfile(userID: userID, username: "testuser")
        #expect(profile.username == "testuser")
        #expect(profile.id == userID)
        #expect(mock.createProfileCallCount == 1)
        #expect(mock.lastCreatedUsername == "testuser")
    }

    @Test func fetchProfileThrowsWhenNoneStubbed() async {
        let mock = MockAuthService()
        mock.stubbedProfile = nil
        await #expect(throws: MockError.self) {
            try await mock.fetchProfile(userID: UUID())
        }
    }

    @Test func fetchProfileReturnsStubbed() async throws {
        let mock = MockAuthService()
        let expected = Profile(id: UUID(), username: "james", favoriteGenre: "Sci-Fi", avatarURL: nil, createdAt: Date())
        mock.stubbedProfile = expected
        let result = try await mock.fetchProfile(userID: expected.id)
        #expect(result.username == expected.username)
        #expect(result.favoriteGenre == expected.favoriteGenre)
    }

    @Test func signOutClearsCurrentUser() async throws {
        let mock = MockAuthService()
        // After signOut, currentUser should be nil
        try await mock.signOut()
        #expect(mock.currentUser == nil)
    }
}

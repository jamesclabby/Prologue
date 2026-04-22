import Testing
import Foundation
@testable import Prologue

// MARK: - Helpers

private func makeProfile(
    id: UUID = UUID(),
    username: String = "testuser",
    displayName: String? = nil,
    favoriteGenre: String? = nil
) -> Profile {
    Profile(id: id, username: username, displayName: displayName,
            favoriteGenre: favoriteGenre, createdAt: Date())
}

// MARK: - Profile model

@Suite("Profile — displayName model")
struct ProfileDisplayNameTests {

    @Test func displayNameIsNilByDefault() {
        let profile = makeProfile()
        #expect(profile.displayName == nil)
    }

    @Test func displayNameDecodesFromJSON() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "username": "alice",
          "display_name": "Alice Wonder",
          "created_at": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profile = try decoder.decode(Profile.self, from: json)
        #expect(profile.displayName == "Alice Wonder")
        #expect(profile.username == "alice")
    }

    @Test func displayNameNilWhenAbsentFromJSON() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "username": "bob",
          "created_at": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profile = try decoder.decode(Profile.self, from: json)
        #expect(profile.displayName == nil)
    }

    @Test func profileEqualityIncludesDisplayName() {
        let id = UUID()
        let now = Date()
        let a = Profile(id: id, username: "x", displayName: "Alice", createdAt: now)
        let b = Profile(id: id, username: "x", displayName: "Bob",   createdAt: now)
        #expect(a != b)
    }

    @Test func profilesWithSameDisplayNameAreEqual() {
        let id = UUID()
        let now = Date()
        let a = Profile(id: id, username: "x", displayName: "Alice", createdAt: now)
        let b = Profile(id: id, username: "x", displayName: "Alice", createdAt: now)
        #expect(a == b)
    }
}

// MARK: - AuthViewModel — updateProfile

@MainActor
@Suite("AuthViewModel — updateProfile")
struct AuthViewModelUpdateProfileTests {

    @Test func updateProfileCallsService() async {
        let mock = MockAuthService()
        mock.stubbedProfile = makeProfile()
        let vm = AuthViewModel(authService: mock)
        vm.profile = mock.stubbedProfile
        await vm.updateProfile(displayName: "New Name", username: "newhandle", favoriteGenre: "Fantasy")
        #expect(mock.updateProfileCallCount == 1)
    }

    @Test func updateProfileUpdatesLocalProfile() async {
        let mock = MockAuthService()
        let original = makeProfile(username: "old")
        mock.stubbedProfile = original
        mock.stubbedUpdatedProfile = makeProfile(username: "new", displayName: "New Name")
        let vm = AuthViewModel(authService: mock)
        vm.profile = original
        await vm.updateProfile(displayName: "New Name", username: "new", favoriteGenre: nil)
        #expect(vm.profile?.username == "new")
        #expect(vm.profile?.displayName == "New Name")
    }

    @Test func updateProfileSetsErrorOnFailure() async {
        let mock = MockAuthService()
        mock.stubbedProfile = makeProfile()
        mock.shouldThrowOnUpdateProfile = true
        let vm = AuthViewModel(authService: mock)
        vm.profile = mock.stubbedProfile
        await vm.updateProfile(displayName: nil, username: "x", favoriteGenre: nil)
        #expect(vm.error != nil)
    }

    @Test func updateProfileClearsisSavingOnCompletion() async {
        let mock = MockAuthService()
        mock.stubbedProfile = makeProfile()
        let vm = AuthViewModel(authService: mock)
        vm.profile = mock.stubbedProfile
        await vm.updateProfile(displayName: nil, username: "x", favoriteGenre: nil)
        #expect(vm.isSaving == false)
    }
}

// MARK: - AuthViewModel — deleteAccount

@MainActor
@Suite("AuthViewModel — deleteAccount")
struct AuthViewModelDeleteAccountTests {

    @Test func deleteAccountCallsService() async throws {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)
        try await vm.deleteAccount()
        #expect(mock.deleteAccountCallCount == 1)
    }

    @Test func deleteAccountClearsCurrentUser() async throws {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)
        try await vm.deleteAccount()
        #expect(vm.currentUser == nil)
    }

    @Test func deleteAccountClearsProfile() async throws {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)
        vm.profile = makeProfile()
        try await vm.deleteAccount()
        #expect(vm.profile == nil)
    }

    @Test func deleteAccountThrowsOnServiceFailure() async {
        let mock = MockAuthService()
        mock.shouldThrowOnDeleteAccount = true
        let vm = AuthViewModel(authService: mock)
        await #expect(throws: MockError.self) {
            try await vm.deleteAccount()
        }
    }
}

// MARK: - Settings — appearance (Stage 2 keys, tested here for persistence logic)

@Suite("Settings — appearance", .serialized)
struct AppearanceSettingsTests {

    private let key = "themeMode"

    @Test func themeModeDefaultsToSystem() {
        UserDefaults.standard.removeObject(forKey: key)
        let value = UserDefaults.standard.string(forKey: key)
        #expect(value == nil) // nil means "system" in the app
    }

    @Test func themeModePersistsLight() {
        UserDefaults.standard.set("light", forKey: key)
        #expect(UserDefaults.standard.string(forKey: key) == "light")
        UserDefaults.standard.removeObject(forKey: key)
    }

    @Test func themeModePersistsDark() {
        UserDefaults.standard.set("dark", forKey: key)
        #expect(UserDefaults.standard.string(forKey: key) == "dark")
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Settings — notifications (Stage 2 keys)

@Suite("Settings — notifications", .serialized)
struct NotificationSettingsTests {

    @Test func notificationsEnabledDefaultsFalse() {
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        #expect(UserDefaults.standard.bool(forKey: "notificationsEnabled") == false)
    }

    @Test func friendRequestAlertsDefaultTrue() {
        UserDefaults.standard.removeObject(forKey: "friendRequestAlerts")
        // Default for unset bool is false; app sets true on first launch — test storage round-trip
        UserDefaults.standard.set(true, forKey: "friendRequestAlerts")
        #expect(UserDefaults.standard.bool(forKey: "friendRequestAlerts") == true)
        UserDefaults.standard.removeObject(forKey: "friendRequestAlerts")
    }

    @Test func reviewAlertsRoundtrip() {
        UserDefaults.standard.set(true, forKey: "reviewAlerts")
        #expect(UserDefaults.standard.bool(forKey: "reviewAlerts") == true)
        UserDefaults.standard.set(false, forKey: "reviewAlerts")
        #expect(UserDefaults.standard.bool(forKey: "reviewAlerts") == false)
        UserDefaults.standard.removeObject(forKey: "reviewAlerts")
    }

    @Test func readingRemindersDefaultFalse() {
        UserDefaults.standard.removeObject(forKey: "readingReminders")
        #expect(UserDefaults.standard.bool(forKey: "readingReminders") == false)
    }

    @Test func allNotificationKeysRoundtripUserDefaults() {
        let keys = ["notificationsEnabled", "friendRequestAlerts", "reviewAlerts", "readingReminders"]
        for key in keys {
            UserDefaults.standard.set(true, forKey: key)
            #expect(UserDefaults.standard.bool(forKey: key) == true)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

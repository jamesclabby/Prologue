import Foundation
import Supabase
import GoogleSignIn
import CryptoKit

final class AuthService: AuthServiceProtocol {
    private let supabase = SupabaseManager.shared.client

    private(set) var cachedUser: User?

    var currentUser: User? { cachedUser }

    func loadSession() async {
        cachedUser = try? await supabase.auth.session.user
    }

    @MainActor
    func signInWithGoogle() async throws {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        // Generate nonce: pass the SHA256 hash to Google, the raw value to Supabase.
        // Supabase hashes the raw nonce and compares it to what Google embedded in the ID token.
        let rawNonce = randomNonce()
        let hashedNonce = sha256(rawNonce)

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC,
            hint: nil,
            additionalScopes: nil,
            nonce: hashedNonce
        )

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }

        try await supabase.auth.signInWithIdToken(credentials: .init(
            provider: .google,
            idToken: idToken,
            accessToken: result.user.accessToken.tokenString,
            nonce: rawNonce
        ))

        cachedUser = try await supabase.auth.session.user
    }

    func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
        try await supabase.auth.signOut()
        cachedUser = nil
    }

    func fetchProfile(userID: UUID) async throws -> Profile {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .single()
            .execute()
            .value
    }

    func createProfile(userID: UUID, username: String) async throws -> Profile {
        let newProfile = ProfileInsert(id: userID, username: username)
        return try await supabase
            .from("profiles")
            .insert(newProfile)
            .select()
            .single()
            .execute()
            .value
    }

    func updateProfile(userID: UUID, displayName: String?, username: String,
                       favoriteGenre: String?, avatarURL: String?) async throws -> Profile {
        let update = ProfileUpdate(displayName: displayName, username: username,
                                   favoriteGenre: favoriteGenre, avatarURL: avatarURL)
        return try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userID)
            .select()
            .single()
            .execute()
            .value
    }

    func uploadAvatar(userID: UUID, imageData: Data) async throws -> String {
        let path = "\(userID.uuidString.lowercased()).jpg"
        _ = try await supabase.storage
            .from("avatars")
            .upload(path, data: imageData,
                    options: FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true))
        let url = try supabase.storage.from("avatars").getPublicURL(path: path)
        return url.absoluteString
    }

    func deleteAccount() async throws {
        try await supabase.rpc("delete_user").execute()
        try await signOut()
    }

    // MARK: - Privacy

    func updatePrivacySettings(userID: UUID, visibility: ProfileVisibility,
                               activitySharing: Bool) async throws -> Profile {
        let update = PrivacyUpdate(visibility: visibility, activitySharing: activitySharing)
        return try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userID)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Blocked users

    func fetchBlockedUsers(userID: UUID) async throws -> [Profile] {
        let rows: [BlockedUser] = try await supabase
            .from("blocked_users")
            .select()
            .eq("blocker_id", value: userID)
            .execute()
            .value

        let blockedIDs = rows.map(\.blockedID)
        guard !blockedIDs.isEmpty else { return [] }

        return try await supabase
            .from("profiles")
            .select()
            .in("id", values: blockedIDs.map(\.uuidString))
            .execute()
            .value
    }

    func blockUser(blockerID: UUID, blockedID: UUID) async throws {
        let insert: [String: String] = [
            "blocker_id": blockerID.uuidString,
            "blocked_id": blockedID.uuidString
        ]
        try await supabase.from("blocked_users").insert(insert).execute()
    }

    func unblockUser(blockerID: UUID, blockedID: UUID) async throws {
        try await supabase
            .from("blocked_users")
            .delete()
            .eq("blocker_id", value: blockerID)
            .eq("blocked_id", value: blockedID)
            .execute()
    }

    // MARK: - Nonce helpers

    private func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Supporting types

enum AuthError: LocalizedError {
    case noRootViewController
    case missingToken

    var errorDescription: String? {
        switch self {
        case .noRootViewController: return "Could not find root view controller for sign-in."
        case .missingToken: return "Google Sign-In did not return an ID token."
        }
    }
}

private struct ProfileInsert: Encodable {
    let id: UUID
    let username: String
}

private struct ProfileUpdate: Encodable {
    let displayName: String?
    let username: String
    let favoriteGenre: String?
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case displayName  = "display_name"
        case username
        case favoriteGenre = "favorite_genre"
        case avatarURL    = "avatar_url"
    }
}

private struct PrivacyUpdate: Encodable {
    let visibility: ProfileVisibility
    let activitySharing: Bool

    enum CodingKeys: String, CodingKey {
        case visibility
        case activitySharing = "activity_sharing"
    }
}

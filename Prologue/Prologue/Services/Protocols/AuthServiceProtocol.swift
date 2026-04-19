import Foundation
import Supabase

protocol AuthServiceProtocol {
    var currentUser: User? { get }
    func signInWithGoogle() async throws
    func signOut() async throws
    func fetchProfile(userID: UUID) async throws -> Profile
    func createProfile(userID: UUID, username: String) async throws -> Profile
}

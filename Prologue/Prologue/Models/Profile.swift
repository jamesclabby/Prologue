import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var favoriteGenre: String?
    var avatarURL: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case favoriteGenre = "favorite_genre"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}

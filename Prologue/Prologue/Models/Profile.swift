import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var displayName: String?
    var favoriteGenre: String?
    var avatarURL: String?
    let createdAt: Date

    init(id: UUID, username: String, displayName: String? = nil,
         favoriteGenre: String? = nil, avatarURL: String? = nil, createdAt: Date) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.favoriteGenre = favoriteGenre
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case favoriteGenre = "favorite_genre"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}

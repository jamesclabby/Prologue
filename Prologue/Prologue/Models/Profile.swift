import Foundation

enum ProfileVisibility: String, Codable, CaseIterable, Equatable {
    case `public`    = "public"
    case friendsOnly = "friends_only"
    case `private`   = "private"

    var displayName: String {
        switch self {
        case .public:      return "Public"
        case .friendsOnly: return "Friends Only"
        case .private:     return "Private"
        }
    }
}

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var displayName: String?
    var favoriteGenre: String?
    var avatarURL: String?
    var visibility: ProfileVisibility
    var activitySharing: Bool
    let createdAt: Date

    init(id: UUID, username: String, displayName: String? = nil,
         favoriteGenre: String? = nil, avatarURL: String? = nil,
         visibility: ProfileVisibility = .public,
         activitySharing: Bool = true,
         createdAt: Date) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.favoriteGenre = favoriteGenre
        self.avatarURL = avatarURL
        self.visibility = visibility
        self.activitySharing = activitySharing
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName     = "display_name"
        case favoriteGenre   = "favorite_genre"
        case avatarURL       = "avatar_url"
        case visibility
        case activitySharing = "activity_sharing"
        case createdAt       = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self, forKey: .id)
        username        = try c.decode(String.self, forKey: .username)
        displayName     = try c.decodeIfPresent(String.self, forKey: .displayName)
        favoriteGenre   = try c.decodeIfPresent(String.self, forKey: .favoriteGenre)
        avatarURL       = try c.decodeIfPresent(String.self, forKey: .avatarURL)
        visibility      = try c.decodeIfPresent(ProfileVisibility.self, forKey: .visibility) ?? .public
        activitySharing = try c.decodeIfPresent(Bool.self, forKey: .activitySharing) ?? true
        createdAt       = try c.decode(Date.self, forKey: .createdAt)
    }
}

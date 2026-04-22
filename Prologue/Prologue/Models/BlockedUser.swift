import Foundation

struct BlockedUser: Codable, Identifiable, Equatable {
    let id: UUID
    let blockerID: UUID
    let blockedID: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case blockerID = "blocker_id"
        case blockedID = "blocked_id"
        case createdAt = "created_at"
    }
}

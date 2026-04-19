import Foundation

enum FriendshipStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
}

struct Friendship: Codable, Identifiable, Equatable {
    let id: UUID
    let requesterID: UUID
    let receiverID: UUID
    var status: FriendshipStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case requesterID = "requester_id"
        case receiverID = "receiver_id"
        case status
        case createdAt = "created_at"
    }
}

//======================================================================
// MARK: - Message.swift
// Path: foodai/Core/DataModels/Message.swift
//======================================================================
import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let isEdited: Bool
    let isDeleted: Bool
    
    // Relationships
    var sender: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isEdited = "is_edited"
        case isDeleted = "is_deleted"
        case sender
    }
}

struct Conversation: Identifiable, Codable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let lastMessageAt: Date?
    let lastMessagePreview: String?
    
    // Relationships
    var participants: [ConversationParticipant]?
    var messages: [Message]?
    var unreadCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessageAt = "last_message_at"
        case lastMessagePreview = "last_message_preview"
        case participants = "conversation_participants"
        case messages
        case unreadCount
    }
    
    // Helper computed properties
    func otherParticipant(currentUserId: String?) -> UserProfile? {
        // For direct messages, get the other participant
        guard let participants = participants,
              participants.count == 2,
              let currentUserId = currentUserId else { return nil }
        
        return participants.first { $0.userId != currentUserId }?.user
    }
    
    func displayName(currentUserId: String?) -> String {
        // For now, show other participant's name for direct messages
        let participant = otherParticipant(currentUserId: currentUserId)
        return participant?.displayName ?? participant?.username ?? "Unknown"
    }
    
    func displayAvatar(currentUserId: String?) -> String? {
        return otherParticipant(currentUserId: currentUserId)?.avatarUrl
    }
}

struct ConversationParticipant: Codable {
    let id: String
    let conversationId: String
    let userId: String
    let joinedAt: Date
    let lastReadAt: Date?
    
    // Relationships
    var user: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case lastReadAt = "last_read_at"
        case user
    }
}

// MARK: - Message Request/Response Models
struct SendMessageRequest: Codable {
    let conversationId: String
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case content
    }
}

struct CreateConversationRequest: Codable {
    let participantIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case participantIds = "participant_ids"
    }
}
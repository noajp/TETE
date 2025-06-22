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
        let otherUser = otherParticipant(currentUserId: currentUserId)
        
        // Debug: Print participant information
        if let otherUser = otherUser {
            print("🔵 Found other participant user: \(otherUser.id)")
            print("🔵 Username: \(otherUser.username)")
            print("🔵 Display name: \(otherUser.displayName ?? "nil")")
            
            return otherUser.preferredDisplayName
        } else {
            print("⚠️ No other participant found via participants list")
            print("⚠️ Current user ID: \(currentUserId ?? "nil")")
            print("⚠️ Total participants: \(participants?.count ?? 0)")
            
            // Try to find other participant manually from participants list
            if let participants = participants, let currentUserId = currentUserId {
                let otherParticipant = participants.first { $0.userId.lowercased() != currentUserId.lowercased() }
                if let otherParticipant = otherParticipant {
                    print("🔵 Found other participant (manual): \(otherParticipant.userId)")
                    if let user = otherParticipant.user {
                        print("🔵 Other participant username: \(user.username)")
                        return user.preferredDisplayName
                    } else {
                        print("⚠️ Other participant has no user profile")
                        return "User-\(String(otherParticipant.userId.prefix(8)))"
                    }
                }
            }
            
            // Last resort: Try to get from messages if available
            print("🔵 Messages available: \(messages?.count ?? 0)")
            if let messages = messages, let currentUserId = currentUserId {
                print("🔵 Trying to find other user from messages...")
                print("🔵 Looking for messages not from: \(currentUserId)")
                
                for (index, message) in messages.enumerated() {
                    print("🔵 Message \(index): from \(message.senderId), isOther: \(message.senderId.lowercased() != currentUserId.lowercased())")
                }
                
                // Find a message from someone other than current user
                if let otherMessage = messages.first(where: { $0.senderId.lowercased() != currentUserId.lowercased() }) {
                    print("🔵 Found message from other user: \(otherMessage.senderId)")
                    if let sender = otherMessage.sender {
                        print("🔵 Other user from message: \(sender.username)")
                        return sender.preferredDisplayName
                    } else {
                        print("🔵 No sender profile, using partial ID")
                        // Return partial user ID if no profile data
                        return "User-\(String(otherMessage.senderId.prefix(8)))"
                    }
                } else {
                    print("⚠️ No messages from other users found")
                }
            } else {
                print("⚠️ No messages available or no current user ID")
            }
            
            return "Unknown"
        }
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
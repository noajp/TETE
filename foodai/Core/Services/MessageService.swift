//======================================================================
// MARK: - MessageService.swift
// Path: foodai/Core/Services/MessageService.swift
//======================================================================
import Foundation
import Supabase

@MainActor
class MessageService: ObservableObject {
    static let shared = MessageService()
    private let supabase = SupabaseManager.shared.client
    
    // Timer for polling updates
    private var updateTimer: Timer?
    
    private init() {
        // Setup subscriptions when user authenticates
        setupAuthenticationListener()
    }
    
    private func setupAuthenticationListener() {
        // Listen for authentication changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(authStateChanged),
            name: .authStateChanged,
            object: nil
        )
        
        // Setup immediately if user is already authenticated
        if AuthManager.shared.currentUser != nil {
            setupRealtimeSubscriptions()
        }
    }
    
    @objc private func authStateChanged() {
        if AuthManager.shared.currentUser != nil {
            setupRealtimeSubscriptions()
        } else {
            // Cleanup timer when user logs out
            updateTimer?.invalidate()
            updateTimer = nil
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    // MARK: - Realtime Setup (Simplified polling approach)
    
    private func setupRealtimeSubscriptions() {
        // For now, implement a simple polling approach instead of complex realtime
        // This ensures messages are updated regularly
        startPollingForUpdates()
    }
    
    private func startPollingForUpdates() {
        // Invalidate existing timer
        updateTimer?.invalidate()
        
        // Disable automatic polling to prevent UI flickering
        // Messages will only refresh when user manually pulls to refresh or sends a message
        // updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
        //     Task { @MainActor in
        //         await self?.checkForUpdates()
        //     }
        // }
    }
    
    private func checkForUpdates() async {
        // Only trigger updates when explicitly called (e.g., after sending a message)
        // Removed automatic objectWillChange.send() to prevent flickering
        // objectWillChange.send()
    }
    
    // MARK: - Conversations
    
    /// Fetch all conversations for the current user
    func fetchConversations() async throws -> [Conversation] {
        let conversations: [Conversation] = try await supabase
            .from("conversations")
            .select("""
                *,
                conversation_participants!inner(
                    *,
                    user:user_profiles(*)
                )
            """)
            .order("last_message_at", ascending: false)
            .execute()
            .value
        
        // Calculate unread count for each conversation
        var conversationsWithUnread: [Conversation] = []
        for var conversation in conversations {
            let unreadCount = try await getUnreadCount(for: conversation.id)
            conversation.unreadCount = unreadCount
            conversationsWithUnread.append(conversation)
        }
        
        return conversationsWithUnread
    }
    
    /// Get or create a direct conversation with another user
    func getOrCreateDirectConversation(with userId: String) async throws -> String {
        let conversationId: String = try await supabase
            .rpc("get_or_create_direct_conversation", params: ["other_user_id": userId])
            .execute()
            .value
        return conversationId
    }
    
    /// Get unread message count for a conversation
    private func getUnreadCount(for conversationId: String) async throws -> Int {
        guard let userId = AuthManager.shared.currentUser?.id else { return 0 }
        
        // Get the user's last read timestamp
        struct LastReadResponse: Codable {
            let lastReadAt: Date?
            
            enum CodingKeys: String, CodingKey {
                case lastReadAt = "last_read_at"
            }
        }
        
        let lastReadData: LastReadResponse = try await supabase
            .from("conversation_participants")
            .select("last_read_at")
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        let lastReadAt = lastReadData.lastReadAt ?? Date.distantPast
        
        // Count messages after last read
        let countResponse = try await supabase
            .from("messages")
            .select("id", head: true, count: .exact)
            .eq("conversation_id", value: conversationId)
            .neq("sender_id", value: userId)
            .gt("created_at", value: ISO8601DateFormatter().string(from: lastReadAt))
            .execute()
        
        return countResponse.count ?? 0
    }
    
    // MARK: - Messages
    
    /// Fetch messages for a conversation
    func fetchMessages(for conversationId: String, limit: Int = 50, before: Date? = nil) async throws -> [Message] {
        let query = supabase
            .from("messages")
            .select("""
                *,
                sender:user_profiles(*)
            """)
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: false)
            .limit(limit)
        
        var messages: [Message] = try await query.execute().value
        messages.reverse() // Reverse to show oldest first
        return messages
    }
    
    /// Send a message
    func sendMessage(to conversationId: String, content: String) async throws -> Message {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let messageData = [
            "conversation_id": conversationId,
            "sender_id": userId,
            "content": content
        ]
        
        let message: Message = try await supabase
            .from("messages")
            .insert(messageData)
            .select("""
                *,
                sender:user_profiles(*)
            """)
            .single()
            .execute()
            .value
        
        // Mark conversation as read after sending
        try await markConversationAsRead(conversationId)
        
        // Trigger UI update only when a message is sent
        objectWillChange.send()
        
        return message
    }
    
    /// Mark a conversation as read
    func markConversationAsRead(_ conversationId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        let updateData: [String: AnyJSON] = [
            "last_read_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await supabase
            .from("conversation_participants")
            .update(updateData)
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    /// Delete a message (soft delete)
    func deleteMessage(_ messageId: String) async throws {
        let updateData: [String: AnyJSON] = [
            "is_deleted": AnyJSON.bool(true),
            "content": AnyJSON.string("Message deleted")
        ]
        
        try await supabase
            .from("messages")
            .update(updateData)
            .eq("id", value: messageId)
            .execute()
    }
    
    /// Edit a message
    func editMessage(_ messageId: String, newContent: String) async throws {
        let updateData: [String: AnyJSON] = [
            "content": AnyJSON.string(newContent),
            "is_edited": AnyJSON.bool(true),
            "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await supabase
            .from("messages")
            .update(updateData)
            .eq("id", value: messageId)
            .execute()
    }
}

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
    
    // Published property for unread conversations count (how many people sent messages)
    @Published var unreadConversationsCount: Int = 0
    
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
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // First, get conversation IDs where the current user is a participant
        struct ConversationIDMapping: Codable {
            let id: String
            enum CodingKeys: String, CodingKey {
                case id = "conversation_id"
            }
        }
        
        let userConversationIds: [ConversationIDMapping] = try await supabase
            .from("conversation_participants")
            .select("conversation_id")
            .eq("user_id", value: currentUserId)
            .execute()
            .value
        
        let conversationIds = userConversationIds.map { $0.id }
        
        if conversationIds.isEmpty {
            return []
        }
        
        print("🔵 Found \(conversationIds.count) conversation IDs for user")
        
        // Get conversation details (without participants first)
        let conversations: [Conversation] = try await supabase
            .from("conversations")
            .select("id, created_at, updated_at, last_message_at, last_message_preview")
            .in("id", values: conversationIds)
            .order("last_message_at", ascending: false)
            .execute()
            .value
        
        // Now manually fetch all participants for each conversation
        var conversationsWithAllParticipants: [Conversation] = []
        
        for var conversation in conversations {
            print("🔵 Fetching participants for conversation: \(conversation.id)")
            
            // Try different approach: First get participant IDs, then get user profiles separately
            struct ParticipantID: Codable {
                let userId: String
                let id: String
                let joinedAt: Date
                let lastReadAt: Date?
                
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case id
                    case joinedAt = "joined_at"
                    case lastReadAt = "last_read_at"
                }
            }
            
            // First, get all participant IDs for this conversation
            let participantIDs: [ParticipantID] = try await supabase
                .from("conversation_participants")
                .select("id, user_id, joined_at, last_read_at")
                .eq("conversation_id", value: conversation.id)
                .execute()
                .value
            
            print("🔵 Found \(participantIDs.count) participant IDs for conversation \(conversation.id)")
            for participantID in participantIDs {
                print("🔵 Participant ID: \(participantID.userId)")
            }
            
            // Now fetch user profiles for each participant
            var allParticipants: [ConversationParticipant] = []
            
            for participantData in participantIDs {
                // Get user profile for this participant
                do {
                    let userProfile: UserProfile = try await supabase
                        .from("user_profiles")
                        .select("id, username, display_name, avatar_url, bio")
                        .eq("id", value: participantData.userId)
                        .single()
                        .execute()
                        .value
                    
                    let participant = ConversationParticipant(
                        id: participantData.id,
                        conversationId: conversation.id,
                        userId: participantData.userId,
                        joinedAt: participantData.joinedAt,
                        lastReadAt: participantData.lastReadAt,
                        user: userProfile
                    )
                    
                    allParticipants.append(participant)
                    print("🔵 Added participant: \(userProfile.username)")
                } catch {
                    print("❌ Failed to get user profile for \(participantData.userId): \(error)")
                    
                    // Add participant without user profile
                    let participant = ConversationParticipant(
                        id: participantData.id,
                        conversationId: conversation.id,
                        userId: participantData.userId,
                        joinedAt: participantData.joinedAt,
                        lastReadAt: participantData.lastReadAt,
                        user: nil
                    )
                    allParticipants.append(participant)
                }
            }
            
            print("🔵 Final participants count: \(allParticipants.count)")
            conversation.participants = allParticipants
            conversationsWithAllParticipants.append(conversation)
        }
        
        print("🔵 Fetched \(conversationsWithAllParticipants.count) conversations for user \(currentUserId)")
        
        // Debug: Print conversation details
        for (index, conversation) in conversationsWithAllParticipants.enumerated() {
            print("🔵 Conversation \(index): \(conversation.id)")
            print("🔵 Participants count: \(conversation.participants?.count ?? 0)")
            for (pIndex, participant) in (conversation.participants ?? []).enumerated() {
                print("🔵   Participant \(pIndex): \(participant.userId)")
                print("🔵   User: \(participant.user?.username ?? "nil") (\(participant.user?.displayName ?? "nil"))")
            }
            let otherParticipant = conversation.otherParticipant(currentUserId: currentUserId)
            print("🔵 Other participant: \(otherParticipant?.username ?? "nil")")
            print("🔵 Display name: \(conversation.displayName(currentUserId: currentUserId))")
        }
        
        // Calculate unread count for each conversation
        var conversationsWithUnread: [Conversation] = []
        var conversationsWithUnreadMessages = 0
        
        for var conversation in conversationsWithAllParticipants {
            let unreadCount = try await getUnreadCount(for: conversation.id)
            conversation.unreadCount = unreadCount
            if unreadCount > 0 {
                conversationsWithUnreadMessages += 1
            }
            conversationsWithUnread.append(conversation)
        }
        
        // Update the count of conversations with unread messages
        self.unreadConversationsCount = conversationsWithUnreadMessages
        
        return conversationsWithUnread
    }
    
    /// Get or create a direct conversation with another user
    func getOrCreateDirectConversation(with userId: String) async throws -> String {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🔵 Creating conversation between \(currentUserId) and \(userId)")
        
        // Verify both users exist in user_profiles table using count instead of full object
        do {
            let currentUserCount = try await supabase
                .from("user_profiles")
                .select("id", head: true, count: .exact)
                .eq("id", value: currentUserId)
                .execute()
                .count ?? 0
            
            if currentUserCount == 0 {
                print("❌ Current user profile not found")
                throw NSError(domain: "MessageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Current user profile not found"])
            }
            print("✅ Current user profile found: \(currentUserId)")
        } catch {
            print("❌ Error checking current user profile: \(error)")
            throw NSError(domain: "MessageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Current user profile not found"])
        }
        
        do {
            let targetUserCount = try await supabase
                .from("user_profiles")
                .select("id", head: true, count: .exact)
                .eq("id", value: userId)
                .execute()
                .count ?? 0
            
            if targetUserCount == 0 {
                print("❌ Target user profile not found")
                throw NSError(domain: "MessageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Target user profile not found"])
            }
            print("✅ Target user profile found: \(userId)")
        } catch {
            print("❌ Error checking target user profile: \(error)")
            throw NSError(domain: "MessageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Target user profile not found"])
        }
        
        // Debug: Check current authentication state
        print("🔵 Checking authentication state...")
        print("🔵 AuthManager currentUser: \(AuthManager.shared.currentUser?.id ?? "nil")")
        print("🔵 AuthManager isAuthenticated: \(AuthManager.shared.isAuthenticated)")
        
        // Check if we're using the same Supabase client instance
        print("🔵 MessageService supabase client: \(ObjectIdentifier(supabase))")
        print("🔵 SupabaseManager shared client: \(ObjectIdentifier(SupabaseManager.shared.client))")
        print("🔵 Are they the same instance? \(supabase === SupabaseManager.shared.client)")
        
        // Try to get session
        do {
            let session = try await supabase.auth.session
            print("🔵 MessageService auth session user ID: \(session.user.id.uuidString)")
            print("🔵 Session access token exists: \(!session.accessToken.isEmpty)")
        } catch {
            print("❌ MessageService session error: \(error)")
            
            // Try AuthManager's client
            do {
                let authSession = try await SupabaseManager.shared.client.auth.session
                print("🔵 AuthManager session user ID: \(authSession.user.id.uuidString)")
                print("⚠️ Session exists in AuthManager but not in MessageService - this indicates a problem")
            } catch {
                print("❌ No session in AuthManager either: \(error)")
            }
        }
        
        // Now safely call the RPC function
        do {
            // Ensure userId is a valid UUID format
            guard UUID(uuidString: userId) != nil else {
                throw NSError(domain: "MessageService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
            }
            
            let conversationId: String = try await supabase
                .rpc("get_or_create_direct_conversation", params: ["other_user_id": AnyJSON.string(userId)])
                .execute()
                .value
            print("✅ Conversation created/found: \(conversationId)")
            return conversationId
        } catch {
            print("❌ RPC call failed: \(error)")
            if let postgrestError = error as? PostgrestError {
                print("❌ PostgrestError details:")
                print("❌   Code: \(postgrestError.code ?? "nil")")
                print("❌   Message: \(postgrestError.message)")
                print("❌   Detail: \(postgrestError.detail ?? "nil")")
                print("❌   Hint: \(postgrestError.hint ?? "nil")")
            }
            throw error
        }
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
        
        // Don't trigger UI update to prevent infinite loops
        // The UI will update when the message is appended directly
        // objectWillChange.send()
        
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
        
        // Post notification that conversation was marked as read
        await MainActor.run {
            print("🔵 MessageService: Posting notification for conversation \(conversationId) marked as read")
            NotificationCenter.default.post(name: .conversationMarkedAsRead, object: conversationId)
        }
        
        // Update unread count after marking as read without triggering objectWillChange
        // This prevents the infinite loop while keeping the badge count accurate
        Task {
            await updateUnreadCount()
        }
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
    
    /// Delete a conversation
    func deleteConversation(_ conversationId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Delete the participant record (soft delete for the user)
        try await supabase
            .from("conversation_participants")
            .delete()
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    // MARK: - Helper Methods
    
    /// Update unread conversation count without triggering full UI refresh
    private func updateUnreadCount() async {
        do {
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
            
            var unreadCount = 0
            for conversation in conversations {
                let messageUnreadCount = try await getUnreadCount(for: conversation.id)
                if messageUnreadCount > 0 {
                    unreadCount += 1
                }
            }
            
            await MainActor.run {
                self.unreadConversationsCount = unreadCount
            }
        } catch {
            print("❌ Error updating unread count: \(error)")
        }
    }
}

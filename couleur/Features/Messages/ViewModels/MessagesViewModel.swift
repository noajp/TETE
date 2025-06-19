//======================================================================
// MARK: - MessagesViewModel.swift
// Path: foodai/Features/Messages/ViewModels/MessagesViewModel.swift
//======================================================================
import Foundation
import SwiftUI
import Combine

extension Notification.Name {
    static let conversationMarkedAsRead = Notification.Name("conversationMarkedAsRead")
}

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let messageService = MessageService.shared
    
    init() {
        Task {
            await loadConversations()
        }
        
        // Listen for real-time updates
        setupRealtimeListeners()
    }
    
    private func setupRealtimeListeners() {
        // Listen for conversation read status changes
        NotificationCenter.default.publisher(for: .conversationMarkedAsRead)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let conversationId = notification.object as? String else { return }
                
                // Update the specific conversation's unread count to 0
                print("🔵 Received notification to mark conversation \(conversationId) as read")
                if let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                    print("🔵 Found conversation at index \(index), setting unread count to 0")
                    self.conversations[index].unreadCount = 0
                    // Force UI update
                    self.objectWillChange.send()
                } else {
                    print("⚠️ Could not find conversation with ID \(conversationId)")
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateConversationInList(_ updatedConversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == updatedConversation.id }) {
            conversations[index] = updatedConversation
            // Re-sort by last message time
            conversations.sort { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
        }
    }
    
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            conversations = try await messageService.fetchConversations()
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            print("❌ Error loading conversations: \(error)")
        }
        
        isLoading = false
    }
    
    func createNewConversation(with userId: String) async -> String? {
        do {
            let conversationId = try await messageService.getOrCreateDirectConversation(with: userId)
            await loadConversations() // Reload to show new conversation
            return conversationId
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            print("❌ Error creating conversation: \(error)")
            return nil
        }
    }
    
    func formatTimestamp(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func deleteConversation(_ conversationId: String) async {
        do {
            try await messageService.deleteConversation(conversationId)
            // Remove from local list
            conversations.removeAll { $0.id == conversationId }
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
            print("❌ Error deleting conversation: \(error)")
        }
    }
}
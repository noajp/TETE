//======================================================================
// MARK: - MessagesViewModel.swift
// Path: foodai/Features/Messages/ViewModels/MessagesViewModel.swift
//======================================================================
import Foundation
import SwiftUI
import Combine

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
        // Listen for updates from MessageService polling
        messageService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadConversations()
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
}
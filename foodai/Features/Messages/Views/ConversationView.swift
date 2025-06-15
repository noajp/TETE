//======================================================================
// MARK: - ConversationView.swift
// Path: foodai/Features/Messages/Views/ConversationView.swift
//======================================================================
import SwiftUI
import Combine

@MainActor
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    
    let conversationId: String
    let conversation: Conversation?
    private let messageService = MessageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(conversationId: String, conversation: Conversation? = nil) {
        self.conversationId = conversationId
        self.conversation = conversation
        
        Task {
            await loadMessages()
            await markAsRead()
        }
        
        setupRealtimeListeners()
    }
    
    private func setupRealtimeListeners() {
        // Listen for updates from MessageService polling
        messageService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshMessages()
                }
            }
            .store(in: &cancellables)
    }
    
    private func addNewMessage(_ message: Message) {
        messages.append(message)
        
        // Auto-mark as read when viewing the conversation
        Task {
            await markAsRead()
        }
    }
    
    private func refreshMessages() async {
        // Only refresh if we haven't loaded recently to avoid excessive API calls
        let now = Date()
        if now.timeIntervalSince(lastRefresh) > 3.0 { // Minimum 3 seconds between refreshes
            lastRefresh = now
            await loadMessages()
        }
    }
    
    private var lastRefresh = Date.distantPast
    
    func loadMessages() async {
        isLoading = true
        
        do {
            messages = try await messageService.fetchMessages(for: conversationId)
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            print("❌ Error loading messages: \(error)")
        }
        
        isLoading = false
    }
    
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSending = true
        
        do {
            let newMessage = try await messageService.sendMessage(to: conversationId, content: content)
            messages.append(newMessage)
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            print("❌ Error sending message: \(error)")
        }
        
        isSending = false
    }
    
    func markAsRead() async {
        do {
            try await messageService.markConversationAsRead(conversationId)
        } catch {
            print("❌ Error marking conversation as read: \(error)")
        }
    }
}

struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    init(conversationId: String, conversation: Conversation? = nil) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(conversationId: conversationId, conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .environmentObject(authManager)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    // Scroll to bottom when new message is added
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    // Scroll to bottom on appear
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            // Message input
            MessageInputView(
                text: $messageText,
                isSending: viewModel.isSending,
                onSend: {
                    Task {
                        await viewModel.sendMessage(messageText)
                        messageText = ""
                    }
                }
            )
            .focused($isTextFieldFocused)
        }
        .navigationTitle(viewModel.conversation?.displayName(currentUserId: authManager.currentUser?.id) ?? "Message")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let avatarUrl = viewModel.conversation?.displayAvatar(currentUserId: authManager.currentUser?.id) {
                ToolbarItem(placement: .principal) {
                    HStack {
                        RemoteImageView(imageURL: avatarUrl)
                            .frame(width: 32, height: 32)
                            .clipShape(Rectangle())
                        
                        Text(viewModel.conversation?.displayName(currentUserId: authManager.currentUser?.id) ?? "")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.markAsRead()
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    @EnvironmentObject var authManager: AuthManager
    
    private var isCurrentUser: Bool {
        guard let currentUserId = authManager.currentUser?.id else { 
            print("⚠️ No current user ID available")
            return false 
        }
        
        let result = message.senderId == currentUserId
        print("🔵 Message from: \(message.senderId), Current user: \(currentUserId), Is current user: \(result)")
        return result
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isCurrentUser { 
                Spacer(minLength: 50) 
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? AppEnvironment.Colors.textPrimary : Color.gray.opacity(0.2))
                    .foregroundColor(isCurrentUser ? AppEnvironment.Colors.background : AppEnvironment.Colors.textPrimary)
                    .cornerRadius(0)
                
                if message.isEdited {
                    Text("Edited")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser { 
                Spacer(minLength: 50) 
            }
        }
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let isSending: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("Type a message...", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isSending)
                    .onSubmit {
                        onSend()
                    }
                
                Button(action: onSend) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(AppEnvironment.Colors.textPrimary)
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Spacer to account for custom tab bar
            Rectangle()
                .fill(Color(.systemBackground))
                .frame(height: 60) // Height to clear the custom tab bar
        }
    }
}
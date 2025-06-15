import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var showNewMessage = false
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading conversations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.conversations.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.conversations) { conversation in
                                NavigationLink(destination: ConversationView(conversationId: conversation.id, conversation: conversation)) {
                                    ConversationRow(
                                        conversation: conversation,
                                        timestamp: viewModel.formatTimestamp(conversation.lastMessageAt)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if conversation.id != viewModel.conversations.last?.id {
                                    Divider()
                                        .padding(.leading, 70)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showNewMessage = true }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.black)
                    }
                }
            }
            .refreshable {
                await viewModel.loadConversations()
            }
            .sheet(isPresented: $showNewMessage) {
                NewMessageView { userId in
                    Task {
                        if let conversationId = await viewModel.createNewConversation(with: userId) {
                            // Reload conversations to show the new one
                            await viewModel.loadConversations()
                        }
                    }
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let timestamp: String
    @EnvironmentObject var authManager: AuthManager
    
    private var hasUnread: Bool {
        (conversation.unreadCount ?? 0) > 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // プロフィール画像
            if let avatarUrl = conversation.displayAvatar(currentUserId: authManager.currentUser?.id) {
                RemoteImageView(imageURL: avatarUrl)
                    .frame(width: 50, height: 50)
                    .clipShape(Rectangle())
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName(currentUserId: authManager.currentUser?.id))
                        .font(.system(size: 16, weight: hasUnread ? .semibold : .regular))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text(timestamp)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Text(conversation.lastMessagePreview ?? "Start a conversation")
                    .font(.system(size: 14))
                    .foregroundColor(hasUnread ? .black : .gray)
                    .lineLimit(1)
            }
            
            if hasUnread {
                ZStack {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                    
                    Text("\(conversation.unreadCount ?? 0)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No messages yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a conversation with someone")
                .font(.body)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NewMessageView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = UserSearchViewModel()
    @State private var searchText = ""
    let onSelectUser: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { _, newValue in
                            Task {
                                await viewModel.searchUsers(query: newValue)
                            }
                        }
                }
                .padding()
                
                // User list
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.users.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No users found")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Search for users to start a conversation")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.users, id: \.id) { user in
                        UserRowView(user: user) {
                            onSelectUser(user.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("All Users") {
                        Task {
                            await viewModel.getAllUsers()
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }
}

struct UserRowView: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Profile image
                if let avatarUrl = user.avatarUrl {
                    RemoteImageView(imageURL: avatarUrl)
                        .frame(width: 50, height: 50)
                        .clipShape(Rectangle())
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName ?? user.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
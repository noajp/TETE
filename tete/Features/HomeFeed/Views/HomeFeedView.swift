//======================================================================
// MARK: - HomeFeedView（写真共有アプリ版）
// Path: tete/Features/HomeFeed/Views/HomeFeedView.swift
//======================================================================
import SwiftUI
import Combine

@MainActor
struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @Binding var showGridMode: Bool
    @Binding var showingCreatePost: Bool
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var uploadCaption = ""
    @State private var newPost: Post?
    
    var body: some View {
        VStack(spacing: 0) {
            // Unified Header
            UnifiedHeader(
                title: "Feed",
                rightButton: HeaderButton(
                    icon: "plus",
                    action: {
                        print("🟢 Plus button tapped! Current state: \(showingCreatePost)")
                        showingCreatePost = true
                        print("🟢 After setting: \(showingCreatePost)")
                    }
                )
            )
                
            // Upload progress bar
            if isUploading {
                VStack(spacing: 8) {
                    HStack {
                        Text("Uploading")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !uploadCaption.isEmpty {
                            Text("・")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(uploadCaption)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(uploadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.red))
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
                
            // Content
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.posts.isEmpty && newPost == nil {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No posts yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Tap the + button\nto create your first post")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    if showGridMode {
                        // Complex Grid View
                        LazyVStack(spacing: 1) {
                            // Show new post first if available
                            if let newPost = newPost {
                                ComplexGridRowView(
                                    posts: [newPost],
                                    isOddRow: true,
                                    highlightFirst: true,
                                    onTap: { post in
                                        // Handle grid post tap if needed
                                    }
                                )
                            }
                            
                            // Group posts into rows and display them
                            ForEach(Array(groupPostsForComplexGrid(posts: viewModel.posts).enumerated()), id: \.offset) { index, rowPosts in
                                let isOddRow = (index + (newPost != nil ? 2 : 1)) % 2 == 1
                                ComplexGridRowView(
                                    posts: rowPosts,
                                    isOddRow: isOddRow,
                                    highlightFirst: false,
                                    onTap: { post in
                                        // Handle grid post tap if needed
                                    }
                                )
                            }
                        }
                        .padding(1)
                    } else {
                        // Single View (Feed)
                        LazyVStack(spacing: 0) {
                            // Show new post temporarily at top
                            if let newPost = newPost {
                                PostCardView(post: newPost, onLikeTapped: { post in
                                    Task {
                                        await viewModel.toggleLike(for: post)
                                    }
                                })
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red, lineWidth: 2)
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }
                            
                            // Regular posts
                            ForEach(viewModel.posts) { post in
                                PostCardView(post: post, onLikeTapped: { post in
                                    Task {
                                        await viewModel.toggleLike(for: post)
                                    }
                                })
                            }
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.forceRefreshPosts()
            }
        }
        .ignoresSafeArea(.container, edges: [])
        .onAppear {
            setupNotificationObservers()
        }
        .onReceive(NotificationCenter.default.publisher(for: .postUploadCompleted)) { notification in
            print("🟢 HomeFeedView: Received post upload completed notification")
            Task {
                await viewModel.forceRefreshPosts()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .postUploadStarted)) { notification in
            print("🟢 HomeFeedView: Post upload started")
            // Could show upload indicator here
        }
    }
    
    // MARK: - Helper Functions
    
    private func setupNotificationObservers() {
        // This function is called in onAppear but the actual observers are handled by onReceive modifiers
        print("🟢 HomeFeedView: Notification observers set up")
    }
    
    private func groupPostsForComplexGrid(posts: [Post]) -> [[Post]] {
        var result: [[Post]] = []
        var currentIndex = 0
        var isOddRow = true
        
        while currentIndex < posts.count {
            if isOddRow {
                // 奇数段: 2つの投稿 (横長1枚 + 正方形1枚)
                let rowPosts = Array(posts[currentIndex..<min(currentIndex + 2, posts.count)])
                result.append(rowPosts)
                currentIndex += 2
            } else {
                // 偶数段: 6つの投稿 (正方形6枚、3×2配置)
                let rowPosts = Array(posts[currentIndex..<min(currentIndex + 6, posts.count)])
                result.append(rowPosts)
                currentIndex += 6
            }
            isOddRow.toggle()
        }
        
        return result
    }
}

// MARK: - Complex Grid Row View
struct ComplexGridRowView: View {
    let posts: [Post]
    let isOddRow: Bool
    let highlightFirst: Bool
    let onTap: (Post) -> Void
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        if isOddRow {
            // 奇数段: 横長1枚 + 正方形1枚
            HStack(spacing: 1) {
                if posts.count > 0 {
                    // 横長写真 (幅の2/3)
                    GridImageView(
                        post: posts[0],
                        width: (screenWidth * 2/3) - 1,
                        height: (screenWidth * 1/3) - 1,
                        highlight: highlightFirst,
                        onTap: onTap
                    )
                }
                
                if posts.count > 1 {
                    // 正方形写真 (幅の1/3)
                    GridImageView(
                        post: posts[1],
                        width: (screenWidth * 1/3) - 1,
                        height: (screenWidth * 1/3) - 1,
                        highlight: false,
                        onTap: onTap
                    )
                }
            }
        } else {
            // 偶数段: 正方形6枚 (3列×2行、同じサイズを維持)
            VStack(spacing: 1) {
                // 上段3枚
                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { index in
                        if index < posts.count {
                            GridImageView(
                                post: posts[index],
                                width: (screenWidth / 3) - 1,
                                height: (screenWidth / 3) - 1,
                                highlight: false,
                                onTap: onTap
                            )
                        } else {
                            // 空のスペース
                            Rectangle()
                                .fill(Color(.systemBackground))
                                .frame(width: (screenWidth / 3) - 1, height: (screenWidth / 3) - 1)
                        }
                    }
                }
                
                // 下段3枚
                HStack(spacing: 1) {
                    ForEach(3..<6, id: \.self) { index in
                        if index < posts.count {
                            GridImageView(
                                post: posts[index],
                                width: (screenWidth / 3) - 1,
                                height: (screenWidth / 3) - 1,
                                highlight: false,
                                onTap: onTap
                            )
                        } else {
                            // 空のスペース
                            Rectangle()
                                .fill(Color(.systemBackground))
                                .frame(width: (screenWidth / 3) - 1, height: (screenWidth / 3) - 1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Grid Image View
struct GridImageView: View {
    let post: Post
    let width: CGFloat
    let height: CGFloat
    let highlight: Bool
    let onTap: (Post) -> Void
    
    var body: some View {
        Button(action: { onTap(post) }) {
            AsyncImage(url: URL(string: post.mediaUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            }
            .frame(width: width, height: height)
            .clipped()
            .overlay(
                highlight ? RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.red, lineWidth: 2) : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Grid Post View
struct GridPostView: View {
    let post: Post
    let onTap: (Post) -> Void
    
    var body: some View {
        Button(action: { onTap(post) }) {
            AsyncImage(url: URL(string: post.mediaUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            }
            .frame(width: UIScreen.main.bounds.width / 3 - 1, height: UIScreen.main.bounds.width / 3 - 1)
            .clipped()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Post Card View
struct PostCardView: View {
    let post: Post
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // User Header
            HStack(spacing: 12) {
                // Avatar
                AsyncImage(url: URL(string: post.user?.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay(
                            Text(post.user?.username.prefix(1).uppercased() ?? "?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onAppear {
                    print("🔍 PostCardView - Post ID: \(post.id)")
                    print("🔍 PostCardView - User ID: \(post.userId)")
                    print("🔍 PostCardView - User object: \(post.user?.username ?? "nil")")
                    print("🔍 PostCardView - Avatar URL: \(post.user?.avatarUrl ?? "nil")")
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user?.username ?? "unknown_user")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let location = post.locationName {
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Options
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Image
            AsyncImage(url: URL(string: post.mediaUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
            }
            .frame(maxHeight: 400)
            .clipped()
            
            // Actions
            HStack(spacing: 16) {
                // Like Button
                Button(action: { onLikeTapped(post) }) {
                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(post.isLikedByMe ? .red : .primary)
                }
                
                // Comment Button
                Button(action: {}) {
                    Image(systemName: "message")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Time
                Text(timeAgoString(from: post.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Caption
            if let caption = post.caption, !caption.isEmpty {
                HStack {
                    Text(caption)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
struct HomeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeedView(showGridMode: .constant(false), showingCreatePost: .constant(false))
    }
}

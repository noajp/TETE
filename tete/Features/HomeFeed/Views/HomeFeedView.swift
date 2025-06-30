import SwiftUI
import Combine

@MainActor
struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @Binding var showGridMode: Bool
    @Binding var showingCreatePost: Bool
    @State private var headerOffset: CGFloat = 0
    @State private var selectedPost: Post?
    
    private let headerHeight: CGFloat = 56
    
    var body: some View {
        ZStack(alignment: .top) {
            // Content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Scroll tracking - より信頼性の高い方法
                        GeometryReader { geometry in
                            Color.clear
                                .onChange(of: geometry.frame(in: .named("scroll")).minY) { _, newValue in
                                    updateHeaderOffset(scrollOffset: newValue)
                                }
                        }
                        .frame(height: 1)
                        .id("scrollTracker")
                    // Header space
                    Color.clear
                        .frame(height: headerHeight)
                    
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.posts.isEmpty {
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
                        // Posts Display - Grid or List mode
                        if showGridMode {
                            // Custom Grid View with alternating layout
                            CustomGridView(posts: viewModel.posts, showGridMode: $showGridMode, selectedPost: $selectedPost)
                        } else {
                            // List View (default)
                            if let selectedPost = selectedPost {
                                // Show selected post first, then other posts
                                PostCardView(post: selectedPost, onLikeTapped: { post in
                                    Task {
                                        await viewModel.toggleLike(for: post)
                                    }
                                })
                                .id(selectedPost.id)
                                
                                // Show other posts below
                                ForEach(viewModel.posts.filter { $0.id != selectedPost.id }) { post in
                                    PostCardView(post: post, onLikeTapped: { post in
                                        Task {
                                            await viewModel.toggleLike(for: post)
                                        }
                                    })
                                }
                            } else {
                                // Show all posts
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
            }
            .coordinateSpace(name: "scroll")
            .refreshable {
                await viewModel.forceRefreshPosts()
            }
        }
            
            // Floating Header
            VStack(spacing: 0) {
                UnifiedHeader(
                    title: "TETE",
                    rightButton: HeaderButton(
                        icon: "plus",
                        action: {
                            showingCreatePost = true
                        }
                    )
                )
                
                // Status Bar removed - handled by MainTabView
            }
            .offset(y: headerOffset)
            .zIndex(1000)
        }
        .ignoresSafeArea(.container, edges: [])
        .onAppear {
            print("🟢 HomeFeedView appeared")
            Task {
                await viewModel.loadPostsIfNeeded()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))) { _ in
            print("🔄 Post created notification received - refreshing feed")
            Task {
                await viewModel.forceRefreshPosts()
            }
        }
        // HomeFeedViewでの通知受信は無効化（MainTabViewで処理）
    }
    
    private func updateHeaderOffset(scrollOffset: CGFloat) {
        // シンプルな方法: 負の値（上にスクロール）に応じてヘッダーを隠す
        if scrollOffset < 0 {
            // 下にスクロールした場合（scrollOffsetが負の値）
            let scrollDistance = abs(scrollOffset)
            headerOffset = -min(scrollDistance, headerHeight)
        } else {
            // 上端付近
            headerOffset = 0
        }
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

// MARK: - Custom Grid View

struct CustomGridView: View {
    let posts: [Post]
    @Binding var showGridMode: Bool
    @Binding var selectedPost: Post?
    
    var body: some View {
        LazyVStack(spacing: 1.5) {
            ForEach(0..<groupedPosts.count, id: \.self) { groupIndex in
                let group = groupedPosts[groupIndex]
                let isOddRow = groupIndex % 2 == 0
                
                if isOddRow {
                    // 奇数段: 横長写真1枚 + 正方形写真1枚
                    OddRowView(posts: group) { post in
                        selectedPost = post
                        showGridMode = false
                    }
                } else {
                    // 偶数段: 正方形写真6枚
                    EvenRowView(posts: group) { post in
                        selectedPost = post
                        showGridMode = false
                    }
                }
            }
        }
    }
    
    private var groupedPosts: [[Post]] {
        var groups: [[Post]] = []
        var currentIndex = 0
        
        while currentIndex < posts.count {
            let isOddGroup = groups.count % 2 == 0
            
            if isOddGroup {
                // 奇数段: 2枚
                let count = min(2, posts.count - currentIndex)
                let group = Array(posts[currentIndex..<currentIndex + count])
                groups.append(group)
                currentIndex += count
            } else {
                // 偶数段: 6枚
                let count = min(6, posts.count - currentIndex)
                let group = Array(posts[currentIndex..<currentIndex + count])
                groups.append(group)
                currentIndex += count
            }
        }
        
        return groups
    }
}

// MARK: - Odd Row View (横長 + 正方形)

struct OddRowView: View {
    let posts: [Post]
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        HStack(spacing: 1.5) {
            // 横長写真 (幅は2/3)
            if posts.count > 0 {
                GridImageView(post: posts[0]) {
                    onPostTapped(posts[0])
                }
                .frame(width: rectangleWidth, height: squareSize)
                .clipped()
            }
            
            // 正方形写真 (幅は1/3)
            if posts.count > 1 {
                GridImageView(post: posts[1]) {
                    onPostTapped(posts[1])
                }
                .frame(width: squareSize, height: squareSize)
                .clipped()
            }
        }
        .frame(height: squareSize)
    }
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private var spacing: CGFloat {
        1.5
    }
    
    private var availableWidth: CGFloat {
        screenWidth - spacing // 中間のスペースのみ
    }
    
    private var squareSize: CGFloat {
        availableWidth / 3 // 3等分した1つ分
    }
    
    private var rectangleWidth: CGFloat {
        squareSize * 2 // 正方形の2倍の幅
    }
}

// MARK: - Even Row View (正方形6枚)

struct EvenRowView: View {
    let posts: [Post]
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        VStack(spacing: 1.5) {
            // 上段3枚
            HStack(spacing: 1.5) {
                ForEach(0..<3, id: \.self) { index in
                    if index < posts.count {
                        GridImageView(post: posts[index]) {
                            onPostTapped(posts[index])
                        }
                        .frame(width: squareSize, height: squareSize)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(.tertiarySystemBackground))
                            .frame(width: squareSize, height: squareSize)
                    }
                }
            }
            
            // 下段3枚
            HStack(spacing: 1.5) {
                ForEach(3..<6, id: \.self) { index in
                    if index < posts.count {
                        GridImageView(post: posts[index]) {
                            onPostTapped(posts[index])
                        }
                        .frame(width: squareSize, height: squareSize)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(.tertiarySystemBackground))
                            .frame(width: squareSize, height: squareSize)
                    }
                }
            }
        }
        .frame(height: totalHeight)
    }
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private var spacing: CGFloat {
        1.5
    }
    
    private var availableWidth: CGFloat {
        screenWidth - (spacing * 2) // 中間のスペース2箇所のみ
    }
    
    private var squareSize: CGFloat {
        availableWidth / 3 // 3等分した1つ分（奇数段の正方形と同じサイズ）
    }
    
    private var totalHeight: CGFloat {
        squareSize * 2 + spacing // 2段 + 中間のスペーシング
    }
}

// MARK: - Grid Image View

struct GridImageView: View {
    let post: Post
    let onTap: (() -> Void)?
    
    init(post: Post, onTap: (() -> Void)? = nil) {
        self.post = post
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            AsyncImage(url: URL(string: post.mediaUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        )
                case .empty:
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay(
                            ProgressView()
                                .tint(.secondary)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HomeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeedView(showGridMode: .constant(false), showingCreatePost: .constant(false))
    }
}
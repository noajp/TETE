//======================================================================
// MARK: - HomeFeedView.swift
// Purpose: Main feed displaying posts in grid or single view (グリッドまたはシングルビューで投稿を表示するメインフィード)
// Path: tete/Features/HomeFeed/Views/HomeFeedView.swift
//======================================================================
import SwiftUI
import Combine

@MainActor
struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @Binding var showGridMode: Bool
    @Binding var showingCreatePost: Bool
    @Binding var isInSingleView: Bool
    let onBackToGrid: (() -> Void)?
    @State private var headerOffset: CGFloat = 0
    @State private var selectedPost: Post?
    @State private var navigateToSingleView: Bool = false
    @Environment(\.dismiss) private var dismiss
    
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
                            CustomGridView(posts: viewModel.posts, showGridMode: $showGridMode, selectedPost: $selectedPost, navigateToSingleView: $navigateToSingleView)
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
        .navigationDestination(isPresented: $navigateToSingleView) {
            if let selectedPost = selectedPost {
                SinglePostView(
                    initialPost: selectedPost,
                    viewModel: viewModel,
                    showGridMode: $showGridMode
                )
                .onAppear {
                    isInSingleView = true
                }
                .onDisappear {
                    isInSingleView = false
                }
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
        .onChange(of: isInSingleView) { _, newValue in
            if !newValue && navigateToSingleView {
                // シングルビューから戻る時
                navigateToSingleView = false
                selectedPost = nil
            }
        }
        .onChange(of: showGridMode) { _, newValue in
            if newValue && isInSingleView {
                // グリッドモードに戻る時にシングルビューからも戻る
                navigateToSingleView = false
                selectedPost = nil
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
    @Binding var navigateToSingleView: Bool
    
    var body: some View {
        LazyVStack(spacing: 1.5) {
            ForEach(0..<groupedPosts.count, id: \.self) { groupIndex in
                let group = groupedPosts[groupIndex]
                let isOddRow = groupIndex % 2 == 0
                
                if isOddRow {
                    // 奇数段: 横長写真1枚 + 正方形写真1枚
                    OddRowView(posts: group) { post in
                        selectedPost = post
                        navigateToSingleView = true
                    }
                    .onAppear {
                        print("🎨 Using OddRowView for group \(groupIndex) with \(group.count) posts")
                    }
                } else {
                    // 偶数段: 正方形写真6枚
                    EvenRowView(posts: group) { post in
                        selectedPost = post
                        navigateToSingleView = true
                    }
                    .onAppear {
                        print("🎨 Using EvenRowView for group \(groupIndex) with \(group.count) posts")
                    }
                }
            }
        }
    }
    
    private var groupedPosts: [[Post]] {
        return createOptimalGrid(from: posts)
    }
    
    /// アスペクト比に基づいて最適なグリッドレイアウトを生成
    private func createOptimalGrid(from posts: [Post]) -> [[Post]] {
        print("🔍 CustomGridView: Creating grid for \(posts.count) posts")
        
        // デバッグ: 各投稿のアスペクト比を表示
        for (index, post) in posts.enumerated() {
            let aspectRatio = post.aspectRatio
            let shouldDisplayAsLandscape = post.shouldDisplayAsLandscape
            print("🔍 Post \(index): ID=\(post.id.prefix(8)), aspectRatio=\(aspectRatio?.description ?? "nil"), landscape=\(shouldDisplayAsLandscape)")
        }
        
        var groups: [[Post]] = []
        var currentIndex = 0
        
        while currentIndex < posts.count {
            let remainingPosts = posts.count - currentIndex
            
            // 現在位置から最適なグループを決定
            print("🔍 Processing from index \(currentIndex), remaining: \(remainingPosts)")
            
            // まず6枚以上ある場合の処理を優先（より効率的なレイアウト）
            if remainingPosts >= 6 {
                // 6枚以上の場合、最も厳しい条件で横長写真をチェック
                // 1枚目が横長の場合のみ横長グループを作成、それ以外は全て6枚グループ
                let firstPostIsLandscape = posts[currentIndex].shouldDisplayAsLandscape
                
                if firstPostIsLandscape {
                    // 1枚目が横長の場合のみ横長グループを作成
                    let group = createLandscapeGroup(startIndex: currentIndex, landscapeIndex: currentIndex, in: posts)
                    print("🔍 Created landscape group with \(group.count) posts (first post is landscape)")
                    print("🔍 Group posts: \(group.map { $0.id.prefix(8) })")
                    groups.append(group)
                    currentIndex += group.count
                } else {
                    // 1枚目が正方形の場合は必ず6枚グループを作成
                    let group = Array(posts[currentIndex..<currentIndex + 6])
                    print("🔍 Created 6-post square group (first post is not landscape)")
                    print("🔍 Group posts: \(group.map { $0.id.prefix(8) })")
                    groups.append(group)
                    currentIndex += 6
                }
            } else if let landscapeIndex = findNextLandscapePost(from: currentIndex, in: posts, maxLookAhead: remainingPosts) {
                // 6枚未満で横長写真がある場合
                let group = createLandscapeGroup(startIndex: currentIndex, landscapeIndex: landscapeIndex, in: posts)
                print("🔍 Created landscape group with \(group.count) posts (landscape at index \(landscapeIndex))")
                print("🔍 Group posts: \(group.map { $0.id.prefix(8) })")
                groups.append(group)
                currentIndex += group.count
            } else if remainingPosts >= 2 {
                // 残り2-5枚の場合は2枚グループ（横長スタイル）
                let count = min(2, remainingPosts)
                let group = Array(posts[currentIndex..<currentIndex + count])
                print("🔍 Created \(count)-post row group from index \(currentIndex)")
                print("🔍 Group posts: \(group.map { $0.id.prefix(8) })")
                groups.append(group)
                currentIndex += count
            } else {
                // 残り1枚の場合
                let group = Array(posts[currentIndex..<currentIndex + 1])
                print("🔍 Created single post group from index \(currentIndex)")
                print("🔍 Group posts: \(group.map { $0.id.prefix(8) })")
                groups.append(group)
                currentIndex += 1
            }
        }
        
        print("🔍 Final grid layout: \(groups.count) groups")
        return groups
    }
    
    /// 指定された範囲内で次の横長写真のインデックスを検索
    private func findNextLandscapePost(from startIndex: Int, in posts: [Post], maxLookAhead: Int) -> Int? {
        let endIndex = min(startIndex + maxLookAhead, posts.count)
        for i in startIndex..<endIndex {
            if posts[i].shouldDisplayAsLandscape {
                print("🔍 Found landscape post at index \(i): \(posts[i].id.prefix(8))")
                return i
            }
        }
        print("🔍 No landscape posts found in range \(startIndex)..<\(endIndex)")
        return nil
    }
    
    /// 横長写真を含むグループを作成（横長写真を最初に配置）
    private func createLandscapeGroup(startIndex: Int, landscapeIndex: Int, in posts: [Post]) -> [Post] {
        var group: [Post] = []
        
        // 横長写真を最初に追加
        group.append(posts[landscapeIndex])
        
        // 開始インデックスから横長写真より前の写真を追加
        for i in startIndex..<landscapeIndex {
            if group.count < 2 {
                group.insert(posts[i], at: 0)
            }
        }
        
        // 横長写真より後の写真を追加（必要に応じて）
        var nextIndex = landscapeIndex + 1
        while group.count < 2 && nextIndex < posts.count {
            group.append(posts[nextIndex])
            nextIndex += 1
        }
        
        return group
    }
}

// MARK: - Odd Row View (横長 + 正方形)

struct OddRowView: View {
    let posts: [Post]
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        HStack(spacing: 1.5) {
            // 最初の写真（アスペクト比に基づいて表示）
            if posts.count > 0 {
                let firstPost = posts[0]
                let isLandscape = firstPost.shouldDisplayAsLandscape
                
                if isLandscape {
                    // 横長写真は横長で表示 (幅は2/3)
                    GridImageView(post: firstPost) {
                        onPostTapped(firstPost)
                    }
                    .frame(width: rectangleWidth, height: squareSize)
                    .clipped()
                    .background(Color.blue.opacity(0.1)) // デバッグ用背景色
                    .onAppear {
                        print("🎨 OddRowView: First post \(firstPost.id.prefix(8)) isLandscape=\(isLandscape)")
                    }
                } else {
                    // 横長でない写真は正方形で表示
                    GridImageView(post: firstPost) {
                        onPostTapped(firstPost)
                    }
                    .frame(width: squareSize, height: squareSize)
                    .clipped()
                    .aspectRatio(1, contentMode: .fill)
                    .background(Color.red.opacity(0.1)) // デバッグ用背景色
                    .onAppear {
                        print("🎨 OddRowView: First post \(firstPost.id.prefix(8)) isLandscape=\(isLandscape)")
                    }
                }
            }
            
            // 2枚目の写真（常に正方形）
            if posts.count > 1 {
                let secondaryWidth = posts[0].shouldDisplayAsLandscape ? squareSize : rectangleWidth
                
                GridImageView(post: posts[1]) {
                    onPostTapped(posts[1])
                }
                .frame(width: secondaryWidth, height: squareSize)
                .clipped()
                .aspectRatio(1, contentMode: .fill)
                .background(Color.green.opacity(0.1)) // デバッグ用背景色
                .onAppear {
                    print("🎨 OddRowView: Second post width=\(secondaryWidth)")
                }
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
                        .aspectRatio(1, contentMode: .fill)
                        .background(Color.yellow.opacity(0.1)) // デバッグ用背景色
                        .onAppear {
                            print("🎨 EvenRowView: Top row index \(index) - Post \(posts[index].id.prefix(8))")
                        }
                    } else {
                        Rectangle()
                            .fill(Color(.tertiarySystemBackground))
                            .frame(width: squareSize, height: squareSize)
                            .onAppear {
                                print("🎨 EvenRowView: Top row index \(index) - Empty placeholder")
                            }
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
                        .aspectRatio(1, contentMode: .fill)
                        .background(Color.orange.opacity(0.1)) // デバッグ用背景色
                        .onAppear {
                            print("🎨 EvenRowView: Bottom row index \(index) - Post \(posts[index].id.prefix(8))")
                        }
                    } else {
                        Rectangle()
                            .fill(Color(.tertiarySystemBackground))
                            .frame(width: squareSize, height: squareSize)
                            .onAppear {
                                print("🎨 EvenRowView: Bottom row index \(index) - Empty placeholder")
                            }
                    }
                }
            }
        }
        .frame(height: totalHeight)
        .onAppear {
            print("🎨 EvenRowView: Displaying \(posts.count) posts total")
        }
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
            // 高性能なOptimizedAsyncImageを使用
            OptimizedAsyncImage(urlString: post.mediaUrl) { phase in
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
        HomeFeedView(
            showGridMode: .constant(false), 
            showingCreatePost: .constant(false),
            isInSingleView: .constant(false),
            onBackToGrid: nil
        )
    }
}
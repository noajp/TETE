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
    @StateObject private var postStatusManager = PostStatusManager.shared
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
                        .frame(height: headerHeight - 8)
                    
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
            
            // Floating Header with Status Bar
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
                
                // Post Upload Status Bar
                if PostStatusManager.shared.showStatus {
                    VStack(spacing: 0) {
                        // Status message
                        HStack {
                            Text(PostStatusManager.shared.statusMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("×") {
                                PostStatusManager.shared.hideStatus()
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                        
                        // Thin progress bar
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 2)
                            
                            Rectangle()
                                .fill(PostStatusManager.shared.statusColor)
                                .frame(width: UIScreen.main.bounds.width * PostStatusManager.shared.progress, height: 2)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
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
    @Environment(\.colorScheme) var colorScheme
    
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
                                .font(.title)
                                .foregroundColor(.secondary)
                        )
                case .empty:
                    // 読み込み中のスケルトン表示
                    ZStack {
                        if colorScheme == .dark {
                            // ダークモード: 濃いダークグレーの塗りつぶし
                            Rectangle()
                                .fill(Color(white: 0.15))
                        } else {
                            // 通常モード: グレーの塗りつぶし
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                        }
                    }
                @unknown default:
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                }
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
    @State private var loadedImages: Set<String> = []
    @State private var groupLoadStatus: [Int: Bool] = [:]
    
    var body: some View {
        LazyVStack(spacing: 1.5) {
            ForEach(0..<groupedPosts.count, id: \.self) { groupIndex in
                let group = groupedPosts[groupIndex]
                let isOddRow = groupIndex % 2 == 0
                let showGroup = groupLoadStatus[groupIndex] ?? false
                
                if isOddRow {
                    // 奇数段: 横長写真1枚 + 正方形写真1枚
                    OddRowView(
                        posts: group,
                        showContent: showGroup,
                        onImageLoaded: { postId in
                            loadedImages.insert(postId)
                            checkGroupLoadStatus(groupIndex: groupIndex, group: group)
                        }
                    ) { post in
                        selectedPost = post
                        navigateToSingleView = true
                    }
                    .onAppear {
                        print("🎨 Using OddRowView for group \(groupIndex) with \(group.count) posts")
                    }
                } else {
                    // 偶数段: 正方形写真6枚
                    EvenRowView(
                        posts: group,
                        showContent: showGroup,
                        onImageLoaded: { postId in
                            loadedImages.insert(postId)
                            checkGroupLoadStatus(groupIndex: groupIndex, group: group)
                        }
                    ) { post in
                        selectedPost = post
                        navigateToSingleView = true
                    }
                    .onAppear {
                        print("🎨 Using EvenRowView for group \(groupIndex) with \(group.count) posts")
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var groupedPosts: [[Post]] {
        return createOptimalGrid(from: posts)
    }
    
    private func checkGroupLoadStatus(groupIndex: Int, group: [Post]) {
        let allImagesInGroupLoaded = group.allSatisfy { post in
            loadedImages.contains(post.id)
        }
        
        if allImagesInGroupLoaded && groupLoadStatus[groupIndex] != true {
            withAnimation(.easeIn(duration: 0.3)) {
                groupLoadStatus[groupIndex] = true
            }
        }
    }
    
    /// 新しい仕様に基づいてグリッドレイアウトを生成
    private func createOptimalGrid(from posts: [Post]) -> [[Post]] {
        print("🔍 CustomGridView: Creating grid for \(posts.count) posts")
        
        var groups: [[Post]] = []
        var blockNumber = 1 // ブロック番号（1から開始）
        
        // 投稿を横長と正方形に分類
        var landscapePosts: [(index: Int, post: Post)] = []
        var squarePosts: [(index: Int, post: Post)] = []
        
        for (index, post) in posts.enumerated() {
            if post.shouldDisplayAsLandscape {
                landscapePosts.append((index, post))
            } else {
                squarePosts.append((index, post))
            }
        }
        
        print("🔍 Total posts: \(posts.count), Landscape: \(landscapePosts.count), Square: \(squarePosts.count)")
        
        var landscapeIndex = 0
        var squareIndex = 0
        
        while landscapeIndex < landscapePosts.count || squareIndex < squarePosts.count {
            if blockNumber % 2 == 1 {
                // 奇数ブロック：横長1枚 + 正方形1枚
                var block: [Post] = []
                
                // 横長写真を1枚追加
                if landscapeIndex < landscapePosts.count {
                    block.append(landscapePosts[landscapeIndex].post)
                    landscapeIndex += 1
                } else if squareIndex < squarePosts.count {
                    // 横長写真がない場合は正方形を使用
                    block.append(squarePosts[squareIndex].post)
                    squareIndex += 1
                }
                
                // 正方形写真を1枚追加
                if squareIndex < squarePosts.count {
                    block.append(squarePosts[squareIndex].post)
                    squareIndex += 1
                } else if landscapeIndex < landscapePosts.count {
                    // 正方形写真がない場合は横長を使用
                    block.append(landscapePosts[landscapeIndex].post)
                    landscapeIndex += 1
                }
                
                if !block.isEmpty {
                    print("🔍 Created odd block #\(blockNumber) with \(block.count) posts")
                    groups.append(block)
                }
            } else {
                // 偶数ブロック：正方形6枚
                var block: [Post] = []
                let neededSquares = 6
                
                // まず正方形写真を使用
                while block.count < neededSquares && squareIndex < squarePosts.count {
                    block.append(squarePosts[squareIndex].post)
                    squareIndex += 1
                }
                
                // 不足分は横長写真で補填
                while block.count < neededSquares && landscapeIndex < landscapePosts.count {
                    block.append(landscapePosts[landscapeIndex].post)
                    landscapeIndex += 1
                }
                
                if !block.isEmpty {
                    print("🔍 Created even block #\(blockNumber) with \(block.count) posts")
                    groups.append(block)
                }
            }
            
            blockNumber += 1
            
            // 全ての写真を使い切ったら終了
            if landscapeIndex >= landscapePosts.count && squareIndex >= squarePosts.count {
                break
            }
        }
        
        print("🔵 Grid creation complete with \(groups.count) blocks")
        return groups
    }
}

// MARK: - Odd Row View (横長 + 正方形)

struct OddRowView: View {
    let posts: [Post]
    let showContent: Bool
    let onImageLoaded: (String) -> Void
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        HStack(spacing: 1.5) {
            // 最初の写真（アスペクト比に基づいて表示）
            if posts.count > 0 {
                let firstPost = posts[0]
                let isLandscape = firstPost.shouldDisplayAsLandscape
                
                if isLandscape {
                    // 横長写真は横長で表示 (幅は2/3)
                    GridImageView(
                        post: firstPost,
                        showContent: showContent,
                        onImageLoaded: { onImageLoaded(firstPost.id) }
                    ) {
                        onPostTapped(firstPost)
                    }
                    .frame(width: rectangleWidth, height: squareSize)
                    .clipped()
                    .onAppear {
                        print("🎨 OddRowView: First post \(firstPost.id.prefix(8)) isLandscape=\(isLandscape)")
                    }
                } else {
                    // 横長でない写真は正方形で表示
                    GridImageView(
                        post: firstPost,
                        showContent: showContent,
                        onImageLoaded: { onImageLoaded(firstPost.id) }
                    ) {
                        onPostTapped(firstPost)
                    }
                    .frame(width: squareSize, height: squareSize)
                    .clipped()
                    .aspectRatio(1, contentMode: .fill)
                    .onAppear {
                        print("🎨 OddRowView: First post \(firstPost.id.prefix(8)) isLandscape=\(isLandscape)")
                    }
                }
            }
            
            // 2枚目の写真（常に正方形）
            if posts.count > 1 {
                let secondaryWidth = posts[0].shouldDisplayAsLandscape ? squareSize : rectangleWidth
                
                GridImageView(
                    post: posts[1],
                    showContent: showContent,
                    onImageLoaded: { onImageLoaded(posts[1].id) }
                ) {
                    onPostTapped(posts[1])
                }
                .frame(width: secondaryWidth, height: squareSize)
                .clipped()
                .aspectRatio(1, contentMode: .fill)
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
    let showContent: Bool
    let onImageLoaded: (String) -> Void
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        VStack(spacing: 1.5) {
            // 上段3枚
            HStack(spacing: 1.5) {
                ForEach(0..<3, id: \.self) { index in
                    if index < posts.count {
                        GridImageView(
                            post: posts[index],
                            showContent: showContent,
                            onImageLoaded: { onImageLoaded(posts[index].id) }
                        ) {
                            onPostTapped(posts[index])
                        }
                        .frame(width: squareSize, height: squareSize)
                        .clipped()
                        .aspectRatio(1, contentMode: .fill)
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
                        GridImageView(
                            post: posts[index],
                            showContent: showContent,
                            onImageLoaded: { onImageLoaded(posts[index].id) }
                        ) {
                            onPostTapped(posts[index])
                        }
                        .frame(width: squareSize, height: squareSize)
                        .clipped()
                        .aspectRatio(1, contentMode: .fill)
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
    let showContent: Bool
    let onImageLoaded: (() -> Void)?
    let onTap: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    @State private var imageLoaded = false
    
    init(post: Post, showContent: Bool = true, onImageLoaded: (() -> Void)? = nil, onTap: (() -> Void)? = nil) {
        self.post = post
        self.showContent = showContent
        self.onImageLoaded = onImageLoaded
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
                    Group {
                        if showContent {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .transition(.opacity)
                        } else {
                            // コンテンツをまだ表示しない場合はスケルトンを表示
                            ZStack {
                                if colorScheme == .dark {
                                    // ダークモード: 濃いダークグレーの塗りつぶし
                                    Rectangle()
                                        .fill(Color(white: 0.15))
                                } else {
                                    // 通常モード: グレーの塗りつぶし
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.15))
                                }
                            }
                        }
                    }
                    // 画像が読み込まれたことを通知
                    .onAppear {
                        if !imageLoaded {
                            imageLoaded = true
                            onImageLoaded?()
                        }
                    }
                case .failure(_):
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        )
                case .empty:
                    // 読み込み中のスケルトン表示
                    ZStack {
                        if colorScheme == .dark {
                            // ダークモード: 濃いダークグレーの塗りつぶし
                            Rectangle()
                                .fill(Color(white: 0.15))
                        } else {
                            // 通常モード: グレーの塗りつぶし
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                        }
                    }
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
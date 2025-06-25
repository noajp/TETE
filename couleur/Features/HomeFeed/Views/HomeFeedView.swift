//======================================================================
// MARK: - HomeFeedView（写真共有アプリ版）
// Path: foodai/Features/HomeFeed/Views/HomeFeedView.swift
//======================================================================
import SwiftUI

@MainActor
struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @Binding var showGridMode: Bool
    
    // 投稿をグループ化（横長1枚+正方形1枚、正方形6枚のパターン）
    private var groupedPosts: [(Int, [Post])] {
        let posts = viewModel.posts
        var groups: [(Int, [Post])] = []
        var currentIndex = 0
        
        while currentIndex < posts.count {
            if (groups.count + 1) % 2 == 1 {
                // 奇数行：横長1枚+正方形1枚
                let group = Array(posts[currentIndex..<min(currentIndex + 2, posts.count)])
                groups.append((groups.count, group))
                currentIndex += 2
            } else {
                // 偶数行：正方形6枚（2x3グリッド）
                let group = Array(posts[currentIndex..<min(currentIndex + 6, posts.count)])
                groups.append((groups.count, group))
                currentIndex += 6
            }
        }
        
        return groups
    }
    
    private var columns: [GridItem] {
        if showGridMode {
            // グリッドモード（2x2）
            return [
                GridItem(.flexible(), spacing: 1),
                GridItem(.flexible(), spacing: 1)
            ]
        } else {
            // シングルモード（1枚表示）
            return [GridItem(.flexible())]
        }
    }
    
    var body: some View {
        ScrollableHeaderView(title: "Feed") {
            ZStack {
                // 背景色
                MinimalDesign.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.posts.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
        }
        .accentColor(MinimalDesign.Colors.accentRed)
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        ProgressView("Loading...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MinimalDesign.Colors.background)
    }
    
    private var emptyView: some View {
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
        .background(MinimalDesign.Colors.background)
    }
    
    private var contentView: some View {
        ZStack(alignment: .top) {
            ScrollView {
                if showGridMode {
                    // 複数枚フィードモード（グリッドビュー）
                    LazyVStack(spacing: 2) {
                        ForEach(groupedPosts, id: \.0) { (groupIndex, group) in
                            MultiPhotoRowView(posts: group, onLikeTapped: { post in
                                // グリッドビューで写真をタップしたらシングルビューに切り替え
                                showGridMode = false
                            })
                        }
                    }
                    .padding(.horizontal, 0)
                } else {
                    // シングルモード（1枚ずつ表示）
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.posts) { post in
                            SingleCardView(post: post, onLikeTapped: { post in
                                Task {
                                    await viewModel.toggleLike(for: post)
                                }
                            })
                            .buttonStyle(PlainButtonStyle())
                            .background(Color.clear)
                        }
                    }
                }
            }
            .padding(.bottom, 100) // タブバー分のスペース
        }
        .refreshable {
            await viewModel.loadPosts()
        }
    }
}

// MARK: - Multi Photo Row Component

struct MultiPhotoRowView: View {
    let posts: [Post]
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        if posts.count == 1 {
            // 単体表示
            SinglePhotoView(post: posts[0], onLikeTapped: onLikeTapped)
        } else if posts.count == 2 {
            // 横長1枚+正方形1枚
            LandscapeSquareRowView(posts: posts, onLikeTapped: onLikeTapped)
        } else if posts.count == 3 {
            // 正方形3枚（一時的に3枚処理）
            ThreeSquareRowView(posts: posts, onLikeTapped: onLikeTapped)
        } else if posts.count >= 4 {
            // 正方形6枚（4枚の場合は4枚、6枚以上の場合は6枚）
            SixSquareRowView(posts: Array(posts.prefix(6)), onLikeTapped: onLikeTapped)
        }
    }
}

// 横長1枚+正方形1枚の行
struct LandscapeSquareRowView: View {
    let posts: [Post]
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        HStack(spacing: 2) {
            if posts.count >= 1 {
                // 横長写真（左側）余白2ptを考慮して274pt
                MultiPhotoCard(post: posts[0], width: 274, height: 117, onLikeTapped: onLikeTapped)
            }
            
            if posts.count >= 2 {
                // 正方形写真（右側）117x117の正方形
                MultiPhotoCard(post: posts[1], width: 117, height: 117, onLikeTapped: onLikeTapped)
            }
        }
    }
}

// 正方形3枚の行（一時的処理用）
struct ThreeSquareRowView: View {
    let posts: [Post]
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                if index < posts.count {
                    MultiPhotoCard(post: posts[index], width: 129.67, height: 129.67, onLikeTapped: onLikeTapped)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 129.67, height: 129.67)
                }
            }
        }
    }
}

// 正方形6枚の行（2x3グリッド）
struct SixSquareRowView: View {
    let posts: [Post]
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            // 上段：3枚
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    if index < posts.count {
                        MultiPhotoCard(post: posts[index], width: 129.67, height: 129.67, onLikeTapped: onLikeTapped)
                    } else {
                        // 投稿が不足している場合は空のスペース
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 129.67, height: 129.67)
                    }
                }
            }
            
            // 下段：3枚
            HStack(spacing: 2) {
                ForEach(3..<6, id: \.self) { index in
                    if index < posts.count {
                        MultiPhotoCard(post: posts[index], width: 129.67, height: 129.67, onLikeTapped: onLikeTapped)
                    } else {
                        // 投稿が不足している場合は空のスペース
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 129.67, height: 129.67)
                    }
                }
            }
        }
    }
}

// 単体写真表示
struct SinglePhotoView: View {
    let post: Post
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        SingleCardView(post: post, onLikeTapped: onLikeTapped)
    }
}

// マルチフォト用カード
struct MultiPhotoCard: View {
    let post: Post
    let width: CGFloat
    let height: CGFloat
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        Button(action: {
            onLikeTapped(post)
        }) {
            // 画像
            FastAsyncImage(urlString: post.mediaUrl) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Feed Components

struct ModernFeedHeader: View {
    @Binding var showGridMode: Bool
    
    var body: some View {
        HStack {
            Text("couleur")
                .font(MinimalDesign.Typography.title)
                .fontWeight(.light)
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Spacer()
            
            // View Mode Toggle
            Button(action: { showGridMode.toggle() }) {
                Image(systemName: showGridMode ? "rectangle.grid.1x2" : "square.grid.2x2")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(MinimalDesign.Colors.primary)
            }
        }
        .padding(.horizontal, MinimalDesign.Spacing.md)
        .padding(.vertical, MinimalDesign.Spacing.sm)
    }
}

struct ModernFeedCard: View {
    let post: Post
    let onLikeTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // User Header
            HStack(spacing: MinimalDesign.Spacing.sm) {
                // Avatar
                AsyncImage(url: URL(string: post.user?.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(MinimalDesign.Colors.tertiaryBackground)
                }
                .frame(width: 32, height: 32)
                .clipped()
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user?.username ?? "unknown")
                        .font(MinimalDesign.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(MinimalDesign.Colors.primary)
                    
                    if let location = post.locationName {
                        Text(location)
                            .font(MinimalDesign.Typography.caption)
                            .foregroundColor(MinimalDesign.Colors.secondary)
                    }
                }
                
                Spacer()
                
                // Options
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(MinimalDesign.Colors.tertiary)
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
            .padding(.vertical, MinimalDesign.Spacing.sm)
            
            // Image
            AsyncImage(url: URL(string: post.mediaUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(MinimalDesign.Colors.tertiaryBackground)
            }
            .frame(maxHeight: 400)
            .clipped()
            
            // Actions
            HStack(spacing: MinimalDesign.Spacing.md) {
                // Like Button
                Button(action: onLikeTapped) {
                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(post.isLikedByMe ? .red : MinimalDesign.Colors.primary)
                }
                
                // Comment Button
                Button(action: {}) {
                    Image(systemName: "message")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(MinimalDesign.Colors.primary)
                }
                
                Spacer()
                
                // Time
                Text(timeAgoString(from: post.createdAt))
                    .font(MinimalDesign.Typography.caption)
                    .foregroundColor(MinimalDesign.Colors.tertiary)
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
            .padding(.vertical, MinimalDesign.Spacing.sm)
            
            // Caption
            if let caption = post.caption, !caption.isEmpty {
                HStack {
                    Text(caption)
                        .font(MinimalDesign.Typography.body)
                        .foregroundColor(MinimalDesign.Colors.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, MinimalDesign.Spacing.md)
                .padding(.bottom, MinimalDesign.Spacing.sm)
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ModernGridCard: View {
    let post: Post
    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: post.mediaUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(MinimalDesign.Colors.tertiaryBackground)
            }
            .frame(height: 160)
            .clipped()
            
            // Overlay
            if post.isLikedByMe {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(MinimalDesign.Spacing.xs)
            }
        }
    }
}

// MARK: - Preview
struct HomeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeedView(showGridMode: .constant(false))
    }
}


//======================================================================
// MARK: - HomeFeedView（写真共有アプリ版）
// Path: foodai/Features/HomeFeed/Views/HomeFeedView.swift
//======================================================================
import SwiftUI

@MainActor
struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @Binding var showGridMode: Bool
    
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
                    // グリッドモード
                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(destination: PostDetailView(post: post, onLikeTapped: { post in
                                Task {
                                    await viewModel.toggleLike(for: post)
                                }
                            })) {
                                PinCardView(post: post, onLikeTapped: { post in
                                    Task {
                                        await viewModel.toggleLike(for: post)
                                    }
                                })
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(Color.clear)
                        }
                    }
                    .padding(.horizontal, 0)
                } else {
                    // シングルモード（1枚ずつ表示）
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(destination: PostDetailView(post: post, onLikeTapped: { post in
                                Task {
                                    await viewModel.toggleLike(for: post)
                                }
                            })) {
                                SingleCardView(post: post, onLikeTapped: { post in
                                    Task {
                                        await viewModel.toggleLike(for: post)
                                    }
                                })
                            }
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


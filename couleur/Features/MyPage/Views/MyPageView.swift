//======================================================================
// MARK: - MyPageView.swift (Minimal Design Profile)
// Path: couleur/Features/MyPage/Views/MyPageView.swift
//======================================================================
import SwiftUI
import PhotosUI

@MainActor
struct MyPageView: View {
    @StateObject private var viewModel = MyPageViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header
                ModernProfileHeader(
                    onSettings: { showSettings = true }
                )
                
                Divider()
                    .foregroundColor(MinimalDesign.Colors.border)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: MinimalDesign.Spacing.xl) {
                        // Profile Section
                        ModernProfileSection(
                            profile: viewModel.userProfile,
                            isLoading: viewModel.isLoading,
                            onEditProfile: { showEditProfile = true },
                            selectedPhotoItem: $selectedPhotoItem
                        )
                        
                        // Stats Section
                        ModernStatsSection(
                            postsCount: viewModel.postsCount,
                            followersCount: viewModel.followersCount,
                            followingCount: viewModel.followingCount,
                            onFollowersTap: { viewModel.navigateToFollowers() },
                            onFollowingTap: { viewModel.navigateToFollowing() }
                        )
                        
                        // Posts Tab Section
                        ModernPostsTabSection(posts: viewModel.userPosts)
                    }
                    .padding(.vertical, MinimalDesign.Spacing.md)
                }
            }
            .background(MinimalDesign.Colors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authManager)
            }
            .task {
                await viewModel.loadUserData()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await viewModel.updateProfilePhoto(item: newItem)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Modern Profile Components

struct ModernProfileHeader: View {
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Text("Profile")
                .font(MinimalDesign.Typography.title)
                .fontWeight(.light)
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Spacer()
            
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(MinimalDesign.Colors.primary)
            }
        }
        .padding(.horizontal, MinimalDesign.Spacing.md)
        .padding(.vertical, MinimalDesign.Spacing.sm)
    }
}

struct ModernProfileSection: View {
    let profile: UserProfile?
    let isLoading: Bool
    let onEditProfile: () -> Void
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: MinimalDesign.Spacing.lg) {
            // Profile Image
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack {
                    // Avatar
                    if let avatarUrl = profile?.avatarUrl {
                        FastAsyncImage(urlString: avatarUrl) {
                            Rectangle()
                                .fill(MinimalDesign.Colors.tertiaryBackground)
                        }
                        .frame(width: 120, height: 120)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiaryBackground)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(MinimalDesign.Colors.tertiary)
                            )
                    }
                    
                    // Edit Indicator
                    Rectangle()
                        .fill(MinimalDesign.Colors.primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .offset(x: 44, y: 44)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                VStack(spacing: MinimalDesign.Spacing.sm) {
                    // Name
                    Text(profile?.displayName ?? profile?.username ?? "User")
                        .font(MinimalDesign.Typography.title)
                        .fontWeight(.medium)
                        .foregroundColor(MinimalDesign.Colors.primary)
                    
                    // Bio
                    if let bio = profile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(MinimalDesign.Typography.body)
                            .foregroundColor(MinimalDesign.Colors.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, MinimalDesign.Spacing.lg)
                    }
                    
                    // Edit Button
                    Button(action: onEditProfile) {
                        Text("Edit Profile")
                            .minimalButton(style: .secondary)
                    }
                }
            }
        }
        .padding(.horizontal, MinimalDesign.Spacing.md)
    }
}

struct ModernStatsSection: View {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let onFollowersTap: () -> Void
    let onFollowingTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ModernStatItem(value: "\(postsCount)", label: "Posts", action: nil)
            
            Rectangle()
                .fill(MinimalDesign.Colors.border)
                .frame(width: 1, height: 48)
            
            ModernStatItem(value: "\(followersCount)", label: "Followers", action: onFollowersTap)
            
            Rectangle()
                .fill(MinimalDesign.Colors.border)
                .frame(width: 1, height: 48)
            
            ModernStatItem(value: "\(followingCount)", label: "Following", action: onFollowingTap)
        }
        .background(MinimalDesign.Colors.background)
        .overlay(
            Rectangle()
                .stroke(MinimalDesign.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, MinimalDesign.Spacing.md)
    }
}

struct ModernStatItem: View {
    let value: String
    let label: String
    let action: (() -> Void)?
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    statContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                statContent
            }
        }
    }
    
    private var statContent: some View {
        VStack(spacing: MinimalDesign.Spacing.xs) {
            Text(value)
                .font(MinimalDesign.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Text(label)
                .font(MinimalDesign.Typography.caption)
                .foregroundColor(MinimalDesign.Colors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MinimalDesign.Spacing.md)
    }
}

struct ModernPostsTabSection: View {
    @State private var showGridMode = false
    @State private var selectedTab: PostTab = .posts
    let posts: [Post]
    
    enum PostTab: String, CaseIterable {
        case posts = "posts"
        case magazine = "book"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                // Posts button with toggle functionality
                Button(action: {
                    if selectedTab == .posts {
                        showGridMode.toggle()
                    } else {
                        selectedTab = .posts
                    }
                }) {
                    Group {
                        if showGridMode && selectedTab == .posts {
                            // Grid mode - 4 small squares
                            VStack(spacing: 2) {
                                HStack(spacing: 2) {
                                    Rectangle()
                                        .fill(selectedTab == .posts ? MinimalDesign.Colors.primary : MinimalDesign.Colors.tertiary)
                                        .frame(width: 8, height: 8)
                                    Rectangle()
                                        .fill(selectedTab == .posts ? MinimalDesign.Colors.primary : MinimalDesign.Colors.tertiary)
                                        .frame(width: 8, height: 8)
                                }
                                HStack(spacing: 2) {
                                    Rectangle()
                                        .fill(selectedTab == .posts ? MinimalDesign.Colors.primary : MinimalDesign.Colors.tertiary)
                                        .frame(width: 8, height: 8)
                                    Rectangle()
                                        .fill(selectedTab == .posts ? MinimalDesign.Colors.primary : MinimalDesign.Colors.tertiary)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        } else {
                            // Single mode - 1 large square
                            Rectangle()
                                .fill(selectedTab == .posts ? MinimalDesign.Colors.primary : MinimalDesign.Colors.tertiary)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .frame(height: 30)
                }
                .frame(maxWidth: .infinity)
                
                // Magazine button
                Button(action: { selectedTab = .magazine }) {
                    Image(systemName: selectedTab == .magazine ? "book.fill" : "book")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(selectedTab == .magazine ? MinimalDesign.Colors.primary : MinimalDesign.Colors.tertiary)
                        .frame(height: 30)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
            .padding(.vertical, MinimalDesign.Spacing.md)
            
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .posts:
                    if showGridMode {
                        GridView(posts: posts)
                    } else {
                        SingleCardGridView(posts: posts)
                    }
                case .magazine:
                    MagazineView(posts: posts)
                }
            }
            .padding(.top, MinimalDesign.Spacing.md)
        }
    }
}

struct SingleCardGridView: View {
    let posts: [Post]
    
    var body: some View {
        if posts.isEmpty {
            VStack(spacing: MinimalDesign.Spacing.lg) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(MinimalDesign.Colors.tertiary)
                
                Text("まだ投稿がありません")
                    .font(MinimalDesign.Typography.body)
                    .foregroundColor(MinimalDesign.Colors.secondary)
            }
            .frame(height: 300)
        } else {
            ScrollView {
                LazyVStack(spacing: MinimalDesign.Spacing.lg) {
                    ForEach(posts) { post in
                        VStack(spacing: 0) {
                            // User header
                            HStack(spacing: MinimalDesign.Spacing.sm) {
                                // Avatar
                                if let avatarUrl = post.user?.avatarUrl {
                                    FastAsyncImage(urlString: avatarUrl) {
                                        Rectangle()
                                            .fill(MinimalDesign.Colors.tertiaryBackground)
                                    }
                                    .frame(width: 32, height: 32)
                                    .clipped()
                                } else {
                                    Rectangle()
                                        .fill(MinimalDesign.Colors.tertiaryBackground)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(MinimalDesign.Colors.tertiary)
                                        )
                                }
                                
                                Text(post.user?.username ?? "unknown")
                                    .font(MinimalDesign.Typography.body)
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, MinimalDesign.Spacing.md)
                            .padding(.vertical, MinimalDesign.Spacing.sm)
                            
                            // Image
                            FastAsyncImage(urlString: post.mediaUrl) {
                                Rectangle()
                                    .fill(MinimalDesign.Colors.tertiaryBackground)
                            }
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width)
                            .clipped()
                            
                            // Actions
                            HStack(spacing: MinimalDesign.Spacing.md) {
                                Button(action: {}) {
                                    HStack(spacing: MinimalDesign.Spacing.xs) {
                                        Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(post.isLikedByMe ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
                                        
                                        if post.likeCount > 0 {
                                            Text("\(post.likeCount)")
                                                .font(MinimalDesign.Typography.body)
                                                .foregroundColor(MinimalDesign.Colors.primary)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {}) {
                                    Image(systemName: "message")
                                        .font(.system(size: 24, weight: .regular))
                                        .foregroundColor(MinimalDesign.Colors.primary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, MinimalDesign.Spacing.md)
                            .padding(.vertical, MinimalDesign.Spacing.sm)
                            
                            // Caption
                            if let caption = post.caption, !caption.isEmpty {
                                Text(caption)
                                    .font(MinimalDesign.Typography.body)
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, MinimalDesign.Spacing.md)
                                    .padding(.bottom, MinimalDesign.Spacing.md)
                            }
                        }
                        .background(MinimalDesign.Colors.background)
                    }
                }
            }
        }
    }
}

struct GridView: View {
    let posts: [Post]
    
    var body: some View {
        if posts.isEmpty {
            VStack(spacing: MinimalDesign.Spacing.lg) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(MinimalDesign.Colors.tertiary)
                
                Text("まだ投稿がありません")
                    .font(MinimalDesign.Typography.body)
                    .foregroundColor(MinimalDesign.Colors.secondary)
            }
            .frame(height: 300)
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: MinimalDesign.Spacing.xs),
                GridItem(.flexible(), spacing: MinimalDesign.Spacing.xs)
            ], spacing: MinimalDesign.Spacing.xs) {
                ForEach(posts) { post in
                    FastAsyncImage(urlString: post.mediaUrl) {
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiaryBackground)
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
        }
    }
}

struct MagazineView: View {
    let posts: [Post]
    
    var body: some View {
        if posts.isEmpty {
            VStack(spacing: MinimalDesign.Spacing.lg) {
                Image(systemName: "book")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(MinimalDesign.Colors.tertiary)
                
                Text("まだ投稿がありません")
                    .font(MinimalDesign.Typography.body)
                    .foregroundColor(MinimalDesign.Colors.secondary)
            }
            .frame(height: 300)
        } else {
            ScrollView {
                VStack(spacing: MinimalDesign.Spacing.lg) {
                    ForEach(posts) { post in
                        HStack(spacing: MinimalDesign.Spacing.md) {
                            FastAsyncImage(urlString: post.mediaUrl) {
                                Rectangle()
                                    .fill(MinimalDesign.Colors.tertiaryBackground)
                            }
                            .frame(width: 100, height: 130)
                            .clipped()
                            
                            VStack(alignment: .leading, spacing: MinimalDesign.Spacing.sm) {
                                Text(post.user?.displayName ?? post.user?.username ?? "Unknown")
                                    .font(MinimalDesign.Typography.headline)
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .lineLimit(1)
                                
                                if let caption = post.caption {
                                    Text(caption)
                                        .font(MinimalDesign.Typography.body)
                                        .foregroundColor(MinimalDesign.Colors.secondary)
                                        .lineLimit(3)
                                }
                                
                                Spacer()
                            }
                            
                            Spacer()
                        }
                        .frame(height: 130)
                        .padding(.horizontal, MinimalDesign.Spacing.md)
                    }
                }
            }
        }
    }
}



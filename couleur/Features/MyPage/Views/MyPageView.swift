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
        ScrollableHeaderView(
            title: "Profile",
            rightButton: HeaderButton(
                icon: "gearshape",
                action: { showSettings = true }
            )
        ) {
            LazyVStack(spacing: MinimalDesign.Spacing.xl) {
                // Profile Section
                ModernProfileSection(
                    profile: viewModel.userProfile,
                    isLoading: viewModel.isLoading,
                    postsCount: viewModel.postsCount,
                    followersCount: viewModel.followersCount,
                    onEditProfile: { showEditProfile = true },
                    selectedPhotoItem: $selectedPhotoItem
                )
                
                
                // Posts Tab Section
                ModernPostsTabSection(posts: viewModel.userPosts)
            }
            .padding(.vertical, MinimalDesign.Spacing.md)
            .padding(.bottom, 100) // タブバー分のスペース
        }
        .background(MinimalDesign.Colors.background)
        .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authManager)
            }
            .task {
                await viewModel.loadUserDataIfNeeded()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await viewModel.updateProfilePhoto(item: newItem)
                }
            }
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
                    .foregroundColor(MinimalDesign.Colors.secondary)
            }
        }
        .padding(.horizontal, MinimalDesign.Spacing.md)
        .padding(.vertical, MinimalDesign.Spacing.sm)
    }
}

struct ModernProfileSection: View {
    let profile: UserProfile?
    let isLoading: Bool
    let postsCount: Int
    let followersCount: Int
    let onEditProfile: () -> Void
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @State private var showGridMode = false
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Image - Rounded Square (Left aligned)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    if let avatarUrl = profile?.avatarUrl {
                        FastAsyncImage(urlString: avatarUrl) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Profile Info
                VStack(alignment: .leading, spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        // Name with verified badge
                        HStack {
                            Text(profile?.displayName ?? profile?.username ?? "User")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            // Verified badge
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                        
                        // Bio
                        if let bio = profile?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                    // Edit Profile Button
                    Button(action: onEditProfile) {
                        Text("Edit Profile")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Share Profile Button
                    Button(action: { shareProfile() }) {
                        Text("Share Profile")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
            }
        }
        .padding(.horizontal, MinimalDesign.Spacing.md)
    }
    
    private func shareProfile() {
        // TODO: Implement share profile functionality
        print("Share profile tapped")
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
                        if showGridMode {
                            if selectedTab == .posts {
                                // Grid mode - 4 small squares (red when posts tab is selected)
                                VStack(spacing: 2) {
                                    HStack(spacing: 2) {
                                        Rectangle()
                                            .fill(MinimalDesign.Colors.accentRed)
                                            .frame(width: 8, height: 8)
                                        Rectangle()
                                            .fill(MinimalDesign.Colors.accentRed)
                                            .frame(width: 8, height: 8)
                                    }
                                    HStack(spacing: 2) {
                                        Rectangle()
                                            .fill(MinimalDesign.Colors.accentRed)
                                            .frame(width: 8, height: 8)
                                        Rectangle()
                                            .fill(MinimalDesign.Colors.accentRed)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            } else {
                                // Grid mode - 4 small squares (gray when magazine tab is selected)
                                VStack(spacing: 2) {
                                    HStack(spacing: 2) {
                                        Rectangle()
                                            .stroke(MinimalDesign.Colors.tertiary, lineWidth: 1)
                                            .frame(width: 8, height: 8)
                                        Rectangle()
                                            .stroke(MinimalDesign.Colors.tertiary, lineWidth: 1)
                                            .frame(width: 8, height: 8)
                                    }
                                    HStack(spacing: 2) {
                                        Rectangle()
                                            .stroke(MinimalDesign.Colors.tertiary, lineWidth: 1)
                                            .frame(width: 8, height: 8)
                                        Rectangle()
                                            .stroke(MinimalDesign.Colors.tertiary, lineWidth: 1)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        } else {
                            // Single mode - 1 large square 
                            Rectangle()
                                .fill(selectedTab == .posts ? MinimalDesign.Colors.accentRed : Color.clear)
                                .overlay(
                                    Rectangle()
                                        .stroke(selectedTab == .posts ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.tertiary, lineWidth: 1)
                                )
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
                        .foregroundColor(selectedTab == .magazine ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.tertiary)
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
                                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                                        .font(.system(size: 24, weight: .regular))
                                        .foregroundColor(post.isLikedByMe ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
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



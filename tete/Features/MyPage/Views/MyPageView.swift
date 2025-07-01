//======================================================================
// MARK: - MyPageView.swift (Minimal Design Profile)
// Path: tete/Features/MyPage/Views/MyPageView.swift
//======================================================================
import SwiftUI
import PhotosUI

@MainActor
struct MyPageView: View {
    @StateObject private var viewModel = MyPageViewModel()
    @EnvironmentObject var authManager: AuthManager
    @Binding var isInProfileSingleView: Bool
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPost: Post?
    @State private var navigateToSingleView: Bool = false
    
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
                ModernPostsTabSection(
                    posts: viewModel.userPosts,
                    selectedPost: $selectedPost,
                    navigateToSingleView: $navigateToSingleView,
                    onDeletePost: { post in
                        Task {
                            await viewModel.deletePost(post)
                        }
                    }
                )
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
            .navigationDestination(isPresented: $navigateToSingleView) {
                if let selectedPost = selectedPost {
                    ProfileSinglePostView(
                        initialPost: selectedPost,
                        allPosts: viewModel.userPosts
                    )
                    .onAppear {
                        isInProfileSingleView = true
                    }
                    .onDisappear {
                        isInProfileSingleView = false
                    }
                }
            }
            .onChange(of: isInProfileSingleView) { _, newValue in
                if !newValue && navigateToSingleView {
                    // プロフィールボタンが押されたら戻る
                    navigateToSingleView = false
                    selectedPost = nil
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

@MainActor
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
                ProfileImagePicker(
                    profile: profile,
                    selectedPhotoItem: $selectedPhotoItem
                )
                .buttonStyle(PlainButtonStyle())
                
                // Profile Info
                VStack(alignment: .leading, spacing: 8) {
                    // Username
                    if let username = profile?.username {
                        Text("@\(username)")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .lineLimit(1)
                    }
                    
                    // Display Name
                    if let displayName = profile?.displayName, !displayName.isEmpty {
                        Text(displayName)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(MinimalDesign.Colors.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Edit Profile Button
                    Button(action: onEditProfile) {
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            // Bio Section
            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, MinimalDesign.Spacing.sm)
            }
            
            // Stats Row
            HStack(spacing: 40) {
                StatItem(value: postsCount, label: "posts")
                StatItem(value: followersCount, label: "followers")
                StatItem(value: 0, label: "following") // TODO: Add following count
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
        }
        .padding(.vertical, MinimalDesign.Spacing.lg)
        .background(MinimalDesign.Colors.background)
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(MinimalDesign.Colors.tertiary)
        }
    }
}

struct ModernPostsTabSection: View {
    let posts: [Post]
    @Binding var selectedPost: Post?
    @Binding var navigateToSingleView: Bool
    let onDeletePost: ((Post) -> Void)?
    @State private var selectedTab = 0
    @State private var showGridMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                TabButton(
                    icon: "square.grid.3x3.fill",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                TabButton(
                    icon: "book.fill",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            Divider()
                .padding(.top, MinimalDesign.Spacing.xs)
            
            // Content
            Group {
                switch selectedTab {
                case 0:
                    if posts.isEmpty {
                        EmptyStateView(
                            icon: "camera",
                            title: "No Posts Yet",
                            message: "Share your first photo to get started"
                        )
                        .frame(height: 300)
                    } else {
                        if showGridMode {
                            GridView(posts: posts, onPostTapped: { post in
                                selectedPost = post
                                navigateToSingleView = true
                            }, onDeletePost: onDeletePost)
                                .transition(.opacity)
                        } else {
                            SingleCardGridView(posts: posts, onPostTapped: { post in
                                selectedPost = post
                                navigateToSingleView = true
                            }, onDeletePost: onDeletePost)
                                .transition(.opacity)
                        }
                    }
                case 1:
                    EmptyStateView(
                        icon: "book",
                        title: "No Articles",
                        message: "Your written articles will appear here"
                    )
                    .frame(height: 300)
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
        }
    }
}

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? MinimalDesign.Colors.primary : MinimalDesign.Colors.tertiary)
                
                Rectangle()
                    .fill(isSelected ? MinimalDesign.Colors.primary : Color.clear)
                    .frame(height: 1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(MinimalDesign.Colors.tertiary)
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(MinimalDesign.Colors.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct SingleCardGridView: View {
    let posts: [Post]
    let onPostTapped: ((Post) -> Void)?
    let onDeletePost: ((Post) -> Void)?
    let columns = [
        GridItem(.flexible(), spacing: 1.5),
        GridItem(.flexible(), spacing: 1.5),
        GridItem(.flexible(), spacing: 1.5)
    ]
    
    init(posts: [Post], onPostTapped: ((Post) -> Void)? = nil, onDeletePost: ((Post) -> Void)? = nil) {
        self.posts = posts
        self.onPostTapped = onPostTapped
        self.onDeletePost = onDeletePost
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 1.5) {
                ForEach(posts) { post in
                    ProfileSingleCardView(post: post, onTap: {
                        onPostTapped?(post)
                    })
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            onDeletePost?(post)
                        }
                    }
                }
            }
        }
    }
}

struct ProfileSingleCardView: View {
    let post: Post
    let onTap: (() -> Void)?
    @State private var image: UIImage?
    
    init(post: Post, onTap: (() -> Void)? = nil) {
        self.post = post
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            GeometryReader { geometry in
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiaryBackground)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: MinimalDesign.Colors.secondary))
                            )
                    }
                }
                .onAppear {
                    loadImage()
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func loadImage() {
        Task {
            if let url = URL(string: post.mediaUrl),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = uiImage
                }
            }
        }
    }
}

// Classic Grid View
struct GridView: View {
    let posts: [Post]
    let onPostTapped: ((Post) -> Void)?
    let onDeletePost: ((Post) -> Void)?
    let columns = [
        GridItem(.flexible(), spacing: 1.5),
        GridItem(.flexible(), spacing: 1.5),
        GridItem(.flexible(), spacing: 1.5)
    ]
    
    init(posts: [Post], onPostTapped: ((Post) -> Void)? = nil, onDeletePost: ((Post) -> Void)? = nil) {
        self.posts = posts
        self.onPostTapped = onPostTapped
        self.onDeletePost = onDeletePost
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 1.5) {
                ForEach(posts) { post in
                    GridItemView(post: post, onTap: {
                        onPostTapped?(post)
                    })
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            onDeletePost?(post)
                        }
                    }
                }
            }
        }
    }
}

struct GridItemView: View {
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
            GeometryReader { geometry in
                AsyncImage(url: URL(string: post.mediaUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(MinimalDesign.Colors.tertiaryBackground)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Magazine-style Feed View
struct MagazineView: View {
    let posts: [Post]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: MinimalDesign.Spacing.lg) {
                ForEach(posts) { post in
                    MagazinePostCard(post: post)
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
        }
    }
}

struct MagazinePostCard: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: MinimalDesign.Spacing.sm) {
            // Image
            AsyncImage(url: URL(string: post.mediaUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 280)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(MinimalDesign.Colors.tertiaryBackground)
                    .frame(height: 280)
            }
            .cornerRadius(MinimalDesign.Radius.md)
            
            // Caption
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(MinimalDesign.Typography.body)
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Profile Image Picker
@MainActor
struct ProfileImagePicker: View {
    let profile: UserProfile?
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            if let avatarUrl = profile?.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
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
    }
}
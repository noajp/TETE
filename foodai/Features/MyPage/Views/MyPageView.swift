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
                        
                        // Posts Grid
                        ModernPostsGrid()
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
                            Circle()
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
            
            Divider()
                .frame(height: 60)
                .background(MinimalDesign.Colors.border)
            
            ModernStatItem(value: "\(followersCount)", label: "Followers", action: onFollowersTap)
            
            Divider()
                .frame(height: 60)
                .background(MinimalDesign.Colors.border)
            
            ModernStatItem(value: "\(followingCount)", label: "Following", action: onFollowingTap)
        }
        .background(MinimalDesign.Colors.background)
        .cornerRadius(MinimalDesign.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: MinimalDesign.Radius.lg)
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

struct ModernPostsGrid: View {
    // Placeholder for user's posts grid
    var body: some View {
        VStack(spacing: MinimalDesign.Spacing.md) {
            HStack {
                Text("Posts")
                    .font(MinimalDesign.Typography.headline)
                    .foregroundColor(MinimalDesign.Colors.primary)
                Spacer()
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
            
            // Placeholder grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: MinimalDesign.Spacing.xs),
                GridItem(.flexible(), spacing: MinimalDesign.Spacing.xs),
                GridItem(.flexible(), spacing: MinimalDesign.Spacing.xs)
            ], spacing: MinimalDesign.Spacing.xs) {
                ForEach(0..<9, id: \.self) { _ in
                    Rectangle()
                        .fill(MinimalDesign.Colors.tertiaryBackground)
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(MinimalDesign.Radius.sm)
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
        }
    }
}



//======================================================================
// MARK: - MyPageView.swift (マイページ/アカウント画面)
// Path: foodai/Features/MyPage/Views/MyPageView.swift
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
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィールセクション
                    ProfileSection(
                        profile: viewModel.userProfile,
                        isLoading: viewModel.isLoading,
                        onEditProfile: { showEditProfile = true },
                        selectedPhotoItem: $selectedPhotoItem
                    )
                    
                    // 統計セクション
                    StatsSection(
                        postsCount: viewModel.postsCount,
                        followersCount: viewModel.followersCount,
                        followingCount: viewModel.followingCount,
                        onFollowersTap: { viewModel.navigateToFollowers() },
                        onFollowingTap: { viewModel.navigateToFollowing() }
                    )
                    
                    // メニューリスト
                    MenuSection(
                        onSettings: { showSettings = true },
                        onHelp: { viewModel.navigateToHelp() }
                    )
                    
                    // サインアウトボタン
                    SignOutButton {
                        Task {
                            try? await authManager.signOut()
                        }
                    }
                }
                .padding()
            }
            .background(AppEnvironment.Colors.background)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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

struct ProfileSection: View {
    let profile: UserProfile?
    let isLoading: Bool
    let onEditProfile: () -> Void
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 16) {
            // プロフィール画像
            PhotosPicker(selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()) {
                ZStack {
                    if let avatarUrl = profile?.avatarUrl {
                        RemoteImageView(imageURL: avatarUrl)
                            .frame(width: 100, height: 100)
                            .clipShape(Rectangle())
                    } else {
                        Rectangle()
                            .fill(AppEnvironment.Colors.inputBackground)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.black)
                            )
                    }
                    
                    // カメラアイコンオーバーレイ
                    Rectangle()
                        .fill(AppEnvironment.Colors.accentRed)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .offset(x: 34, y: 34)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                VStack(spacing: 8) {
                    Text(profile?.displayName ?? profile?.username ?? "Username")
                        .font(AppEnvironment.Fonts.primaryBold(size: 24))
                        .foregroundColor(.black)
                    
                    if let bio = profile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(AppEnvironment.Fonts.primary(size: 14))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    
                    Button(action: onEditProfile) {
                        Text("Edit Profile")
                            .font(AppEnvironment.Fonts.primary(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatsSection: View {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let onFollowersTap: () -> Void
    let onFollowingTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            StatItemView(value: "\(postsCount)", label: "Posts", action: nil)
            Divider()
                .frame(height: 40)
            StatItemView(value: "\(followersCount)", label: "Followers", action: onFollowersTap)
            Divider()
                .frame(height: 40)
            StatItemView(value: "\(followingCount)", label: "Following", action: onFollowingTap)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StatItemView: View {
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
    
    var statContent: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppEnvironment.Fonts.primaryBold(size: 20))
                .foregroundColor(.black)
            Text(label)
                .font(AppEnvironment.Fonts.primary(size: 12))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct MenuSection: View {
    let onSettings: () -> Void
    let onHelp: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            MenuRowView(icon: "gearshape.fill", title: "Settings", action: onSettings)
            Divider().padding(.leading, 56)
            MenuRowView(icon: "questionmark.circle.fill", title: "Help & Support", action: onHelp)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

struct MenuRowView: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppEnvironment.Fonts.primary(size: 16))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SignOutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))
                Text("Sign Out")
                    .font(AppEnvironment.Fonts.primary(size: 16))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
}




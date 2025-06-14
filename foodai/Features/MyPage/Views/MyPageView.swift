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
                        followingCount: viewModel.followingCount
                    )
                    
                    // メニューリスト
                    MenuSection(
                        onSavedPosts: { viewModel.navigateToSavedPosts() },
                        onFollowers: { viewModel.navigateToFollowers() },
                        onFollowing: { viewModel.navigateToFollowing() },
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
            .navigationTitle("アカウント")
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
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                    } else {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(AppEnvironment.Colors.inputBackground)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppEnvironment.Colors.textSecondary)
                            )
                    }
                    
                    // カメラアイコンオーバーレイ
                    RoundedRectangle(cornerRadius: 0)
                        .fill(AppEnvironment.Colors.accentGreen)
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
                    Text(profile?.displayName ?? profile?.username ?? "ユーザー名")
                        .font(AppEnvironment.Fonts.primaryBold(size: 24))
                        .foregroundColor(AppEnvironment.Colors.textPrimary)
                    
                    if let bio = profile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(AppEnvironment.Fonts.primary(size: 14))
                            .foregroundColor(AppEnvironment.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    
                    Button(action: onEditProfile) {
                        Text("プロフィールを編集")
                            .font(AppEnvironment.Fonts.primary(size: 14))
                            .foregroundColor(AppEnvironment.Colors.accentGreen)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppEnvironment.Colors.accentGreen, lineWidth: 1)
                            )
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
    
    var body: some View {
        HStack(spacing: 0) {
            StatItemView(value: "\(postsCount)", label: "投稿")
            Divider()
                .frame(height: 40)
            StatItemView(value: "\(followersCount)", label: "フォロワー")
            Divider()
                .frame(height: 40)
            StatItemView(value: "\(followingCount)", label: "フォロー中")
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct StatItemView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppEnvironment.Fonts.primaryBold(size: 20))
                .foregroundColor(AppEnvironment.Colors.textPrimary)
            Text(label)
                .font(AppEnvironment.Fonts.primary(size: 12))
                .foregroundColor(AppEnvironment.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct MenuSection: View {
    let onSavedPosts: () -> Void
    let onFollowers: () -> Void
    let onFollowing: () -> Void
    let onSettings: () -> Void
    let onHelp: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            MenuRowView(icon: "bookmark.fill", title: "保存済み投稿", action: onSavedPosts)
            Divider().padding(.leading, 56)
            MenuRowView(icon: "person.2.fill", title: "フォロワー", action: onFollowers)
            Divider().padding(.leading, 56)
            MenuRowView(icon: "person.fill.checkmark", title: "フォロー中", action: onFollowing)
            Divider().padding(.leading, 56)
            MenuRowView(icon: "gearshape.fill", title: "設定", action: onSettings)
            Divider().padding(.leading, 56)
            MenuRowView(icon: "questionmark.circle.fill", title: "ヘルプ・お問い合わせ", action: onHelp)
        }
        .background(Color.white)
        .cornerRadius(12)
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
                    .foregroundColor(AppEnvironment.Colors.accentGreen)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppEnvironment.Fonts.primary(size: 16))
                    .foregroundColor(AppEnvironment.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppEnvironment.Colors.textSecondary)
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
                Text("サインアウト")
                    .font(AppEnvironment.Fonts.primary(size: 16))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
        }
        .padding(.top, 8)
    }
}




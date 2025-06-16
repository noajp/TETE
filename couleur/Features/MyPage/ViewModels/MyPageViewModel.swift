//======================================================================
// MARK: - MyPageViewModel (アカウント画面のViewModel)
// Path: foodai/Features/MyPage/ViewModels/MyPageViewModel.swift
//======================================================================
import SwiftUI
import Combine
import PhotosUI

@MainActor
class MyPageViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var savedPosts: [Post] = []
    @Published var postsCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let postService = PostService()
    private let supabaseManager = SupabaseManager.shared
    
    init() {
        Task {
            await loadUserData()
        }
    }
    
    func loadUserData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // ユーザープロフィールを取得
            let session = try await supabaseManager.client.auth.session
            let userId = session.user.id
            
            // プロフィールデータを取得
            let profile: UserProfile = try await supabaseManager.client
                .from("user_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            self.userProfile = profile
            
            // 統計情報を取得（実装は仮）
            self.postsCount = await getPostsCount(userId: userId.uuidString)
            self.followersCount = await getFollowersCount(userId: userId.uuidString)
            self.followingCount = await getFollowingCount(userId: userId.uuidString)
            
        } catch {
            errorMessage = "Failed to load data"
            print("Error loading user data: \(error)")
        }
    }
    
    func updateProfile(username: String, displayName: String, bio: String) async {
        do {
            let session = try await supabaseManager.client.auth.session
            let userId = session.user.id
            
            _ = try await supabaseManager.client
                .from("user_profiles")
                .update([
                    "username": username,
                    "display_name": displayName,
                    "bio": bio
                ])
                .eq("id", value: userId.uuidString)
                .execute()
            
            await loadUserData()
        } catch {
            errorMessage = "Failed to update profile"
            print("Error updating profile: \(error)")
        }
    }
    
    func updateProfilePhoto(item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // TODO: Storageにアップロードして、URLを取得
                // TODO: プロフィールのavatar_urlを更新
                print("Photo data loaded: \(data.count) bytes")
            }
        } catch {
            errorMessage = "Failed to upload photo"
            print("Error uploading photo: \(error)")
        }
    }
    
    // MARK: - Navigation Methods
    func navigateToSavedPosts() {
        // TODO: 保存済み投稿画面への遷移
    }
    
    func navigateToFollowers() {
        // TODO: フォロワー一覧画面への遷移
    }
    
    func navigateToFollowing() {
        // TODO: フォロー中一覧画面への遷移
    }
    
    func navigateToHelp() {
        // TODO: ヘルプ画面への遷移
    }
    
    // MARK: - Private Methods
    private func getPostsCount(userId: String) async -> Int {
        // TODO: 実際のデータ取得を実装
        return 12
    }
    
    private func getFollowersCount(userId: String) async -> Int {
        // TODO: 実際のデータ取得を実装
        return 42
    }
    
    private func getFollowingCount(userId: String) async -> Int {
        // TODO: 実際のデータ取得を実装
        return 28
    }
}

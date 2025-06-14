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
    @Published var reviewsCount: Int = 0
    @Published var savedRestaurantsCount: Int = 0
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
            guard let userId = supabaseManager.client.auth.session?.user.id else {
                return
            }
            
            // プロフィールデータを取得
            let profile: UserProfile = try await supabaseManager.client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            self.userProfile = profile
            
            // 統計情報を取得（実装は仮）
            self.postsCount = await getPostsCount(userId: userId)
            self.reviewsCount = await getReviewsCount(userId: userId)
            self.savedRestaurantsCount = await getSavedRestaurantsCount(userId: userId)
            
        } catch {
            errorMessage = "データの読み込みに失敗しました"
            print("Error loading user data: \(error)")
        }
    }
    
    func updateProfile(username: String, displayName: String, bio: String) async {
        guard let userId = supabaseManager.client.auth.session?.user.id else {
            return
        }
        
        do {
            let updatedProfile = try await supabaseManager.client
                .from("profiles")
                .update([
                    "username": username,
                    "display_name": displayName,
                    "bio": bio
                ])
                .eq("id", value: userId)
                .execute()
            
            await loadUserData()
        } catch {
            errorMessage = "プロフィールの更新に失敗しました"
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
            errorMessage = "写真のアップロードに失敗しました"
            print("Error uploading photo: \(error)")
        }
    }
    
    // MARK: - Navigation Methods
    func navigateToSavedRestaurants() {
        // TODO: 保存済みレストラン画面への遷移
    }
    
    func navigateToReservations() {
        // TODO: 予約履歴画面への遷移
    }
    
    func navigateToReviews() {
        // TODO: レビュー履歴画面への遷移
    }
    
    func navigateToHelp() {
        // TODO: ヘルプ画面への遷移
    }
    
    // MARK: - Private Methods
    private func getPostsCount(userId: String) async -> Int {
        // TODO: 実際のデータ取得を実装
        return 12
    }
    
    private func getReviewsCount(userId: String) async -> Int {
        // TODO: 実際のデータ取得を実装
        return 8
    }
    
    private func getSavedRestaurantsCount(userId: String) async -> Int {
        // TODO: 実際のデータ取得を実装
        return 24
    }
}

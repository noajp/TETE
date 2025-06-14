//======================================================================
// MARK: - 更新版 HomeFeedViewModel（SNS用）
// Path: foodai/Features/HomeFeed/ViewModels/HomeFeedViewModel.swift
//======================================================================
import SwiftUI
import Combine

@MainActor
class HomeFeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let postService = PostService()
    
    init() {
        loadPosts()
    }
    
    func loadPosts() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedPosts = try await postService.fetchFeedPosts()
                self.posts = fetchedPosts
                self.isLoading = false
            } catch {
                self.errorMessage = "投稿の読み込みに失敗しました"
                self.isLoading = false
                print("❌ Error loading posts: \(error)")
            }
        }
    }
}


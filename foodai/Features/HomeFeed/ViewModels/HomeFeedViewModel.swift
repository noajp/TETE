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
    private var currentUserId: String?
    
    init() {
        // TODO: Get current user ID from AuthManager
        currentUserId = "user-1" // Mock for now
        loadPosts()
    }
    
    func loadPosts() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedPosts = try await postService.fetchFeedPosts(currentUserId: currentUserId)
                self.posts = fetchedPosts
                self.isLoading = false
            } catch {
                self.errorMessage = "投稿の読み込みに失敗しました"
                self.isLoading = false
                print("❌ Error loading posts: \(error)")
            }
        }
    }
    
    // MARK: - Like Operations
    
    func toggleLike(for post: Post) {
        guard let userId = currentUserId else {
            errorMessage = "ログインが必要です"
            return
        }
        
        // Optimistic UI update
        let newLikeStatus = !post.isLikedByMe
        updatePostLikeStatus(postId: post.id, isLiked: newLikeStatus)
        
        Task {
            do {
                let isNowLiked = try await postService.toggleLike(
                    postId: post.id,
                    userId: userId
                )
                
                // Only update like status, not count (to avoid double counting)
                updatePostLikeStatusOnly(postId: post.id, isLiked: isNowLiked)
                
            } catch {
                // Revert optimistic update on error
                updatePostLikeStatus(postId: post.id, isLiked: post.isLikedByMe)
                errorMessage = "いいねの更新に失敗しました"
                print("❌ Error toggling like: \(error)")
            }
        }
    }
    
    private func updatePostLikeStatus(postId: String, isLiked: Bool) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLikedByMe = isLiked
            
            // Update like count
            if isLiked {
                posts[index].likeCount += 1
            } else {
                posts[index].likeCount = max(0, posts[index].likeCount - 1)
            }
        }
    }
    
    // Like状態のみ更新（カウントは更新しない）
    private func updatePostLikeStatusOnly(postId: String, isLiked: Bool) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLikedByMe = isLiked
        }
    }
    
    func refreshPosts() {
        loadPosts()
    }
    
    func setCurrentUserId(_ userId: String) {
        currentUserId = userId
        loadPosts() // Reload to get correct like status
    }
}


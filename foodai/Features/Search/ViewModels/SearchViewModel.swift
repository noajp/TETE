//======================================================================
// MARK: - 3. SearchViewModel.swift の修正
// Path: foodai/Features/Search/ViewModels/SearchViewModel.swift
//======================================================================
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [Post] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let postService = PostService()
    
    func search(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // TODO: 検索APIを実装
                // 仮実装：全投稿から検索
                let allPosts = try await postService.fetchFeedPosts()
                self.searchResults = allPosts.filter { post in
                    post.restaurant?.name.localizedCaseInsensitiveContains(query) ?? false ||
                    post.restaurant?.area?.localizedCaseInsensitiveContains(query) ?? false ||
                    post.caption?.localizedCaseInsensitiveContains(query) ?? false
                }
                self.isLoading = false
            } catch {
                self.errorMessage = "検索に失敗しました"
                self.isLoading = false
            }
        }
    }
    
    func showFilters() {
        // フィルター画面を表示
    }
}


//======================================================================
// MARK: - MyPageViewModel修正版
// Path: foodai/Features/MyPage/ViewModels/MyPageViewModel.swift
//======================================================================
import SwiftUI
import Combine

@MainActor
class MyPageViewModel: ObservableObject {
    @Published var savedPosts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let postService = PostService()
    
    init() {
        loadUserData()
    }
    
    private func loadUserData() {
        isLoading = true
        
        Task {
            // catchブロックを削除（エラーがスローされないため）
            // TODO: 保存済み投稿を取得する機能を実装
            // 現時点では空の配列
            self.savedPosts = []
            self.isLoading = false
        }
    }
    
    func refreshData() {
        loadUserData()
    }
}

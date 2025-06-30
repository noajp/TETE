//
//  CreateArticleViewModel.swift
//  tete
//
//  記事作成用ViewModel
//

import Foundation
import PhotosUI
import SwiftUI

@MainActor
class CreateArticleViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let articleRepository = ArticleRepository.shared
    // TODO: Implement storage service for cover image upload
    
    /// 記事を作成
    func createArticle(
        title: String,
        content: String,
        summary: String?,
        category: String,
        tags: [String],
        isPremium: Bool,
        coverImageUrl: String?,
        status: ArticleStatus
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = CreateArticleRequest(
                title: title,
                content: content,
                summary: summary,
                category: category,
                tags: tags,
                isPremium: isPremium,
                coverImageUrl: coverImageUrl,
                status: status
            )
            
            let article = try await articleRepository.createArticle(request)
            print("✅ Article created successfully: \(article.id)")
            
            // 投稿完了通知を送信
            NotificationCenter.default.post(
                name: NSNotification.Name("ArticleCreated"),
                object: article
            )
            
        } catch {
            print("❌ Failed to create article: \(error)")
            errorMessage = "記事の作成に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// カバー画像をアップロード
    func uploadCoverImage(item: PhotosPickerItem?) async -> String? {
        guard let item = item else { return nil }
        
        // TODO: Implement actual image upload to Supabase Storage
        // For now, return a placeholder URL
        do {
            guard try await item.loadTransferable(type: Data.self) != nil else {
                print("❌ Failed to load image data")
                return nil
            }
            
            // 仮のURLを返す（実際の実装ではストレージサービスを使用）
            let fileName = "article_cover_\(UUID().uuidString).jpg"
            print("✅ Cover image prepared: \(fileName)")
            
            // 仮のURLを返す
            return "https://via.placeholder.com/800x400/2196F3/FFFFFF?text=Article+Cover"
            
        } catch {
            print("❌ Failed to process cover image: \(error)")
            errorMessage = "画像の処理に失敗しました"
            return nil
        }
    }
    
    /// 記事の下書きを自動保存
    func autoSaveDraft(
        title: String,
        content: String,
        summary: String?,
        category: String,
        tags: [String],
        isPremium: Bool,
        coverImageUrl: String?
    ) async {
        // 最低限のコンテンツがある場合のみ自動保存
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        do {
            let request = CreateArticleRequest(
                title: title.isEmpty ? "無題の記事" : title,
                content: content,
                summary: summary,
                category: category,
                tags: tags,
                isPremium: isPremium,
                coverImageUrl: coverImageUrl,
                status: .draft
            )
            
            _ = try await articleRepository.createArticle(request)
            print("✅ Draft auto-saved")
            
        } catch {
            print("❌ Failed to auto-save draft: \(error)")
        }
    }
}
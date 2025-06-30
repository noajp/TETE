//
//  ArticleRepository.swift
//  tete
//
//  記事投稿用のリポジトリ（完成版）
//

import Foundation
import Supabase

@MainActor
class ArticleRepository: ObservableObject {
    static let shared = ArticleRepository()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Article CRUD Operations
    
    /// 記事を作成
    func createArticle(_ request: CreateArticleRequest) async throws -> BlogArticle {
        let response: BlogArticle = try await supabase
            .from("articles")
            .insert(request)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value
        
        print("✅ Article created: \(response.id)")
        return response
    }
    
    /// 記事を更新
    func updateArticle(id: String, _ request: UpdateArticleRequest) async throws -> BlogArticle {
        let response: BlogArticle = try await supabase
            .from("articles")
            .update(request)
            .eq("id", value: id)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value
        
        print("✅ Article updated: \(response.id)")
        return response
    }
    
    /// 記事を削除
    func deleteArticle(id: String) async throws {
        try await supabase
            .from("articles")
            .delete()
            .eq("id", value: id)
            .execute()
        
        print("✅ Article deleted: \(id)")
    }
    
    /// 記事を公開
    func publishArticle(id: String) async throws -> BlogArticle {
        let request = UpdateArticleRequest(
            title: nil,
            content: nil,
            summary: nil,
            category: nil,
            tags: nil,
            isPremium: nil,
            coverImageUrl: nil,
            status: .published
        )
        
        return try await updateArticle(id: id, request)
    }
    
    // MARK: - Article Fetching
    
    /// 公開済み記事一覧を取得
    func getPublishedArticles(limit: Int = 20, offset: Int = 0) async throws -> [BlogArticle] {
        let query = """
            *,
            user:profiles(id, username, display_name, avatar_url),
            is_liked_by_me:article_likes!left(user_id)
        """
        
        let response: [BlogArticle] = try await supabase
            .from("articles")
            .select(query)
            .eq("status", value: ArticleStatus.published.rawValue)
            .order("published_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return response.map { article in
            var updatedArticle = article
            updatedArticle.isLikedByMe = checkIfLiked(article: article)
            return updatedArticle
        }
    }
    
    /// 特定ユーザーの記事一覧を取得
    func getUserArticles(userId: String, status: ArticleStatus? = nil) async throws -> [BlogArticle] {
        var baseQuery = supabase
            .from("articles")
            .select("*, user:profiles(id, username, display_name, avatar_url)")
            .eq("user_id", value: userId)
        
        if let status = status {
            baseQuery = baseQuery.eq("status", value: status.rawValue)
        }
        
        let response: [BlogArticle] = try await baseQuery
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// 記事詳細を取得
    func getArticle(id: String) async throws -> BlogArticle {
        // ビュー数を増加
        try await recordArticleView(articleId: id)
        
        let query = """
            *,
            user:profiles(id, username, display_name, avatar_url),
            is_liked_by_me:article_likes!left(user_id)
        """
        
        let response: BlogArticle = try await supabase
            .from("articles")
            .select(query)
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        var updatedArticle = response
        updatedArticle.isLikedByMe = checkIfLiked(article: response)
        return updatedArticle
    }
    
    /// カテゴリ別記事を取得
    func getArticlesByCategory(_ category: String, limit: Int = 20) async throws -> [BlogArticle] {
        let response: [BlogArticle] = try await supabase
            .from("articles")
            .select("*, user:profiles(id, username, display_name, avatar_url)")
            .eq("status", value: ArticleStatus.published.rawValue)
            .eq("category", value: category)
            .order("published_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response
    }
    
    /// タグ検索
    func searchArticlesByTag(_ tag: String, limit: Int = 20) async throws -> [BlogArticle] {
        let response: [BlogArticle] = try await supabase
            .from("articles")
            .select("*, user:profiles(id, username, display_name, avatar_url)")
            .eq("status", value: ArticleStatus.published.rawValue)
            .contains("tags", value: [tag])
            .order("published_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response
    }
    
    /// 記事検索
    func searchArticles(query: String, limit: Int = 20) async throws -> [BlogArticle] {
        let response: [BlogArticle] = try await supabase
            .from("articles")
            .select("*, user:profiles(id, username, display_name, avatar_url)")
            .eq("status", value: ArticleStatus.published.rawValue)
            .or("title.ilike.%\(query)%,content.ilike.%\(query)%")
            .order("published_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Article Interactions
    
    /// 記事にいいね/いいね取り消し
    func toggleArticleLike(articleId: String) async throws -> Bool {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw RepositoryError.notAuthenticated
        }
        
        // 既存のいいねをチェック
        let existingLikes: [ArticleLike] = try await supabase
            .from("article_likes")
            .select()
            .eq("article_id", value: articleId)
            .eq("user_id", value: currentUserId)
            .execute()
            .value
        
        if existingLikes.isEmpty {
            // いいねを追加
            let newLike = ArticleLike(
                id: UUID().uuidString,
                articleId: articleId,
                userId: currentUserId,
                createdAt: Date()
            )
            
            try await supabase
                .from("article_likes")
                .insert(newLike)
                .execute()
            
            print("✅ Article liked: \(articleId)")
            return true
        } else {
            // いいねを削除
            try await supabase
                .from("article_likes")
                .delete()
                .eq("article_id", value: articleId)
                .eq("user_id", value: currentUserId)
                .execute()
            
            print("✅ Article unliked: \(articleId)")
            return false
        }
    }
    
    /// 記事閲覧記録
    private func recordArticleView(articleId: String) async throws {
        let currentUserId = AuthManager.shared.currentUser?.id
        
        let newView = ArticleView(
            id: UUID().uuidString,
            articleId: articleId,
            userId: currentUserId,
            ipAddress: nil, // クライアントサイドでは取得困難
            createdAt: Date()
        )
        
        try await supabase
            .from("article_views")
            .insert(newView)
            .execute()
    }
    
    // MARK: - Helper Methods
    
    private func checkIfLiked(article: BlogArticle) -> Bool {
        guard AuthManager.shared.currentUser?.id != nil else {
            return false
        }
        
        // TODO: Supabaseからの実際のレスポンスに基づいて実装
        // LEFT JOINで取得したarticle_likesの情報を確認
        return false
    }
}

// MARK: - Supporting Models

struct ArticleLike: Codable {
    let id: String
    let articleId: String
    let userId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case articleId = "article_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct ArticleView: Codable {
    let id: String
    let articleId: String
    let userId: String?
    let ipAddress: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case articleId = "article_id"
        case userId = "user_id"
        case ipAddress = "ip_address"
        case createdAt = "created_at"
    }
}

// MARK: - Repository Errors

enum RepositoryError: Error, LocalizedError {
    case notAuthenticated
    case networkError(String)
    case serverError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .unknownError:
            return "不明なエラーが発生しました"
        }
    }
}
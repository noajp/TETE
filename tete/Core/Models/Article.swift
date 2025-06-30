//
//  Article.swift
//  tete
//
//  記事投稿用のモデル（完成版）
//

import Foundation

struct BlogArticle: Identifiable, Codable, Hashable {
    let id: String  // データベースではUUIDだがStringとして扱う
    let userId: String  // データベースではUUIDだがStringとして扱う  
    let title: String
    let content: String
    let summary: String?
    let category: String?
    let tags: [String]
    let isPremium: Bool
    let coverImageUrl: String?
    let status: ArticleStatus
    let publishedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    var viewCount: Int
    var likeCount: Int
    
    // ユーザー情報（JOIN結果）
    var user: UserProfile?
    
    // いいね状態（ログインユーザーがいいねしているか）
    var isLikedByMe: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case summary
        case category
        case tags
        case isPremium = "is_premium"
        case coverImageUrl = "cover_image_url"
        case status
        case publishedAt = "published_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case user
        case isLikedByMe = "is_liked_by_me"
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BlogArticle, rhs: BlogArticle) -> Bool {
        return lhs.id == rhs.id
    }
}

enum ArticleStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case published = "published"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .draft:
            return "下書き"
        case .published:
            return "公開済み"
        case .archived:
            return "アーカイブ"
        }
    }
}

// 記事作成用のリクエストモデル
struct CreateArticleRequest: Codable {
    let title: String
    let content: String
    let summary: String?
    let category: String?
    let tags: [String]
    let isPremium: Bool
    let coverImageUrl: String?
    let status: ArticleStatus
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case summary
        case category
        case tags
        case isPremium = "is_premium"
        case coverImageUrl = "cover_image_url"
        case status
    }
}

// 記事更新用のリクエストモデル
struct UpdateArticleRequest: Codable {
    let title: String?
    let content: String?
    let summary: String?
    let category: String?
    let tags: [String]?
    let isPremium: Bool?
    let coverImageUrl: String?
    let status: ArticleStatus?
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case summary
        case category
        case tags
        case isPremium = "is_premium"
        case coverImageUrl = "cover_image_url"
        case status
    }
}

// 記事カテゴリ
enum ArticleCategory: String, CaseIterable {
    case technology = "technology"
    case design = "design"
    case lifestyle = "lifestyle"
    case business = "business"
    case travel = "travel"
    case food = "food"
    case health = "health"
    case entertainment = "entertainment"
    case education = "education"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .technology:
            return "テクノロジー"
        case .design:
            return "デザイン"
        case .lifestyle:
            return "ライフスタイル"
        case .business:
            return "ビジネス"
        case .travel:
            return "旅行"
        case .food:
            return "グルメ"
        case .health:
            return "健康"
        case .entertainment:
            return "エンターテイメント"
        case .education:
            return "教育"
        case .other:
            return "その他"
        }
    }
    
    var icon: String {
        switch self {
        case .technology:
            return "laptopcomputer"
        case .design:
            return "paintbrush"
        case .lifestyle:
            return "heart"
        case .business:
            return "briefcase"
        case .travel:
            return "airplane"
        case .food:
            return "fork.knife"
        case .health:
            return "heart.text.square"
        case .entertainment:
            return "tv"
        case .education:
            return "graduationcap"
        case .other:
            return "ellipsis.circle"
        }
    }
}
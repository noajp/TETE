//======================================================================
// MARK: - Post.swift（写真共有アプリ版）
// Path: foodai/Core/DataModels/Post.swift
//======================================================================
import Foundation

struct Post: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let mediaUrl: String
    let mediaType: MediaType
    let thumbnailUrl: String?
    let caption: String?
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let isPublic: Bool
    let createdAt: Date
    
    // 統計情報
    var likeCount: Int
    let commentCount: Int
    
    // リレーション（オプショナル）
    var user: UserProfile?
    var isLikedByMe: Bool = false
    var isSavedByMe: Bool = false
    
    enum MediaType: String, Codable {
        case photo = "photo"
        case video = "video"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case thumbnailUrl = "thumbnail_url"
        case caption
        case locationName = "location_name"
        case latitude
        case longitude
        case isPublic = "is_public"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
    }
    
    // MARK: - Hashable Implementation
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}


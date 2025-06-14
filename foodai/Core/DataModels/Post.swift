//======================================================================
// MARK: - Post.swift（Double評価対応版）
// Path: foodai/Core/DataModels/Post.swift
//======================================================================
import Foundation

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let restaurantId: String
    let mediaUrl: String
    let mediaType: MediaType
    let thumbnailUrl: String?
    let caption: String?
    let rating: Double
    let visitDate: Date?
    let createdAt: Date
    
    // リレーション（オプショナル）
    var user: UserProfile?
    var restaurant: Restaurant?
    var likeCount: Int = 0
    var saveCount: Int = 0
    var isLikedByMe: Bool = false
    var isSavedByMe: Bool = false
    
    enum MediaType: String, Codable {
        case photo = "photo"
        case video = "video"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case restaurantId = "restaurant_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case thumbnailUrl = "thumbnail_url"
        case caption
        case rating
        case visitDate = "visit_date"
        case createdAt = "created_at"
    }
}


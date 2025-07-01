//======================================================================
// MARK: - Post.swift
// Purpose: Data model for posts with media content, location, and social features (メディアコンテンツ、位置情報、ソーシャル機能を持つ投稿のデータモデル)
// Path: tete/Core/DataModels/Post.swift
//======================================================================
import Foundation
import CoreTransferable

struct Post: Identifiable, Codable, Hashable, Transferable {
    let id: String
    let userId: String
    let mediaUrl: String
    let mediaType: MediaType
    let thumbnailUrl: String?
    let mediaWidth: Double?
    let mediaHeight: Double?
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
        case mediaWidth = "media_width"
        case mediaHeight = "media_height"
        case caption
        case locationName = "location_name"
        case latitude
        case longitude
        case isPublic = "is_public"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
    }
    
    // MARK: - Initializers
    
    init(
        id: String,
        userId: String,
        mediaUrl: String,
        mediaType: MediaType,
        thumbnailUrl: String? = nil,
        mediaWidth: Double? = nil,
        mediaHeight: Double? = nil,
        caption: String? = nil,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isPublic: Bool = true,
        createdAt: Date = Date(),
        likeCount: Int = 0,
        commentCount: Int = 0,
        user: UserProfile? = nil,
        isLikedByMe: Bool = false,
        isSavedByMe: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
        self.thumbnailUrl = thumbnailUrl
        self.mediaWidth = mediaWidth
        self.mediaHeight = mediaHeight
        self.caption = caption
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.user = user
        self.isLikedByMe = isLikedByMe
        self.isSavedByMe = isSavedByMe
    }
    
    // MARK: - Custom Decodable Implementation
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        mediaUrl = try container.decode(String.self, forKey: .mediaUrl)
        mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        mediaWidth = try container.decodeIfPresent(Double.self, forKey: .mediaWidth)
        mediaHeight = try container.decodeIfPresent(Double.self, forKey: .mediaHeight)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        
        // Handle date parsing - Supabase returns ISO 8601 string
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: createdAtString) {
            createdAt = date
        } else {
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: createdAtString) {
                createdAt = date
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .createdAt,
                    in: container,
                    debugDescription: "Cannot parse date string: \(createdAtString)"
                )
            }
        }
    }
    
    // MARK: - Hashable Implementation
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Aspect Ratio Utilities
    
    /// アスペクト比を計算（幅/高さ）
    var aspectRatio: Double? {
        guard let width = mediaWidth, let height = mediaHeight, height > 0 else {
            return nil
        }
        return width / height
    }
    
    /// 横長写真として表示すべきかを判定
    var shouldDisplayAsLandscape: Bool {
        guard let ratio = aspectRatio else {
            // アスペクト比が不明な場合は正方形表示
            print("⚠️ Post \(id): No aspect ratio data, defaulting to square display")
            return false
        }
        
        // アスペクト比が1.3以上（横:縦 = 1.3:1以上）を横長とする
        // 例: 1600x1200 = 1.33, 1920x1080 = 1.78
        let isLandscape = ratio >= 1.3
        print("🔍 Post \(id): Aspect ratio \(String(format: "%.2f", ratio)) -> \(isLandscape ? "landscape" : "square") display")
        return isLandscape
    }
    
    /// グリッド表示タイプを判定
    enum GridDisplayType {
        case landscape  // 横長表示
        case square     // 正方形表示
    }
    
    /// グリッド表示タイプを取得
    var gridDisplayType: GridDisplayType {
        return shouldDisplayAsLandscape ? .landscape : .square
    }
    
    // MARK: - Transferable Implementation
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}


//======================================================================
// MARK: - Post.swift（写真共有アプリ版）
// Path: foodai/Core/DataModels/Post.swift
//======================================================================
import Foundation
import CoreTransferable

struct Post: Identifiable, Codable, Hashable, Transferable {
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
    
    // MARK: - Initializers
    
    init(
        id: String,
        userId: String,
        mediaUrl: String,
        mediaType: MediaType,
        thumbnailUrl: String? = nil,
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
    
    // MARK: - Transferable Implementation
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}


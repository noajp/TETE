//======================================================================
// MARK: - Follow.swift（フォロー機能用モデル）
// Path: foodai/Core/DataModels/Follow.swift
//======================================================================
import Foundation

struct Follow: Identifiable, Codable {
    let id: String
    let followerId: String
    let followingId: String
    let createdAt: Date
    
    // リレーション（オプショナル）
    var follower: UserProfile?
    var following: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}

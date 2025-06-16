//======================================================================
// MARK: - UserProfile.swift（ユーザープロフィール）
// Path: foodai/Core/DataModels/UserProfile.swift
//======================================================================
import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let bio: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }
}


//======================================================================
// MARK: - UserProfile.swift（ユーザープロフィール）
// Path: foodai/Core/DataModels/UserProfile.swift
//======================================================================
import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String              // UserID: 一意識別子
    var username: String        // ユーザー名: @username形式、ログイン用
    var displayName: String?    // 表示名: 実名やニックネーム
    var avatarUrl: String?
    var bio: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }
    
    // MARK: - 表示用ヘルパーメソッド
    
    /// アプリ全体で使用する統一された表示名
    /// 優先順位: displayName → username
    var preferredDisplayName: String {
        return displayName?.isEmpty == false ? displayName! : username
    }
    
    /// @付きのユーザー名表示
    var usernameWithAt: String {
        return "@\(username)"
    }
    
    /// フルネーム表示（表示名 + @username）
    var fullDisplayName: String {
        if let displayName = displayName, !displayName.isEmpty {
            return "\(displayName) (@\(username))"
        } else {
            return "@\(username)"
        }
    }
}


//======================================================================
// MARK: - PostService.swift（写真共有アプリ版）
// Path: foodai/Core/Services/PostService.swift
//======================================================================
import Foundation
import Supabase

class PostService {
    private let client = SupabaseManager.shared.client
    private let likeService = LikeService()
    static let useMockData = false // 写真共有アプリ用モックデータ
    
    // モックデータ用のいいね状態を保存
    private static var mockLikedPosts: Set<String> = ["1", "3"] // 初期状態
    
    // フィード用の投稿一覧を取得
    func fetchFeedPosts(currentUserId: String? = nil) async throws -> [Post] {
        // モックモードの場合
        if PostService.useMockData {
            print("🔵 写真共有アプリ用モックデータを使用します")
            var posts = getMockPosts()
            
            // モックデータにもいいね状態を設定
            if let userId = currentUserId {
                for i in 0..<posts.count {
                    posts[i].isLikedByMe = await checkMockLikeStatus(postId: posts[i].id, userId: userId)
                }
            }
            
            return posts
        }
        
        // 本番モード
        print("🔵 PostService: フィード投稿を取得開始")
        
        do {
            var posts: [Post] = try await client
                .from("posts")
                .select("*")
                .eq("is_public", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ PostService: \(posts.count)件の投稿を取得")
            
            // 手動でユーザー情報を取得
            for i in 0..<posts.count {
                do {
                    let userProfile: UserProfile = try await client
                        .from("user_profiles")
                        .select("*")
                        .eq("id", value: posts[i].userId)
                        .single()
                        .execute()
                        .value
                    posts[i].user = userProfile
                    
                    // いいね状態を取得
                    if let userId = currentUserId {
                        posts[i].isLikedByMe = try await likeService.checkUserLikeStatus(
                            postId: posts[i].id,
                            userId: userId
                        )
                    }
                    
                    print("✅ ユーザー情報取得: \(userProfile.username)")
                } catch {
                    print("⚠️ ユーザー情報取得エラー: \(error)")
                }
            }
            
            return posts
            
        } catch {
            print("❌ PostService エラー: \(error)")
            throw error
        }
    }
    
    // 特定ユーザーの投稿を取得
    func fetchUserPosts(userId: String) async throws -> [Post] {
        if PostService.useMockData {
            return getMockPosts().filter { $0.userId == userId }
        }
        
        do {
            var posts: [Post] = try await client
                .from("posts")
                .select("*")
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // 手動でユーザー情報を取得
            for i in 0..<posts.count {
                do {
                    let userProfile: UserProfile = try await client
                        .from("user_profiles")
                        .select("*")
                        .eq("id", value: posts[i].userId)
                        .single()
                        .execute()
                        .value
                    posts[i].user = userProfile
                } catch {
                    print("⚠️ ユーザー情報取得エラー: \(error)")
                }
            }
            
            return posts
            
        } catch {
            print("❌ fetchUserPosts エラー: \(error)")
            throw error
        }
    }
    
    // 写真共有アプリ用モックデータ
    private func getMockPosts() -> [Post] {
        return [
            Post(
                id: "1",
                userId: "user-1",
                mediaUrl: "https://picsum.photos/400/400?random=1",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: "美しい夕日を撮影しました 📸✨",
                locationName: "渋谷スカイ",
                latitude: 35.6580,
                longitude: 139.7016,
                isPublic: true,
                createdAt: Date(),
                likeCount: 24,
                commentCount: 3,
                user: UserProfile(
                    id: "user-1",
                    username: "photo_lover",
                    displayName: "フォトグラファー",
                    avatarUrl: "https://ui-avatars.com/api/?name=PL&background=0D8ABC&color=fff",
                    bio: "写真が好きです📷",
                    createdAt: Date()
                )
            ),
            Post(
                id: "2",
                userId: "user-2", 
                mediaUrl: "https://picsum.photos/400/400?random=2",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: "今日のランチ 🍝 パスタが絶品でした！",
                locationName: "恵比寿ガーデンプレイス",
                latitude: 35.6461,
                longitude: 139.7118,
                isPublic: true,
                createdAt: Date().addingTimeInterval(-3600),
                likeCount: 15,
                commentCount: 2,
                user: UserProfile(
                    id: "user-2",
                    username: "food_explorer",
                    displayName: "グルメ探検家",
                    avatarUrl: "https://ui-avatars.com/api/?name=FE&background=E91E63&color=fff",
                    bio: "美味しいもの巡り中",
                    createdAt: Date()
                )
            ),
            Post(
                id: "3",
                userId: "user-3",
                mediaUrl: "https://picsum.photos/400/400?random=3",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: "桜が満開です 🌸 春の訪れを感じます",
                locationName: "上野公園",
                latitude: 35.7153,
                longitude: 139.7734,
                isPublic: true,
                createdAt: Date().addingTimeInterval(-7200),
                likeCount: 42,
                commentCount: 8,
                user: UserProfile(
                    id: "user-3",
                    username: "nature_shots",
                    displayName: "自然写真家",
                    avatarUrl: "https://ui-avatars.com/api/?name=NS&background=4CAF50&color=fff",
                    bio: "自然の美しさを伝えます",
                    createdAt: Date()
                )
            ),
            Post(
                id: "4",
                userId: "user-1",
                mediaUrl: "https://picsum.photos/400/400?random=4",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: "新しいカメラでテスト撮影 📷",
                locationName: nil,
                latitude: nil,
                longitude: nil,
                isPublic: true,
                createdAt: Date().addingTimeInterval(-10800),
                likeCount: 8,
                commentCount: 1,
                user: UserProfile(
                    id: "user-1",
                    username: "photo_lover",
                    displayName: "フォトグラファー",
                    avatarUrl: "https://ui-avatars.com/api/?name=PL&background=0D8ABC&color=fff",
                    bio: "写真が好きです📷",
                    createdAt: Date()
                )
            ),
            Post(
                id: "5",
                userId: "user-4",
                mediaUrl: "https://picsum.photos/400/400?random=5",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: "コーヒーアート ☕️ 今日も素敵な一杯",
                locationName: "表参道",
                latitude: 35.6654,
                longitude: 139.7186,
                isPublic: true,
                createdAt: Date().addingTimeInterval(-14400),
                likeCount: 18,
                commentCount: 4,
                user: UserProfile(
                    id: "user-4",
                    username: "coffee_artist",
                    displayName: "カフェ愛好家",
                    avatarUrl: "https://ui-avatars.com/api/?name=CA&background=FF5722&color=fff",
                    bio: "コーヒーとアートが好き",
                    createdAt: Date()
                )
            )
        ]
    }
    
    // MARK: - Like Operations
    
    func toggleLike(postId: String, userId: String) async throws -> Bool {
        if PostService.useMockData {
            // モックデータ用のいいね処理
            let isCurrentlyLiked = PostService.mockLikedPosts.contains(postId)
            if isCurrentlyLiked {
                PostService.mockLikedPosts.remove(postId)
                print("✅ PostService (Mock): Post \(postId) unliked")
                return false
            } else {
                PostService.mockLikedPosts.insert(postId)
                print("✅ PostService (Mock): Post \(postId) liked")
                return true
            }
        } else {
            let isNowLiked = try await likeService.toggleLike(postId: postId, userId: userId)
            print("✅ PostService: Post \(postId) like toggled. Now liked: \(isNowLiked)")
            return isNowLiked
        }
    }
    
    func getLikes(for postId: String) async throws -> [Like] {
        return try await likeService.getLikes(for: postId)
    }
    
    func getLikeCount(for postId: String) async throws -> Int {
        return try await likeService.getLikeCount(for: postId)
    }
    
    // MARK: - Mock Data Helper
    
    private func checkMockLikeStatus(postId: String, userId: String) async -> Bool {
        // モックデータ用：動的ないいね状態を返す
        return PostService.mockLikedPosts.contains(postId)
    }
}


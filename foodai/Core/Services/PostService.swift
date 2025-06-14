//======================================================================
// MARK: - PostService.swift（エラー修正版）
// Path: foodai/Core/Services/PostService.swift
//======================================================================
import Foundation
import Supabase

// Supabaseから取得するデータ構造
struct PostResponse: Codable {
    let id: String
    let userId: String
    let restaurantId: String
    let mediaUrl: String
    let mediaType: String
    let thumbnailUrl: String?
    let caption: String?
    let rating: Int
    let visitDate: String?
    let createdAt: String
    
    // リレーション
    let userProfiles: UserProfile?
    let restaurants: Restaurant?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case restaurantId = "restaurant_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case thumbnailUrl = "thumbnail_url"
        case caption, rating
        case visitDate = "visit_date"
        case createdAt = "created_at"
        case userProfiles = "user_profiles"
        case restaurants
    }
}

class PostService {
    private let client = SupabaseManager.shared.client
    static let useMockData = false // 本番モードに切り替え
    
    // フィード用の投稿一覧を取得
    func fetchFeedPosts() async throws -> [Post] {
        // モックモードの場合
        if PostService.useMockData || AuthManager.shared.currentUser?.id == "mock-user-id" {
            print("🔵 モックデータを使用します")
            return getMockPosts()
        }
        
        // 本番モード
        print("🔵 PostService: フィード投稿を取得開始")
        
        do {
            // シンプルなクエリでテスト
            var posts: [Post] = try await client
                .from("posts")
                .select("*")
                .eq("is_public", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ PostService: \(posts.count)件の投稿を取得")
            
            // 手動でユーザーとレストラン情報を取得
            for i in 0..<posts.count {
                // ユーザー情報を取得
                do {
                    let userProfile: UserProfile = try await client
                        .from("user_profiles")
                        .select("*")
                        .eq("id", value: posts[i].userId)
                        .single()
                        .execute()
                        .value
                    posts[i].user = userProfile
                    print("✅ ユーザー情報取得: \(userProfile.username)")
                } catch {
                    print("⚠️ ユーザー情報取得エラー: \(error)")
                }
                
                // レストラン情報を取得
                do {
                    let restaurant: Restaurant = try await client
                        .from("restaurants")
                        .select("*")
                        .eq("id", value: posts[i].restaurantId)
                        .single()
                        .execute()
                        .value
                    posts[i].restaurant = restaurant
                    print("✅ レストラン情報取得: \(restaurant.name)")
                } catch {
                    print("⚠️ レストラン情報取得エラー: \(error)")
                }
            }
            
            return posts
            
        } catch {
            print("❌ PostService エラー: \(error)")
            // エラーの詳細を出力
            if let supabaseError = error as? PostgrestError {
                print("❌ Supabase エラー詳細:")
                print("   - Code: \(supabaseError.code ?? "なし")")
                print("   - Message: \(supabaseError.message)")
                print("   - Hint: \(supabaseError.hint ?? "なし")")
            }
            // 一般的なエラー情報も出力
            print("❌ エラー全体: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 特定ユーザーの投稿を取得
    func fetchUserPosts(userId: String) async throws -> [Post] {
        if PostService.useMockData || AuthManager.shared.currentUser?.id == "mock-user-id" {
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
            
            // 手動でユーザーとレストラン情報を取得
            for i in 0..<posts.count {
                // ユーザー情報を取得
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
                
                // レストラン情報を取得
                do {
                    let restaurant: Restaurant = try await client
                        .from("restaurants")
                        .select("*")
                        .eq("id", value: posts[i].restaurantId)
                        .single()
                        .execute()
                        .value
                    posts[i].restaurant = restaurant
                } catch {
                    print("⚠️ レストラン情報取得エラー: \(error)")
                }
            }
            
            return posts
            
        } catch {
            print("❌ fetchUserPosts エラー: \(error)")
            throw error
        }
    }
    
    // モックデータ
    private func getMockPosts() -> [Post] {
        return [
            Post(
                id: "1",
                userId: "mock-user-id",
                restaurantId: "restaurant-1",
                mediaUrl: "https://picsum.photos/400/300?random=1",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: "素晴らしいイタリアンレストラン！パスタが絶品でした。雰囲気も最高で、デートにもおすすめです。",
                rating: 4.8,
                visitDate: Date(),
                createdAt: Date(),
                user: UserProfile(
                    id: "mock-user-id",
                    username: "foodlover123",
                    displayName: "美食家",
                    avatarUrl: "https://ui-avatars.com/api/?name=FL&background=0D8ABC&color=fff",
                    bio: "美味しいものが大好き",
                    createdAt: Date()
                ),
                restaurant: Restaurant(
                    id: "restaurant-1",
                    name: "トラットリア ベラ",
                    area: "東京都渋谷区",
                    address: "渋谷1-2-3",
                    latitude: 35.6580,
                    longitude: 139.7016,
                    googlePlaceId: nil,
                    createdAt: Date()
                )
            ),
            Post(
                id: "2",
                userId: "user-2",
                restaurantId: "restaurant-2",
                mediaUrl: "https://picsum.photos/400/300?random=2",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: "ランチセットがコスパ最高！濃厚な豚骨スープが癖になる味。",
                rating: 4.3,
                visitDate: Date(),
                createdAt: Date().addingTimeInterval(-3600),
                user: UserProfile(
                    id: "user-2",
                    username: "ramen_master",
                    displayName: "ラーメンマスター",
                    avatarUrl: "https://ui-avatars.com/api/?name=RM&background=E91E63&color=fff",
                    bio: "ラーメン巡りが趣味",
                    createdAt: Date()
                ),
                restaurant: Restaurant(
                    id: "restaurant-2",
                    name: "麺屋 極",
                    area: "東京都新宿区",
                    address: "新宿3-4-5",
                    latitude: 35.6896,
                    longitude: 139.7006,
                    googlePlaceId: nil,
                    createdAt: Date()
                )
            ),
            Post(
                id: "3",
                userId: "user-3",
                restaurantId: "restaurant-3",
                mediaUrl: "https://picsum.photos/400/300?random=3",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: "新鮮なネタが自慢の寿司屋。特に中トロが絶品！",
                rating: 4.7,
                visitDate: Date(),
                createdAt: Date().addingTimeInterval(-7200),
                user: UserProfile(
                    id: "user-3",
                    username: "sushi_lover",
                    displayName: "寿司愛好家",
                    avatarUrl: "https://ui-avatars.com/api/?name=SL&background=FF5722&color=fff",
                    bio: "お寿司大好き",
                    createdAt: Date()
                ),
                restaurant: Restaurant(
                    id: "restaurant-3",
                    name: "鮨処 かねさか",
                    area: "東京都港区",
                    address: "港区赤坂1-2-3",
                    latitude: 35.6762,
                    longitude: 139.7363,
                    googlePlaceId: nil,
                    createdAt: Date()
                )
            ),
            Post(
                id: "4",
                userId: "mock-user-id",
                restaurantId: "restaurant-4",
                mediaUrl: "https://picsum.photos/400/300?random=4",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: "隠れ家的なカフェを発見！静かで落ち着いた雰囲気です。",
                rating: 3.6,
                visitDate: Date(),
                createdAt: Date().addingTimeInterval(-10800),
                user: UserProfile(
                    id: "mock-user-id",
                    username: "foodlover123",
                    displayName: "美食家",
                    avatarUrl: "https://ui-avatars.com/api/?name=FL&background=0D8ABC&color=fff",
                    bio: "美味しいものが大好き",
                    createdAt: Date()
                ),
                restaurant: Restaurant(
                    id: "restaurant-4",
                    name: "カフェ 青山",
                    area: "東京都港区",
                    address: "南青山2-3-4",
                    latitude: 35.6654,
                    longitude: 139.7186,
                    googlePlaceId: nil,
                    createdAt: Date()
                )
            )
        ]
    }
}


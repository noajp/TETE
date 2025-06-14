//======================================================================
// MARK: - PinCardView（星評価を下に配置版）
// Path: foodai/Features/HomeFeed/Components/PinCardView.swift
//======================================================================
import SwiftUI

struct PinCardView: View {
    let post: Post
    
    var body: some View {
        VStack(spacing: 0) {
            // 画像部分（シンプルに画像のみ）
            GeometryReader { geometry in
                RemoteImageView(imageURL: post.mediaUrl)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.width) // 正方形
                    .clipped()
            }
            .aspectRatio(1, contentMode: .fit) // 1:1の比率を強制
            
            // 情報部分
            VStack(alignment: .leading, spacing: 6) {
                // レストラン名
                Text(post.restaurant?.name ?? "Unknown Restaurant")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // エリア
                Text(post.restaurant?.area ?? "エリア不明")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // 評価（星と数値）- エリアの下に配置
                HStack(spacing: 4) {
                    PreciseStarRatingView(rating: post.rating, size: 12)
                    Text(String(format: "%.1f", post.rating))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer(minLength: 0)
                
                // ユーザー情報
                HStack(spacing: 4) {
                    Group {
                        if let avatarUrl = post.user?.avatarUrl {
                            RemoteImageView(imageURL: avatarUrl)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())
                    
                    Text(post.user?.username ?? "unknown")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                }
            }
            .padding(10)
            .frame(height: 100) // 情報部分の高さを固定
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}


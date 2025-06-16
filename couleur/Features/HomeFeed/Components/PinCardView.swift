//======================================================================
// MARK: - PinCardView（写真共有アプリ版）
// Path: foodai/Features/HomeFeed/Components/PinCardView.swift
//======================================================================
import SwiftUI

struct PinCardView: View {
    let post: Post
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 画像部分
            SophisticatedImageView(imageUrl: post.mediaUrl, height: 250)
            
            // 下部の情報（シンプルに）
            HStack {
                // ユーザー情報
                HStack(spacing: 6) {
                    Group {
                        if let avatarUrl = post.user?.avatarUrl {
                            RemoteImageView(imageURL: avatarUrl)
                        } else {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 20, height: 20)
                    .clipShape(Rectangle())
                    
                    Text(post.user?.username ?? "unknown")
                        .font(.system(size: 12))
                        .foregroundColor(AppEnvironment.Colors.textPrimary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // いいねボタン
                Button(action: {
                    onLikeTapped(post)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(post.isLikedByMe ? .red : .black)
                        
                        if post.likeCount > 0 {
                            Text("\(post.likeCount)")
                                .font(.system(size: 12))
                                .foregroundColor(AppEnvironment.Colors.textPrimary)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(AppEnvironment.Colors.background)
        }
        .background(AppEnvironment.Colors.background)
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
        )
    }
}


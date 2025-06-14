//======================================================================
// MARK: - PinCardView（写真共有アプリ版）
// Path: foodai/Features/HomeFeed/Components/PinCardView.swift
//======================================================================
import SwiftUI

struct PinCardView: View {
    let post: Post
    
    var body: some View {
        VStack(spacing: 0) {
            // 画像部分
            GeometryReader { geometry in
                RemoteImageView(imageURL: post.mediaUrl)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
            }
            .aspectRatio(1, contentMode: .fit)
            
            // 下部の情報（シンプルに）
            HStack {
                // ユーザー情報
                HStack(spacing: 6) {
                    Group {
                        if let avatarUrl = post.user?.avatarUrl {
                            RemoteImageView(imageURL: avatarUrl)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                    
                    Text(post.user?.username ?? "unknown")
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // いいねボタン
                HStack(spacing: 4) {
                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(post.isLikedByMe ? .red : .black)
                    
                    if post.likeCount > 0 {
                        Text("\(post.likeCount)")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.white)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
        )
    }
}


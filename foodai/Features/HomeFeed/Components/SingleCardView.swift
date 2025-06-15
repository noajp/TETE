//======================================================================
// MARK: - SingleCardView（写真共有アプリ版）
// Path: foodai/Features/HomeFeed/Components/SingleCardView.swift
//======================================================================
import SwiftUI

struct SingleCardView: View {
    let post: Post
    
    var body: some View {
        VStack(spacing: 0) {
            // ユーザー情報ヘッダー
            userHeader
            
            // 画像部分
            imageSection
            
            // アクション部分
            actionSection
            
            // キャプション
            if let caption = post.caption, !caption.isEmpty {
                captionSection(caption: caption)
            }
        }
        .background(AppEnvironment.Colors.background)
    }
    
    // MARK: - ユーザーヘッダー
    private var userHeader: some View {
        HStack(spacing: 12) {
            // アバター
            Group {
                if let avatarUrl = post.user?.avatarUrl {
                    RemoteImageView(imageURL: avatarUrl)
                } else {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 0))
            
            // ユーザー名
            Text(post.user?.username ?? "unknown")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppEnvironment.Colors.textPrimary)
            
            Spacer()
            
            // オプションボタン
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(AppEnvironment.Colors.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - 画像セクション
    private var imageSection: some View {
        GeometryReader { geometry in
            RemoteImageView(imageURL: post.mediaUrl)
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.width)
                .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: - アクションセクション
    private var actionSection: some View {
        HStack(spacing: 16) {
            // いいねボタン
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundColor(post.isLikedByMe ? .red : .black)
                    
                    if post.likeCount > 0 {
                        Text("\(post.likeCount)")
                            .font(.system(size: 14))
                            .foregroundColor(AppEnvironment.Colors.textPrimary)
                    }
                }
            }
            
            // コメントボタン
            Button(action: {}) {
                Image(systemName: "message")
                    .font(.system(size: 24))
                    .foregroundColor(AppEnvironment.Colors.textPrimary)
            }
            
            Spacer()
            
            // ブックマークボタン
            Button(action: {}) {
                Image(systemName: post.isSavedByMe ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 24))
                    .foregroundColor(AppEnvironment.Colors.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - キャプションセクション
    private func captionSection(caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(.system(size: 14))
                .foregroundColor(AppEnvironment.Colors.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Text(timeAgoString(from: post.createdAt))
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - ヘルパー関数
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


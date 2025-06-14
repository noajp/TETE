//======================================================================
// MARK: - SingleCardView（単一表示用カード）
// Path: foodai/Features/HomeFeed/Components/SingleCardView.swift
//======================================================================
import SwiftUI

struct SingleCardView: View {
    let post: Post
    
    var body: some View {
        VStack(spacing: 0) {
            // 画像部分
            imageSection
            
            // 情報部分
            infoSection
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
    
    
    // MARK: - 画像セクション
    private var imageSection: some View {
        GeometryReader { geometry in
            RemoteImageView(imageURL: post.mediaUrl)
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .aspectRatio(1.2, contentMode: .fit)
        .cornerRadius(16, corners: [.topLeft, .topRight])
    }
    
    // MARK: - 情報セクション
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // タイトルと評価
            titleAndRatingRow
            
            // エリア情報
            locationInfo
            
            // キャプション
            captionText
            
            // アクションボタン
            actionButtons
            
            Divider()
            
            // ユーザー情報
            userInfoRow
        }
        .padding(24)  // パディングを増やして情報部分を大きく
        .background(Color(.systemBackground))
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }
    
    // MARK: - タイトルと評価
    private var titleAndRatingRow: some View {
        Text(post.restaurant?.name ?? "Unknown Restaurant")
                            .font(.system(size: 24, weight: .bold))  // フォントサイズを大きく
            .foregroundColor(.primary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 位置情報
    private var locationInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            // エリア
            HStack(spacing: 16) {
                Label {
                    Text(post.restaurant?.area ?? "エリア不明")
                        .font(.system(size: 15))
                } icon: {
                    Image(systemName: "map")
                        .font(.system(size: 14))
                }
                .foregroundColor(.secondary)
                
                // 訪問日
                if let visitDate = post.visitDate {
                    Label {
                        Text(visitDate, style: .date)
                            .font(.system(size: 15))
                    } icon: {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // 評価（星と数値）
            HStack(spacing: 4) {
                PreciseStarRatingView(rating: post.rating, size: 18)  // 星も大きく
                Text(String(format: "%.1f", post.rating))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - キャプション
    @ViewBuilder
    private var captionText: some View {
        if let caption = post.caption, !caption.isEmpty {
            Text(caption)
                                    .font(.system(size: 17))  // キャプションも少し大きく
                .foregroundColor(.primary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - アクションボタン
    private var actionButtons: some View {
        HStack(spacing: 24) {
            // いいねボタン
            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(post.isLikedByMe ? .red : .primary)
                    if post.likeCount > 0 {
                        Text("\(post.likeCount)")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // ブックマークボタン
            Button(action: {}) {
                Image(systemName: post.isSavedByMe ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))
                    .foregroundColor(post.isSavedByMe ? AppEnvironment.Colors.accentGreen : .primary)
            }
            
            // シェアボタン
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - ユーザー情報
    private var userInfoRow: some View {
        HStack {
            // アバター
            userAvatar
            
            // ユーザー名と時間
            VStack(alignment: .leading, spacing: 2) {
                Text(post.user?.displayName ?? post.user?.username ?? "unknown")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(timeAgoString(from: post.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // フォローボタン
            if post.userId != AuthManager.shared.currentUser?.id {
                followButton
            }
        }
    }
    
    // MARK: - ユーザーアバター
    private var userAvatar: some View {
        Group {
            if let avatarUrl = post.user?.avatarUrl {
                RemoteImageView(imageURL: avatarUrl)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
    
    // MARK: - フォローボタン
    private var followButton: some View {
        Button(action: {}) {
            Text("フォロー")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppEnvironment.Colors.accentGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppEnvironment.Colors.accentGreen, lineWidth: 1)
                )
        }
    }
    
    // MARK: - ヘルパー関数
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


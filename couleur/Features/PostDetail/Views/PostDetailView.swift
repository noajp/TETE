//======================================================================
// MARK: - PostDetailView（写真共有アプリ版）
// Path: foodai/Features/PostDetail/Views/PostDetailView.swift
//======================================================================
import SwiftUI
import MapKit

struct PostDetailView: View {
    let post: Post
    let onLikeTapped: ((Post) -> Void)?
    @State private var cameraPosition: MapCameraPosition?
    
    init(post: Post, onLikeTapped: ((Post) -> Void)? = nil) {
        self.post = post
        self.onLikeTapped = onLikeTapped
        
        // 位置情報がある場合のみマップの初期位置を設定
        if let latitude = post.latitude, let longitude = post.longitude {
            self._cameraPosition = State(initialValue: MapCameraPosition.region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ))
        } else {
            self._cameraPosition = State(initialValue: nil)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 投稿画像
                SophisticatedImageView(imageUrl: post.mediaUrl, height: 400)
                
                VStack(alignment: .leading, spacing: 16) {
                    // ユーザー情報
                    HStack {
                        if let avatarUrl = post.user?.avatarUrl {
                            RemoteImageView(imageURL: avatarUrl)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 0))
                        } else {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.user?.username ?? "unknown")
                                .font(.system(size: 16, weight: .semibold))
                            Text(post.createdAt, style: .date)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // アクションボタン
                    HStack(spacing: 16) {
                        // いいねボタン
                        Button(action: {
                            onLikeTapped?(post)
                        }) {
                            Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(post.isLikedByMe ? .red : MinimalDesign.Colors.primary)
                        }
                        
                        // コメントボタン
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "message")
                                    .font(.system(size: 24))
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                
                                if post.commentCount > 0 {
                                    Text("\(post.commentCount)")
                                        .font(.system(size: 16))
                                        .foregroundColor(MinimalDesign.Colors.primary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // キャプション
                    if let caption = post.caption {
                        Text(caption)
                            .font(.system(size: 16))
                            .padding(.vertical, 8)
                    }
                    
                    // 位置情報
                    if let locationName = post.locationName {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label(locationName, systemImage: "location")
                                .font(.system(size: 16))
                                .foregroundColor(MinimalDesign.Colors.primary)
                            
                            // マップ（位置情報がある場合）
                            if let cameraPosition = cameraPosition,
                               let latitude = post.latitude,
                               let longitude = post.longitude {
                                
                                Map(position: .constant(cameraPosition)) {
                                    Marker(
                                        locationName,
                                        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                    )
                                    .tint(.black)
                                }
                                .frame(height: 200)
                                .disabled(true)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // 投稿日時
                    Text(post.createdAt.timeAgoDisplay())
                        .font(.system(size: 12))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                        .padding(.top, 8)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .accentColor(MinimalDesign.Colors.accentRed)
    }
}

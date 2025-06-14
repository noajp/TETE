//======================================================================
// MARK: - PostDetailView（iOS 17+対応完全版）
// Path: foodai/Features/PostDetail/Views/PostDetailView.swift
//======================================================================
import SwiftUI
import MapKit

struct PostDetailView: View {
    let post: Post
    @State private var cameraPosition: MapCameraPosition
    
    init(post: Post) {
        self.post = post
        
        // マップの初期位置を設定
        let latitude = post.restaurant?.latitude ?? 35.6812
        let longitude = post.restaurant?.longitude ?? 139.7671
        
        self._cameraPosition = State(initialValue: MapCameraPosition.region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 投稿画像
                RemoteImageView(imageURL: post.mediaUrl)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .clipped()
                    .background(Color.black)
                
                VStack(alignment: .leading, spacing: 16) {
                    // ユーザー情報
                    HStack {
                        if let avatarUrl = post.user?.avatarUrl {
                            RemoteImageView(imageURL: avatarUrl)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
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
                    
                    // レストラン情報
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.restaurant?.name ?? "Unknown Restaurant")
                            .font(.system(size: 24, weight: .bold))
                        
                        // 評価
                        HStack(spacing: 4) {
                            PreciseStarRatingView(rating: post.rating, size: 16)
                            Text(String(format: "%.1f", post.rating))
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        if let area = post.restaurant?.area {
                            Text(area)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // キャプション
                    if let caption = post.caption {
                        Text(caption)
                            .font(.system(size: 16))
                            .padding(.vertical, 8)
                    }
                    
                    Divider()
                    
                    // マップ
                    if post.restaurant?.latitude != nil {
                        Text("場所")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.top, 8)
                        
                        // iOS 17+の新しいMap構文
                        Map(position: $cameraPosition) {
                            if let lat = post.restaurant?.latitude,
                               let lng = post.restaurant?.longitude {
                                Marker(
                                    post.restaurant?.name ?? "レストラン",
                                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                                )
                                .tint(.red)
                            }
                        }
                        .frame(height: 200)
                        .cornerRadius(10)
                        
                        if let address = post.restaurant?.address {
                            Text(address)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

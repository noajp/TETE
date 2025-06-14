//======================================================================
// MARK: - MapView（写真共有アプリ版）
// Path: foodai/Features/Map/Views/MapView.swift
//======================================================================
import SwiftUI
import MapKit

@MainActor
class MapViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var searchText = ""
    @Published var isLoading = false
    
    private let postService = PostService()
    
    init() {
        loadPostsWithLocation()
    }
    
    func loadPostsWithLocation() {
        Task {
            do {
                let allPosts = try await postService.fetchFeedPosts()
                self.posts = allPosts.filter { $0.latitude != nil && $0.longitude != nil }
            } catch {
                print("❌ 位置情報付き投稿の取得に失敗: \(error)")
            }
        }
    }
}

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                // iOS 17+の新しいMap構文
                Map(position: $cameraPosition) {
                    ForEach(viewModel.posts) { post in
                        if let lat = post.latitude,
                           let lng = post.longitude {
                            Annotation(post.locationName ?? "写真", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                                PhotoMapPin(post: post)
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .ignoresSafeArea(edges: .top)
                
                // 検索バー
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("場所を検索", text: $viewModel.searchText)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
                    
                    Spacer()
                }
                
                // 現在地ボタン
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // TODO: 現在地に移動
                            print("現在地に移動")
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("マップ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 写真のマップピン
struct PhotoMapPin: View {
    let post: Post
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            AsyncImage(url: URL(string: post.mediaUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(radius: 3)
        }
        .sheet(isPresented: $showingDetail) {
            PhotoQuickView(post: post)
        }
    }
}

// 写真のクイックビュー
struct PhotoQuickView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                AsyncImage(url: URL(string: post.mediaUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                }
                .frame(maxHeight: 300)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(post.user?.username ?? "unknown")
                            .font(.headline)
                        Spacer()
                    }
                    
                    if let caption = post.caption {
                        Text(caption)
                            .font(.body)
                    }
                    
                    if let locationName = post.locationName {
                        Label(locationName, systemImage: "location")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("写真")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

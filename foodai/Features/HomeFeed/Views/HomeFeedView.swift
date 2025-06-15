//======================================================================
// MARK: - HomeFeedView（写真共有アプリ版）
// Path: foodai/Features/HomeFeed/Views/HomeFeedView.swift
//======================================================================
import SwiftUI

@MainActor
struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @Binding var showGridMode: Bool
    
    private var columns: [GridItem] {
        if showGridMode {
            // グリッドモード（2x2）
            return [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ]
        } else {
            // シングルモード（1枚表示）
            return [GridItem(.flexible())]
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                AppEnvironment.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.posts.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        ProgressView("Loading...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppEnvironment.Colors.background)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No posts yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Tap the + button\nto create your first post")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppEnvironment.Colors.background)
    }
    
    private var contentView: some View {
        ScrollView {
            if showGridMode {
                // グリッドモード
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.posts) { post in
                        NavigationLink(destination: PostDetailView(post: post, onLikeTapped: { post in
                            viewModel.toggleLike(for: post)
                        })) {
                            PinCardView(post: post, onLikeTapped: { post in
                                viewModel.toggleLike(for: post)
                            })
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(2)
            } else {
                // シングルモード（1枚ずつ表示）
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.posts) { post in
                        NavigationLink(destination: PostDetailView(post: post, onLikeTapped: { post in
                            viewModel.toggleLike(for: post)
                        })) {
                            SingleCardView(post: post, onLikeTapped: { post in
                                viewModel.toggleLike(for: post)
                            })
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .refreshable {
            viewModel.loadPosts()
        }
    }
}

// MARK: - Preview
struct HomeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeedView(showGridMode: .constant(false))
    }
}


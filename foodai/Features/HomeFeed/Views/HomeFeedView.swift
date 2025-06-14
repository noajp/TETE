//======================================================================
// MARK: - HomeFeedView（クリーンアップ版）
// Path: foodai/Features/HomeFeed/Views/HomeFeedView.swift
//======================================================================
import SwiftUI

enum GridLayout {
    case single
    case grid
}

@MainActor
struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @State private var gridLayout: GridLayout = .grid
    
    private var columns: [GridItem] {
        switch gridLayout {
        case .single:
            return [GridItem(.flexible())]
        case .grid:
            return [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ]
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(.systemGroupedBackground)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        ProgressView("読み込み中...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("まだ投稿がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("右上の＋ボタンから\n最初の投稿をしてみましょう")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: gridLayout == .single ? 20 : 8) {
                ForEach(viewModel.posts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        if gridLayout == .single {
                            SingleCardView(post: post)
                                .padding(.horizontal, 8)
                        } else {
                            PinCardView(post: post)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .refreshable {
            viewModel.loadPosts()
        }
    }
    
    private var toolbarButtons: some View {
        // グリッド切り替えボタンのみ
        Button(action: toggleGridLayout) {
            Image(systemName: gridLayout == .grid ? "square.grid.2x2" : "square")
                .font(.system(size: 20))
                .foregroundColor(AppEnvironment.Colors.accentGreen)
        }
    }
    
    // MARK: - Actions
    
    private func toggleGridLayout() {
        withAnimation(.spring(response: 0.3)) {
            gridLayout = gridLayout == .grid ? .single : .grid
        }
    }
}

// MARK: - Preview
struct HomeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeedView()
    }
}


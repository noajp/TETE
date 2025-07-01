import SwiftUI

@MainActor
struct SinglePostView: View {
    let initialPost: Post
    @StateObject private var viewModel: HomeFeedViewModel
    @Binding var showGridMode: Bool
    @State private var scrollToTop = false
    
    init(initialPost: Post, viewModel: HomeFeedViewModel, showGridMode: Binding<Bool>) {
        self.initialPost = initialPost
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._showGridMode = showGridMode
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // すべての投稿を元の順序で表示
                    ForEach(viewModel.posts) { post in
                        SingleCardView(post: post) { post in
                            Task {
                                await viewModel.toggleLike(for: post)
                            }
                        }
                        .id(post.id)
                    }
                }
            }
            .onAppear {
                // シングルビューモードに切り替え
                showGridMode = false
                // 選択された投稿までスクロール
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        proxy.scrollTo(initialPost.id, anchor: .top)
                    }
                }
            }
            .onChange(of: scrollToTop) { _, newValue in
                if newValue {
                    withAnimation {
                        proxy.scrollTo(initialPost.id, anchor: .top)
                    }
                    scrollToTop = false
                }
            }
        }
        .navigationBarHidden(true)
    }
}
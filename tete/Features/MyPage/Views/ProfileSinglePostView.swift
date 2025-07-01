import SwiftUI

@MainActor
struct ProfileSinglePostView: View {
    let initialPost: Post
    let allPosts: [Post]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 選択された投稿を最初に表示
                    SingleCardView(post: initialPost) { post in
                        // プロフィールページなのでlike機能は無効
                    }
                    .id(initialPost.id)
                    
                    // それ以外の投稿を下に表示
                    ForEach(allPosts.filter { $0.id != initialPost.id }) { post in
                        SingleCardView(post: post) { post in
                            // プロフィールページなのでlike機能は無効
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}
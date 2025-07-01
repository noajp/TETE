//======================================================================
// MARK: - ProfileSinglePostView.swift
// Purpose: Profile-specific single post view with scroll navigation (スクロールナビゲーション付きプロフィール専用シングル投稿ビュー)
// Path: tete/Features/MyPage/Views/ProfileSinglePostView.swift
//======================================================================
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
                    // すべての投稿を元の順序で表示
                    ForEach(allPosts) { post in
                        SingleCardView(post: post) { post in
                            // プロフィールページなのでlike機能は無効
                        }
                        .id(post.id)
                    }
                }
            }
            .onAppear {
                // 選択された投稿までスクロール
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        proxy.scrollTo(initialPost.id, anchor: .top)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}
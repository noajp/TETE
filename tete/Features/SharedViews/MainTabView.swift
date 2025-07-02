//======================================================================
// MARK: - MainTabView.swift（5タブ版 - 中央に投稿ボタン）
// Path: foodai/Features/SharedViews/MainTabView.swift
//======================================================================
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCreatePost = false
    @State private var showGridMode = false
    @State private var pageSelection = 1  // 0: Camera, 1: Feed
    @State private var isInSingleView = false
    @State private var isInProfileSingleView = false
    
    var body: some View {
        ZStack {
            // TabViewでカメラとフィードをスワイプで切り替え
            TabView(selection: $pageSelection) {
                // カメラビュー
                CameraView()
                    .tag(0)
                    .ignoresSafeArea()
                
                // メインコンテンツ - 横スワイプで画面遷移
                // ホーム → アーティクル → メッセージ → プロフィール
                TabView(selection: $selectedTab) {
                    // ホームフィード (0)
                    UnifiedNavigationView {
                        HomeFeedView(
                            showGridMode: $showGridMode, 
                            showingCreatePost: $showingCreatePost,
                            isInSingleView: $isInSingleView,
                            onBackToGrid: {
                                // シングルビューからグリッドビューに戻る
                                if isInSingleView {
                                    isInSingleView = false
                                    showGridMode = true
                                }
                            }
                        )
                    }
                    .tag(0)
                    
                    // アーティクル (1)
                    UnifiedNavigationView {
                        MagazineFeedView()
                    }
                    .tag(1)
                    
                    // メッセージ (2) - タブの順序用に2に変更
                    UnifiedNavigationView {
                        MessagesView()
                    }
                    .tag(2)
                    
                    // プロフィール (3) - タブの順序用に3に変更
                    UnifiedNavigationView {
                        MyPageView(isInProfileSingleView: $isInProfileSingleView)
                    }
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .tag(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Status bar moved to HomeFeedView
            
            // カメラビューの時はタブバーを非表示
            if pageSelection == 1 {
                // カスタムタブバー（フッター）
                VStack {
                    Spacer()
                    CustomTabBar(
                        selectedTab: $selectedTab,
                        showGridMode: $showGridMode,
                        unreadMessageCount: 0,
                        onCreatePost: {
                            showingCreatePost = true
                        },
                        isInSingleView: isInSingleView,
                        onBackToGrid: {
                            // シングルビューからグリッドビューに戻る
                            if isInSingleView {
                                isInSingleView = false
                                showGridMode = true
                            }
                        },
                        onBackFromProfileSingleView: {
                            // プロフィールのシングルビューから戻る
                            if isInProfileSingleView {
                                isInProfileSingleView = false
                            }
                        }
                    )
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .accentColor(MinimalDesign.Colors.accentRed)
        .fullScreenCover(isPresented: $showingCreatePost) {
            CreatePostNavigationView()
                .transition(.move(edge: .bottom))
        }
    }
}

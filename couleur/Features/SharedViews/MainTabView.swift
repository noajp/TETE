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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // TabViewでカメラとフィードをスワイプで切り替え
            TabView(selection: $pageSelection) {
                // カメラビュー
                CameraView()
                    .tag(0)
                    .ignoresSafeArea()
                
                // メインコンテンツ
                Group {
                    switch selectedTab {
                    case 0:
                        UnifiedNavigationView {
                            HomeFeedView(showGridMode: $showGridMode)
                        }
                    case 1:
                        UnifiedNavigationView {
                            MagazineFeedView()
                        }
                    case 3:
                        UnifiedNavigationView {
                            MapView()
                        }
                    case 4:
                        UnifiedNavigationView {
                            MyPageView()
                        }
                    default:
                        EmptyView()
                    }
                }
                .tag(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // カメラビューの時はタブバーを非表示
            if pageSelection == 1 {
                // カスタムタブバー（フッター）
                CustomTabBar(
                    selectedTab: $selectedTab,
                    showGridMode: $showGridMode,
                    unreadMessageCount: 0,
                    onCreatePost: {
                        showingCreatePost = true
                    }
                )
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

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
    @StateObject private var postStatusManager = PostStatusManager.shared
    
    var body: some View {
        ZStack {
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
                            HomeFeedView(showGridMode: $showGridMode, showingCreatePost: $showingCreatePost)
                        }
                    case 1:
                        UnifiedNavigationView {
                            MagazineFeedView()
                        }
                    case 3:
                        UnifiedNavigationView {
                            MessagesView()
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
            
            // Global Status Bar at the top
            VStack(spacing: 0) {
                if postStatusManager.showStatus {
                    VStack(spacing: 0) {
                        // Status message
                        HStack {
                            Text(postStatusManager.statusMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("×") {
                                postStatusManager.hideStatus()
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                        
                        // Thin progress bar
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 2)
                            
                            Rectangle()
                                .fill(postStatusManager.statusColor)
                                .frame(width: UIScreen.main.bounds.width * postStatusManager.progress, height: 2)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2000)
                }
                
                Spacer()
            }
            
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

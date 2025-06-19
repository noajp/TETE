//======================================================================
// MARK: - MainTabView.swift（5タブ版 - 中央に投稿ボタン）
// Path: foodai/Features/SharedViews/MainTabView.swift
//======================================================================
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCreatePost = false
    @State private var showGridMode = false
    @ObservedObject private var messageService = MessageService.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // コンテンツ
            Group {
                switch selectedTab {
                case 0:
                    HomeFeedView(showGridMode: $showGridMode)
                case 1:
                    MessagesView()
                case 3:
                    MapView()
                case 4:
                    MyPageView()
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // カスタムタブバー
            CustomTabBar(
                selectedTab: $selectedTab,
                showGridMode: $showGridMode,
                unreadMessageCount: messageService.unreadConversationsCount,
                onCreatePost: {
                    showingCreatePost = true
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showingCreatePost) {
            CreatePostNavigationView()
                .transition(.move(edge: .bottom))
        }
        .onAppear {
            // Fetch conversations to get initial unread count
            Task {
                _ = try? await messageService.fetchConversations()
            }
        }
    }
}

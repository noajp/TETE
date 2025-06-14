//======================================================================
// MARK: - MainTabView.swift（5タブ版 - 中央に投稿ボタン）
// Path: foodai/Features/SharedViews/MainTabView.swift
//======================================================================
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCreatePost = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム
            HomeFeedView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            // 検索
            SearchView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                }
                .tag(1)
            
            // 投稿（真ん中）
            Text("")
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                }
                .tag(2)
            
            // 地図
            MapView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "map.fill" : "map")
                }
                .tag(3)
            
            // アカウント設定
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                }
                .tag(4)
        }
        .accentColor(AppEnvironment.Colors.accentGreen)
        .onChange(of: selectedTab) { _,newValue in
            if newValue == 2 {
                showingCreatePost = true
                // 元のタブに戻す
                DispatchQueue.main.async {
                    selectedTab = 0
                }
            }
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostView()
        }
    }
}

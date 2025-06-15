import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showGridMode: Bool
    let onCreatePost: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // フィードボタン（正方形）
            Button(action: {
                if selectedTab == 0 {
                    showGridMode.toggle()
                } else {
                    selectedTab = 0
                }
            }) {
                Group {
                    if showGridMode && selectedTab == 0 {
                        // 4つの小さな正方形（外枠なし）
                        VStack(spacing: 3) {
                            HStack(spacing: 3) {
                                Rectangle()
                                    .stroke(AppEnvironment.Colors.textPrimary, lineWidth: 1)
                                    .frame(width: 7, height: 7)
                                Rectangle()
                                    .stroke(AppEnvironment.Colors.textPrimary, lineWidth: 1)
                                    .frame(width: 7, height: 7)
                            }
                            HStack(spacing: 3) {
                                Rectangle()
                                    .stroke(AppEnvironment.Colors.textPrimary, lineWidth: 1)
                                    .frame(width: 7, height: 7)
                                Rectangle()
                                    .stroke(AppEnvironment.Colors.textPrimary, lineWidth: 1)
                                    .frame(width: 7, height: 7)
                            }
                        }
                    } else {
                        // 通常時は1つの正方形
                        Rectangle()
                            .stroke(AppEnvironment.Colors.textPrimary, lineWidth: selectedTab == 0 ? 1.5 : 1)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // メッセージボタン
            Button(action: {
                selectedTab = 1
            }) {
                Image(systemName: selectedTab == 1 ? "message.fill" : "message")
                    .font(.system(size: 20))
                    .foregroundColor(AppEnvironment.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            
            // 投稿ボタン（中央）
            Button(action: onCreatePost) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(AppEnvironment.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            
            // マップボタン
            Button(action: {
                selectedTab = 3
            }) {
                Image(systemName: selectedTab == 3 ? "map.fill" : "map")
                    .font(.system(size: 20))
                    .foregroundColor(AppEnvironment.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            
            // アカウントボタン
            Button(action: {
                selectedTab = 4
            }) {
                Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    .font(.system(size: 20))
                    .foregroundColor(AppEnvironment.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(AppEnvironment.Colors.background)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(AppEnvironment.Colors.subtleBorder),
            alignment: .top
        )
    }
}
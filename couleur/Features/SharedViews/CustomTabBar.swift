import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showGridMode: Bool
    let unreadMessageCount: Int
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
                        // グリッドモード時は4つの小さな正方形（塗りつぶし）
                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                Rectangle()
                                    .fill(selectedTab == 0 ? AppEnvironment.Colors.accentRed : AppEnvironment.Colors.textPrimary)
                                    .frame(width: 8, height: 8)
                                Rectangle()
                                    .fill(selectedTab == 0 ? AppEnvironment.Colors.accentRed : AppEnvironment.Colors.textPrimary)
                                    .frame(width: 8, height: 8)
                            }
                            HStack(spacing: 2) {
                                Rectangle()
                                    .fill(selectedTab == 0 ? AppEnvironment.Colors.accentRed : AppEnvironment.Colors.textPrimary)
                                    .frame(width: 8, height: 8)
                                Rectangle()
                                    .fill(selectedTab == 0 ? AppEnvironment.Colors.accentRed : AppEnvironment.Colors.textPrimary)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    } else {
                        // シングルモード時は1つの大きな正方形（塗りつぶし）
                        Rectangle()
                            .fill(selectedTab == 0 ? AppEnvironment.Colors.accentRed : AppEnvironment.Colors.textPrimary)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // メッセージボタン
            Button(action: {
                selectedTab = 1
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: selectedTab == 1 ? "message.fill" : "message")
                        .font(.system(size: 20))
                        .foregroundColor(selectedTab == 1 ? AppEnvironment.Colors.accentRed : AppEnvironment.Colors.textPrimary)
                    
                    // Badge for unread messages
                    if unreadMessageCount > 0 {
                        Text(unreadMessageCount > 99 ? "99+" : "\(unreadMessageCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 10, y: -8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // 投稿ボタン（中央）
            Button(action: onCreatePost) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(selectedTab == 2 ? AppEnvironment.Colors.accentRed : AppEnvironment.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            
            // マップボタン
            Button(action: {
                selectedTab = 3
            }) {
                Image(systemName: selectedTab == 3 ? "map.fill" : "map")
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == 3 ? AppEnvironment.Colors.accentRed : AppEnvironment.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            
            // アカウントボタン
            Button(action: {
                selectedTab = 4
            }) {
                Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == 4 ? AppEnvironment.Colors.accentRed : AppEnvironment.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(AppEnvironment.Colors.background)
    }
}
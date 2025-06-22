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
                        // グリッドモード時は4つの小さな正方形（選択時は塗りつぶし、非選択時は枠線のみ）
                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                if selectedTab == 0 {
                                    Rectangle()
                                        .fill(MinimalDesign.Colors.accentRed)
                                        .frame(width: 8, height: 8)
                                    Rectangle()
                                        .fill(MinimalDesign.Colors.accentRed)
                                        .frame(width: 8, height: 8)
                                } else {
                                    Rectangle()
                                        .stroke(MinimalDesign.Colors.primary, lineWidth: 1)
                                        .frame(width: 8, height: 8)
                                    Rectangle()
                                        .stroke(MinimalDesign.Colors.primary, lineWidth: 1)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            HStack(spacing: 2) {
                                if selectedTab == 0 {
                                    Rectangle()
                                        .fill(MinimalDesign.Colors.accentRed)
                                        .frame(width: 8, height: 8)
                                    Rectangle()
                                        .fill(MinimalDesign.Colors.accentRed)
                                        .frame(width: 8, height: 8)
                                } else {
                                    Rectangle()
                                        .stroke(MinimalDesign.Colors.primary, lineWidth: 1)
                                        .frame(width: 8, height: 8)
                                    Rectangle()
                                        .stroke(MinimalDesign.Colors.primary, lineWidth: 1)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    } else {
                        // シングルモード時は1つの大きな正方形（選択時は塗りつぶし、非選択時は枠線のみ）
                        if selectedTab == 0 {
                            Rectangle()
                                .fill(MinimalDesign.Colors.accentRed)
                                .frame(width: 20, height: 20)
                        } else {
                            Rectangle()
                                .stroke(MinimalDesign.Colors.primary, lineWidth: 1)
                                .frame(width: 20, height: 20)
                        }
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
                        .foregroundColor(selectedTab == 1 ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
                    
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
                ZStack {
                    Circle()
                        .fill(MinimalDesign.Colors.accentRed)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            
            // 雑誌ボタン
            Button(action: {
                selectedTab = 3
            }) {
                Image(systemName: selectedTab == 3 ? "book.fill" : "book")
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == 3 ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
            }
            .frame(maxWidth: .infinity)
            
            // アカウントボタン
            Button(action: {
                selectedTab = 4
            }) {
                Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == 4 ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(MinimalDesign.Colors.background)
    }
}
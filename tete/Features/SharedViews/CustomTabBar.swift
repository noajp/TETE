//======================================================================
// MARK: - CustomTabBar.swift
// Purpose: Custom tab bar with dynamic icons and navigation (動的アイコンとナビゲーション機能付きカスタムタブバー)
// Path: tete/Features/SharedViews/CustomTabBar.swift
//======================================================================
import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showGridMode: Bool
    let unreadMessageCount: Int
    let onCreatePost: () -> Void
    let isInSingleView: Bool
    let onBackToGrid: (() -> Void)?
    let onBackFromProfileSingleView: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 0) {
            // フィードボタン（正方形）
            Button(action: {
                if isInSingleView {
                    // シングルビューからグリッドビューに戻る
                    onBackToGrid?()
                } else if selectedTab == 0 {
                    showGridMode.toggle()
                } else {
                    selectedTab = 0
                }
            }) {
                Group {
                    if isInSingleView {
                        // シングルビュー表示中は1つの大きな正方形（常に塗りつぶし）
                        Rectangle()
                            .fill(selectedTab == 0 ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
                            .frame(width: 20, height: 20)
                    } else if showGridMode && selectedTab == 0 {
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
            
            // 雑誌ボタン
            Button(action: {
                selectedTab = 1
            }) {
                Image(systemName: selectedTab == 1 ? "book.fill" : "book")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(selectedTab == 1 ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
            }
            .frame(maxWidth: .infinity)
            
            // 投稿ボタン（中央）- 非表示にする
            /*
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
            */
            
            // メッセージボタン
            Button(action: {
                selectedTab = 3
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: selectedTab == 3 ? "message.fill" : "message")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(selectedTab == 3 ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
                    
                    // 未読メッセージバッジ
                    if unreadMessageCount > 0 {
                        Circle()
                            .fill(MinimalDesign.Colors.accentRed)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // アカウントボタン
            Button(action: {
                if selectedTab == 4 && onBackFromProfileSingleView != nil {
                    // プロフィールのシングルビューから戻る
                    onBackFromProfileSingleView?()
                } else {
                    selectedTab = 4
                }
            }) {
                Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(selectedTab == 4 ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(MinimalDesign.Colors.background)
    }
}
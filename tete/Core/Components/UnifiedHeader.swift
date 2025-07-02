//======================================================================
// MARK: - UnifiedHeader.swift
// Purpose: Unified header component used across the app (アプリ全体で使用される統一ヘッダーコンポーネント)
// Path: tete/Core/Components/UnifiedHeader.swift
//======================================================================
import SwiftUI

struct UnifiedHeader: View {
    let title: String
    let showBackButton: Bool
    let rightButton: HeaderButton?
    let onBack: (() -> Void)?
    let isDarkMode: Bool
    
    init(
        title: String,
        showBackButton: Bool = false,
        rightButton: HeaderButton? = nil,
        onBack: (() -> Void)? = nil,
        isDarkMode: Bool = false
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightButton = rightButton
        self.onBack = onBack
        self.isDarkMode = isDarkMode
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header content
            HStack(spacing: 0) {
                // Title - 左端に配置
                Text(title)
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(isDarkMode ? .white : MinimalDesign.Colors.primary)
                    .padding(.leading, 8)
                
                Spacer()
                
                // Left button area (if back button is needed)
                if showBackButton {
                    Button(action: {
                        onBack?()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(isDarkMode ? .white : MinimalDesign.Colors.primary)
                    }
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 8)
                }
                
                // Right button area
                if let rightButton = rightButton {
                    Button(action: {
                        print("🔴 Header button action triggered")
                        rightButton.action()
                    }) {
                        Image(systemName: rightButton.icon)
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(isDarkMode ? .white : MinimalDesign.Colors.primary)
                    }
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 2)
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            .padding(.vertical, MinimalDesign.Spacing.xs)
            .padding(.top, -4)
            .background(isDarkMode ? Color.black.opacity(0.3) : MinimalDesign.Colors.background)
        }
        .background(isDarkMode ? Color.black.ignoresSafeArea(edges: .top) : MinimalDesign.Colors.background.ignoresSafeArea(edges: .top))
    }
}

struct HeaderButton {
    let icon: String
    let action: () -> Void
}

// Unified navigation wrapper
struct UnifiedNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationBarHidden(true)
        }
    }
}
import SwiftUI

struct UnifiedHeader: View {
    let title: String
    let showBackButton: Bool
    let rightButton: HeaderButton?
    let onBack: (() -> Void)?
    
    init(
        title: String,
        showBackButton: Bool = false,
        rightButton: HeaderButton? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightButton = rightButton
        self.onBack = onBack
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header content
            HStack(spacing: 0) {
                // Title - 左端に配置
                Text(title)
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .padding(.leading, 16)
                
                Spacer()
                
                // Left button area (if back button is needed)
                if showBackButton {
                    Button(action: {
                        onBack?()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .regular))
                            .actionTextButtonStyle()
                    }
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 16)
                }
                
                // Right button area
                if let rightButton = rightButton {
                    Button(action: {
                        print("🔴 Header button action triggered")
                        rightButton.action()
                    }) {
                        Image(systemName: rightButton.icon)
                            .font(.system(size: 20, weight: .regular))
                            .actionTextButtonStyle()
                    }
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 16)
                }
            }
            .frame(height: 56)
            .background(MinimalDesign.Colors.background)
            .padding(.top, -15)
        }
        .background(MinimalDesign.Colors.background.ignoresSafeArea(edges: .top))
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
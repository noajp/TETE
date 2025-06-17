//======================================================================
// MARK: - AppEnvironment
// Purpose: App-wide environment settings using MinimalDesign system
// Deprecated: Use MinimalDesign directly for new code
//======================================================================
import SwiftUI

struct AppEnvironment {
    
    // MARK: - Fonts (Bridged to MinimalDesign)
    struct Fonts {
        static func primary(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            Font.system(size: size, weight: weight, design: .default)
        }
        
        static func primaryBold(size: CGFloat) -> Font {
            primary(size: size, weight: .bold)
        }
        
        // Standard sizes using MinimalDesign typography
        static let title = MinimalDesign.Typography.title
        static let headline = MinimalDesign.Typography.headline
        static let body = MinimalDesign.Typography.body
        static let caption = MinimalDesign.Typography.caption
        static let small = MinimalDesign.Typography.small
    }
}


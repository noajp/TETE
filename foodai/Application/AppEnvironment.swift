// foodai/Application/AppEnvironment.swift
import SwiftUI

struct AppEnvironment {
    struct Colors {
        // Off-white background for modern monochrome look - Custom couleur white #FFFFFD
        static let background = Color(
            light: Color(red: 1.0, green: 1.0, blue: 0.992),
            dark: Color.black
        )
        
        // Pure black/white text for maximum contrast
        static let textPrimary = Color(
            light: Color.black,
            dark: Color.white
        )
        
        static let textSecondary = Color(
            light: Color.black.opacity(0.6),
            dark: Color.white.opacity(0.6)
        )
        
        // Red accent color for modern look - Custom couleur red #BF0B2C
        static let accentRed = Color(red: 0.749, green: 0.043, blue: 0.173)
        
        // Keep green for backward compatibility but update to pure green
        static let accentGreen = Color.green
        
        static let buttonText = Color(
            light: Color.white, // White text on black buttons
            dark: Color.black   // Black text on white buttons
        )
        
        // Sharp borders for modern geometric look
        static let subtleBorder = Color(
            light: Color.black.opacity(0.2),
            dark: Color.white.opacity(0.2)
        )
        
        // Pure white/black input backgrounds
        static let inputBackground = Color(
            light: Color.white,
            dark: Color.black
        )
        
        // Modern button backgrounds
        static let buttonBackground = Color(
            light: Color.black,
            dark: Color.white
        )
    }

    struct Fonts {
        static func primary(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .default)
        }
        static func primaryBold(size: CGFloat) -> Font {
            primary(size: size, weight: .bold)
        }
    }
}


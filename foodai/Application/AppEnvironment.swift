// foodai/Application/AppEnvironment.swift
import SwiftUI

struct AppEnvironment {
    struct Colors {
        // Very subtle cream background - almost white with tiny hint of yellow
        static let background = Color(
            light: Color(red: 0.9996, green: 0.9996, blue: 0.9965), // Almost white with tiny yellow hint
            dark: Color(red: 0.1, green: 0.1, blue: 0.1) // Dark background
        )
        
        // Always black text on light, white on dark
        static let textPrimary = Color(
            light: Color.black,
            dark: Color.white
        )
        
        static let textSecondary = Color(
            light: Color.black.opacity(0.6),
            dark: Color.white.opacity(0.6)
        )
        
        static let accentGreen = Color(red: 0.0863, green: 0.3608, blue: 0.0902) // #165C17
        
        static let buttonText = Color(
            light: Color.black,
            dark: Color.white
        )
        
        static let subtleBorder = Color(
            light: Color.black.opacity(0.1),
            dark: Color.white.opacity(0.1)
        )
        
        static let inputBackground = Color(
            light: Color(red: 0.999, green: 0.999, blue: 0.995), // Very subtle cream
            dark: Color(red: 0.15, green: 0.15, blue: 0.15)
        )
        
        static let lightGreenButtonBackground = Color(
            light: Color(red: 0.999, green: 0.999, blue: 0.995),
            dark: Color(red: 0.2, green: 0.2, blue: 0.2)
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


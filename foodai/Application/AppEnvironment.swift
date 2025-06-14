// foodai/Application/AppEnvironment.swift
import SwiftUI

struct AppEnvironment {
    struct Colors {
        static let background = Color("appBackground")
        static let textPrimary = Color("textPrimary")
        static let textSecondary = Color("textSecondary")
        static let accentGreen = Color(red: 0.0863, green: 0.3608, blue: 0.0902) // #165C17
        static let buttonText = Color("buttonText")
        static let subtleBorder = Color("subtleBorder")
        static let inputBackground = Color("inputBackground")
        static let lightGreenButtonBackground = Color("lightGreenButtonBackground")
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


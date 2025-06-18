//
//  PresetModels.swift
//  couleur
//
//  プリセット関連のデータモデル
//

import SwiftUI

// MARK: - Preset Category
enum PresetCategory: String, CaseIterable {
    case allPresets = "ALL PRESETS"
    case forThisPhoto = "FOR THIS PHOTO"
    case favorites = "FAVORITES"
    case popular = "POPULAR"
}

// MARK: - Preset Type
enum PresetType: String, CaseIterable {
    case none = "-"
    case au1 = "AU1"
    case au5 = "AU5"
    case av4 = "AV4"
    case av8 = "AV8"
    case fa1 = "FA1"
    case hb2 = "HB2"
    
    var color: Color? {
        switch self {
        case .none, .hb2:
            return nil
        case .au1, .au5:
            return Color(red: 195/255, green: 125/255, blue: 255/255) // Purple
        case .av4, .av8:
            return Color(red: 255/255, green: 138/255, blue: 128/255) // Red
        case .fa1:
            return Color(red: 255/255, green: 214/255, blue: 10/255) // Yellow
        }
    }
    
    var filterSettings: FilterSettings {
        switch self {
        case .none:
            return FilterSettings()
        case .au1:
            return FilterSettings(
                brightness: 0.1,
                contrast: 1.2,
                saturation: 0.9,
                temperature: 5500,
                tint: -5
            )
        case .au5:
            return FilterSettings(
                brightness: 0.05,
                contrast: 1.15,
                saturation: 0.85,
                temperature: 5800,
                tint: -3
            )
        case .av4:
            return FilterSettings(
                brightness: 0.15,
                contrast: 1.1,
                saturation: 1.2,
                temperature: 6000,
                tint: 5
            )
        case .av8:
            return FilterSettings(
                brightness: 0.08,
                contrast: 1.25,
                saturation: 1.15,
                temperature: 6200,
                tint: 8
            )
        case .fa1:
            return FilterSettings(
                brightness: 0.2,
                contrast: 1.0,
                saturation: 1.1,
                temperature: 5200,
                tint: 0
            )
        case .hb2:
            return FilterSettings(
                brightness: -0.05,
                contrast: 1.3,
                saturation: 0.8,
                temperature: 4800,
                tint: -10
            )
        }
    }
}

// MARK: - Filter Settings
struct FilterSettings {
    var brightness: Float = 0
    var contrast: Float = 1
    var saturation: Float = 1
    var temperature: Float = 5000
    var tint: Float = 0
}

// MARK: - Preset Model
struct Preset: Identifiable {
    let id = UUID()
    let type: PresetType
    let thumbnail: UIImage?
    var isFavorite: Bool = false
    var usageCount: Int = 0
    
    init(type: PresetType, thumbnail: UIImage? = nil) {
        self.type = type
        self.thumbnail = thumbnail
    }
}

// MARK: - Editor Tab
enum EditorTab: String, CaseIterable {
    case presets
    case effects
    case adjust
    case tools
    case export
    
    var icon: String {
        switch self {
        case .presets:
            return "square.grid.2x2"
        case .effects:
            return "fx"
        case .adjust:
            return "slider.horizontal.3"
        case .tools:
            return "paperclip"
        case .export:
            return "star"
        }
    }
    
    var title: String {
        switch self {
        case .presets:
            return "プリセット"
        case .effects:
            return "エフェクト"
        case .adjust:
            return "調整"
        case .tools:
            return "ツール"
        case .export:
            return "書き出し"
        }
    }
}
//======================================================================
// MARK: - Config.swift（Secrets.plist版）
// Path: foodai/Core/Config/Config.swift
//======================================================================
import Foundation

enum Config {
    private static let secrets: [String: Any] = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("❌ Secrets.plist not found")
            fatalError("Secrets.plist not found. Please create it with SUPABASE_URL and SUPABASE_ANON_KEY")
        }
        print("✅ Secrets.plist loaded successfully")
        return dict
    }()
    
    static let supabaseURL: String = {
        guard let url = secrets["SUPABASE_URL"] as? String else {
            fatalError("SUPABASE_URL not found in Secrets.plist")
        }
        print("🔵 Supabase URL: \(url)")
        return url
    }()
    
    static let supabaseAnonKey: String = {
        guard let key = secrets["SUPABASE_ANON_KEY"] as? String else {
            fatalError("SUPABASE_ANON_KEY not found in Secrets.plist")
        }
        print("🔵 Supabase Key: \(String(key.prefix(20)))...")
        return key
    }()
    // Google Places API Key追加
    static let googlePlacesAPIKey: String = {
        guard let key = secrets["GOOGLE_PLACES_API_KEY"] as? String else {
            fatalError("GOOGLE_PLACES_API_KEY not found in Secrets.plist")
        }
        print("🔵 Google Places API Key loaded")
        return key
    }()
}


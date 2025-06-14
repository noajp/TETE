
//======================================================================
// MARK: - 修正版 SupabaseManager.swift
// Path: foodai/Core/Networking/SupabaseManager.swift
//======================================================================
import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }
}


//======================================================================
// MARK: - foodaiApp.swift の更新
// Path: foodai/foodaiApp.swift
//======================================================================
import SwiftUI

@main
struct foodaiApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    print("🔵 App received URL: \(url)")
                    Task {
                        do {
                            try await AuthManager.shared.handleAuthCallback(url: url)
                        } catch {
                            print("❌ Error handling auth callback: \(error)")
                        }
                    }
                }
        }
    }
}


//======================================================================
// MARK: - 最終版 AuthManager.swift（型の問題を修正）
// Path: foodai/Core/Auth/AuthManager.swift
//======================================================================
import Foundation
import Supabase

// アプリ内で使用するUser構造体（名前を変更してSupabaseのUserと区別）
struct AppUser: Codable {
    let id: String
    let email: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    
    private let client = SupabaseManager.shared.client
    
    private init() {
        // 現在のユーザーをチェック
        Task {
            await checkCurrentUser()
        }
    }
    
    func checkCurrentUser() async {
        do {
            let session = try await client.auth.session
            let user = session.user
            
            await MainActor.run {
                self.currentUser = AppUser(
                    id: user.id.uuidString,
                    email: user.email,
                    createdAt: user.createdAt.ISO8601Format()
                )
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        let user = session.user
        await MainActor.run {
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let session = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        let user = session.user
        await MainActor.run {
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
}


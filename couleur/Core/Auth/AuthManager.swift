//======================================================================
// MARK: - AuthManager.swift (Google + Email Authentication)
// Path: foodai/Core/Auth/AuthManager.swift
//======================================================================
import Foundation
import Supabase

extension Notification.Name {
    static let authStateChanged = Notification.Name("authStateChanged")
}

// アプリ内で使用するUser構造体
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

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let client = SupabaseManager.shared.client
    
    private init() {
        Task {
            await checkCurrentUser()
        }
    }
    
    // MARK: - Current User Check
    
    func checkCurrentUser() async {
        isLoading = true
        
        do {
            let session = try await client.auth.session
            let user = session.user
            
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            print("✅ Current user found: \(user.email ?? "No email")")
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
            print("ℹ️ No current user session")
        }
        
        isLoading = false
    }
    
    // MARK: - Email Authentication
    
    func signInWithEmail(email: String, password: String) async throws {
        print("🔵 Attempting sign in with email: \(email)")
        isLoading = true
        
        do {
            print("🔵 Calling Supabase auth.signIn...")
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            print("🔵 Sign in response received")
            let user = session.user
            print("🔵 User ID: \(user.id.uuidString)")
            print("🔵 User Email: \(user.email ?? "nil")")
            
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            print("✅ Email sign in successful: \(user.email ?? "")")
        } catch {
            print("❌ Email sign in failed: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
            let nsError = error as NSError
            print("❌ Error domain: \(nsError.domain)")
            print("❌ Error code: \(nsError.code)")
            print("❌ Error userInfo: \(nsError.userInfo)")
            
            isLoading = false
            throw error
        }
        
        isLoading = false
    }
    
    func signUpWithEmail(email: String, password: String) async throws -> String {
        isLoading = true
        
        do {
            let session = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            let user = session.user
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            print("✅ Email sign up successful: \(user.email ?? "")")
            return user.id.uuidString
        } catch {
            print("❌ Email sign up failed: \(error)")
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Google Authentication (Web OAuth)
    
    func signInWithGoogle() async throws {
        print("🔵 Starting Google OAuth sign in")
        isLoading = true
        
        do {
            // Start OAuth flow - this will open the browser
            let redirectURL = URL(string: "com.takanorinakano.couleur://auth")!
            try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: redirectURL
            )
            
            print("✅ Google OAuth flow initiated - waiting for callback")
            // Note: isLoading will be set to false in handleAuthCallback
        } catch {
            print("❌ Google sign in failed: \(error)")
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Profile Management
    
    func createUserProfile(userId: String, username: String, displayName: String, bio: String? = nil) async throws {
        let profileData: [String: AnyJSON] = [
            "id": AnyJSON.string(userId),
            "username": AnyJSON.string(username),
            "display_name": AnyJSON.string(displayName),
            "bio": AnyJSON.string(bio ?? "Hello, I'm \(displayName)!")
        ]
        
        try await client
            .from("user_profiles")
            .insert(profileData)
            .execute()
        
        print("✅ User profile created: \(username)")
    }
    
    func checkUsernameAvailability(username: String) async throws -> Bool {
        do {
            let response = try await client
                .from("user_profiles")
                .select("username")
                .eq("username", value: username)
                .execute()
            
            // If we get data, username is taken
            let data = String(data: response.data, encoding: .utf8) ?? ""
            return data == "[]" // Empty array means username is available
        } catch {
            print("❌ Error checking username: \(error)")
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        isLoading = true
        
        do {
            try await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            print("✅ Sign out successful")
        } catch {
            print("❌ Sign out failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
        print("✅ Password reset email sent to: \(email)")
    }
    
    // MARK: - OAuth URL Handling
    
    func handleAuthCallback(url: URL) async throws {
        print("🔵 Handling auth callback URL: \(url)")
        
        // Extract the session from the URL callback
        do {
            let session = try await client.auth.session(from: url)
            let user = session.user
            
            print("🔵 Auth callback successful")
            print("🔵 User ID: \(user.id.uuidString)")
            print("🔵 User Email: \(user.email ?? "nil")")
            
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
            self.isLoading = false
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            print("✅ OAuth authentication successful: \(user.email ?? "")")
        } catch {
            print("❌ Auth callback failed: \(error)")
            self.isLoading = false
            throw error
        }
    }
    
    // MARK: - Legacy methods (backward compatibility)
    
    func signIn(email: String, password: String) async throws {
        try await signInWithEmail(email: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        let _ = try await signUpWithEmail(email: email, password: password)
    }
}
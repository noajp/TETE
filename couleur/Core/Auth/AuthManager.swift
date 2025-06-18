//======================================================================
// MARK: - AuthManager.swift (Secure Authentication System)
// Path: couleur/Core/Auth/AuthManager.swift
//======================================================================
import Foundation
import Supabase

extension Notification.Name {
    static let authStateChanged = Notification.Name("authStateChanged")
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidInput(String)
    case rateLimitExceeded(TimeInterval)
    case accountLocked
    case weakPassword([String])
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .rateLimitExceeded(let duration):
            return "Too many failed attempts. Please try again in \(Int(duration/60)) minutes."
        case .accountLocked:
            return "Account temporarily locked due to multiple failed login attempts."
        case .weakPassword(let errors):
            return "Password requirements not met: \(errors.joined(separator: ", "))"
        }
    }
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
class AuthManager: ObservableObject, AuthManagerProtocol {
    typealias User = AppUser
    static let shared = AuthManager()
    
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let client = SupabaseManager.shared.client
    private let secureLogger = SecureLogger.shared
    
    // セキュリティ設定
    private let maxLoginAttempts = 5
    private let lockoutDuration: TimeInterval = 900 // 15分
    private var loginAttempts: [String: (count: Int, lastAttempt: Date)] = [:]
    
    private init() {
        setupSecurityConfiguration()
        Task {
            await checkCurrentUser()
        }
    }
    
    private func setupSecurityConfiguration() {
        // セキュア設定の初期化
        SecureConfig.shared.setupCredentials()
        secureLogger.info("AuthManager initialized with secure configuration")
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
            
            secureLogger.authEvent("Current user session found", userID: user.id.uuidString)
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
            secureLogger.debug("No current user session found")
        }
        
        isLoading = false
    }
    
    // MARK: - Email Authentication
    
    func signIn(email: String, password: String) async throws {
        try await signInWithEmail(email: email, password: password)
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        // 入力検証
        let emailValidation = InputValidator.validateEmail(email)
        guard emailValidation.isValid, let validEmail = emailValidation.value else {
            secureLogger.securityEvent("Invalid email format during sign in", details: ["email": email])
            throw AuthError.invalidInput("Invalid email format")
        }
        
        // レート制限チェック
        try checkRateLimit(for: validEmail)
        
        secureLogger.authEvent("Sign in attempt", userID: nil)
        isLoading = true
        
        do {
            let session = try await client.auth.signIn(
                email: validEmail,
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
            
            // ログイン成功時はレート制限をリセット
            resetLoginAttempts(for: validEmail)
            
            secureLogger.authEvent("Sign in successful", userID: user.id.uuidString)
        } catch {
            recordFailedLoginAttempt(for: validEmail)
            secureLogger.securityEvent("Sign in failed", details: ["error": error.localizedDescription])
            isLoading = false
            throw error
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, username: String) async throws {
        // Use existing signUpWithEmail method and ignore the return value for protocol compliance
        _ = try await signUpWithEmail(email: email, password: password)
    }
    
    func signUpWithEmail(email: String, password: String) async throws -> String {
        // 入力検証
        let emailValidation = InputValidator.validateEmail(email)
        guard emailValidation.isValid, let validEmail = emailValidation.value else {
            secureLogger.securityEvent("Invalid email format during sign up", details: ["email": email])
            throw AuthError.invalidInput("Invalid email format")
        }
        
        // パスワード強度チェック
        let passwordValidation = InputValidator.validatePassword(password)
        guard passwordValidation.isValid else {
            secureLogger.securityEvent("Weak password during sign up")
            throw AuthError.weakPassword(passwordValidation.errors)
        }
        
        isLoading = true
        secureLogger.authEvent("Sign up attempt", userID: nil)
        
        do {
            let session = try await client.auth.signUp(
                email: validEmail,
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
            
            secureLogger.authEvent("Sign up successful", userID: user.id.uuidString)
            return user.id.uuidString
        } catch {
            secureLogger.securityEvent("Sign up failed", details: ["error": error.localizedDescription])
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
        let userID = currentUser?.id
        
        do {
            try await client.auth.signOut()
            
            // メモリ内の機密データをクリア
            clearSensitiveData()
            
            self.currentUser = nil
            self.isAuthenticated = false
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            secureLogger.authEvent("Sign out successful", userID: userID)
        } catch {
            secureLogger.securityEvent("Sign out failed", details: ["error": error.localizedDescription])
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Security Helper Methods
    
    private func checkRateLimit(for email: String) throws {
        let currentTime = Date()
        
        if let attempts = loginAttempts[email] {
            // ロックアウト期間中かチェック
            if attempts.count >= maxLoginAttempts {
                let timeSinceLastAttempt = currentTime.timeIntervalSince(attempts.lastAttempt)
                if timeSinceLastAttempt < lockoutDuration {
                    let remainingTime = lockoutDuration - timeSinceLastAttempt
                    secureLogger.securityEvent("Rate limit exceeded", details: ["email": email, "remaining_time": remainingTime])
                    throw AuthError.rateLimitExceeded(remainingTime)
                } else {
                    // ロックアウト期間が過ぎたのでリセット
                    loginAttempts.removeValue(forKey: email)
                }
            }
        }
    }
    
    private func recordFailedLoginAttempt(for email: String) {
        let currentTime = Date()
        
        if var attempts = loginAttempts[email] {
            attempts.count += 1
            attempts.lastAttempt = currentTime
            loginAttempts[email] = attempts
        } else {
            loginAttempts[email] = (count: 1, lastAttempt: currentTime)
        }
        
        secureLogger.securityEvent("Failed login attempt recorded", details: [
            "email": email,
            "attempt_count": loginAttempts[email]?.count ?? 0
        ])
    }
    
    private func resetLoginAttempts(for email: String) {
        loginAttempts.removeValue(forKey: email)
    }
    
    private func clearSensitiveData() {
        // メモリ内の機密データをゼロクリア
        loginAttempts.removeAll()
        
        // 追加のクリーンアップ処理
        secureLogger.debug("Sensitive data cleared from memory")
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
    
    // MARK: - Protocol Compliance
    // AuthManagerProtocol methods signIn and signUp are implemented above
    
}
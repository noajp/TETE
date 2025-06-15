//======================================================================
// MARK: - SignUpView.swift (Redesigned)
// Path: foodai/Core/Auth/Views/SignUpView.swift
//======================================================================
import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool?
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(AppEnvironment.Colors.accentGreen)
                        
                        Text("アカウント作成")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("couleurコミュニティに参加しましょう")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Google Sign-Up Button
                    Button(action: {
                        Task {
                            await signUpWithGoogle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 18))
                            Text("Googleでアカウント作成")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(0)
                    }
                    .disabled(authManager.isLoading)
                    .padding(.horizontal, 20)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("または")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Email
                        VStack(alignment: .leading, spacing: 4) {
                            Text("メールアドレス")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            TextField("your.email@example.com", text: $email)
                                .textFieldStyle(SquareTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disabled(authManager.isLoading)
                        }
                        
                        // Username
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ユーザー名")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            HStack {
                                TextField("username", text: $username)
                                    .textFieldStyle(SquareTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disabled(authManager.isLoading)
                                    .onChange(of: username) { _, newValue in
                                        checkUsernameAvailability(newValue)
                                    }
                                
                                if isCheckingUsername {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if let available = usernameAvailable {
                                    Rectangle()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(available ? .red : .gray)
                                        .overlay(
                                            available ? Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.system(size: 12, weight: .bold)) : nil
                                        )
                                }
                            }
                        }
                        
                        // Display Name
                        VStack(alignment: .leading, spacing: 4) {
                            Text("表示名")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            TextField("山田太郎", text: $displayName)
                                .textFieldStyle(SquareTextFieldStyle())
                                .disabled(authManager.isLoading)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 4) {
                            Text("パスワード")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            SecureField("6文字以上", text: $password)
                                .textFieldStyle(SquareTextFieldStyle())
                                .textContentType(.none)
                                .autocorrectionDisabled()
                                .disabled(authManager.isLoading)
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 4) {
                            Text("パスワード確認")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            SecureField("パスワードを再入力", text: $confirmPassword)
                                .textFieldStyle(SquareTextFieldStyle())
                                .textContentType(.none)
                                .autocorrectionDisabled()
                                .disabled(authManager.isLoading)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Validation Indicators
                    VStack(spacing: 8) {
                        ValidationRow(
                            isValid: isValidEmail,
                            text: "有効なメールアドレス"
                        )
                        
                        ValidationRow(
                            isValid: usernameAvailable == true && !username.isEmpty,
                            text: "利用可能なユーザー名"
                        )
                        
                        ValidationRow(
                            isValid: password.count >= 6,
                            text: "パスワード6文字以上"
                        )
                        
                        ValidationRow(
                            isValid: password == confirmPassword && !password.isEmpty,
                            text: "パスワードが一致"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Sign Up Button
                    Button(action: {
                        Task {
                            await signUp()
                        }
                    }) {
                        Group {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("アカウント作成")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(0)
                    }
                    .disabled(!isFormValid || authManager.isLoading)
                    .padding(.horizontal, 20)
                    
                    // Quick Fill for Testing
                    VStack(spacing: 12) {
                        Text("テスト用クイック入力")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 16) {
                            Button("TestUser1") {
                                fillTestUser1()
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("TestUser2") {
                                fillTestUser2()
                            }
                            .buttonStyle(TestButtonStyle())
                        }
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("新規登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidEmail: Bool {
        email.contains("@") && email.contains(".") && email.count > 5
    }
    
    private var isFormValid: Bool {
        isValidEmail &&
        usernameAvailable == true &&
        !displayName.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    // MARK: - Methods
    
    private func checkUsernameAvailability(_ username: String) {
        guard !username.isEmpty && username.count >= 3 else {
            usernameAvailable = nil
            return
        }
        
        isCheckingUsername = true
        usernameAvailable = nil
        
        Task {
            do {
                let available = try await authManager.checkUsernameAvailability(username: username)
                await MainActor.run {
                    self.usernameAvailable = available
                    self.isCheckingUsername = false
                }
            } catch {
                await MainActor.run {
                    self.usernameAvailable = nil
                    self.isCheckingUsername = false
                }
            }
        }
    }
    
    private func fillTestUser1() {
        email = "test1@couleur.com"
        username = "testuser1"
        displayName = "テストユーザー1"
        password = "test123"
        confirmPassword = "test123"
        usernameAvailable = true // Assume it's available for testing
    }
    
    private func fillTestUser2() {
        email = "test2@couleur.com"
        username = "testuser2"
        displayName = "テストユーザー2"
        password = "test123"
        confirmPassword = "test123"
        usernameAvailable = true // Assume it's available for testing
    }
    
    private func signUpWithGoogle() async {
        print("🔵 SignUpView: Starting Google sign up")
        do {
            try await authManager.signInWithGoogle()
            print("✅ SignUpView: Google sign up completed successfully")
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ SignUpView: Google sign up failed with error: \(error)")
            await MainActor.run {
                errorMessage = handleSignUpError(error)
                showError = true
                print("🔵 SignUpView: Google error message set to: \(errorMessage)")
            }
        }
    }
    
    private func signUp() async {
        guard isFormValid else { return }
        
        do {
            // Create account with Supabase
            let userId = try await authManager.signUpWithEmail(email: email, password: password)
            
            // Create user profile
            try await authManager.createUserProfile(
                userId: userId,
                username: username,
                displayName: displayName
            )
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = handleSignUpError(error)
                showError = true
            }
        }
    }
    
    private func handleSignUpError(_ error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("user already registered") {
            return "このメールアドレスは既に登録されています"
        } else if errorDescription.contains("password") && errorDescription.contains("weak") {
            return "パスワードが弱すぎます。より複雑なパスワードを使用してください"
        } else if errorDescription.contains("email") && errorDescription.contains("invalid") {
            return "無効なメールアドレスです"
        } else if errorDescription.contains("network") {
            return "ネットワーク接続を確認してください"
        } else {
            return "アカウント作成に失敗しました: \(error.localizedDescription)"
        }
    }
}

// MARK: - Validation Row Component

struct ValidationRow: View {
    let isValid: Bool
    let text: String
    
    var body: some View {
        HStack {
            Rectangle()
                .frame(width: 16, height: 16)
                .foregroundColor(isValid ? .red : .gray.opacity(0.3))
                .overlay(
                    isValid ? Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .bold)) : nil
                )
            
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}
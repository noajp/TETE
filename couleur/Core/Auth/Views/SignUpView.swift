//======================================================================
// MARK: - SignUpView.swift (Simple & Modern)
// Path: foodai/Core/Auth/Views/SignUpView.swift
//======================================================================
import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var userid = ""
    @State private var name = ""
    @State private var newsletter = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSuccessMessage = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button("×") {
                        dismiss()
                    }
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 40) {
                    // Title
                    Text("PERSONAL DETAILS")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.primary)
                    
                    // Form
                    VStack(alignment: .leading, spacing: 25) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("EMAIL")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("", text: $email)
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .padding(.bottom, 10)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.secondary.opacity(0.5)),
                                    alignment: .bottom
                                )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("PASSWORD")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            SecureField("", text: $password)
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .padding(.bottom, 10)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.secondary.opacity(0.5)),
                                    alignment: .bottom
                                )
                        }
                        
                        // User ID Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("USERID")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("", text: $userid)
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .onChange(of: userid) { oldValue, newValue in
                                    // Allow only lowercase letters, numbers, underscore, and hyphen (as per DB constraint)
                                    let filtered = newValue.lowercased().filter { char in
                                        char.isLetter || char.isNumber || char == "_" || char == "-"
                                    }
                                    if filtered != newValue {
                                        userid = filtered
                                    }
                                }
                                .padding(.bottom, 10)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.secondary.opacity(0.5)),
                                    alignment: .bottom
                                )
                        }
                        
                        // Name Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("NAME")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("", text: $name)
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .padding(.bottom, 10)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.secondary.opacity(0.5)),
                                    alignment: .bottom
                                )
                        }
                        
                        // Newsletter Checkbox
                        HStack(alignment: .top, spacing: 10) {
                            Button(action: { newsletter.toggle() }) {
                                Rectangle()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(newsletter ? MinimalDesign.Colors.accentRed : .clear)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.primary, lineWidth: 1)
                                    )
                                    .overlay(
                                        newsletter ? Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 12, weight: .bold)) : nil
                                    )
                            }
                            
                            Text("I would like to receive the latest news from couleur by email")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    // OAuth機能は設定完了まで一時的に無効化
                    // TODO: Supabase DashboardでGoogle/Apple OAuth設定完了後に有効化
                    /*
                    // OR Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("OR")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 15)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                    .padding(.vertical, 10)
                    
                    // OAuth Buttons
                    VStack(spacing: 12) {
                        // Google Sign Up
                        Button(action: {
                            Task {
                                await signUpWithGoogle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                Text("Sign up with Google")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Rectangle()
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                                    .background(Color(.systemBackground))
                            )
                        }
                        .disabled(authManager.isLoading)
                        
                        // Apple Sign Up
                        Button(action: {
                            Task {
                                await signUpWithApple()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                Text("Sign up with Apple")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Rectangle()
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                                    .background(Color(.systemBackground))
                            )
                        }
                        .disabled(authManager.isLoading)
                    }
                    */
                    
                    // Create Account Button
                    Button(action: {
                        Task {
                            await signUp()
                        }
                    }) {
                        Text("CREATE ACCOUNT")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Rectangle()
                                    .stroke(Color.primary, lineWidth: 1)
                                    .background(Color(.systemBackground))
                            )
                    }
                    .disabled(email.isEmpty || password.isEmpty || userid.isEmpty || name.isEmpty || authManager.isLoading)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .alert(isSuccessMessage ? "Success" : "Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Methods
    
    private func signUp() async {
        guard !email.isEmpty && !password.isEmpty && !userid.isEmpty && !name.isEmpty else { return }
        
        do {
            // Create account with Supabase
            let userId = try await authManager.signUpWithEmail(email: email, password: password)
            
            // Create user profile with userid as username and name as display name
            try await authManager.createUserProfile(
                userId: userId,
                username: userid,
                displayName: name
            )
            
            print("✅ User profile created successfully")
            
            await MainActor.run {
                // 開発・テスト用: 成功時は直接ディスミス
                errorMessage = "Account created successfully!"
                isSuccessMessage = true
                showError = true
                
                // 1秒後に自動的に画面を閉じる
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = handleSignUpError(error)
                isSuccessMessage = false
                showError = true
            }
        }
    }
    
    private func signUpWithGoogle() async {
        do {
            try await authManager.signInWithGoogle()
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
    
    private func signUpWithApple() async {
        do {
            try await authManager.signInWithApple()
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
        
        if errorDescription.contains("confirmation link") {
            return "Account created! Please check your email and click the confirmation link to complete registration."
        } else if errorDescription.contains("user already registered") {
            return "This email address is already registered"
        } else if errorDescription.contains("password") && errorDescription.contains("weak") {
            return "Password is too weak. Please use a stronger password"
        } else if errorDescription.contains("email") && errorDescription.contains("invalid") {
            return "Invalid email address"
        } else if errorDescription.contains("network") {
            return "Please check your network connection"
        } else {
            return "Account creation failed: \(error.localizedDescription)"
        }
    }
}
//======================================================================
// MARK: - SignInView.swift (Redesigned)
// Path: foodai/Core/Auth/Views/SignInView.swift
//======================================================================
import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @EnvironmentObject var authManager: AuthManager
    
    init() {
        print("🔵 SignInView: Initialized")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo & Title
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(AppEnvironment.Colors.accentGreen)
                        
                        Text("couleur")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("色とりどりの瞬間をシェアしよう")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Authentication Options
                    VStack(spacing: 20) {
                        // Google Sign-In Button (準備中)
                        Button(action: {
                            Task {
                                await signInWithGoogle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 18))
                                Text("Googleでログイン")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(0)
                        }
                        .disabled(authManager.isLoading)
                        
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
                        
                        // Email Sign-In Form
                        VStack(spacing: 16) {
                            TextField("メールアドレス", text: $email)
                                .textFieldStyle(SquareTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disabled(authManager.isLoading)
                            
                            SecureField("パスワード", text: $password)
                                .textFieldStyle(SquareTextFieldStyle())
                                .textContentType(.none)
                                .autocorrectionDisabled()
                                .disabled(authManager.isLoading)
                            
                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("パスワードを忘れた場合") {
                                    showForgotPassword = true
                                }
                                .font(.caption)
                                .foregroundColor(.black)
                            }
                        }
                        
                        // Sign In Button
                        Button(action: {
                            print("🔵 SignIn button tapped")
                            print("🔵 Current email: \(email)")
                            print("🔵 Current password length: \(password.count)")
                            Task {
                                await signInWithEmail()
                            }
                        }) {
                            Group {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("ログイン")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(0)
                        }
                        .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Sign Up Link
                    VStack(spacing: 16) {
                        HStack {
                            Text("アカウントをお持ちでない場合")
                                .font(.body)
                                .foregroundColor(.gray)
                            
                            Button("新規登録") {
                                showSignUp = true
                            }
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        }
                        
                        // Quick Test Accounts
                        VStack(spacing: 8) {
                            Text("テスト用アカウント")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                Button("TestUser1") {
                                    print("🔵 TestUser1 button tapped")
                                    email = "test1@couleur.com"
                                    password = "test123"
                                    print("🔵 Email set to: \(email), Password set")
                                }
                                .buttonStyle(TestButtonStyle())
                                
                                Button("TestUser2") {
                                    print("🔵 TestUser2 button tapped")
                                    email = "test2@couleur.com"
                                    password = "test123"
                                    print("🔵 Email set to: \(email), Password set")
                                }
                                .buttonStyle(TestButtonStyle())
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .background(AppEnvironment.Colors.background)
            .alert("エラー", isPresented: $showError) {
                Button("OK") { }
                    .foregroundColor(AppEnvironment.Colors.accentRed)
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(authManager)
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    private func signInWithEmail() async {
        print("🔵 SignInView: Starting email sign in")
        print("🔵 Email: \(email)")
        print("🔵 Password length: \(password.count)")
        
        do {
            try await authManager.signInWithEmail(email: email, password: password)
            print("✅ SignInView: Sign in completed successfully")
        } catch {
            print("❌ SignInView: Sign in failed with error: \(error)")
            await MainActor.run {
                errorMessage = handleAuthError(error)
                showError = true
                print("🔵 SignInView: Error message set to: \(errorMessage)")
            }
        }
    }
    
    private func signInWithGoogle() async {
        print("🔵 SignInView: Starting Google sign in")
        do {
            try await authManager.signInWithGoogle()
            print("✅ SignInView: Google sign in completed successfully")
        } catch {
            print("❌ SignInView: Google sign in failed with error: \(error)")
            await MainActor.run {
                errorMessage = handleAuthError(error)
                showError = true
                print("🔵 SignInView: Google error message set to: \(errorMessage)")
            }
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("invalid login credentials") {
            return "メールアドレスまたはパスワードが正しくありません"
        } else if errorDescription.contains("email not confirmed") {
            return "メールアドレスの確認が完了していません"
        } else if errorDescription.contains("too many requests") {
            return "ログイン試行回数が多すぎます。しばらく待ってから再試行してください"
        } else if errorDescription.contains("network") {
            return "ネットワーク接続を確認してください"
        } else {
            return "ログインに失敗しました: \(error.localizedDescription)"
        }
    }
}

// MARK: - Custom Styles

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

struct TestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppEnvironment.Colors.accentRed.opacity(0.1))
            .foregroundColor(AppEnvironment.Colors.accentRed)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SquareTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(0)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}
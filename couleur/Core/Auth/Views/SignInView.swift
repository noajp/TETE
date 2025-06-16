//======================================================================
// MARK: - SignInView.swift (Simple & Modern)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 40) {
                // Title
                Text("LOG IN")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.black)
                
                // Form
                VStack(alignment: .leading, spacing: 25) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("EMAIL")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $email)
                            .font(.system(size: 18))
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(.bottom, 10)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3)),
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
                            .padding(.bottom, 10)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3)),
                                alignment: .bottom
                            )
                    }
                    
                    // Forgot Password
                    Button("Have you forgotten your password?") {
                        showForgotPassword = true
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, -10)
                }
                
                // Buttons
                VStack(spacing: 15) {
                    // Login Button
                    Button(action: {
                        Task {
                            await signInWithEmail()
                        }
                    }) {
                        Text("LOG IN")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppEnvironment.Colors.accentRed)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    
                    // Register Button
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("REGISTER")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Rectangle()
                                    .stroke(Color.black, lineWidth: 1)
                                    .background(Color.white)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.white)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
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
    
    // MARK: - Authentication Methods
    
    private func signInWithEmail() async {
        do {
            try await authManager.signInWithEmail(email: email, password: password)
        } catch {
            await MainActor.run {
                errorMessage = handleAuthError(error)
                showError = true
            }
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("invalid login credentials") {
            return "Invalid email or password"
        } else if errorDescription.contains("email not confirmed") {
            return "Email not confirmed"
        } else if errorDescription.contains("too many requests") {
            return "Too many attempts. Please try again later"
        } else if errorDescription.contains("network") {
            return "Please check your network connection"
        } else {
            return "Login failed: \(error.localizedDescription)"
        }
    }
}
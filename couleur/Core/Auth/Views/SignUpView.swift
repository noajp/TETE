//======================================================================
// MARK: - SignUpView.swift (Simple & Modern)
// Path: foodai/Core/Auth/Views/SignUpView.swift
//======================================================================
import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var surname = ""
    @State private var name = ""
    @State private var newsletter = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                        
                        // Surname Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("SURNAME")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("", text: $surname)
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
                    .disabled(email.isEmpty || password.isEmpty || surname.isEmpty || name.isEmpty || authManager.isLoading)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Methods
    
    private func signUp() async {
        guard !email.isEmpty && !password.isEmpty && !surname.isEmpty && !name.isEmpty else { return }
        
        do {
            // Create account with Supabase
            let userId = try await authManager.signUpWithEmail(email: email, password: password)
            
            // Create user profile with surname + name as display name
            let displayName = "\(surname) \(name)"
            let username = email.components(separatedBy: "@").first ?? "user"
            
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
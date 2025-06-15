//======================================================================
// MARK: - ForgotPasswordView.swift
// Path: foodai/Core/Auth/Views/ForgotPasswordView.swift
//======================================================================
import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.horizontal")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                    
                    Text("パスワードリセット")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("登録済みのメールアドレスを入力してください。\nパスワードリセット用のリンクをお送りします。")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Email Input
                VStack(spacing: 16) {
                    TextField("メールアドレス", text: $email)
                        .textFieldStyle(SquareTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(isLoading)
                    
                    Button(action: {
                        Task {
                            await resetPassword()
                        }
                    }) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("リセットリンクを送信")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(email.contains("@") ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(0)
                    }
                    .disabled(!email.contains("@") || isLoading)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
            .navigationTitle("パスワードリセット")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        dismiss()
                    }
                }
            }
            .alert("送信完了", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("パスワードリセット用のリンクを \(email) に送信しました。\nメールをご確認ください。")
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func resetPassword() async {
        isLoading = true
        
        do {
            try await authManager.resetPassword(email: email)
            await MainActor.run {
                showSuccess = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "パスワードリセットに失敗しました: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
}
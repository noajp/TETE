//======================================================================
// MARK: - SignInView（接続テスト修正版）
// Path: foodai/Features/Auth/Views/SignInView.swift
//======================================================================
import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isTesting = false
    @State private var useMockMode = false
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // ロゴ部分
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("foodai")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 入力フィールド
                VStack(spacing: 15) {
                    TextField("メールアドレス", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(isLoading)
                    
                    SecureField("パスワード", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isLoading)
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                
                // ログインボタン
                Button(action: signIn) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("ログイン")
                            .fontWeight(.bold)
                    }
                }
                .frame(width: 200, height: 50)
                .background(AppEnvironment.Colors.accentGreen)
                .foregroundColor(.white)
                .cornerRadius(25)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                // テスト用セクション
                VStack(spacing: 15) {
                    Text("テスト用機能")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // テストアカウントボタン
                    HStack(spacing: 20) {
                        Button(action: {
                            email = "test1@example.com"
                            password = "testpass123"
                            signIn()
                        }) {
                            Text("test1でログイン")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(5)
                        }
                        .disabled(isLoading)
                        
                        Button(action: {
                            email = "test2@example.com"
                            password = "testpass123"
                            signIn()
                        }) {
                            Text("test2でログイン")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(5)
                        }
                        .disabled(isLoading)
                    }
                    
                    // 接続テストボタン（大きく、押しやすく）
                    Button(action: {
                        testConnection()
                    }) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "network")
                            }
                            Text(isTesting ? "テスト中..." : "接続テスト")
                                .fontWeight(.medium)
                        }
                        .frame(width: 150, height: 40)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isTesting)
                    
                    // オフラインモードトグル
                    HStack {
                        Toggle("オフラインモード", isOn: $useMockMode)
                            .font(.caption)
                        Spacer()
                    }
                    .frame(width: 200)
                    .padding(.top, 10)
                    
                    // デバッグ情報
                    if useMockMode {
                        Text("オフラインモードが有効です")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .alert("エラー", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            // 起動時に自動で接続テスト
            testConnection()
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = ""
        
        // オフラインモードの場合
        if useMockMode {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
                
                await MainActor.run {
                    // モックユーザーでログイン
                    authManager.currentUser = AppUser(
                        id: "mock-user-id",
                        email: email,
                        createdAt: Date().ISO8601Format()
                    )
                    authManager.isAuthenticated = true
                    isLoading = false
                }
            }
            return
        }
        
        // 通常のログイン処理
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                await MainActor.run {
                    // エラーの詳細を表示
                    if let nsError = error as NSError? {
                        switch nsError.code {
                        case -1009:
                            errorMessage = "インターネット接続を確認してください\nオフラインモードを有効にして続けることもできます"
                        case -1001:
                            errorMessage = "接続がタイムアウトしました\nオフラインモードを試してください"
                        case -1005:
                            errorMessage = "ネットワーク接続が失われました\nオフラインモードを有効にしてください"
                        default:
                            errorMessage = "エラー: \(error.localizedDescription)\nコード: \(nsError.code)\n\nオフラインモードで続けることができます"
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    showError = true
                    isLoading = false
                }
                print("ログインエラー詳細: \(error)")
            }
        }
    }
    
    private func testConnection() {
        print("🔵 接続テスト開始")
        isTesting = true
        
        Task {
            await NetworkTest.testSupabaseConnection()
            
            await MainActor.run {
                isTesting = false
                errorMessage = "接続テスト完了\nコンソールログを確認してください"
                showError = true
            }
        }
    }
}


//======================================================================
// MARK: - EditProfileView.swift (プロフィール編集画面)
// Path: foodai/Features/MyPage/Views/EditProfileView.swift
//======================================================================
import SwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: MyPageViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    HStack {
                        Text("ユーザー名")
                            .foregroundColor(AppEnvironment.Colors.textSecondary)
                        TextField("@username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Text("表示名")
                            .foregroundColor(AppEnvironment.Colors.textSecondary)
                        TextField("お名前", text: $displayName)
                    }
                }
                
                Section(header: Text("自己紹介")) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                        .padding(.vertical, 4)
                }
                
                Section {
                    Text("最大200文字まで入力できます")
                        .font(.caption)
                        .foregroundColor(AppEnvironment.Colors.textSecondary)
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(username.isEmpty || displayName.isEmpty)
                }
            }
            .alert("エラー", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }
    
    private func loadCurrentProfile() {
        if let profile = viewModel.userProfile {
            username = profile.username
            displayName = profile.displayName ?? ""
            bio = profile.bio ?? ""
        }
    }
    
    private func saveProfile() {
        guard bio.count <= 200 else {
            alertMessage = "自己紹介は200文字以内で入力してください"
            showAlert = true
            return
        }
        
        Task {
            await viewModel.updateProfile(
                username: username,
                displayName: displayName,
                bio: bio
            )
            dismiss()
        }
    }
}
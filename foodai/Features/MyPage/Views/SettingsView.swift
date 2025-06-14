//======================================================================
// MARK: - SettingsView.swift (設定画面)
// Path: foodai/Features/MyPage/Views/SettingsView.swift
//======================================================================
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("enableLocationServices") private var enableLocationServices = true
    @AppStorage("defaultSearchRadius") private var defaultSearchRadius = 5.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("通知設定")) {
                    Toggle("プッシュ通知", isOn: $enableNotifications)
                    
                    if enableNotifications {
                        VStack(alignment: .leading, spacing: 8) {
                            ToggleRow(title: "新規フォロワー", isOn: .constant(true))
                            ToggleRow(title: "いいね", isOn: .constant(true))
                            ToggleRow(title: "コメント", isOn: .constant(true))
                            ToggleRow(title: "予約リマインダー", isOn: .constant(true))
                        }
                        .padding(.leading, 16)
                    }
                }
                
                Section(header: Text("プライバシー")) {
                    Toggle("位置情報サービス", isOn: $enableLocationServices)
                    
                    HStack {
                        Text("検索範囲")
                        Spacer()
                        Text("\(Int(defaultSearchRadius))km")
                            .foregroundColor(AppEnvironment.Colors.textSecondary)
                    }
                    
                    Slider(value: $defaultSearchRadius, in: 1...50, step: 1)
                        .accentColor(AppEnvironment.Colors.accentGreen)
                }
                
                Section(header: Text("アカウント")) {
                    NavigationLink(destination: EmptyView()) {
                        Label("パスワード変更", systemImage: "lock")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("メールアドレス変更", systemImage: "envelope")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("連携アカウント", systemImage: "link")
                    }
                }
                
                Section(header: Text("その他")) {
                    NavigationLink(destination: EmptyView()) {
                        Label("利用規約", systemImage: "doc.text")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("プライバシーポリシー", systemImage: "hand.raised")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("ライセンス", systemImage: "text.justify")
                    }
                    
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppEnvironment.Colors.textSecondary)
                    }
                }
                
                Section {
                    Button(action: {}) {
                        Text("アカウントを削除")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(.system(size: 14))
            .toggleStyle(SwitchToggleStyle(tint: AppEnvironment.Colors.accentGreen))
    }
}
//======================================================================
// MARK: - MyPageView.swift (マイページ/ブックマーク)
// Path: foodai/Features/MyPage/Views/MyPageView.swift
//======================================================================
import SwiftUI

@MainActor
struct MyPageView: View {
    @StateObject private var viewModel = MyPageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィールセクション
                    ProfileSection()
                    
                    // メニューリスト
                    MenuSection()
                }
                .padding()
            }
            .background(AppEnvironment.Colors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ProfileSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(AppEnvironment.Colors.inputBackground)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppEnvironment.Colors.textSecondary)
                )
            
            Text("Your Name")
                .font(AppEnvironment.Fonts.primaryBold(size: 20))
                .foregroundColor(AppEnvironment.Colors.textPrimary)
            
            Text("Food enthusiast")
                .font(AppEnvironment.Fonts.primary(size: 14))
                .foregroundColor(AppEnvironment.Colors.textSecondary)
        }
    }
}

struct MenuSection: View {
    var body: some View {
        VStack(spacing: 0) {
            MenuRowView(icon: "bookmark", title: "Saved Restaurants", action: {})
            MenuRowView(icon: "calendar", title: "My Reservations", action: {})
            MenuRowView(icon: "star", title: "My Reviews", action: {})
            MenuRowView(icon: "gearshape", title: "Settings", action: {})
            MenuRowView(icon: "questionmark.circle", title: "Help & Support", action: {})
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct MenuRowView: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppEnvironment.Colors.accentGreen)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppEnvironment.Fonts.primary(size: 16))
                    .foregroundColor(AppEnvironment.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppEnvironment.Colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}




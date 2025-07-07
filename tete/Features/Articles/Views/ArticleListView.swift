//======================================================================
// MARK: - ArticleListView.swift
// Purpose: SwiftUI view component (ArticleListViewビューコンポーネント)
// Path: tete/Features/Articles/Views/ArticleListView.swift
//======================================================================
//
//  ArticleListView.swift
//  tete
//
//  記事一覧表示画面
//

import SwiftUI

struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    @State private var showingCreateArticle = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.articles.enumerated()), id: \.element.id) { index, article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            if index % 2 == 0 {
                                NewspaperStyleArticleView(article: article)
                            } else {
                                MagazineStyleArticleView(article: article)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Articles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateArticle = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshArticles()
            }
        }
        .task {
            await viewModel.loadArticles()
        }
        .sheet(isPresented: $showingCreateArticle) {
            CreateArticleView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ArticleCreated"))) { _ in
            Task {
                await viewModel.refreshArticles()
            }
        }
    }
}

// MARK: - Newspaper Style Article View (奇数段: 新聞記事スタイル)

struct NewspaperStyleArticleView: View {
    let article: BlogArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Large Cover Image
            if let coverImageUrl = article.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            ProgressView()
                                .tint(.gray)
                        )
                }
                .frame(height: 280)
                .clipped()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(article.title)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                // Author Info
                if let user = article.user {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.username)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            if let publishedAt = article.publishedAt {
                                Text(timeAgoString(from: publishedAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Magazine Style Article View (偶数段: 雑誌スタイル)

struct MagazineStyleArticleView: View {
    let article: BlogArticle
    
    var body: some View {
        HStack(spacing: 20) {
            // Vertical Image
            if let coverImageUrl = article.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            ProgressView()
                                .tint(.gray)
                        )
                }
                .frame(width: 140, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Category
                if let category = article.category,
                   let categoryEnum = ArticleCategory(rawValue: category) {
                    Text(categoryEnum.displayName.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                }
                
                // Title
                Text(article.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                Spacer()
                
                // Author Info
                if let user = article.user {
                    HStack(spacing: 10) {
                        AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(user.username)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            if let publishedAt = article.publishedAt {
                                Text(timeAgoString(from: publishedAt))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ArticleListView()
}
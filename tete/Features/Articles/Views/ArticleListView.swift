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
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.articles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            ArticleCardView(article: article)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("記事")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateArticle = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
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

// MARK: - Article Card View

struct ArticleCardView: View {
    let article: BlogArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cover Image
            if let coverImageUrl = article.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            }
            
            // Article Info
            VStack(alignment: .leading, spacing: 8) {
                // Category and Premium Badge
                HStack {
                    if let category = article.category,
                       let categoryEnum = ArticleCategory(rawValue: category) {
                        HStack(spacing: 4) {
                            Image(systemName: categoryEnum.icon)
                                .font(.caption2)
                            Text(categoryEnum.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    
                    Spacer()
                }
                
                // Title
                Text(article.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // Summary or Content Preview
                if let summary = article.summary {
                    Text(summary)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                } else {
                    Text(article.content)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                }
                
                // Tags
                if !article.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(article.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                
                // Author and Stats
                HStack {
                    // Author
                    if let user = article.user {
                        HStack(spacing: 8) {
                            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                            
                            Text(user.username)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Stats
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .font(.caption)
                            Text("\(article.likeCount)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                                .font(.caption)
                            Text("\(article.viewCount)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                // Published Date
                if let publishedAt = article.publishedAt {
                    Text(timeAgoString(from: publishedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
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
import SwiftUI

struct MagazineFeedView: View {
    @StateObject private var viewModel = MagazineViewModel()
    @State private var selectedCategory: MagazineCategory = .all
    
    var body: some View {
        ScrollableHeaderView(title: "Magazine") {
            VStack(spacing: 0) {
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(MagazineCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    VStack(spacing: 4) {
                                        Text(category.displayName)
                                            .font(.system(size: 14, weight: selectedCategory == category ? .semibold : .regular))
                                            .foregroundColor(selectedCategory == category ? MinimalDesign.Colors.primary : MinimalDesign.Colors.secondary)
                                        
                                        if selectedCategory == category {
                                            Rectangle()
                                                .fill(MinimalDesign.Colors.accentRed)
                                                .frame(height: 2)
                                        } else {
                                            Rectangle()
                                                .fill(Color.clear)
                                                .frame(height: 2)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(MinimalDesign.Colors.background)
                    
                    // Magazine content
                    LazyVStack(spacing: 32) {
                        ForEach(viewModel.articles.filter { selectedCategory == .all || $0.category == selectedCategory }) { article in
                            MagazineArticleCard(article: article)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 100) // タブバー分のスペース
                }
            }
        .onAppear {
            Task {
                await viewModel.loadArticles()
            }
        }
    }
}

// Magazine categories
enum MagazineCategory: String, CaseIterable {
    case all = "all"
    case trending = "trending"
    case fashion = "fashion"
    case lifestyle = "lifestyle"
    case culture = "culture"
    case technology = "technology"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .trending: return "Trending"
        case .fashion: return "Fashion"
        case .lifestyle: return "Lifestyle"
        case .culture: return "Culture"
        case .technology: return "Technology"
        }
    }
}

// Magazine article card component
struct MagazineArticleCard: View {
    let article: MagazineArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                // Featured image
                if article.post.mediaUrl != "" {
                    let imageUrl = article.post.mediaUrl
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(8)
                        case .failure(_):
                            Rectangle()
                                .fill(MinimalDesign.Colors.tertiary)
                                .frame(height: 200)
                                .cornerRadius(8)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(MinimalDesign.Colors.secondary)
                                )
                        case .empty:
                            Rectangle()
                                .fill(MinimalDesign.Colors.tertiary)
                                .frame(height: 200)
                                .cornerRadius(8)
                                .overlay(
                                    ProgressView()
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // Article content
                VStack(alignment: .leading, spacing: 8) {
                    // Category and date
                    HStack {
                        Text(article.category.displayName.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.accentRed)
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(MinimalDesign.Colors.secondary)
                        
                        Text(article.post.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.system(size: 12))
                            .foregroundColor(MinimalDesign.Colors.secondary)
                        
                        Spacer()
                    }
                    
                    // Title
                    Text(article.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Description
                    Text(article.description)
                        .font(.system(size: 16))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Author info
                    HStack {
                        AsyncImage(url: URL(string: article.post.user?.avatarUrl ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                            default:
                                Circle()
                                    .fill(MinimalDesign.Colors.tertiary)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        
                        Text("by \(article.post.user?.username ?? "Unknown")")
                            .font(.system(size: 14))
                            .foregroundColor(MinimalDesign.Colors.secondary)
                        
                        Spacer()
                        
                        // Read time
                        Text("\(article.readTime) min read")
                            .font(.system(size: 14))
                            .foregroundColor(MinimalDesign.Colors.secondary)
                    }
                    .padding(.top, 4)
                }
                
                Divider()
                    .background(MinimalDesign.Colors.tertiary)
            }
    }
}

// Magazine article model
struct MagazineArticle: Identifiable {
    let id = UUID()
    let post: Post
    let title: String
    let description: String
    let category: MagazineCategory
    let readTime: Int
}

// View model
class MagazineViewModel: ObservableObject {
    @Published var articles: [MagazineArticle] = []
    
    @MainActor
    func loadArticles() async {
        // Fetch posts and convert them to magazine articles
        do {
            let posts = try await PostService().fetchFeedPosts(currentUserId: "")
            
            articles = posts.compactMap { post in
                // Generate magazine-style content from posts
                let category = determineCategory(from: post)
                let readTime = calculateReadTime(from: post)
                
                return MagazineArticle(
                    post: post,
                    title: generateTitle(from: post),
                    description: generateDescription(from: post),
                    category: category,
                    readTime: readTime
                )
            }
        } catch {
            print("Error loading articles: \(error)")
        }
    }
    
    private func determineCategory(from post: Post) -> MagazineCategory {
        // Analyze post content/tags to determine category
        // For now, return random category
        return MagazineCategory.allCases.randomElement() ?? .all
    }
    
    private func calculateReadTime(from post: Post) -> Int {
        // Calculate based on content length
        let words = (post.caption ?? "").split(separator: " ").count
        return max(1, words / 200) // Assuming 200 words per minute
    }
    
    private func generateTitle(from post: Post) -> String {
        // Generate magazine-style title from post
        let caption = post.caption ?? "Untitled"
        if caption.count > 50 {
            return String(caption.prefix(50)) + "..."
        }
        return caption
    }
    
    private func generateDescription(from post: Post) -> String {
        // Generate engaging description
        return "Discover the story behind this captivating moment captured by \(post.user?.username ?? "a talented photographer")."
    }
}
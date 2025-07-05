//======================================================================
// MARK: - StoryStyleEditorView.swift
// Purpose: Instagram Stories-style article editor with paper interface
// Path: tete/Features/Articles/Views/StoryStyleEditorView.swift
//======================================================================
import SwiftUI

struct StoryStyleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StoryStyleEditorViewModel()
    let articleType: ArticleType
    
    @State private var showingTextEditor = false
    @State private var showingColorPicker = false
    @State private var showingPreview = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Instagram-style gradient background
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top toolbar
                    topToolbar
                    
                    Spacer()
                    
                    // Paper canvas (2/3 of screen)
                    paperCanvas(in: geometry)
                        .scaleEffect(isDragging ? 0.95 : 1.0)
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    dragOffset = value.translation
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4)) {
                                        isDragging = false
                                        dragOffset = .zero
                                    }
                                }
                        )
                    
                    Spacer()
                    
                    // Bottom toolbar
                    bottomToolbar
                }
                
                // Floating text editor
                if showingTextEditor {
                    textEditorOverlay
                }
                
                // Color picker overlay
                if showingColorPicker {
                    colorPickerOverlay
                }
                
                // Preview overlay
                if showingPreview {
                    previewOverlay
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: articleType == .newspaper 
                ? [Color.blue.opacity(0.8), Color.indigo.opacity(0.9), Color.purple.opacity(0.8)]
                : [Color.purple.opacity(0.8), Color.pink.opacity(0.9), Color.orange.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Subtle pattern overlay
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .background(
                    Image(systemName: "sparkles")
                        .font(.system(size: 200))
                        .foregroundColor(.white.opacity(0.02))
                        .offset(x: 100, y: -100)
                )
        )
    }
    
    // MARK: - Top Toolbar
    
    private var topToolbar: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Article type indicator
            HStack(spacing: 8) {
                Image(systemName: articleType == .newspaper ? "newspaper" : "magazine")
                    .font(.system(size: 14, weight: .medium))
                Text(articleType == .newspaper ? "新聞" : "雑誌")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
            
            Spacer()
            
            // Publish button
            Button(action: {
                Task {
                    await viewModel.publishArticle(type: articleType)
                    dismiss()
                }
            }) {
                Text("公開")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Paper Canvas
    
    private func paperCanvas(in geometry: GeometryProxy) -> some View {
        let paperHeight = geometry.size.height * 0.67 // 2/3 of screen height
        let paperWidth = min(geometry.size.width * 0.85, paperHeight * 0.7)
        
        return ZStack {
            // Paper background with article type styling
            RoundedRectangle(cornerRadius: articleType == .newspaper ? 8 : 16)
                .fill(articleType == .newspaper ? Color.white : Color.white)
                .frame(width: paperWidth, height: paperHeight)
                .overlay(
                    // Newspaper grid lines or magazine texture
                    articleType == .newspaper 
                        ? AnyView(
                            VStack(spacing: 20) {
                                ForEach(0..<15, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(height: 1)
                                }
                            }
                            .padding(.horizontal, 24)
                        )
                        : AnyView(
                            LinearGradient(
                                colors: [Color.clear, Color.purple.opacity(0.02), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            
            // Paper content
            VStack(alignment: .leading, spacing: 16) {
                // Title area
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.title.isEmpty {
                        Text("タイトルをタップして入力")
                            .font(.system(size: 24, weight: .bold, design: articleType == .newspaper ? .serif : .rounded))
                            .foregroundColor(.gray.opacity(0.5))
                            .onTapGesture {
                                viewModel.editingField = .title
                                showingTextEditor = true
                            }
                    } else {
                        Text(viewModel.title)
                            .font(.system(size: 24, weight: .bold, design: articleType == .newspaper ? .serif : .rounded))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .onTapGesture {
                                viewModel.editingField = .title
                                showingTextEditor = true
                            }
                    }
                    
                    // Subtitle/category
                    if !viewModel.category.isEmpty {
                        Text(viewModel.category.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(articleType == .newspaper ? .blue : .purple)
                            .tracking(1)
                    }
                }
                
                // Divider
                if !viewModel.title.isEmpty {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                
                // Content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if viewModel.content.isEmpty {
                            Text("記事の内容を書いてください...")
                                .font(.system(size: 16, design: articleType == .newspaper ? .serif : .default))
                                .foregroundColor(.gray.opacity(0.5))
                                .onTapGesture {
                                    viewModel.editingField = .content
                                    showingTextEditor = true
                                }
                        } else {
                            Text(viewModel.content)
                                .font(.system(size: 16, design: articleType == .newspaper ? .serif : .default))
                                .foregroundColor(.black)
                                .lineSpacing(6)
                                .onTapGesture {
                                    viewModel.editingField = .content
                                    showingTextEditor = true
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .frame(width: paperWidth, height: paperHeight)
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: 24) {
            // Text tool
            ToolButton(
                icon: "textformat",
                isActive: false,
                color: .white
            ) {
                viewModel.editingField = .content
                showingTextEditor = true
            }
            
            // Add image tool
            ToolButton(
                icon: "photo",
                isActive: false,
                color: .white
            ) {
                // TODO: Implement image picker
            }
            
            // Color picker
            ToolButton(
                icon: "paintpalette",
                isActive: showingColorPicker,
                color: .white
            ) {
                showingColorPicker.toggle()
            }
            
            // Category/tags
            ToolButton(
                icon: "tag",
                isActive: false,
                color: .white
            ) {
                viewModel.editingField = .category
                showingTextEditor = true
            }
            
            Spacer()
            
            // Preview button
            Button(action: {
                showingPreview = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "eye")
                    Text("プレビュー")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Text Editor Overlay
    
    private var textEditorOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    showingTextEditor = false
                }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("キャンセル") {
                        showingTextEditor = false
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(viewModel.editingField?.title ?? "")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("完了") {
                        showingTextEditor = false
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                
                // Text editor
                VStack(alignment: .leading) {
                    switch viewModel.editingField {
                    case .title:
                        TextField("タイトル", text: $viewModel.title)
                            .font(.system(size: 24, weight: .bold))
                            .textFieldStyle(PlainTextFieldStyle())
                    case .content:
                        TextField("記事の内容", text: $viewModel.content, axis: .vertical)
                            .font(.system(size: 16))
                            .textFieldStyle(PlainTextFieldStyle())
                            .lineLimit(10...20)
                    case .category:
                        TextField("カテゴリー", text: $viewModel.category)
                            .font(.system(size: 16))
                            .textFieldStyle(PlainTextFieldStyle())
                    case .none:
                        EmptyView()
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
    
    // MARK: - Color Picker Overlay
    
    private var colorPickerOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                ForEach(viewModel.availableColors, id: \.self) { color in
                    Button(action: {
                        viewModel.selectedColor = color
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: viewModel.selectedColor == color ? 3 : 0)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.5))
            .cornerRadius(25)
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }
    
    // MARK: - Preview Overlay
    
    private var previewOverlay: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Preview header
                HStack {
                    Button("閉じる") {
                        showingPreview = false
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("プレビュー")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("投稿") {
                        Task {
                            await viewModel.publishArticle(type: articleType)
                            dismiss()
                        }
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Preview content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Article type badge
                        HStack {
                            Text(articleType == .newspaper ? "NEWS" : "MAGAZINE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(articleType == .newspaper ? .blue : .purple)
                                .tracking(2)
                            
                            Rectangle()
                                .fill(articleType == .newspaper ? Color.blue : Color.purple)
                                .frame(height: 1)
                            
                            Spacer()
                        }
                        
                        // Title
                        Text(viewModel.title.isEmpty ? "無題の記事" : viewModel.title)
                            .font(.system(size: 28, weight: .bold, design: articleType == .newspaper ? .serif : .rounded))
                            .foregroundColor(.white)
                        
                        // Category
                        if !viewModel.category.isEmpty {
                            Text(viewModel.category.uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(articleType == .newspaper ? .blue : .purple)
                                .tracking(1)
                        }
                        
                        // Content
                        Text(viewModel.content.isEmpty ? "内容が入力されていません。" : viewModel.content)
                            .font(.system(size: 16, design: articleType == .newspaper ? .serif : .default))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(6)
                        
                        // Meta info
                        HStack {
                            Text("今すぐ")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(viewModel.content.split(separator: " ").count / 200 + 1) min read")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
        }
    }
}

// MARK: - Tool Button

struct ToolButton: View {
    let icon: String
    let isActive: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(isActive ? Color.white.opacity(0.3) : Color.clear)
                .clipShape(Circle())
        }
    }
}

// MARK: - ViewModel

@MainActor
class StoryStyleEditorViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var category: String = ""
    @Published var selectedColor: Color = .white
    @Published var editingField: EditingField?
    
    let availableColors: [Color] = [
        .white, .black, .red, .blue, .green, .yellow, .purple, .orange, .pink
    ]
    
    enum EditingField {
        case title, content, category
        
        var title: String {
            switch self {
            case .title: return "タイトル"
            case .content: return "本文"
            case .category: return "カテゴリー"
            }
        }
    }
    
    private let articleRepository = ArticleRepository.shared
    
    func publishArticle(type: ArticleType) async {
        guard !title.isEmpty, !content.isEmpty else { return }
        
        do {
            let request = CreateArticleRequest(
                userId: "current-user-id", // TODO: Get actual user ID from AuthManager
                title: title,
                content: content,
                summary: String(content.prefix(150)),
                category: category.isEmpty ? nil : category,
                tags: [],
                isPremium: false,
                coverImageUrl: nil,
                status: .published,
                articleType: type
            )
            
            let _ = try await articleRepository.createArticle(request)
            
            // Notify that article was created
            NotificationCenter.default.post(name: NSNotification.Name("ArticleCreated"), object: nil)
            
            print("✅ Successfully published \(type.rawValue) article: \(title)")
        } catch {
            print("❌ Failed to publish article: \(error)")
        }
    }
}

#Preview {
    StoryStyleEditorView(articleType: .newspaper)
}
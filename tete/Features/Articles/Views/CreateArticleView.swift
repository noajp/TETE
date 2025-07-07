//======================================================================
// MARK: - CreateArticleView.swift
// Purpose: SwiftUI view component (CreateArticleViewビューコンポーネント)
// Path: tete/Features/Articles/Views/CreateArticleView.swift
//======================================================================
//
//  CreateArticleView.swift
//  tete
//
//  記事作成画面
//

import SwiftUI
import PhotosUI

struct CreateArticleView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateArticleViewModel()
    
    @State private var title = ""
    @State private var content = ""
    @State private var summary = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var coverImageItem: PhotosPickerItem?
    @State private var coverImageUrl: String?
    @State private var showingPublishOptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Cover Image Section
                    coverImageSection
                    
                    // Article Content
                    VStack(spacing: 16) {
                        // Title
                        titleSection
                        
                        // Tags
                        tagsSection
                        
                        // Summary
                        summarySection
                        
                        // Content
                        contentSection
                        
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("新しい記事")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("投稿") {
                        showingPublishOptions = true
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingPublishOptions) {
            PublishOptionsView(
                title: title,
                content: content,
                summary: summary.isEmpty ? nil : summary,
                category: "other",
                tags: tags,
                coverImageUrl: coverImageUrl,
                onPublish: { status in
                    Task {
                        await viewModel.createArticle(
                            title: title,
                            content: content,
                            summary: summary.isEmpty ? nil : summary,
                            category: "other",
                            tags: tags,
                            isPremium: false,
                            coverImageUrl: coverImageUrl,
                            status: status,
                            articleType: .magazine  // デフォルトは雑誌記事
                        )
                        dismiss()
                    }
                }
            )
        }
        .onChange(of: coverImageItem) { _, newItem in
            Task { @MainActor in
                coverImageUrl = await viewModel.uploadCoverImage(item: newItem)
            }
        }
    }
    
    // MARK: - Cover Image Section
    
@MainActor
    private var coverImageSection: some View {
        VStack(spacing: 0) {
            // 写真表示画面
            if let imageUrl = coverImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit) // 全画面縮小表示
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            ProgressView()
                                .tint(.gray)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: 300) // 全画面表示
                .background(Color.black.opacity(0.05))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.05))
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("写真が選択されていません")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            // 仕切り線
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(height: 2)
            
            // 追加の視覚的分離
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 8)
            
            // カメラロール選択部分
            PhotosPicker(selection: $coverImageItem, matching: .images) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("写真を選択")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Text("カメラロールから写真を選んでください")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(maxWidth: .infinity)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color(.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タイトル")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("記事のタイトルを入力", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
        }
    }
    
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タグ")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Tag Input
            HStack {
                TextField("タグを追加", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button("追加") {
                    addTag()
                }
                .disabled(newTag.isEmpty)
            }
            
            // Tags Display
            if !tags.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80))
                ], spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagView(tag: tag) {
                            removeTag(tag)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("要約（任意）")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("記事の要約を入力", text: $summary, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                .font(.body)
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("本文")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("記事の内容を書いてください...", text: $content, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(10...50)
                .font(.body)
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}


// MARK: - Tag View

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

// MARK: - Publish Options View

struct PublishOptionsView: View {
    let title: String
    let content: String
    let summary: String?
    let category: String
    let tags: [String]
    let coverImageUrl: String?
    let onPublish: (ArticleStatus) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("記事の公開設定")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 16) {
                    PublishOptionButton(
                        title: "下書きとして保存",
                        description: "後で編集・公開できます",
                        icon: "doc.text"
                    ) {
                        onPublish(.draft)
                        dismiss()
                    }
                    
                    PublishOptionButton(
                        title: "今すぐ公開",
                        description: "記事がすぐに公開されます",
                        icon: "paperplane.fill"
                    ) {
                        onPublish(.published)
                        dismiss()
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("公開設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Publish Option Button

struct PublishOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    CreateArticleView()
}
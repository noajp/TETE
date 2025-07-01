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
        let imageUrl = coverImageUrl // ローカルコピーでmain actor isolationを回避
        
        return PhotosPicker(selection: $coverImageItem, matching: .images) {
            if let imageUrl = imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("カバー画像を選択")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                    .cornerRadius(12)
            }
        }
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
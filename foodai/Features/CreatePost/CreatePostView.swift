//======================================================================
// MARK: - CreatePostView（Google Places API対応版）
// Path: foodai/Features/CreatePost/CreatePostView.swift
//======================================================================
import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

@MainActor
struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingMediaPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var locationName: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. メディア選択
                    MediaPickerSection(
                        selectedImage: $viewModel.selectedImage,
                        selectedVideoURL: $viewModel.selectedVideoURL,
                        mediaType: $viewModel.mediaType,
                        showingMediaPicker: $showingMediaPicker,
                        selectedItem: $selectedItem
                    )
                    
                    // 2. 位置情報（オプション）
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Location")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        TextField("Enter location (optional)", text: $locationName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    
                    
                    // 3. コメント
                    CommentSection(caption: $viewModel.caption)
                    
                    // 4. 投稿ボタン
                    VStack(spacing: 10) {
                        if viewModel.isLoading {
                            ProgressView(value: viewModel.uploadProgress) {
                                Text("Uploading...")
                                    .font(.caption)
                            }
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            print("🔵 Post button tapped")
                            Task {
                                print("🔵 Starting createPost task")
                                await viewModel.createPost()
                                print("🔵 createPost completed, isPostCreated: \(viewModel.isPostCreated)")
                                if viewModel.isPostCreated {
                                    await MainActor.run {
                                        dismiss()
                                    }
                                }
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Post")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.canPost && !viewModel.isLoading ? AppEnvironment.Colors.accentGreen : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(!viewModel.canPost || viewModel.isLoading)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppEnvironment.Colors.accentRed)
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") { }
                    .foregroundColor(AppEnvironment.Colors.accentRed)
            } message: {
                Text(viewModel.errorMessage ?? "Failed to create post")
            }
            .onChange(of: locationName) { _, newLocation in
                viewModel.locationName = newLocation
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let newItem = newItem else { return }
                
                // メディアタイプを判定
                let contentType = try? await newItem.loadTransferable(type: Data.self)
                
                // 一旦データとして読み込んで判定
                if let data = contentType {
                    // 動画かどうかを判定（簡易的な方法）
                    if let image = UIImage(data: data) {
                        // 画像の処理
                        viewModel.mediaType = .photo
                        viewModel.selectedImage = image
                        viewModel.selectedVideoURL = nil
                    } else {
                        // 動画として処理を試みる
                        viewModel.mediaType = .video
                        // TODO: 動画の処理
                    }
                }
            }
        }
    }
}

// MARK: - メディア選択セクション（この部分が欠けていました）
struct MediaPickerSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?
    @Binding var mediaType: Post.MediaType
    @Binding var showingMediaPicker: Bool
    @Binding var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Photo/Video")
                .font(.headline)
                .padding(.horizontal)
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .any(of: [.images, .videos])
            ) {
                if let image = selectedImage {
                    ZStack(alignment: .topTrailing) {
                        SophisticatedUIImageView(image: image, height: 300)
                        
                        if mediaType == .video {
                            // 動画インジケーター
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        // メディアタイプバッジ
                        Text(mediaType == .video ? "Video" : "Photo")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(8)
                    }
                    .padding(.horizontal)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("Tap to select photo/video")
                                    .foregroundColor(.gray)
                            }
                        )
                        .padding(.horizontal)
                }
            }
        }
    }
}


// MARK: - コメントセクション
struct CommentSection: View {
    @Binding var caption: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Caption")
                .font(.headline)
                .padding(.horizontal)
            
            TextEditor(text: $caption)
                .frame(height: 100)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
}

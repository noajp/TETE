//======================================================================
// MARK: - CreatePostView（Minimal Design）
// Path: couleur/Features/CreatePost/CreatePostView.swift
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
    @State private var showingPhotoEditor = false
    @State private var imageToEdit: UIImage?
    @State private var showingCustomCamera = false
    @State private var selectedFilter: FilterType = .none
    @State private var showingFilterPreview = false
    @State private var filterIntensity: Float = 1.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                MinimalHeader(
                    onCancel: { dismiss() },
                    onPost: {
                        Task {
                            await viewModel.createPost()
                            if viewModel.isPostCreated {
                                dismiss()
                            }
                        }
                    },
                    canPost: viewModel.canPost,
                    isLoading: viewModel.isLoading
                )
                
                Divider()
                
                // Content
                ScrollView {
                    LazyVStack(spacing: MinimalDesign.Spacing.lg) {
                        // Media Selection
                        MinimalMediaPickerSection(
                            selectedImage: $viewModel.selectedImage,
                            selectedVideoURL: $viewModel.selectedVideoURL,
                            mediaType: $viewModel.mediaType,
                            showingMediaPicker: $showingMediaPicker,
                            selectedItem: $selectedItem,
                            showingPhotoEditor: $showingPhotoEditor,
                            imageToEdit: $imageToEdit,
                            showingCustomCamera: $showingCustomCamera,
                            selectedFilter: $selectedFilter,
                            showingFilterPreview: $showingFilterPreview,
                            filterIntensity: $filterIntensity
                        )
                        
                        // Quick Filter Selection
                        if viewModel.selectedImage != nil && viewModel.mediaType == .photo {
                            QuickFilterSection(
                                originalImage: viewModel.selectedImage,
                                selectedFilter: $selectedFilter,
                                filterIntensity: $filterIntensity,
                                onFilterSelected: { filter, intensity in
                                    applyQuickFilter(filter, intensity: intensity)
                                }
                            )
                        }
                        
                        // Form Fields
                        VStack(spacing: MinimalDesign.Spacing.md) {
                            MinimalCaptionField(caption: $viewModel.caption)
                            MinimalLocationField(locationName: $locationName)
                        }
                        .padding(.horizontal, MinimalDesign.Spacing.md)
                        
                        // Upload Progress
                        if viewModel.isLoading {
                            MinimalProgressView(progress: viewModel.uploadProgress)
                        }
                    }
                    .padding(.vertical, MinimalDesign.Spacing.md)
                }
            }
            .background(MinimalDesign.Colors.background)
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Failed to create post")
        }
        .onChange(of: locationName) { _, newLocation in
            viewModel.locationName = newLocation
        }
        .sheet(isPresented: $showingPhotoEditor) {
            if let imageToEdit = imageToEdit {
                ModernPhotoEditorView(
                    image: imageToEdit,
                    onComplete: { editedImage in
                        viewModel.selectedImage = editedImage
                        showingPhotoEditor = false
                    },
                    onCancel: {
                        showingPhotoEditor = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showingCustomCamera) {
            CustomCameraView { capturedImage in
                viewModel.selectedImage = capturedImage
                viewModel.mediaType = .photo
                viewModel.selectedVideoURL = nil
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
                        // 画像の処理 - 直接編集画面へ
                        viewModel.mediaType = .photo
                        imageToEdit = image
                        showingPhotoEditor = true
                    } else {
                        // 動画として処理を試みる
                        viewModel.mediaType = .video
                        // TODO: 動画の処理
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func applyQuickFilter(_ filterType: FilterType, intensity: Float) {
        guard let originalImage = viewModel.selectedImage else { return }
        
        selectedFilter = filterType
        filterIntensity = intensity
        
        if filterType == .none {
            // オリジナルに戻す
            return
        }
        
        // フィルター適用
        CoreImageManager.shared.applyFilter(
            filterType,
            to: CoreImageManager.shared.createCIImage(from: originalImage) ?? CIImage(),
            intensity: intensity
        ) { result in
            switch result {
            case .success(let filteredImage):
                DispatchQueue.main.async {
                    self.viewModel.selectedImage = filteredImage
                }
            case .failure(let error):
                print("Filter application failed: \(error)")
            }
        }
    }
    
    // MARK: - Minimal Components
    
    // Header Component
    struct MinimalHeader: View {
        let onCancel: () -> Void
        let onPost: () -> Void
        let canPost: Bool
        let isLoading: Bool
        
        var body: some View {
            HStack {
                Button("Cancel", action: onCancel)
                    .font(MinimalDesign.Typography.body)
                    .foregroundColor(MinimalDesign.Colors.secondary)
                
                Spacer()
                
                Text("New Post")
                    .font(MinimalDesign.Typography.headline)
                    .foregroundColor(MinimalDesign.Colors.primary)
                
                Spacer()
                
                Button(action: onPost) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Post")
                            .font(MinimalDesign.Typography.body)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(canPost ? MinimalDesign.Colors.accent : MinimalDesign.Colors.tertiary)
                .disabled(!canPost || isLoading)
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
            .padding(.vertical, MinimalDesign.Spacing.sm)
        }
    }
    
    // Media Picker Component
    struct MinimalMediaPickerSection: View {
        @Binding var selectedImage: UIImage?
        @Binding var selectedVideoURL: URL?
        @Binding var mediaType: Post.MediaType
        @Binding var showingMediaPicker: Bool
        @Binding var selectedItem: PhotosPickerItem?
        @Binding var showingPhotoEditor: Bool
        @Binding var imageToEdit: UIImage?
        @Binding var showingCustomCamera: Bool
        @Binding var selectedFilter: FilterType
        @Binding var showingFilterPreview: Bool
        @Binding var filterIntensity: Float
        
        var body: some View {
            PhotosPicker(
                selection: $selectedItem,
                matching: .any(of: [.images, .videos])
            ) {
                if let image = selectedImage {
                    ZStack {
                        // Image Display
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 280)
                            .clipped()
                        
                        // Overlay Controls
                        VStack {
                            HStack {
                                Spacer()
                                
                                VStack(spacing: MinimalDesign.Spacing.xs) {
                                    // Media Type Badge
                                    Text(mediaType == .video ? "Video" : "Photo")
                                        .font(MinimalDesign.Typography.small)
                                        .padding(.horizontal, MinimalDesign.Spacing.xs)
                                        .padding(.vertical, 2)
                                        .background(.black.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(MinimalDesign.Radius.sm)
                                    
                                    // Edit Button
                                    if mediaType == .photo {
                                        VStack(spacing: 4) {
                                            Button(action: {
                                                imageToEdit = image
                                                showingPhotoEditor = true
                                            }) {
                                                Image(systemName: "wand.and.stars")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .padding(MinimalDesign.Spacing.xs)
                                                    .background(.black.opacity(0.7))
                                                    .cornerRadius(MinimalDesign.Radius.sm)
                                            }
                                            
                                            // Quick Filter Button
                                            Button(action: {
                                                showingFilterPreview.toggle()
                                            }) {
                                                Image(systemName: "camera.filters")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .padding(MinimalDesign.Spacing.xs)
                                                    .background(selectedFilter != .none ? Color.red.opacity(0.8) : .black.opacity(0.7))
                                                    .cornerRadius(MinimalDesign.Radius.sm)
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(MinimalDesign.Spacing.sm)
                    }
                } else {
                    // Empty State
                    VStack(spacing: MinimalDesign.Spacing.lg) {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                        
                        VStack(spacing: MinimalDesign.Spacing.xs) {
                            Text("Add Photo or Video")
                                .font(MinimalDesign.Typography.body)
                                .foregroundColor(MinimalDesign.Colors.primary)
                            
                            Text("Tap to select from library")
                                .font(MinimalDesign.Typography.caption)
                                .foregroundColor(MinimalDesign.Colors.secondary)
                        }
                        
                        // Camera Button
                        Button(action: { showingCustomCamera = true }) {
                            HStack(spacing: MinimalDesign.Spacing.xs) {
                                Image(systemName: "camera")
                                    .font(.caption)
                                Text("Camera")
                                    .font(MinimalDesign.Typography.caption)
                            }
                            .minimalButton(style: .secondary)
                        }
                    }
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                    .background(MinimalDesign.Colors.tertiaryBackground)
                    .minimalCardBorder()
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
        }
    }
    
    // Quick Filter Section Component  
    struct QuickFilterSection: View {
        let originalImage: UIImage?
        @Binding var selectedFilter: FilterType
        @Binding var filterIntensity: Float
        let onFilterSelected: (FilterType, Float) -> Void
        
        // レトロ特化フィルターの選択肢
        private let retroFilters: [FilterType] = [
            .none, .vintage, .sepia, .kodakPortra, .fujiPro, 
            .cinestill, .polaroid, .ilfordHP5, .retro
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: MinimalDesign.Spacing.sm) {
                HStack {
                    Text("Retro Filters")
                        .font(MinimalDesign.Typography.headline)
                        .foregroundColor(MinimalDesign.Colors.primary)
                    
                    Spacer()
                    
                    if selectedFilter != .none {
                        Button("Reset") {
                            selectedFilter = .none
                            onFilterSelected(.none, 0)
                        }
                        .font(MinimalDesign.Typography.caption)
                        .foregroundColor(MinimalDesign.Colors.accent)
                    }
                }
                .padding(.horizontal, MinimalDesign.Spacing.md)
                
                // フィルター選択
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MinimalDesign.Spacing.sm) {
                        ForEach(retroFilters, id: \.self) { filter in
                            FilterQuickPreview(
                                filter: filter,
                                originalImage: originalImage,
                                isSelected: selectedFilter == filter,
                                onTap: {
                                    let intensity = filter.defaultIntensity
                                    selectedFilter = filter
                                    filterIntensity = intensity
                                    onFilterSelected(filter, intensity)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, MinimalDesign.Spacing.md)
                }
                
                // 強度調整スライダー
                if selectedFilter != .none && selectedFilter.isAdjustable {
                    VStack(spacing: MinimalDesign.Spacing.xs) {
                        HStack {
                            Text("Intensity")
                                .font(MinimalDesign.Typography.caption)
                                .foregroundColor(MinimalDesign.Colors.secondary)
                            
                            Spacer()
                            
                            Text("\\(Int(filterIntensity * 100))%")
                                .font(MinimalDesign.Typography.caption)
                                .foregroundColor(MinimalDesign.Colors.secondary)
                        }
                        
                        Slider(value: $filterIntensity, in: 0...1) { _ in
                            onFilterSelected(selectedFilter, filterIntensity)
                        }
                        .accentColor(MinimalDesign.Colors.accent)
                    }
                    .padding(.horizontal, MinimalDesign.Spacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.vertical, MinimalDesign.Spacing.sm)
            .background(MinimalDesign.Colors.secondaryBackground)
            .cornerRadius(MinimalDesign.Radius.lg)
            .padding(.horizontal, MinimalDesign.Spacing.md)
        }
    }
    
    // Filter Quick Preview Component
    struct FilterQuickPreview: View {
        let filter: FilterType
        let originalImage: UIImage?
        let isSelected: Bool
        let onTap: () -> Void
        
        @State private var previewImage: UIImage?
        
        var body: some View {
            VStack(spacing: MinimalDesign.Spacing.xs) {
                Button(action: onTap) {
                    ZStack {
                        // プレビュー画像
                        if let previewImage = previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm))
                        } else if let originalImage = originalImage {
                            Image(uiImage: originalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm)
                                        .fill(Color.black.opacity(0.3))
                                )
                        } else {
                            RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm)
                                .fill(MinimalDesign.Colors.tertiaryBackground)
                                .frame(width: 60, height: 60)
                        }
                        
                        // 選択インジケーター
                        if isSelected {
                            RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm)
                                .stroke(MinimalDesign.Colors.accent, lineWidth: 2)
                                .frame(width: 60, height: 60)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // フィルター名
                Text(filter.rawValue)
                    .font(MinimalDesign.Typography.caption)
                    .foregroundColor(isSelected ? MinimalDesign.Colors.accent : MinimalDesign.Colors.secondary)
                    .lineLimit(1)
                    .frame(width: 60)
            }
            .onAppear {
                generatePreview()
            }
        }
        
        private func generatePreview() {
            guard let originalImage = originalImage,
                  filter != .none else {
                previewImage = originalImage
                return
            }
            
            // サムネイル生成
            let thumbnailSize = CGSize(width: 120, height: 120)
            let thumbnail = originalImage.resized(to: thumbnailSize)
            
            guard let ciImage = CoreImageManager.shared.createCIImage(from: thumbnail) else {
                previewImage = thumbnail
                return
            }
            
            // フィルター適用
            if let filtered = CoreImageManager.shared.applyFilterSync(
                filter,
                to: ciImage,
                intensity: filter.previewIntensity
            ) {
                let context = CIContext()
                if let cgImage = context.createCGImage(filtered, from: filtered.extent) {
                    previewImage = UIImage(cgImage: cgImage)
                }
            }
        }
    }
    
    // Caption Field Component
    struct MinimalCaptionField: View {
        @Binding var caption: String
        @FocusState private var isFocused: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: MinimalDesign.Spacing.xs) {
                Text("Caption")
                    .font(MinimalDesign.Typography.caption)
                    .foregroundColor(MinimalDesign.Colors.secondary)
                
                TextEditor(text: $caption)
                    .font(MinimalDesign.Typography.body)
                    .focused($isFocused)
                    .frame(minHeight: 80)
                    .padding(MinimalDesign.Spacing.sm)
                    .background(MinimalDesign.Colors.tertiaryBackground)
                    .cornerRadius(MinimalDesign.Radius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: MinimalDesign.Radius.md)
                            .stroke(
                                isFocused ? MinimalDesign.Colors.accent : MinimalDesign.Colors.border,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
    }
    
    // Location Field Component
    struct MinimalLocationField: View {
        @Binding var locationName: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: MinimalDesign.Spacing.xs) {
                Text("Location (Optional)")
                    .font(MinimalDesign.Typography.caption)
                    .foregroundColor(MinimalDesign.Colors.secondary)
                
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(MinimalDesign.Colors.tertiary)
                    
                    TextField("Add location", text: $locationName)
                        .textFieldStyle(MinimalTextFieldStyle())
                }
            }
        }
    }
    
    // Progress View Component
    struct MinimalProgressView: View {
        let progress: Double
        
        var body: some View {
            VStack(spacing: MinimalDesign.Spacing.xs) {
                HStack {
                    Text("Uploading...")
                        .font(MinimalDesign.Typography.caption)
                        .foregroundColor(MinimalDesign.Colors.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(MinimalDesign.Typography.caption)
                        .foregroundColor(MinimalDesign.Colors.secondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: MinimalDesign.Colors.accent))
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
        }
    }
}

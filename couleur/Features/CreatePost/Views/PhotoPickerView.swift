//
//  PhotoPickerView.swift
//  couleur
//
//  写真選択画面
//

import SwiftUI
import PhotosUI
import Photos

extension Notification.Name {
    static let navigateToEditor = Notification.Name("navigateToEditor")
}

struct PhotoPickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedImage: UIImage?
    @State private var selectedImages: [UIImage] = []
    @State private var recentPhotos: [UIImage] = []
    @State private var isLoadingPhotos = true
    @State private var showingCamera = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // メインコンテンツ
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 選択中の写真
                        selectedPhotoView
                        
                        // サムネイルグリッド
                        thumbnailGridView
                    }
                }
            }
        }
        .onAppear {
            loadRecentPhotos()
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CustomCameraView { capturedImage in
                selectedImage = capturedImage
                selectedImages = [capturedImage]
                showingCamera = false
            }
        }
    }
    
    // MARK: - Views
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("新規投稿")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button("次へ") {
                if let image = selectedImage {
                    NotificationCenter.default.post(name: .navigateToEditor, object: image)
                }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(selectedImage != nil ? MinimalDesign.Colors.accentRed : .gray)
            .disabled(selectedImage == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color(white: 0.15))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var selectedPhotoView: some View {
        ZStack(alignment: .bottomLeading) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(white: 0.1))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("写真を選択")
                                .foregroundColor(.gray)
                        }
                    )
            }
            
        }
    }
    
    
    private var thumbnailGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 4), spacing: 1) {
            ForEach(0..<recentPhotos.count, id: \.self) { index in
                Button(action: {
                    selectedImage = recentPhotos[index]
                    selectedImages = [recentPhotos[index]]
                }) {
                    Image(uiImage: recentPhotos[index])
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                }
            }
            
            // プレースホルダー
            if isLoadingPhotos {
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(white: 0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .shimmer()
                }
            }
        }
    }
    
    
    // MARK: - Methods
    
    private func loadRecentPhotos() {
        Task {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 50
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var photos: [UIImage] = []
            
            let imageManager = PHImageManager.default()
            let targetSize = CGSize(width: 200, height: 200)
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            
            assets.enumerateObjects { asset, _, _ in
                imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    if let image = image {
                        photos.append(image)
                    }
                }
            }
            
            await MainActor.run {
                self.recentPhotos = photos
                self.isLoadingPhotos = false
                if !photos.isEmpty {
                    self.selectedImage = photos[0]
                    self.selectedImages = [photos[0]]
                }
            }
        }
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmer() -> some View {
        self
            .redacted(reason: .placeholder)
            .shimmering()
    }
}

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear { phase = 1 }
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(Shimmer())
    }
}

// MARK: - Preview
#if DEBUG
struct PhotoPickerView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPickerView()
    }
}
#endif
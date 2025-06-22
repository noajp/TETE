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
    let onImageSelected: ((PhotoEditorData) -> Void)?
    
    init(onImageSelected: ((PhotoEditorData) -> Void)? = nil) {
        self.onImageSelected = onImageSelected
    }
    @State private var selectedImage: UIImage?
    @State private var selectedImages: [UIImage] = []
    @State private var recentPhotos: [UIImage] = []
    @State private var recentAssets: [PHAsset] = []
    @State private var selectedIndex: Int? = nil
    @State private var selectedAsset: PHAsset? = nil
    @State private var isLoadingPhotos = true
    @State private var rawProcessor = RAWImageProcessor.shared
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
                        
                        // セパレーター
                        separatorView
                        
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
            
            Text("New Post")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button("次へ") {
                print("🔵 次へボタンが押されました")
                
                if let asset = selectedAsset {
                    print("🔵 Asset選択済み: \(asset)")
                    // RAW画像かどうかを判定してエディターに渡す
                    let rawInfo = rawProcessor.getRAWInfo(for: asset)
                    print("🔵 RAW情報: \(rawInfo)")
                    
                    // AssetとRAW情報をセットで渡す
                    let editorData = PhotoEditorData(asset: asset, rawInfo: rawInfo, previewImage: selectedImage)
                    print("🔵 Completion handler呼び出し")
                    print("🔵 onImageSelected is nil: \(onImageSelected == nil)")
                    
                    // completion handlerで直接渡す
                    if let handler = onImageSelected {
                        print("🔵 ハンドラー実行中...")
                        handler(editorData)
                        print("🔵 ハンドラー実行完了")
                    } else {
                        print("🔴 ハンドラーがnil!")
                    }
                } else if let image = selectedImage {
                    print("🔵 UIImage fallback")
                    // UIImageの場合、ダミーのassetでPhotoEditorDataを作成
                    if let asset = selectedAsset {
                        let rawInfo = RAWImageInfo(isRAW: false, format: nil, fileSize: 0, 
                                                 dimensions: image.size, asset: asset)
                        let editorData = PhotoEditorData(asset: asset, rawInfo: rawInfo, previewImage: image)
                        onImageSelected?(editorData)
                    }
                } else {
                    print("🔴 画像が選択されていません")
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
    
    private var separatorView: some View {
        VStack(spacing: 0) {
            // 上部のシャドウ
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 6)
            
            // メインセパレーター
            HStack {
                // カメラロールテキスト
                Text("Camera Roll")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(white: 0.05))
        }
    }
    
    private var selectedPhotoView: some View {
        ZStack(alignment: .topLeading) {
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
                    selectedIndex = index
                    selectedAsset = recentAssets[index]
                }) {
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: recentPhotos[index])
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                        
                        // RAWバッジ
                        if index < recentAssets.count {
                            let rawInfo = rawProcessor.getRAWInfo(for: recentAssets[index])
                            if rawInfo.isRAW {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Text(rawInfo.displayFormat)
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.9))
                                            .cornerRadius(4)
                                        Spacer()
                                    }
                                }
                                .padding(4)
                            }
                        }
                        
                        // 選択中の画像にチェックマーク表示
                        if selectedIndex == index {
                            VStack {
                                HStack {
                                    ZStack {
                                        Rectangle()
                                            .fill(MinimalDesign.Colors.accentRed)
                                            .frame(width: 14, height: 14)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(6)
                        }
                    }
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
            var assetArray: [PHAsset] = []
            
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
                        assetArray.append(asset)
                    }
                }
            }
            
            await MainActor.run {
                self.recentPhotos = photos
                self.recentAssets = assetArray
                self.isLoadingPhotos = false
                if !photos.isEmpty && !assetArray.isEmpty {
                    self.selectedImage = photos[0]
                    self.selectedImages = [photos[0]]
                    self.selectedAsset = assetArray[0]
                    self.selectedIndex = 0
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
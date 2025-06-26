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
    @State private var isSquareMode = true // デフォルトは正方形モード
    @State private var imageOffset: CGSize = .zero // 画像のドラッグオフセット
    @State private var currentImageOffset: CGSize = .zero // 現在の画像位置を保存

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // ヘッダー (固定高さ: 56pt)
                    headerView
                        .frame(height: 56)
                    
                    // 残りの領域をZStackで管理
                    ZStack(alignment: .bottom) {
                        // セクション1: 選択写真表示画面（上部に配置、可変高さ）
                        VStack {
                            selectedPhotoView
                                .frame(height: getPreviewHeight(geometry: geometry))
                            Spacer()
                        }
                        
                        // 下部固定領域（セクション2+3）
                        VStack(spacing: 0) {
                            // セクション2: 仕切り線（固定高さ: 70pt）
                            separatorView
                                .frame(height: 70)
                            
                            // セクション3: カメラロール（固定高さ）
                            ScrollView(showsIndicators: false) {
                                thumbnailGridView
                            }
                            .frame(height: getCameraRollHeight(geometry: geometry))
                        }
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
    
    // MARK: - Helper Methods
    
    private func getPreviewHeight(geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        
        if isSquareMode {
            return screenWidth // 正方形
        } else if let image = selectedImage {
            // 元画像のアスペクト比で高さを計算
            let imageAspectRatio = image.size.width / image.size.height
            return screenWidth / imageAspectRatio
        } else {
            return screenWidth // デフォルトは正方形
        }
    }
    
    private func calculateImageSize(image: UIImage, in geometry: GeometryProxy) -> CGSize {
        let imageAspectRatio = image.size.width / image.size.height
        let viewWidth = geometry.size.width
        let viewHeight = geometry.size.height
        let viewAspectRatio = viewWidth / viewHeight
        
        if imageAspectRatio > viewAspectRatio {
            // 画像の方が横長 - 高さに合わせる
            let height = viewHeight
            let width = height * imageAspectRatio
            return CGSize(width: width, height: height)
        } else {
            // 画像の方が縦長 - 幅に合わせる
            let width = viewWidth
            let height = width / imageAspectRatio
            return CGSize(width: width, height: height)
        }
    }
    
    private func getCameraRollHeight(geometry: GeometryProxy) -> CGFloat {
        // 画面全体の高さから固定要素を引いた残り
        let totalHeight = geometry.size.height
        let headerHeight: CGFloat = 56
        let separatorHeight: CGFloat = 70
        let bottomSafeArea = geometry.safeAreaInsets.bottom
        
        // カメラロールに割り当てる固定の高さ（例：画面の40%）
        return totalHeight * 0.4
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
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: calculateImageSize(image: image, in: geometry).width,
                               height: calculateImageSize(image: image, in: geometry).height)
                        .offset(x: imageOffset.width + currentImageOffset.width,
                               y: imageOffset.height + currentImageOffset.height)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    imageOffset = value.translation
                                }
                                .onEnded { value in
                                    currentImageOffset.width += value.translation.width
                                    currentImageOffset.height += value.translation.height
                                    imageOffset = .zero
                                }
                        )
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(white: 0.1))
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
                
                // アスペクト比切り替えボタン
                if selectedImage != nil {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSquareMode.toggle()
                            // モード切り替え時にオフセットをリセット
                            imageOffset = .zero
                            currentImageOffset = .zero
                        }
                    }) {
                        Image(systemName: isSquareMode ? "arrow.up.left.and.arrow.down.right" : "square")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(16)
                }
            }
        }
    }
    
    
    
    private var thumbnailGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 4), spacing: 1) {
            ForEach(0..<recentPhotos.count, id: \.self) { index in
                Button(action: {
                    selectedIndex = index
                    selectedAsset = recentAssets[index]
                    // 高品質な画像を選択時に取得
                    loadHighQualityImage(for: recentAssets[index])
                    // オフセットをリセット
                    imageOffset = .zero
                    currentImageOffset = .zero
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
            let targetSize = CGSize(width: 800, height: 800) // 画質向上のためサイズ増加
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            
            assets.enumerateObjects { asset, _, _ in
                imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFit,
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
                    self.selectedAsset = assetArray[0]
                    self.selectedIndex = 0
                    // 最初の画像を高品質で取得
                    self.loadHighQualityImage(for: assetArray[0])
                }
            }
        }
    }
    
    private func loadHighQualityImage(for asset: PHAsset) {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .none // オリジナルサイズで取得
        
        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize, // 最大サイズで取得
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    self.selectedImage = image
                    self.selectedImages = [image]
                    
                    // 画像のアスペクト比に基づいてモードを自動設定
                    let aspectRatio = image.size.width / image.size.height
                    // 横長の写真（16:9より横長）の場合は元画像モードに
                    if aspectRatio > 1.7 {
                        self.isSquareMode = false
                    } else {
                        // それ以外は正方形モード
                        self.isSquareMode = true
                    }
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
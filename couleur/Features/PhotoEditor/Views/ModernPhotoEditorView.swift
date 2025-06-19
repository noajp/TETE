//
//  ModernPhotoEditorView.swift
//  couleur
//
//  モダンな写真編集画面（HTML参照）
//

import SwiftUI
import CoreImage

struct ModernPhotoEditorView: View {
    // MARK: - Properties
    let originalImage: UIImage
    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void
    
    @StateObject private var viewModel: PhotoEditorViewModel
    @State private var selectedPreset: PresetType = .none
    @State private var selectedCategory: PresetCategory = .allPresets
    @State private var selectedTab: EditorTab = .presets
    @State private var filterIntensity: Float = 1.0
    
    // MARK: - Initialization
    init(image: UIImage,
         onComplete: @escaping (UIImage) -> Void,
         onCancel: @escaping () -> Void) {
        self.originalImage = image
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._viewModel = StateObject(wrappedValue: PhotoEditorViewModel(image: image))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // メイン画像（全画面表示）
                mainImageView
                
                // 編集メニュー
                editMenuView
            }
            
            // カスタム戻るボタン
            Button(action: onCancel) {
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
            }
            .padding(.top, 50) // Safe Area対応
            .padding(.leading, 16)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // 右方向にスワイプで戻る
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        onCancel()
                    }
                }
        )
    }
    
    // MARK: - Views
    
    
    private var mainImageView: some View {
        GeometryReader { geometry in
            if viewModel.ciImage != nil {
                MetalPreviewView(
                    currentImage: $viewModel.ciImage,
                    filterType: .constant(.none),
                    filterIntensity: $filterIntensity
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black)
            } else if let image = viewModel.currentImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
    
    private var editMenuView: some View {
        VStack(spacing: 0) {
            // タブごとのコンテンツ
            switch selectedTab {
            case .presets:
                PresetSelectionView(
                    selectedPreset: $selectedPreset,
                    selectedCategory: $selectedCategory,
                    originalImage: originalImage,
                    onPresetSelected: applyPreset
                )
                .frame(height: 180)
                
            case .effects:
                // エフェクト選択ビュー（後で実装）
                effectsPlaceholderView
                
            case .adjust:
                // 調整スライダービュー（後で実装）
                adjustmentPlaceholderView
                
            case .tools:
                // ツールビュー（後で実装）
                toolsPlaceholderView
                
            case .export:
                // エクスポート設定ビュー（後で実装）
                exportPlaceholderView
            }
            
            // フッターボタン
            EditorFooterView(
                selectedTab: $selectedTab,
                onTabSelected: { tab in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            )
        }
        .background(Color(red: 28/255, green: 28/255, blue: 30/255))
    }
    
    // MARK: - Placeholder Views
    
    private var effectsPlaceholderView: some View {
        VStack {
            Text("エフェクト")
                .foregroundColor(.white)
                .padding()
            Spacer()
        }
        .frame(height: 180)
    }
    
    private var adjustmentPlaceholderView: some View {
        VStack {
            Text("調整")
                .foregroundColor(.white)
                .padding()
            Spacer()
        }
        .frame(height: 180)
    }
    
    private var toolsPlaceholderView: some View {
        VStack {
            Text("ツール")
                .foregroundColor(.white)
                .padding()
            Spacer()
        }
        .frame(height: 180)
    }
    
    private var exportPlaceholderView: some View {
        VStack(spacing: 20) {
            Text("書き出し設定")
                .foregroundColor(.white)
                .font(.headline)
            
            Button(action: {
                if let editedImage = viewModel.currentImage {
                    onComplete(editedImage)
                }
            }) {
                Text("完了")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MinimalDesign.Colors.accentRed)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
        .frame(height: 180)
    }
    
    // MARK: - Methods
    
    private func applyPreset(_ preset: PresetType) {
        let settings = preset.filterSettings
        viewModel.applyFilterSettings(settings)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#if DEBUG
struct ModernPhotoEditorView_Previews: PreviewProvider {
    static var previews: some View {
        ModernPhotoEditorView(
            image: UIImage(systemName: "photo")!,
            onComplete: { _ in },
            onCancel: { }
        )
    }
}
#endif
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
    @State private var selectedCategory: PresetCategory = .basePresets
    @State private var selectedTab: EditorTab = .presets
    @State private var filterIntensity: Float = 1.0
    @State private var currentFilterSettings = FilterSettings()
    @State private var currentToneCurve = ToneCurve()
    
    // MARK: - Initialization
    init(image: UIImage,
         onComplete: @escaping (UIImage) -> Void,
         onCancel: @escaping () -> Void) {
        self.originalImage = image
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._viewModel = StateObject(wrappedValue: PhotoEditorViewModel(image: image))
    }
    
    // RAW画像対応のイニシャライザ
    init(editorData: PhotoEditorData,
         onComplete: @escaping (UIImage) -> Void,
         onCancel: @escaping () -> Void) {
        self.originalImage = editorData.previewImage ?? UIImage()
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._viewModel = StateObject(wrappedValue: PhotoEditorViewModel(
            asset: editorData.asset,
            rawInfo: editorData.rawInfo,
            previewImage: editorData.previewImage
        ))
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
            
            // ヘッダーボタン
            HStack {
                // 戻るボタン
                Button(action: onCancel) {
                    Text("Back")
                        .actionTextButtonStyle()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                }
                
                Spacer()
                
                // 完了ボタン
                Button(action: {
                    if let editedImage = viewModel.currentImage {
                        onComplete(editedImage)
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(MinimalDesign.Colors.accentRed)
                        .cornerRadius(20)
                }
            }
            .padding(.top, 60) // Safe Area対応
            .padding(.horizontal, 16)
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
                
            case .adjust:
                // 詳細調整ビュー
                AdjustmentView(
                    filterSettings: $currentFilterSettings,
                    toneCurve: $currentToneCurve,
                    onSettingsChanged: applyFilterSettings,
                    onToneCurveChanged: applyToneCurve
                )
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
    
    // MARK: - Methods
    
    private func applyPreset(_ preset: PresetType) {
        let settings = preset.filterSettings
        currentFilterSettings = settings
        viewModel.applyFilterSettings(settings, toneCurve: currentToneCurve)
    }
    
    private func applyFilterSettings(_ settings: FilterSettings) {
        currentFilterSettings = settings
        viewModel.applyFilterSettings(settings, toneCurve: currentToneCurve)
    }
    
    private func applyToneCurve(_ curve: ToneCurve) {
        currentToneCurve = curve
        viewModel.applyFilterSettings(currentFilterSettings, toneCurve: curve)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    typealias UIViewControllerType = UIActivityViewController
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {}
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
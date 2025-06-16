//
//  PhotoEditorView.swift
//  couleur
//
//  写真編集画面
//

import SwiftUI

struct PhotoEditorView: View {
    // MARK: - Properties
    let originalImage: UIImage
    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void
    
    @StateObject private var viewModel: PhotoEditorViewModel
    @State private var selectedFilter: FilterType = .none
    @State private var filterIntensity: Float = 1.0
    @State private var showingIntensitySlider = false
    
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
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 編集中の画像表示
                    editingImageView
                    
                    // フィルター強度スライダー
                    if showingIntensitySlider && selectedFilter.isAdjustable {
                        intensitySliderView
                            .transition(.move(edge: .bottom))
                    }
                    
                    // フィルター選択
                    filterSelectionView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        if let editedImage = viewModel.currentImage {
                            onComplete(editedImage)
                        }
                    }
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Views
    
    private var editingImageView: some View {
        GeometryReader { geometry in
            if viewModel.ciImage != nil {
                // Metalを使用したリアルタイムプレビュー
                MetalPreviewView(
                    currentImage: $viewModel.ciImage,
                    filterType: $selectedFilter,
                    filterIntensity: $filterIntensity
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
    
    private var intensitySliderView: some View {
        VStack(spacing: 16) {
            Text("強度: \(Int(filterIntensity * 100))%")
                .foregroundColor(.white)
                .font(.caption)
            
            Slider(value: $filterIntensity, in: 0...1) { _ in
                // スライダー操作終了時にフィルター適用
                viewModel.applyFilter(selectedFilter, intensity: filterIntensity)
            }
            .accentColor(.white)
            .padding(.horizontal)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    private var filterSelectionView: some View {
        VStack(spacing: 12) {
            // フィルタータイプ選択
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterType.allCases) { filterType in
                        FilterThumbnailView(
                            filterType: filterType,
                            thumbnail: viewModel.filterThumbnails[filterType],
                            isSelected: selectedFilter == filterType,
                            onTap: {
                                selectFilter(filterType)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 100)
        }
        .padding(.vertical)
        .background(Color.black.opacity(0.9))
    }
    
    // MARK: - Methods
    
    private func selectFilter(_ filterType: FilterType) {
        selectedFilter = filterType
        filterIntensity = filterType.defaultIntensity
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showingIntensitySlider = filterType.isAdjustable
        }
        
        viewModel.applyFilter(filterType, intensity: filterIntensity)
    }
}

// MARK: - Filter Thumbnail View
struct FilterThumbnailView: View {
    let filterType: FilterType
    let thumbnail: UIImage?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: onTap) {
                ZStack {
                    // サムネイル画像
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // ローディング中
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5)
                            )
                    }
                    
                    // 選択インジケーター
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 70, height: 70)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // フィルター名
            Text(filterType.rawValue)
                .font(.caption2)
                .foregroundColor(isSelected ? .white : .gray)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct PhotoEditorView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoEditorView(
            image: UIImage(systemName: "photo")!,
            onComplete: { _ in },
            onCancel: { }
        )
    }
}
#endif
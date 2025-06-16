//
//  PhotoEditorViewModel.swift
//  foodai
//
//  写真編集ViewのViewModel
//

import SwiftUI
import Combine
import CoreImage

@MainActor
class PhotoEditorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentImage: UIImage?
    @Published var ciImage: CIImage?
    @Published var filterThumbnails: [FilterType: UIImage] = [:]
    @Published var isProcessing = false
    @Published var currentFilter = FilterState()
    
    // MARK: - Private Properties
    private let originalImage: UIImage
    private let originalCIImage: CIImage
    private let imageProcessor = ImageProcessor()
    private let coreImageManager = CoreImageManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(image: UIImage) {
        // 画像を最適化
        self.originalImage = imageProcessor.resizeImageIfNeeded(image)
        
        // CIImage作成
        if let ciImage = coreImageManager.createCIImage(from: self.originalImage) {
            self.originalCIImage = ciImage
        } else {
            self.originalCIImage = CIImage()
            print("❌ Failed to create CIImage")
        }
        
        // 初期画像設定
        self.currentImage = self.originalImage
        self.ciImage = self.originalCIImage
        
        // サムネイル生成
        Task {
            await generateFilterThumbnails()
        }
    }
    
    // MARK: - Public Methods
    
    /// フィルター適用（リアルタイムプレビューは自動更新される）
    func applyFilter(_ filterType: FilterType, intensity: Float) {
        // 現在のフィルター状態を更新
        currentFilter = FilterState(filterType: filterType, intensity: intensity)
        
        // 最終的な出力画像を非同期で生成（エクスポート用）
        Task {
            coreImageManager.applyFilter(
                filterType,
                to: originalCIImage,
                intensity: intensity
            ) { [weak self] result in
                switch result {
                case .success(let filteredImage):
                    self?.currentImage = filteredImage
                    
                case .failure(let error):
                    print("❌ Filter application failed: \(error)")
                    self?.currentImage = self?.originalImage
                }
            }
        }
    }
    
    /// オリジナルに戻す
    func resetToOriginal() {
        currentImage = originalImage
        ciImage = originalCIImage
        currentFilter = FilterState()
    }
    
    /// 編集済み画像を保存用に準備
    func prepareForExport(quality: ExportQuality = .high) -> Data? {
        guard let image = currentImage else { return nil }
        return imageProcessor.exportImage(image, quality: quality)
    }
    
    // MARK: - Private Methods
    
    /// フィルターサムネイル生成
    private func generateFilterThumbnails() async {
        // サムネイル用の小さい画像を作成
        guard let thumbnailImage = imageProcessor.createThumbnail(from: originalImage),
              let thumbnailCIImage = coreImageManager.createCIImage(from: thumbnailImage) else {
            return
        }
        
        // 各フィルターのサムネイルを非同期で生成
        await withTaskGroup(of: (FilterType, UIImage?).self) { group in
            for filterType in FilterType.allCases {
                group.addTask { [weak self] in
                    guard let self = self else { return (filterType, nil) }
                    
                    if filterType == .none {
                        return (filterType, thumbnailImage)
                    }
                    
                    // フィルター適用
                    let filtered = self.coreImageManager.applyFilterSync(
                        filterType,
                        to: thumbnailCIImage,
                        intensity: filterType.previewIntensity
                    )
                    
                    // UIImageに変換
                    if let filtered = filtered,
                       let cgImage = CIContext().createCGImage(filtered, from: filtered.extent) {
                        return (filterType, UIImage(cgImage: cgImage))
                    }
                    
                    return (filterType, nil)
                }
            }
            
            // 結果を収集
            for await (filterType, thumbnail) in group {
                await MainActor.run {
                    self.filterThumbnails[filterType] = thumbnail
                }
            }
        }
    }
    
    // MARK: - Memory Management
    
    /// メモリ使用量の推定
    var estimatedMemoryUsage: String {
        let bytes = imageProcessor.estimateMemoryUsage(for: originalImage)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
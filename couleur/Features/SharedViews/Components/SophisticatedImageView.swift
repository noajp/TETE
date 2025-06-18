//======================================================================
// MARK: - SophisticatedImageView.swift (Optimized)
// Path: foodai/Features/SharedViews/Components/SophisticatedImageView.swift
// Features: メモリ効率化、キャッシュ活用、パフォーマンス最適化
//======================================================================
import SwiftUI

struct SophisticatedImageView: View {
    let imageUrl: String
    let height: CGFloat
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadingTask: Task<Void, Never>?
    
    init(imageUrl: String, height: CGFloat = 400) {
        self.imageUrl = imageUrl
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = image {
                    // Optimized image display
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: height)
                        .clipped()
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                } else if isLoading {
                    // Loading placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: height)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.2)
                        )
                } else {
                    // Error placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: height)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                        )
                }
            }
        }
        .frame(height: height)
        .onAppear {
            loadImageOptimized()
        }
        .onDisappear {
            cancelImageLoading()
        }
    }
    
    // MARK: - Optimized Image Loading
    private func loadImageOptimized() {
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        loadingTask = Task {
            do {
                // Use ImageCacheManager for optimized loading
                let loadedImage = await ImageCacheManager.shared.loadImage(from: imageUrl)
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                // Update UI on main thread
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.image = loadedImage
                        self.isLoading = false
                    }
                }
            } catch {
                // Handle error
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func cancelImageLoading() {
        loadingTask?.cancel()
        loadingTask = nil
    }
}

// MARK: - UIImage version for CreatePost preview
struct SophisticatedUIImageView: View {
    let image: UIImage
    let height: CGFloat
    
    init(image: UIImage, height: CGFloat = 300) {
        self.image = image
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Main image - properly scaled
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width, height: height)
                .clipped()
        }
        .frame(height: height)
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        SophisticatedImageView(imageUrl: "https://picsum.photos/800/400")
            .padding()
        
        SophisticatedImageView(imageUrl: "https://picsum.photos/400/800")
            .padding()
    }
}
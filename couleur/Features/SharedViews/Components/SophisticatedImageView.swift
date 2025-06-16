//======================================================================
// MARK: - SophisticatedImageView.swift
// Path: foodai/Features/SharedViews/Components/SophisticatedImageView.swift
//======================================================================
import SwiftUI

struct SophisticatedImageView: View {
    let imageUrl: String
    let height: CGFloat
    
    init(imageUrl: String, height: CGFloat = 400) {
        self.imageUrl = imageUrl
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: imageUrl)) { image in
                // Main image - properly scaled
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: height)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: height)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                    )
            }
        }
        .frame(height: height)
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
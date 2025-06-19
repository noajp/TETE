//
//  CreatePostNavigationView.swift
//  couleur
//
//  投稿作成のナビゲーション管理
//

import SwiftUI

struct CreatePostNavigationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var navigationPath = NavigationPath()
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            PhotoPickerView()
                .navigationDestination(for: UIImage.self) { image in
                    ModernPhotoEditorView(
                        image: image,
                        onComplete: { editedImage in
                            // 編集完了後の処理
                            dismiss()
                        },
                        onCancel: {
                            navigationPath.removeLast()
                        }
                    )
                    .navigationBarHidden(true)
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToEditor)) { notification in
            if let image = notification.object as? UIImage {
                navigationPath.append(image)
            }
        }
    }
}
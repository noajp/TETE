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
    @State private var selectedEditorData: PhotoEditorData?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            PhotoPickerView { editorData in
                print("🟢 CreatePostNavigationViewで画像受信")
                selectedEditorData = editorData
                navigationPath.append(editorData)
            }
            .navigationDestination(for: PhotoEditorData.self) { editorData in
                ModernPhotoEditorView(
                    editorData: editorData,
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
    }
}
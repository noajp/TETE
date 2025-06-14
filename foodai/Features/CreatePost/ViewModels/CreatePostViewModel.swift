//======================================================================
// MARK: - CreatePostViewModel（画像・動画対応版）
// Path: foodai/Features/CreatePost/ViewModels/CreatePostViewModel.swift
//======================================================================
import SwiftUI
import PhotosUI
import AVKit
import Supabase

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedVideoURL: URL?
    @Published var mediaType: Post.MediaType = .photo
    @Published var caption = ""
    @Published var locationName = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isPostCreated = false
    @Published var uploadProgress: Double = 0
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var isPublic = true
    
    private let postService = PostService()
    private let supabase = SupabaseManager.shared.client
    
    var canPost: Bool {
        selectedImage != nil || selectedVideoURL != nil
    }
    
    func createPost() async {
        guard canPost else { return }
        guard let userId = AuthManager.shared.currentUser?.id else {
            errorMessage = "ログインが必要です"
            showError = true
            return
        }
        
        isLoading = true
        uploadProgress = 0
        
        do {
            // 1. メディアをアップロード
            uploadProgress = 0.3
            let mediaUrl: String
            if let image = selectedImage {
                mediaUrl = try await uploadImage(image)
            } else if let videoURL = selectedVideoURL {
                mediaUrl = try await uploadVideo(videoURL)
            } else {
                throw PostError.noMediaSelected
            }
            
            // 2. 投稿を作成
            uploadProgress = 0.8
            try await createPostRecord(
                userId: userId,
                mediaUrl: mediaUrl
            )
            
            uploadProgress = 1.0
            isPostCreated = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ 投稿エラー: \(error)")
        }
        
        isLoading = false
    }
    
    private func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PostError.imageProcessingFailed
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = "posts/\(fileName)"
        
        print("🔵 画像アップロード開始: \(filePath)")
        
        // Supabase Storageにアップロード
        _ = try await supabase.storage
            .from("user-uploads")
            .upload(
                filePath,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )
        
        // 公開URLを構築
        let projectUrl = Config.supabaseURL
        let publicUrl = "\(projectUrl)/storage/v1/object/public/user-uploads/\(filePath)"
        
        print("✅ 画像アップロード完了: \(publicUrl)")
        return publicUrl
    }
    
    private func uploadVideo(_ videoURL: URL) async throws -> String {
        // 動画データを読み込む
        let videoData = try Data(contentsOf: videoURL)
        
        let fileName = "\(UUID().uuidString).mp4"
        let filePath = "posts/\(fileName)"
        
        print("🔵 動画アップロード開始: \(filePath)")
        
        // Supabase Storageにアップロード
        _ = try await supabase.storage
            .from("user-uploads")
            .upload(
                filePath,
                data: videoData,
                options: FileOptions(contentType: "video/mp4")
            )
        
        // 公開URLを構築
        let projectUrl = Config.supabaseURL
        let publicUrl = "\(projectUrl)/storage/v1/object/public/user-uploads/\(filePath)"
        
        print("✅ 動画アップロード完了: \(publicUrl)")
        return publicUrl
    }
    
    private func createPostRecord(userId: String, mediaUrl: String) async throws {
        struct NewPost: Encodable {
            let user_id: String
            let media_url: String
            let media_type: String
            let caption: String?
            let location_name: String?
            let latitude: Double?
            let longitude: Double?
            let is_public: Bool
        }
        
        let newPost = NewPost(
            user_id: userId,
            media_url: mediaUrl,
            media_type: mediaType.rawValue,
            caption: caption.isEmpty ? nil : caption,
            location_name: locationName.isEmpty ? nil : locationName,
            latitude: latitude,
            longitude: longitude,
            is_public: isPublic
        )
        
        try await supabase
            .from("posts")
            .insert(newPost)
            .execute()
    }
    
    // 動画のサムネイル生成
    // generateThumbnail関数を更新（iOS 18対応）
    func generateThumbnail(from videoURL: URL) -> UIImage? {
        let asset = AVURLAsset(url: videoURL) // 修正: AVAsset → AVURLAsset
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 1)
        
        // iOS 18対応の非同期メソッドを使用
        var thumbnail: UIImage?
        let semaphore = DispatchSemaphore(value: 0)
        
        imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
            if let cgImage = cgImage {
                thumbnail = UIImage(cgImage: cgImage)
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return thumbnail
    }
}

enum PostError: LocalizedError {
    case imageProcessingFailed
    case uploadFailed
    case noMediaSelected
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "画像の処理に失敗しました"
        case .uploadFailed:
            return "アップロードに失敗しました"
        case .noMediaSelected:
            return "画像または動画を選択してください"
        }
    }
}


//
//  CustomCameraViewModel.swift
//  foodai
//
//  カスタムカメラのViewModel
//

import SwiftUI
import AVFoundation
import CoreImage
import Photos

@MainActor
class CustomCameraViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isCapturing = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var focusPoint: CGPoint?
    @Published var currentFilter: FilterType = .none
    
    // MARK: - Camera Properties
    let session = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private var photoOutput = AVCapturePhotoOutput()
    private var currentCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    
    // MARK: - Image Processing
    private let imageProcessor = ImageProcessor()
    private let filterManager = AdvancedFilterManager()
    private var photoCompletionHandler: ((UIImage) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupCamera()
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        Task {
            await requestCameraPermission()
        }
    }
    
    private func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            configureSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                configureSession()
            } else {
                showCameraError("カメラへのアクセスが拒否されました")
            }
        case .denied, .restricted:
            showCameraError("カメラへのアクセスが拒否されています。設定で許可してください。")
        @unknown default:
            showCameraError("カメラの状態を確認できません")
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // カメラデバイスの設定
        setupCameraDevices()
        
        // バックカメラを初期設定
        if let backCamera = backCamera {
            do {
                videoInput = try AVCaptureDeviceInput(device: backCamera)
                if session.canAddInput(videoInput!) {
                    session.addInput(videoInput!)
                    currentCamera = backCamera
                }
            } catch {
                showCameraError("カメラの初期化に失敗しました: \(error.localizedDescription)")
                return
            }
        }
        
        // 写真出力の設定
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            // 写真設定
            photoOutput.isHighResolutionCaptureEnabled = true
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoOutput.isDepthDataDeliveryEnabled = false
            }
        }
        
        session.commitConfiguration()
    }
    
    private func setupCameraDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        for device in discoverySession.devices {
            switch device.position {
            case .back:
                backCamera = device
            case .front:
                frontCamera = device
            default:
                break
            }
        }
    }
    
    // MARK: - Session Control
    
    func startSession() {
        guard !session.isRunning else { return }
        
        Task {
            session.startRunning()
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        
        session.stopRunning()
    }
    
    // MARK: - Camera Controls
    
    func switchCamera() {
        guard let currentInput = videoInput else { return }
        
        session.beginConfiguration()
        session.removeInput(currentInput)
        
        let newCamera: AVCaptureDevice?
        if currentCamera?.position == .back {
            newCamera = frontCamera
        } else {
            newCamera = backCamera
        }
        
        guard let camera = newCamera else {
            session.addInput(currentInput)
            session.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                videoInput = newInput
                currentCamera = camera
            } else {
                session.addInput(currentInput)
            }
        } catch {
            session.addInput(currentInput)
            showCameraError("カメラの切り替えに失敗しました")
        }
        
        session.commitConfiguration()
    }
    
    func setZoomLevel(_ zoomLevel: CGFloat) {
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = min(max(zoomLevel, 1.0), device.activeFormat.videoMaxZoomFactor)
            device.unlockForConfiguration()
        } catch {
            print("ズーム設定エラー: \(error)")
        }
    }
    
    func focusAt(point: CGPoint) {
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
            
            // フォーカス指示を表示
            focusPoint = point
            
            // 1秒後に非表示
            Task {
                try await Task.sleep(for: .seconds(1))
                focusPoint = nil
            }
            
        } catch {
            print("フォーカス設定エラー: \(error)")
        }
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }
    
    func setCurrentFilter(_ filterType: FilterType) {
        currentFilter = filterType
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        photoCompletionHandler = completion
        
        var settings = AVCapturePhotoSettings()
        
        // フラッシュ設定
        if let device = currentCamera, device.hasFlash {
            settings.flashMode = flashMode
        }
        
        // 高解像度設定
        settings.isHighResolutionPhotoEnabled = true
        
        // フォーマット設定
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        
        isCapturing = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Error Handling
    
    private func showCameraError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CustomCameraViewModel: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        defer { isCapturing = false }
        
        if let error = error {
            showCameraError("写真の撮影に失敗しました: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else {
            showCameraError("画像データの処理に失敗しました")
            return
        }
        
        // フィルター適用
        Task {
            let processedImage = await processImage(uiImage)
            photoCompletionHandler?(processedImage)
        }
    }
    
    private func processImage(_ image: UIImage) async -> UIImage {
        // 画像を最適化
        let optimizedImage = imageProcessor.resizeImageIfNeeded(image)
        
        // フィルター適用
        if currentFilter != .none,
           let ciImage = CIImage(image: optimizedImage) {
            let filteredCIImage = filterManager.applyFilterRealtime(currentFilter, to: ciImage, intensity: 1.0)
            
            if let cgImage = CIContext().createCGImage(filteredCIImage, from: filteredCIImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return optimizedImage
    }
}

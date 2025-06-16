//
//  MetalPreviewView.swift
//  couleur
//
//  Metalを使用したリアルタイムプレビュー
//

import SwiftUI
import MetalKit
import CoreImage

// MARK: - Metal Preview View
struct MetalPreviewView: UIViewRepresentable {
    @Binding var currentImage: CIImage?
    @Binding var filterType: FilterType
    @Binding var filterIntensity: Float
    let metalDevice = MTLCreateSystemDefaultDevice()
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = metalDevice
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.contentScaleFactor = UIScreen.main.scale
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 30 // リアルタイム更新用
        
        // 背景を黒に
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        return mtkView
    }
    
    func updateUIView(_ mtkView: MTKView, context: Context) {
        // フィルター変更を通知
        context.coordinator.updateFilter(filterType, intensity: filterIntensity)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalPreviewView
        private let ciContext: CIContext
        private let filterManager = AdvancedFilterManager()
        private var currentFilterType: FilterType = .none
        private var currentIntensity: Float = 1.0
        private let commandQueue: MTLCommandQueue?
        
        init(_ parent: MetalPreviewView) {
            self.parent = parent
            
            // Metal用のCIContext作成
            if let device = parent.metalDevice {
                self.ciContext = CIContext(mtlDevice: device, options: [
                    .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                    .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                    .useSoftwareRenderer: false
                ])
                self.commandQueue = device.makeCommandQueue()
            } else {
                self.ciContext = CIContext()
                self.commandQueue = nil
            }
            
            super.init()
        }
        
        func updateFilter(_ filterType: FilterType, intensity: Float) {
            currentFilterType = filterType
            currentIntensity = intensity
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // サイズ変更時の処理
        }
        
        func draw(in view: MTKView) {
            autoreleasepool {
                guard let currentImage = parent.currentImage,
                      let drawable = view.currentDrawable,
                      let commandBuffer = commandQueue?.makeCommandBuffer() else {
                    return
                }
                
                // フィルター適用（高速版）
                let filteredImage = filterManager.applyFilterRealtime(
                    currentFilterType,
                    to: currentImage,
                    intensity: currentIntensity
                )
                
                // アスペクト比を保持してスケーリング
                let drawableSize = view.drawableSize
                let imageSize = filteredImage.extent.size
                
                let scaleX = drawableSize.width / imageSize.width
                let scaleY = drawableSize.height / imageSize.height
                let scale = min(scaleX, scaleY)
                
                let scaledImage = filteredImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                
                // センタリング
                let x = (drawableSize.width - imageSize.width * scale) / 2
                let y = (drawableSize.height - imageSize.height * scale) / 2
                let centeredImage = scaledImage.transformed(by: CGAffineTransform(translationX: x, y: y))
                
                // レンダリング
                let renderDestination = CIRenderDestination(
                    width: Int(drawableSize.width),
                    height: Int(drawableSize.height),
                    pixelFormat: view.colorPixelFormat,
                    commandBuffer: commandBuffer,
                    mtlTextureProvider: { () -> MTLTexture in
                        return drawable.texture
                    }
                )
                
                do {
                    try ciContext.startTask(toRender: centeredImage, to: renderDestination)
                } catch {
                    print("Render error: \(error)")
                }
                
                commandBuffer.present(drawable)
                commandBuffer.commit()
            }
        }
    }
}
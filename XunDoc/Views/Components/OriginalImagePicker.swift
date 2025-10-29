//
//  OriginalImagePicker.swift
//  XunDoc
//
//  专门用于保持原始图片比例的图片选择器
//

import SwiftUI
import UIKit
import PhotosUI

// MARK: - 原始图片选择器（不裁剪）
struct OriginalImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false // 关键：不允许编辑，保持原始比例
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: OriginalImagePicker
        
        init(_ parent: OriginalImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // 优先使用原始图片，保持完整比例
            if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - 批量图片选择器（支持多选）
@available(iOS 14.0, *)
struct MultipleImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.presentationMode) private var presentationMode
    var maxSelection: Int = 10 // 最多选择10张
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = maxSelection
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultipleImagePicker
        
        init(_ parent: MultipleImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard !results.isEmpty else { return }
            
            // 使用后台线程异步处理图片，避免UI卡顿
            Task.detached(priority: .userInitiated) {
                var loadedImages: [UIImage] = []
                
                // 并发加载和优化图片
                await withTaskGroup(of: UIImage?.self) { group in
                    for result in results {
                        group.addTask {
                            await self.loadAndOptimizeImage(from: result)
                        }
                    }
                    
                    for await image in group {
                        if let image = image {
                            loadedImages.append(image)
                        }
                    }
                }
                
                await MainActor.run {
                    self.parent.images = loadedImages
                    print("✅ 成功加载并优化 \(loadedImages.count) 张图片")
                }
            }
        }
        
        // 异步加载和优化图片
        private func loadAndOptimizeImage(from result: PHPickerResult) async -> UIImage? {
            return await withCheckedContinuation { continuation in
                result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                    if let image = object as? UIImage {
                        // 在后台优化图片
                        let optimized = self.optimizeImage(image)
                        continuation.resume(returning: optimized)
                    } else {
                        if let error = error {
                            print("❌ 加载图片失败: \(error.localizedDescription)")
                        }
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
        
        // 优化图片大小和质量
        private func optimizeImage(_ image: UIImage) -> UIImage {
            let maxDimension: CGFloat = 2048 // 最大尺寸
            let size = image.size
            
            // 如果图片已经足够小，直接返回
            if size.width <= maxDimension && size.height <= maxDimension {
                return image
            }
            
            // 按比例缩放
            let scale = min(maxDimension / size.width, maxDimension / size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resizedImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            
            return resizedImage
        }
    }
}


//
//  ImageStorageManager.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import Foundation
import UIKit

class ImageStorageManager {
    static let shared = ImageStorageManager()
    
    private init() {
        createDirectoryIfNeeded()
    }
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private var avatarsDirectory: URL {
        return documentsDirectory.appendingPathComponent("Avatars")
    }
    
    private func createDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: avatarsDirectory.path) {
            try? FileManager.default.createDirectory(at: avatarsDirectory, withIntermediateDirectories: true)
        }
    }
    
    // 保存头像图片（同步版本，保持向后兼容）
    func saveAvatar(_ image: UIImage, for memberID: UUID) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let filename = "\(memberID.uuidString).jpg"
        let fileURL = avatarsDirectory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            return filename
        } catch {
            print("Failed to save avatar: \(error)")
            return nil
        }
    }
    
    // 异步保存头像图片（推荐使用，不阻塞UI）
    func saveAvatarAsync(_ image: UIImage, for memberID: UUID) async -> String? {
        return await Task.detached(priority: .userInitiated) {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
            
            let filename = "\(memberID.uuidString).jpg"
            let fileURL = self.avatarsDirectory.appendingPathComponent(filename)
            
            do {
                try imageData.write(to: fileURL)
                return filename
            } catch {
                print("Failed to save avatar: \(error)")
                return nil
            }
        }.value
    }
    
    // 加载头像图片
    func loadAvatar(filename: String) -> UIImage? {
        let fileURL = avatarsDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // 删除头像图片
    func deleteAvatar(filename: String) {
        let fileURL = avatarsDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // 获取头像文件路径
    func getAvatarPath(filename: String) -> String {
        return avatarsDirectory.appendingPathComponent(filename).path
    }
}

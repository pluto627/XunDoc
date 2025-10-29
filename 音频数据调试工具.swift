//
//  音频数据调试工具.swift
//  XunDoc
//
//  用于调试和测试音频数据存储
//  可以在任何 View 中临时使用这些工具函数
//

import Foundation
import SwiftUI

// MARK: - 调试工具扩展

extension AudioTranscriptionManager {
    
    /// 打印所有对话的音频文件状态
    func debugPrintAudioStatus() {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 音频数据状态报告")
        print(String(repeating: "=", count: 60))
        
        if conversations.isEmpty {
            print("⚠️ 没有任何对话记录")
            return
        }
        
        for (index, conversation) in conversations.enumerated() {
            print("\n[\(index + 1)] 对话: \(conversation.title)")
            print("  ID: \(conversation.id.uuidString)")
            print("  日期: \(conversation.date.formatted())")
            print("  时长: \(Int(conversation.audioDuration))秒")
            
            // 检查内存中的音频数据
            if let audioData = conversation.audioData {
                print("  ✅ 内存中有音频数据: \(audioData.count) 字节 (\(String(format: "%.2f", Double(audioData.count) / 1024 / 1024)) MB)")
            } else {
                print("  ❌ 内存中无音频数据")
            }
            
            // 检查文件系统中的音频文件
            let fileURL = getAudioDirectoryURL().appendingPathComponent("\(conversation.id.uuidString).m4a")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    print("  ✅ 文件系统中有音频文件: \(fileSize) 字节 (\(String(format: "%.2f", Double(fileSize) / 1024 / 1024)) MB)")
                    print("  📁 文件路径: \(fileURL.path)")
                } else {
                    print("  ⚠️ 文件系统中有音频文件但无法读取属性")
                }
            } else {
                print("  ❌ 文件系统中无音频文件")
                print("  📁 预期路径: \(fileURL.path)")
            }
        }
        
        print("\n" + String(repeating: "=", count: 60))
        print("总计: \(conversations.count) 个对话")
        
        let audioDir = getAudioDirectoryURL()
        if let files = try? FileManager.default.contentsOfDirectory(atPath: audioDir.path) {
            let m4aFiles = files.filter { $0.hasSuffix(".m4a") }
            print("音频文件夹中共有 \(m4aFiles.count) 个 .m4a 文件")
        }
        print(String(repeating: "=", count: 60) + "\n")
    }
    
    /// 清理所有音频文件（慎用！）
    func debugClearAllAudioFiles() {
        let audioDir = getAudioDirectoryURL()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: audioDir.path)
            var deletedCount = 0
            
            for file in files {
                let filePath = audioDir.appendingPathComponent(file)
                try FileManager.default.removeItem(at: filePath)
                deletedCount += 1
                print("🗑️ 已删除: \(file)")
            }
            
            print("✅ 共删除 \(deletedCount) 个文件")
        } catch {
            print("❌ 清理失败: \(error)")
        }
    }
    
    /// 清理所有对话数据（包括音频文件）
    func debugClearAllData() {
        print("\n⚠️ 开始清理所有数据...")
        
        // 删除所有音频文件
        let audioDir = getAudioDirectoryURL()
        if let files = try? FileManager.default.contentsOfDirectory(atPath: audioDir.path) {
            for file in files {
                let filePath = audioDir.appendingPathComponent(file)
                try? FileManager.default.removeItem(at: filePath)
                print("🗑️ 删除音频文件: \(file)")
            }
        }
        
        // 清空内存数据
        conversations.removeAll()
        
        // 清空 UserDefaults
        UserDefaults.standard.removeObject(forKey: "medical_conversations")
        
        print("✅ 所有数据已清理\n")
    }
    
    /// 验证音频文件完整性
    func debugVerifyAudioIntegrity() {
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 验证音频文件完整性")
        print(String(repeating: "=", count: 60))
        
        var validCount = 0
        var invalidCount = 0
        var missingCount = 0
        
        for conversation in conversations {
            let fileURL = getAudioDirectoryURL().appendingPathComponent("\(conversation.id.uuidString).m4a")
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // 尝试加载音频数据
                if let data = try? Data(contentsOf: fileURL), !data.isEmpty {
                    // 验证是否是有效的音频格式
                    let header = data.prefix(12)
                    let headerBytes = [UInt8](header)
                    
                    // 检查 M4A 文件头 (ftyp)
                    if headerBytes.count >= 8 &&
                       headerBytes[4] == 0x66 && // 'f'
                       headerBytes[5] == 0x74 && // 't'
                       headerBytes[6] == 0x79 && // 'y'
                       headerBytes[7] == 0x70 {  // 'p'
                        print("✅ \(conversation.title): 有效的 M4A 文件 (\(data.count) 字节)")
                        validCount += 1
                    } else {
                        print("⚠️ \(conversation.title): 文件格式可能不正确")
                        print("   文件头: \(headerBytes.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " "))")
                        invalidCount += 1
                    }
                } else {
                    print("❌ \(conversation.title): 文件为空或无法读取")
                    invalidCount += 1
                }
            } else {
                print("❌ \(conversation.title): 文件不存在")
                missingCount += 1
            }
        }
        
        print("\n" + String(repeating: "-", count: 60))
        print("总计: \(conversations.count) 个对话")
        print("  ✅ 有效: \(validCount)")
        print("  ⚠️ 无效: \(invalidCount)")
        print("  ❌ 丢失: \(missingCount)")
        print(String(repeating: "=", count: 60) + "\n")
    }
}

// MARK: - 使用示例

/*
 在任何 View 中临时添加调试按钮：
 
 import SwiftUI
 
 struct DebugView: View {
     @StateObject private var transcriptionManager = AudioTranscriptionManager.shared
     
     var body: some View {
         VStack(spacing: 20) {
             Button("📊 查看音频状态") {
                 transcriptionManager.debugPrintAudioStatus()
             }
             
             Button("🔍 验证音频完整性") {
                 transcriptionManager.debugVerifyAudioIntegrity()
             }
             
             Button("🗑️ 清理所有数据（危险）") {
                 transcriptionManager.debugClearAllData()
             }
             .foregroundColor(.red)
         }
         .padding()
     }
 }
 
 使用方式：
 1. 在 Xcode 中打开任意视图
 2. 临时添加上述调试按钮
 3. 运行 App，点击按钮
 4. 查看 Xcode 控制台输出
 5. 调试完成后删除调试代码
 
 或者直接在代码中调用：
 
 .onAppear {
     AudioTranscriptionManager.shared.debugPrintAudioStatus()
 }
*/

// MARK: - 快速测试脚本

/*
 快速测试步骤：
 
 1. 打开 HomeView.swift 或 RecordsView.swift
 
 2. 在 .onAppear 中添加：
    .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            AudioTranscriptionManager.shared.debugPrintAudioStatus()
        }
    }
 
 3. 运行 App
 
 4. 查看控制台输出，检查：
    - 是否有对话记录
    - 每个对话是否有音频文件
    - 音频文件大小是否合理
 
 5. 如果发现问题：
    - 旧数据没有音频文件 → 需要重新录制
    - 新录制的对话也没有音频 → 检查保存逻辑
 
 6. 清理旧数据（可选）：
    AudioTranscriptionManager.shared.debugClearAllData()
 
 7. 重新录制一个测试对话
 
 8. 再次运行调试工具，确认音频文件已正确保存
*/


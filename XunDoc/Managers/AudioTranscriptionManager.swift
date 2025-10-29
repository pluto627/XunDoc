//
//  AudioTranscriptionManager.swift
//  XunDoc
//
//  音频转文本管理器
//

import Foundation
import AVFoundation

class AudioTranscriptionManager: ObservableObject {
    static let shared = AudioTranscriptionManager()
    
    @Published var conversations: [MedicalConversation] = []
    
    private let conversationsKey = "medical_conversations"
    private let audioDirectory = "MedicalConversationAudios"
    
    init() {
        createAudioDirectoryIfNeeded()
        loadConversations()
    }
    
    // MARK: - 文件管理
    
    private func createAudioDirectoryIfNeeded() {
        let audioDir = getAudioDirectoryURL()
        if !FileManager.default.fileExists(atPath: audioDir.path) {
            try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
            print("📁 创建音频文件夹: \(audioDir.path)")
        }
    }
    
    private func getAudioDirectoryURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(audioDirectory)
    }
    
    private func getAudioFileURL(for conversationId: UUID) -> URL {
        return getAudioDirectoryURL().appendingPathComponent("\(conversationId.uuidString).m4a")
    }
    
    // 保存音频文件到文件系统
    private func saveAudioFile(data: Data, for conversationId: UUID) -> Bool {
        let fileURL = getAudioFileURL(for: conversationId)
        do {
            try data.write(to: fileURL)
            print("💾 音频文件已保存: \(fileURL.lastPathComponent), 大小: \(data.count) 字节")
            return true
        } catch {
            print("❌ 音频文件保存失败: \(error)")
            return false
        }
    }
    
    // 从文件系统加载音频数据
    private func loadAudioFile(for conversationId: UUID) -> Data? {
        let fileURL = getAudioFileURL(for: conversationId)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ 音频文件不存在: \(fileURL.lastPathComponent)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            print("✅ 加载音频文件: \(fileURL.lastPathComponent), 大小: \(data.count) 字节")
            return data
        } catch {
            print("❌ 音频文件加载失败: \(error)")
            return nil
        }
    }
    
    // 删除音频文件
    private func deleteAudioFile(for conversationId: UUID) {
        let fileURL = getAudioFileURL(for: conversationId)
        try? FileManager.default.removeItem(at: fileURL)
        print("🗑️ 删除音频文件: \(fileURL.lastPathComponent)")
    }
    
    // MARK: - 数据持久化
    
    private func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: conversationsKey),
           let decoded = try? JSONDecoder().decode([MedicalConversation].self, from: data) {
            conversations = decoded
            
            // 加载每个对话的音频数据
            for i in 0..<conversations.count {
                if let audioData = loadAudioFile(for: conversations[i].id) {
                    conversations[i].audioData = audioData
                }
            }
            
            print("✅ 加载了 \(conversations.count) 个对话")
        }
    }
    
    func saveConversations() {
        // 先保存音频文件到文件系统
        for conversation in conversations {
            if let audioData = conversation.audioData, !audioData.isEmpty {
                _ = saveAudioFile(data: audioData, for: conversation.id)
            }
        }
        
        // 创建不含音频数据的副本用于保存到 UserDefaults
        var conversationsToSave = conversations
        for i in 0..<conversationsToSave.count {
            conversationsToSave[i].audioData = nil  // 不保存音频数据到 UserDefaults
        }
        
        // 保存对话元数据到 UserDefaults
        if let encoded = try? JSONEncoder().encode(conversationsToSave) {
            UserDefaults.standard.set(encoded, forKey: conversationsKey)
            print("💾 保存了 \(conversations.count) 个对话（音频文件单独存储）")
        }
    }
    
    // MARK: - 对话管理
    
    func addConversation(_ conversation: MedicalConversation) {
        conversations.append(conversation)
        saveConversations()
    }
    
    func updateConversation(_ conversation: MedicalConversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var updated = conversation
            updated.updatedAt = Date()
            conversations[index] = updated
            saveConversations()
        }
    }
    
    func deleteConversation(_ conversation: MedicalConversation) {
        // 删除音频文件
        deleteAudioFile(for: conversation.id)
        
        // 删除对话数据
        conversations.removeAll { $0.id == conversation.id }
        saveConversations()
    }
    
    func getConversations(for memberId: UUID) -> [MedicalConversation] {
        var memberConversations = conversations.filter { $0.memberId == memberId }
        
        // 确保每个对话都有音频数据
        for i in 0..<memberConversations.count {
            if memberConversations[i].audioData == nil {
                memberConversations[i].audioData = loadAudioFile(for: memberConversations[i].id)
            }
        }
        
        return memberConversations.sorted { $0.date > $1.date }
    }
    
    // 获取单个对话（包含音频数据）
    func getConversation(by id: UUID) -> MedicalConversation? {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        
        var conversation = conversations[index]
        
        // 确保加载音频数据
        if conversation.audioData == nil {
            conversation.audioData = loadAudioFile(for: conversation.id)
        }
        
        return conversation
    }
    
    // MARK: - 音频转文本 (模拟实现)
    
    /// 转译音频为文本 - 实际应用中应接入真实的语音识别API
    func transcribeAudio(for conversationId: UUID, completion: @escaping (Bool) -> Void) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else {
            completion(false)
            return
        }
        
        // 模拟异步转译过程
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // 模拟进度更新
            for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                Thread.sleep(forTimeInterval: 0.3)
                DispatchQueue.main.async {
                    self.conversations[index].transcriptionProgress = progress
                    self.saveConversations()
                }
            }
            
            // 生成模拟对话数据
            let messages = self.generateMockMessages(duration: self.conversations[index].audioDuration)
            let summary = self.generateMockSummary()
            
            DispatchQueue.main.async {
                self.conversations[index].messages = messages
                self.conversations[index].summary = summary
                self.conversations[index].isTranscribed = true
                self.conversations[index].transcriptionProgress = 1.0
                self.saveConversations()
                completion(true)
            }
        }
    }
    
    // MARK: - 模拟数据生成 (仅用于演示)
    
    private func generateMockMessages(duration: TimeInterval) -> [ConversationMessage] {
        let sampleDialogues: [(ConversationRole, String)] = [
            (.doctor, "您好,请问哪里不舒服?"),
            (.patient, "医生您好,我最近总是头疼,特别是下午的时候。"),
            (.doctor, "头疼有多久了?是持续性的还是阵发性的?"),
            (.patient, "大概有一周了,不是一直疼,就是下午工作的时候会疼。"),
            (.doctor, "有没有伴随恶心、呕吐的症状?"),
            (.patient, "没有,就是单纯的头疼,有时候会觉得眼睛也有点胀。"),
            (.doctor, "平时工作用电脑多吗?休息时间够吗?"),
            (.patient, "对,每天都要对着电脑工作七八个小时,最近加班比较多,睡眠不太好。"),
            (.doctor, "我建议您先做个头颅CT检查,排除器质性病变。同时要注意休息,不要过度用眼。"),
            (.patient, "好的医生,那我需要吃药吗?"),
            (.doctor, "可以先服用一些止痛药缓解症状,但最重要的是改善作息。我给您开具检查单。"),
            (.patient, "谢谢医生!")
        ]
        
        var messages: [ConversationMessage] = []
        let timePerMessage = duration / Double(sampleDialogues.count)
        
        for (index, (role, content)) in sampleDialogues.enumerated() {
            let timestamp = Double(index) * timePerMessage
            let message = ConversationMessage(
                role: role,
                content: content,
                timestamp: timestamp,
                duration: timePerMessage * 0.8
            )
            messages.append(message)
        }
        
        return messages
    }
    
    private func generateMockSummary() -> String {
        return """
        【主诉】患者主诉近一周出现头痛症状,以下午工作时为主。
        
        【现病史】头痛为阵发性,无恶心呕吐,偶有眼胀。患者工作需长时间使用电脑,近期睡眠不佳。
        
        【初步诊断】可能为紧张性头痛或视疲劳相关头痛。
        
        【处理建议】
        1. 完善头颅CT检查,排除器质性病变
        2. 改善作息,减少用眼时间
        3. 可适当服用止痛药缓解症状
        4. 建议眼科会诊
        
        【备注】患者依从性好,建议一周后复诊。
        """
    }
    
    // TODO: 集成真实的语音识别API
    // func transcribeWithAPI(audioData: Data) async throws -> [ConversationMessage]
}


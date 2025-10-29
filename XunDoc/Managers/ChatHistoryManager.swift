//
//  ChatHistoryManager.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import Foundation
import SwiftUI

@MainActor
class ChatHistoryManager: ObservableObject {
    static let shared = ChatHistoryManager()
    
    @Published var conversations: [ChatConversation] = []
    @Published var currentConversation: ChatConversation?
    
    private let userDefaults = UserDefaults.standard
    private let conversationsKey = "ChatConversations"
    
    init() {
        loadConversations()
    }
    
    // MARK: - 创建新对话
    func createNewConversation() -> ChatConversation {
        let conversation = ChatConversation(
            title: generateTitle(),
            messages: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        conversations.insert(conversation, at: 0)
        currentConversation = conversation
        saveConversations()
        
        return conversation
    }
    
    // MARK: - 添加消息到当前对话
    func addMessage(_ message: ChatMessage, to conversation: ChatConversation? = nil) {
        let targetConversation = conversation ?? currentConversation ?? createNewConversation()
        
        if let index = conversations.firstIndex(where: { $0.id == targetConversation.id }) {
            conversations[index].messages.append(message)
            conversations[index].updatedAt = Date()
            
            // 更新标题（如果是第一条用户消息）
            if conversations[index].messages.count == 1 && message.isUser {
                conversations[index].title = String(message.content.prefix(30))
            }
            
            // 将对话移到顶部
            let updated = conversations.remove(at: index)
            conversations.insert(updated, at: 0)
            currentConversation = updated
            
            saveConversations()
        }
    }
    
    // MARK: - 删除对话
    func deleteConversation(_ conversation: ChatConversation) {
        conversations.removeAll { $0.id == conversation.id }
        
        if currentConversation?.id == conversation.id {
            currentConversation = conversations.first
        }
        
        saveConversations()
    }
    
    // MARK: - 清空所有对话
    func clearAllConversations() {
        conversations.removeAll()
        currentConversation = nil
        saveConversations()
    }
    
    // MARK: - 选择对话
    func selectConversation(_ conversation: ChatConversation) {
        currentConversation = conversation
    }
    
    // MARK: - 持久化
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            userDefaults.set(encoded, forKey: conversationsKey)
        }
    }
    
    private func loadConversations() {
        guard let data = userDefaults.data(forKey: conversationsKey) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([ChatConversation].self, from: data)
            conversations = decoded
            currentConversation = conversations.first
        } catch {
            // 如果解码失败（可能是旧数据格式），清空数据重新开始
            print("⚠️ 无法加载对话历史，清空旧数据: \(error.localizedDescription)")
            userDefaults.removeObject(forKey: conversationsKey)
            conversations = []
            currentConversation = nil
        }
    }
    
    // MARK: - 辅助方法
    private func generateTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return NSLocalizedString("new_conversation", comment: "") + " - " + formatter.string(from: Date())
    }
}

// MARK: - 对话模型
struct ChatConversation: Identifiable, Codable, Equatable {
    let id = UUID()
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
    
    var preview: String {
        if let lastMessage = messages.last {
            return lastMessage.content
        }
        return NSLocalizedString("no_messages", comment: "")
    }
    
    static func == (lhs: ChatConversation, rhs: ChatConversation) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 消息模型扩展
extension ChatMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case content, isUser, timestamp, imageData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
        
        if let image = image {
            let imageData = image.jpegData(compressionQuality: 0.5)
            try container.encode(imageData, forKey: .imageData)
        }
    }
      
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
        isUser = try container.decode(Bool.self, forKey: .isUser)
        
        // 安全解码 timestamp，如果不存在则使用当前时间
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .imageData) {
            image = UIImage(data: imageData)
        } else {
            image = nil
        }
    }
}

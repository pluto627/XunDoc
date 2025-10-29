//
//  MedicalConversation.swift
//  XunDoc
//
//  医患对话模型
//

import Foundation

// MARK: - 对话角色
enum ConversationRole: String, Codable {
    case doctor = "doctor"
    case patient = "patient"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .doctor: return "医生"
        case .patient: return "患者"
        case .system: return "系统"
        }
    }
}

// MARK: - 对话消息
struct ConversationMessage: Identifiable, Codable {
    let id: UUID
    let role: ConversationRole
    let content: String
    let timestamp: TimeInterval  // 音频中的时间戳(秒)
    let duration: TimeInterval   // 这段话的持续时间
    
    init(
        id: UUID = UUID(),
        role: ConversationRole,
        content: String,
        timestamp: TimeInterval,
        duration: TimeInterval
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.duration = duration
    }
    
    // 格式化时间戳显示
    var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 医患对话
struct MedicalConversation: Identifiable, Codable {
    let id: UUID
    let memberId: UUID
    var title: String
    var date: Date
    var hospitalName: String?
    var department: String?
    var doctorName: String?
    
    // 音频相关
    var audioData: Data?
    var audioDuration: TimeInterval
    var audioFileName: String?
    
    // 转译内容
    var messages: [ConversationMessage]
    var summary: String?  // AI生成的对话摘要
    var tags: [String]
    
    // 状态
    var isTranscribed: Bool  // 是否已完成转译
    var transcriptionProgress: Double  // 转译进度 0.0 - 1.0
    
    // 元数据
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        memberId: UUID,
        title: String,
        date: Date = Date(),
        hospitalName: String? = nil,
        department: String? = nil,
        doctorName: String? = nil,
        audioData: Data? = nil,
        audioDuration: TimeInterval,
        audioFileName: String? = nil,
        messages: [ConversationMessage] = [],
        summary: String? = nil,
        tags: [String] = [],
        isTranscribed: Bool = false,
        transcriptionProgress: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.memberId = memberId
        self.title = title
        self.date = date
        self.hospitalName = hospitalName
        self.department = department
        self.doctorName = doctorName
        self.audioData = audioData
        self.audioDuration = audioDuration
        self.audioFileName = audioFileName
        self.messages = messages
        self.summary = summary
        self.tags = tags
        self.isTranscribed = isTranscribed
        self.transcriptionProgress = transcriptionProgress
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 按时间戳排序的消息
    var sortedMessages: [ConversationMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    // 格式化音频时长
    var formattedDuration: String {
        let minutes = Int(audioDuration) / 60
        let seconds = Int(audioDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


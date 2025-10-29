//
//  KimiAPIManager.swift
//  XunDoc
//
//  Kimi AI API管理器
//

import Foundation

// MARK: - API响应模型
struct KimiChatMessage: Codable {
    let role: String
    let content: String
}

struct KimiChatRequest: Codable {
    let model: String
    let messages: [KimiChatMessage]
    let stream: Bool
    let temperature: Double?
    let maxTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case stream
        case temperature
        case maxTokens = "max_tokens"
    }
    
    init(messages: [KimiChatMessage], stream: Bool = false, temperature: Double = 0.7, maxTokens: Int? = nil) {
        self.model = "moonshot-v1-8k"  // 或使用 moonshot-v1-32k, moonshot-v1-128k
        self.messages = messages
        self.stream = stream
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
}

struct KimiChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [KimiChoice]
    
    struct KimiChoice: Codable {
        let index: Int
        let message: KimiChatMessage?
        let delta: KimiChatMessage?
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case delta
            case finishReason = "finish_reason"
        }
    }
}

// MARK: - AI对话历史
struct AIConversationHistory: Identifiable, Codable {
    let id: UUID
    let memberId: UUID
    var question: String
    var answer: String
    var timestamp: Date
    var isExpanded: Bool  // 用于UI展开/折叠
    var contextFiles: [String]  // 关联的文件/数据
    
    init(
        id: UUID = UUID(),
        memberId: UUID,
        question: String,
        answer: String = "",
        timestamp: Date = Date(),
        isExpanded: Bool = false,
        contextFiles: [String] = []
    ) {
        self.id = id
        self.memberId = memberId
        self.question = question
        self.answer = answer
        self.timestamp = timestamp
        self.isExpanded = isExpanded
        self.contextFiles = contextFiles
    }
}

// MARK: - Kimi API管理器
class KimiAPIManager: ObservableObject {
    static let shared = KimiAPIManager()
    
    @Published var conversationHistories: [AIConversationHistory] = []
    @Published var isLoading = false
    
    private let apiKey = "sk-CE6JIOSti61TqFYhPFs6OrTS5wMtJvA8v2YsnPIw1SFgeqcu"  // 需要替换为实际的API Key
    private let baseURL = "https://api.moonshot.cn/v1/chat/completions"
    private let historiesKey = "ai_conversation_histories"
    
    init() {
        loadHistories()
        
    }
    
    // MARK: - 数据持久化
    
    private func loadHistories() {
        if let data = UserDefaults.standard.data(forKey: historiesKey),
           let decoded = try? JSONDecoder().decode([AIConversationHistory].self, from: data) {
            conversationHistories = decoded
            print("✅ 加载了 \(conversationHistories.count) 条AI对话")
        }
    }
    
    func saveHistories() {
        if let encoded = try? JSONEncoder().encode(conversationHistories) {
            UserDefaults.standard.set(encoded, forKey: historiesKey)
            print("💾 保存了 \(conversationHistories.count) 条AI对话")
        }
    }
    
    // MARK: - AI对话
    
    /// 发送问题并获取流式响应
    func askQuestion(
        question: String,
        memberId: UUID? = nil,
        context: String = "",
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void
    ) {
        isLoading = true
        
        // 🆕 获取用户个人信息
        let userProfile = UserProfileManager.shared.userProfile
        let userContext = userProfile.buildAIContext()
        
        // 构建完整的提示词(包含上下文和用户信息)
        let systemPrompt = """
        你是一位资深的医学AI助手，经过专业医学数据微调训练。你具备以下能力：

        1. **专业医学知识**: 掌握内科、外科、妇科、儿科等各科室专业知识
        2. **诊断辅助**: 能够基于症状提供可能的诊断建议（仅供参考）
        3. **治疗建议**: 提供基于循证医学的治疗方案建议
        4. **药物咨询**: 提供药物使用、副作用、相互作用等信息
        5. **健康教育**: 提供疾病预防、健康生活方式等指导

        **重要声明**:
        - 我的建议仅供医学参考，不能替代专业医生的诊断和治疗
        - 遇到紧急情况请立即就医
        - 用药请遵医嘱，不要自行调整药物
        
        \(userContext)
        """
        
        var userPrompt = question
        if !context.isEmpty {
            userPrompt = """
            【用户上传的医疗数据】
            \(context)
            
            【用户问题】
            \(question)
            
            请基于上述医疗数据回答问题。
            """
        }
        
        let messages = [
            KimiChatMessage(role: "system", content: systemPrompt),
            KimiChatMessage(role: "user", content: userPrompt)
        ]
        
        // 改为非流式模式，避免SSE解析问题
        // 设置max_tokens为4000，确保输出完整（moonshot-v1-8k支持最大8k tokens）
        let request = KimiChatRequest(messages: messages, stream: false, maxTokens: 4000)
        
        // 创建历史记录
        let history = AIConversationHistory(
            memberId: memberId ?? UUID(),  // 如果没有提供 memberId，使用默认值
            question: question,
            answer: "",
            contextFiles: []
        )
        conversationHistories.insert(history, at: 0)
        
        // 发送请求(流式)
        streamChatCompletion(request: request, historyId: history.id, onUpdate: onUpdate, onComplete: onComplete)
    }
    
    /// 流式聊天完成
    private func streamChatCompletion(
        request: KimiChatRequest,
        historyId: UUID,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void
    ) {
        guard let url = URL(string: baseURL) else {
            isLoading = false
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            print("❌ 编码请求失败: \(error)")
            isLoading = false
            return
        }
        
        // 执行真实的API请求
        performRealAPICall(urlRequest: urlRequest, historyId: historyId, onUpdate: onUpdate, onComplete: onComplete)
    }
    
    /// 执行真实的Kimi API调用
    private func performRealAPICall(
        urlRequest: URLRequest,
        historyId: UUID,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void
    ) {
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ API请求失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    let errorMessage = "抱歉，AI服务暂时不可用。请稍后再试。"
                    onUpdate(errorMessage)
                    onComplete(errorMessage)
                }
                return
            }
            
            guard let data = data else {
                print("❌ 没有收到数据")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // 解析响应
            do {
                let decoder = JSONDecoder()
                let chatResponse = try decoder.decode(KimiChatResponse.self, from: data)
                
                if let message = chatResponse.choices.first?.message {
                    let fullResponse = message.content
                    
                    print("✅ 成功获取AI回复，长度: \(fullResponse.count) 字符")
                    
                    // 模拟流式输出效果
                    self.streamText(fullResponse, historyId: historyId, onUpdate: onUpdate, onComplete: onComplete)
                } else {
                    print("❌ 无法获取AI回复")
                    print("响应结构: \(chatResponse)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        let errorMessage = "抱歉，AI回复格式异常。"
                        onUpdate(errorMessage)
                        onComplete(errorMessage)
                    }
                }
            } catch {
                print("❌ 解析响应失败: \(error)")
                print("📄 响应数据: \(String(data: data, encoding: .utf8) ?? "无法解码")")
                
                // 检查是否是HTTP错误
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP状态码: \(httpResponse.statusCode)")
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    let errorMessage = "抱歉，解析AI回复时出错。请检查API配置。"
                    onUpdate(errorMessage)
                    onComplete(errorMessage)
                }
            }
        }
        
        task.resume()
    }
    
    /// 模拟流式文本输出
    private func streamText(
        _ fullText: String,
        historyId: UUID,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void
    ) {
        var currentText = ""
        let characters = Array(fullText)
        
        DispatchQueue.global().async { [weak self] in
            for (index, char) in characters.enumerated() {
                Thread.sleep(forTimeInterval: 0.01)  // 快速输出
                
                currentText.append(char)
                
                DispatchQueue.main.async {
                    onUpdate(currentText)
                    
                    // 更新历史记录
                    if let historyIndex = self?.conversationHistories.firstIndex(where: { $0.id == historyId }) {
                        self?.conversationHistories[historyIndex].answer = currentText
                    }
                }
                
                // 最后一个字符
                if index == characters.count - 1 {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        onComplete(currentText)
                        self?.saveHistories()
                    }
                }
            }
        }
    }
    
    // MARK: - 历史管理
    
    func getHistories(for memberId: UUID) -> [AIConversationHistory] {
        return conversationHistories.filter { $0.memberId == memberId }
    }
    
    func toggleExpand(_ historyId: UUID) {
        if let index = conversationHistories.firstIndex(where: { $0.id == historyId }) {
            conversationHistories[index].isExpanded.toggle()
            saveHistories()
        }
    }
    
    func deleteHistory(_ historyId: UUID) {
        conversationHistories.removeAll { $0.id == historyId }
        saveHistories()
    }
    
    func clearAllHistories() {
        conversationHistories.removeAll()
        saveHistories()
    }
    
    // MARK: - 上下文构建
    
    /// 从健康记录构建上下文
    func buildContextFromHealthRecord(_ record: HealthRecord) -> String {
        var context = ""
        
        context += "医院：\(record.hospitalName)\n"
        context += "科室：\(record.department)\n"
        context += "日期：\(formatDate(record.date))\n"
        
        if !record.symptoms.isEmpty {
            context += "症状：\(record.symptoms)\n"
        }
        
        if let diagnosis = record.diagnosis {
            context += "诊断：\(diagnosis)\n"
        }
        
        if let treatment = record.treatment {
            context += "治疗：\(treatment)\n"
        }
        
        return context
    }
    
    /// 从报告构建上下文
    func buildContextFromReport(_ report: MedicalReport) -> String {
        var context = ""
        
        context += "报告类型：\(report.reportType.displayName)\n"
        context += "检查日期：\(formatDate(report.date))\n"
        context += "医院：\(report.hospitalName)\n"
        
        if let department = report.department {
            context += "科室：\(department)\n"
        }
        
        if let notes = report.notes {
            context += "备注：\(notes)\n"
        }
        
        return context
    }
    
    /// 从对话记录构建上下文
    func buildContextFromConversation(_ conversation: MedicalConversation) -> String {
        guard conversation.isTranscribed else {
            return "医患对话录音 - 尚未转译"
        }
        
        var context = ""
        context += "对话时间：\(formatDate(conversation.date))\n"
        
        if let hospitalName = conversation.hospitalName {
            context += "医院：\(hospitalName)\n"
        }
        
        if let summary = conversation.summary {
            context += "\n对话摘要：\n\(summary)\n"
        }
        
        return context
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - 药物信息搜索
    
    /// 搜索药物信息（用途和服用说明）
    func searchMedicationInfo(
        medicationName: String,
        completion: @escaping (Result<(usage: String, instructions: String), Error>) -> Void
    ) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: nil)))
            return
        }
        
        // 构建简洁的提示词
        let systemPrompt = """
        你是一个药物信息查询助手。请简洁准确地提供药物信息。
        """
        
        let userPrompt = """
        请提供【\(medicationName)】的信息，严格按照以下格式回答（不要有任何额外说明）：
        
        用途：[用10-20字简洁说明药物主要用途]
        服用说明：[用10-20字简洁说明服用方法]
        
        示例格式：
        用途：抗血小板聚集，预防心血管事件
        服用说明：饭后服用，每日一次，每次1片
        """
        
        let messages = [
            KimiChatMessage(role: "system", content: systemPrompt),
            KimiChatMessage(role: "user", content: userPrompt)
        ]
        
        let request = KimiChatRequest(messages: messages, stream: false, temperature: 0.3)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NoData", code: -1, userInfo: nil)))
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let chatResponse = try decoder.decode(KimiChatResponse.self, from: data)
                
                if let message = chatResponse.choices.first?.message {
                    let content = message.content
                    
                    // 解析返回的内容
                    var usage = ""
                    var instructions = ""
                    
                    let lines = content.components(separatedBy: .newlines)
                    for line in lines {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if trimmed.hasPrefix("用途：") {
                            usage = trimmed.replacingOccurrences(of: "用途：", with: "").trimmingCharacters(in: .whitespaces)
                        } else if trimmed.hasPrefix("服用说明：") {
                            instructions = trimmed.replacingOccurrences(of: "服用说明：", with: "").trimmingCharacters(in: .whitespaces)
                        }
                    }
                    
                    // 如果解析失败，使用默认值
                    if usage.isEmpty {
                        usage = "请查看药品说明书"
                    }
                    if instructions.isEmpty {
                        instructions = "请遵医嘱服用"
                    }
                    
                    DispatchQueue.main.async {
                        completion(.success((usage: usage, instructions: instructions)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "NoResponse", code: -1, userInfo: nil)))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

// TODO: 实现真实的SSE流式响应处理
// TODO: 添加错误处理和重试机制
// TODO: 支持多轮对话上下文
// TODO: 添加Token计数和费用估算


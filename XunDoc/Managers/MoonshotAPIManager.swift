//
//  MoonshotAPIManager.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import Foundation
import SwiftUI

class MoonshotAPIManager: ObservableObject {
    static let shared = MoonshotAPIManager()
    
    private let apiKey = "sk-wc9tcOA0q2ShfOjKZ91YStbbyyoMGpiegf6zq54i9kpaQtke"
    private let baseURL = "https://api.moonshot.cn/v1"
    
    @Published var isAnalyzing = false
    @Published var lastError: String?
    
    private init() {}
    
    // MARK: - 皮肤问题分析
    func analyzeSkinCondition(image: UIImage, symptoms: [String]) async throws -> SkinAnalysisResult {
        await MainActor.run {
            isAnalyzing = true
        }
        defer { 
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        // 将图片转换为Base64
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ 图片处理失败：无法转换为JPEG数据")
            throw APIError.imageProcessingFailed
        }
        
        // 检查图片大小
        let imageSizeInMB = Double(imageData.count) / (1024 * 1024)
        print("📸 图片大小: \(String(format: "%.2f", imageSizeInMB)) MB")
        
        // 如果图片太大，降低质量
        let finalImageData: Data
        if imageSizeInMB > 4.0 {
            print("⚠️ 图片过大，降低压缩质量")
            guard let compressedData = image.jpegData(compressionQuality: 0.3) else {
                throw APIError.imageProcessingFailed
            }
            finalImageData = compressedData
        } else {
            finalImageData = imageData
        }
        
        let base64Image = finalImageData.base64EncodedString()
        print("✅ 图片转换成功，Base64长度: \(base64Image.count)")
        
        // 🆕 获取用户个人信息
        let userProfile = UserProfileManager.shared.userProfile
        let userContext = userProfile.buildAIContext()
        
        // 构建提示词
        let prompt = userContext + "\n" + buildSkinAnalysisPrompt(symptoms: symptoms)
        
        // 调用API
        let response = try await callMoonshotAPI(
            messages: [
                ["role": "system", "content": """
                你是一位温和、经验丰富的皮肤科专科医生，不仅拥有扎实的医学知识，更重要的是具有良好的沟通能力和人文关怀。
                
                你的特点：
                - 用温和、易懂的语言解释复杂的医学问题
                - 既专业又有人情味，让患者感到安心
                - 善于用生动的比喻和例子帮助患者理解
                - 会适当使用加粗来突出重要信息
                - 回答自然流畅，不机械化
                
                请像真正的医生面对面咨询一样，用关怀的语调提供专业建议。
                """],
                ["role": "user", "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                ] as [[String : Any]]]
            ],
            model: "moonshot-v1-32k-vision-preview"
        )
        
        return parseSkinAnalysisResponse(response)
    }
    
    // MARK: - 症状分析
    func analyzeSymptoms(_ symptoms: String) async throws -> SymptomAnalysisResult {
        await MainActor.run {
            isAnalyzing = true
        }
        defer { 
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        // 🆕 获取用户个人信息
        let userProfile = UserProfileManager.shared.userProfile
        let userContext = userProfile.buildAIContext()
        
        let prompt = """
        作为一名经验丰富的全科医生，请对以下症状进行详细的医学分析：
        
        \(userContext)
        
        患者主诉症状：\(symptoms)
        
        请以专业医生的角度，用自然流畅的语言进行详细分析。请像真正的医生一样，用温和、关怀的语调回答患者的问题。
        
        请根据具体症状自然地组织内容，可能包括：
        - 对症状的专业分析和可能原因
        - 鉴别诊断和医学解释
        - 是否需要就医及紧急程度评估
        - 具体的处理建议和治疗方案
        - 日常护理和生活调整指导
        - 预防措施和注意事项
        
        **重要格式要求**：
        - 重要的医学术语和疾病名称请用 **加粗** 显示
        - 关键的症状描述和诊断要点请用 **加粗** 显示
        - 重要的注意事项和警告信息请用 **加粗** 显示
        - 药物名称和治疗方法请用 **加粗** 显示
        - 不要使用机械化的编号格式，要像医生口述一样自然
        
        请确保回答既专业又温暖，让患者感受到医生的关怀和专业性。
        直接返回Markdown格式的文本。
        """
        
        let response = try await callMoonshotAPI(
            messages: [
                ["role": "system", "content": """
                你是一位温和、经验丰富的全科医生，既有扎实的医学功底，又具备出色的沟通技巧和人文关怀精神。
                
                你的特点：
                - 用温暖、关怀的语调与患者交流
                - 善于用通俗易懂的语言解释医学问题
                - 会适当使用比喻和生活化的例子
                - 重要信息会用加粗突出，让患者注意
                - 回答自然流畅，像朋友般的医生
                - 既专业又有温度，让患者感到安心
                
                请像真正关心患者的医生一样，用温和的语调提供专业而贴心的建议。
                """],
                ["role": "user", "content": prompt]
            ],
            model: "moonshot-v1-32k"
        )
        
        return parseSymptomAnalysisResponse(response)
    }
    
    // MARK: - 健康报告解读
    func interpretHealthReport(_ reportText: String) async throws -> ReportInterpretation {
        await MainActor.run {
            isAnalyzing = true
        }
        defer { 
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        // 🆕 获取用户个人信息
        let userProfile = UserProfileManager.shared.userProfile
        let userContext = userProfile.buildAIContext()
        
        let prompt = """
        作为一名经验丰富的临床医生，请对以下医疗报告进行详细的专业解读：
        
        \(userContext)
        
        医疗报告内容：
        \(reportText)
        
        请按照专业医学标准进行全面分析，同时用通俗易懂的语言解释：
        
        1. **检查结果详细解读**：
           - 逐项分析各项指标的含义和临床意义
           - 详细说明异常指标的原因和可能影响
           - 解释正常指标的健康意义
           - 分析各指标之间的关联性
        
        2. **健康风险全面评估**：
           - 详细评估当前的健康状况和潜在风险
           - 分析可能的疾病倾向和发展趋势
           - 评估需要重点关注的健康问题
           - 提供风险分级和预防建议
        
        3. **生活方式详细指导**：
           - 针对性的饮食调整建议和具体方案
           - 详细的运动锻炼计划和注意事项
           - 作息调整和压力管理建议
           - 环境因素和生活习惯改善措施
        
        4. **复查和随访计划**：
           - 详细的复查时间安排和检查项目
           - 需要监测的关键指标和频次
           - 什么情况下需要提前就医
           - 长期健康管理和预防策略
        
        请确保解释详细、专业，既体现医学专业性，又让患者容易理解。
        """
        
        let response = try await callMoonshotAPI(
            messages: [
                ["role": "system", "content": """
                你是一位资深的临床医生和医学顾问，具有丰富的医疗报告解读经验。你的专业能力包括：
                
                1. 精准解读各类医疗检查报告和化验结果
                2. 全面评估患者的健康状况和疾病风险
                3. 提供个性化的健康管理和生活指导建议
                4. 制定科学的复查和随访计划
                
                请确保所有解读都详细、准确、专业，同时用通俗易懂的语言让患者理解。体现医学专业水准和人文关怀。
                """],
                ["role": "user", "content": prompt]
            ],
            model: "moonshot-v1-32k"
        )
        
        return parseReportInterpretation(response)
    }
    
    // MARK: - 用药指导
    func getMedicationGuidance(medication: String, condition: String) async throws -> MedicationGuidance {
        await MainActor.run {
            isAnalyzing = true
        }
        defer { 
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        let prompt = """
        作为一名资深的临床药师和医生，请对以下用药情况提供详细的专业指导：
        
        药物名称：\(medication)
        患者情况：\(condition)
        
        请按照药学和临床医学标准提供全面的用药指导：
        
        1. **用药方法和剂量详细指导**：
           - 详细的给药方式、时间和频次
           - 不同情况下的剂量调整原则
           - 起始剂量、维持剂量和最大剂量
           - 特殊人群（老人、儿童、孕妇等）的用药调整
        
        2. **用药注意事项和禁忌症**：
           - 详细的用药前注意事项和检查要求
           - 绝对禁忌症和相对禁忌症
           - 用药期间需要监测的指标
           - 出现不良反应时的处理措施
        
        3. **副作用和不良反应详解**：
           - 常见副作用的发生率和表现
           - 严重不良反应的识别和处理
           - 副作用的预防和减轻方法
           - 需要立即停药并就医的危险信号
        
        4. **药物相互作用分析**：
           - 与其他药物的相互作用机制
           - 需要避免同时使用的药物
           - 与食物、酒精的相互作用
           - 中西药联用的注意事项
        
        5. **储存和管理指导**：
           - 详细的储存条件和环境要求
           - 药物有效期和失效判断
           - 安全用药和防止误用的措施
           - 废弃药物的处理方法
        
        请确保所有建议都详细、专业，体现药学和临床医学的专业水准。
        """
        
        let response = try await callMoonshotAPI(
            messages: [
                ["role": "system", "content": """
                你是一位资深的临床药师和药学专家，具有丰富的药物治疗和用药指导经验。你的专业职责包括：
                
                1. 提供精准的药物使用指导和剂量建议
                2. 全面分析药物的安全性和有效性
                3. 识别和预防药物不良反应和相互作用
                4. 制定个性化的用药方案和监测计划
                
                请确保所有用药指导都详细、准确、安全，体现药学专业水准和临床实践经验。所有回答必须用中文。
                """],
                ["role": "user", "content": prompt]
            ],
            model: "moonshot-v1-32k"
        )
        
        return parseMedicationGuidance(response)
    }
    
    // MARK: - 私有方法
    private func callMoonshotAPI(messages: [[String: Any]], model: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            print("❌ 无效的API URL: \(baseURL)/chat/completions")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0 // 增加超时时间
        
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 4000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ 请求体序列化失败: \(error)")
            throw APIError.requestFailed
        }
        
        print("🚀 发送API请求到: \(url)")
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("❌ 网络请求失败: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    print("❌ 网络连接失败：请检查网络连接")
                    throw APIError.networkError("网络连接失败，请检查网络设置")
                case .timedOut:
                    print("❌ 请求超时：网络响应过慢")
                    throw APIError.timeout
                case .cannotFindHost:
                    print("❌ 无法找到服务器")
                    throw APIError.networkError("无法连接到服务器")
                default:
                    print("❌ 网络错误: \(urlError.localizedDescription)")
                    throw APIError.networkError(urlError.localizedDescription)
                }
            }
            throw APIError.requestFailed
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP状态码: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 响应内容: \(responseString.prefix(500))...") // 只打印前500字符
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ API请求失败，状态码: \(httpResponse.statusCode)")
                
                // 尝试解析错误信息
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("❌ API错误信息: \(message)")
                    throw APIError.apiError(message)
                }
                
                throw APIError.requestFailed
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("❌ 无法解析API响应")
            throw APIError.invalidResponse
        }
        
        print("✅ API调用成功")
        return content
    }
    
    private func buildSkinAnalysisPrompt(symptoms: [String]) -> String {
        var prompt = """
        作为一名专业的皮肤科医生，请对这张皮肤照片进行详细的医学分析。请用自然、专业的语言提供全面的诊断意见。
        """
        
        if !symptoms.isEmpty {
            prompt += "\n\n患者主诉症状："
            for symptom in symptoms {
                prompt += "\n• \(symptom)"
            }
        }
        
        prompt += """
        
        请以专业医生的角度，用自然流畅的语言进行详细分析。请像真正的医生一样，用温和、专业的语调回答。
        
        在回答中请自然地组织内容，可能包括：
        - 对图片的专业观察和描述
        - 可能的诊断分析和医学解释
        - 具体的治疗建议和处理方案
        - 日常护理指导和预防措施
        - 何时需要就医的建议
        
        **重要格式要求**：
        - 重要的医学术语和关键诊断请用 **加粗** 显示
        - 重要的注意事项和警告信息请用 **加粗** 显示
        - 药物名称和治疗方法请用 **加粗** 显示
        - 不要使用机械化的编号格式，要自然流畅
        
        请确保回答既专业又易懂，让患者能够清楚理解病情和处理方案。
        直接返回Markdown格式的文本。
        """
        
        return prompt
    }
    
    private func parseSkinAnalysisResponse(_ response: String) -> SkinAnalysisResult {
        // 现在直接返回Markdown格式的文本
        return SkinAnalysisResult(
            possibleConditions: [],
            description: response, // 直接使用Markdown文本
            recommendations: [],
            needMedicalAttention: response.lowercased().contains("就医") || response.lowercased().contains("医院"),
            severity: determineSeverity(from: response),
            dailyCare: []
        )
    }
    
    private func determineSeverity(from text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("紧急") || lowercased.contains("立即") || lowercased.contains("严重") {
            return "high"
        } else if lowercased.contains("建议就医") || lowercased.contains("需要治疗") {
            return "medium"
        } else {
            return "low"
        }
    }
    
    private func parseSymptomAnalysisResponse(_ response: String) -> SymptomAnalysisResult {
        // 清理响应文本（移除可能的代码块标记）
        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedResponse.hasPrefix("```json") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```json", with: "")
        }
        if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
        }
        if cleanedResponse.hasSuffix("```") {
            cleanedResponse = String(cleanedResponse.dropLast(3))
        }
        cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试解析JSON响应
        if let data = cleanedResponse.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            let possibleCauses = json["1. 可能的病因"] as? [String] ?? json["可能的病因"] as? [String] ?? []
            let recommendations = json["2. 建议采取的措施"] as? [String] ?? json["建议采取的措施"] as? [String] ?? []
            let dailyCare = json["4. 日常护理建议"] as? [String] ?? json["日常护理建议"] as? [String] ?? []
            
            // 处理紧急程度（可能是字符串或数组）
            var urgencyItems: [String] = []
            if let urgencyString = json["3. 是否需要就医及紧急程度"] as? String ?? json["是否需要就医及紧急程度"] as? String {
                urgencyItems = [urgencyString]
            } else if let urgencyArray = json["3. 是否需要就医及紧急程度"] as? [String] ?? json["是否需要就医及紧急程度"] as? [String] {
                urgencyItems = urgencyArray
            }
            
            // 构建格式化的分析结果
            var formattedAnalysis = ""
            
            if !possibleCauses.isEmpty {
                formattedAnalysis += "**1. 可能的病因：**\n"
                for cause in possibleCauses {
                    formattedAnalysis += "• \(cause)\n"
                }
                formattedAnalysis += "\n"
            }
            
            if !recommendations.isEmpty {
                formattedAnalysis += "**2. 建议采取的措施：**\n"
                for recommendation in recommendations {
                    formattedAnalysis += "• \(recommendation)\n"
                }
                formattedAnalysis += "\n"
            }
            
            if !urgencyItems.isEmpty {
                formattedAnalysis += "**3. 是否需要就医及紧急程度：**\n"
                for item in urgencyItems {
                    formattedAnalysis += "• \(item)\n"
                }
                formattedAnalysis += "\n"
            }
            
            if !dailyCare.isEmpty {
                formattedAnalysis += "**4. 日常护理建议：**\n"
                for care in dailyCare {
                    formattedAnalysis += "• \(care)\n"
                }
            }
            
            return SymptomAnalysisResult(
                possibleCauses: possibleCauses,
                recommendations: recommendations,
                urgency: urgencyItems.joined(separator: " "),
                dailyCare: dailyCare,
                fullAnalysis: formattedAnalysis.isEmpty ? response : formattedAnalysis
            )
        }
        
        // 现在直接返回Markdown格式的文本
        return SymptomAnalysisResult(
            possibleCauses: [],
            recommendations: [],
            urgency: determineUrgency(from: response),
            dailyCare: [],
            fullAnalysis: response // 直接使用Markdown文本
        )
    }
    
    private func determineUrgency(from text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("紧急") || lowercased.contains("立即就医") {
            return "紧急"
        } else if lowercased.contains("建议就医") || lowercased.contains("尽快就医") {
            return "建议就医"
        } else {
            return "观察"
        }
    }
    
    private func parseReportInterpretation(_ response: String) -> ReportInterpretation {
        return ReportInterpretation(
            abnormalIndicators: [],
            riskAssessment: "",
            lifestyleAdvice: [],
            followUpRecommendations: [],
            fullInterpretation: response
        )
    }
    
    private func parseMedicationGuidance(_ response: String) -> MedicationGuidance {
        return MedicationGuidance(
            dosageInstructions: "",
            precautions: [],
            sideEffects: [],
            interactions: [],
            storage: "",
            fullGuidance: response
        )
    }
}

// MARK: - 错误类型
enum APIError: LocalizedError {
    case invalidURL
    case requestFailed
    case invalidResponse
    case imageProcessingFailed
    case networkError(String)
    case apiError(String)
    case timeout
    case imageTooLarge
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API地址"
        case .requestFailed:
            return "网络请求失败，请检查网络连接后重试"
        case .invalidResponse:
            return "服务器响应格式错误"
        case .imageProcessingFailed:
            return "图片处理失败，请尝试选择其他图片"
        case .networkError(let message):
            return "网络错误：\(message)"
        case .apiError(let message):
            return "API错误：\(message)"
        case .timeout:
            return "请求超时，请检查网络连接后重试"
        case .imageTooLarge:
            return "图片文件过大，请选择较小的图片"
        }
    }
}

// MARK: - 响应模型
struct SkinAnalysisResult {
    let possibleConditions: [PossibleCondition]
    let description: String
    let recommendations: [String]
    let needMedicalAttention: Bool
    let severity: String
    let dailyCare: [String]
}

struct PossibleCondition {
    let name: String
    let probability: Double
}

struct SymptomAnalysisResult {
    let possibleCauses: [String]
    let recommendations: [String]
    let urgency: String
    let dailyCare: [String]
    let fullAnalysis: String
}

struct ReportInterpretation {
    let abnormalIndicators: [String]
    let riskAssessment: String
    let lifestyleAdvice: [String]
    let followUpRecommendations: [String]
    let fullInterpretation: String
}

struct MedicationGuidance {
    let dosageInstructions: String
    let precautions: [String]
    let sideEffects: [String]
    let interactions: [String]
    let storage: String
    let fullGuidance: String
}


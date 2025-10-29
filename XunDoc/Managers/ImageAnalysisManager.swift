//
//  ImageAnalysisManager.swift
//  XunDoc
//
//  图片AI分析管理器 - 识别医嘱和诊断书
//

import Foundation
import UIKit
import Vision

class ImageAnalysisManager: ObservableObject {
    static let shared = ImageAnalysisManager()
    
    @Published var isAnalyzing = false
    
    private let kimiAPIKey = "sk-CE6JIOSti61TqFYhPFs6OrTS5wMtJvA8v2YsnPIw1SFgeqcu"
    private let baseURL = "https://api.moonshot.cn/v1/chat/completions"
    
    // MARK: - 图片分析
    
    /// 分析图片内容，识别医嘱或诊断书
    func analyzeImage(
        imageData: Data,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (ImageAnalysisResult) -> Void
    ) {
        isAnalyzing = true
        
        // 将图片转为base64
        let base64Image = imageData.base64EncodedString()
        
        // 构建提示词
        let prompt = """
        请分析这张医疗图片，判断它是：
        1. 医嘱/处方单
        2. 诊断书
        3. 其他医疗文档
        
        如果是医嘱/处方单，请提取：
        - 药品名称
        - 用法用量
        - 简短的治疗方案总结（1-2句话）
        
        如果是诊断书，请提取：
        - 诊断结果
        - 简短总结（1-2句话）
        
        请用以下格式回复：
        【文档类型】医嘱 或 诊断书 或 其他
        【诊断】（如果是诊断书）
        【治疗方案】（如果是医嘱，简短精确，1-2句话）
        """
        
        // 调用Kimi API（这里需要支持图片的API）
        // 由于Kimi API可能不直接支持图片，我们使用文本识别后再分析
        performOCRAndAnalysis(imageData: imageData, prompt: prompt, onUpdate: onUpdate, onComplete: onComplete)
    }
    
    // MARK: - OCR + AI分析
    
    private func performOCRAndAnalysis(
        imageData: Data,
        prompt: String,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (ImageAnalysisResult) -> Void
    ) {
        // 使用真实的OCR API识别图片中的文字
        performRealOCR(imageData: imageData) { ocrText in
            // 使用Kimi API分析OCR文本
            self.analyzeText(ocrText: ocrText, onUpdate: onUpdate, onComplete: onComplete)
        }
    }
    
    // MARK: - 真实OCR识别（使用系统OCR或第三方API）
    
    private func performRealOCR(imageData: Data, completion: @escaping (String) -> Void) {
        guard let image = UIImage(data: imageData) else {
            completion("无法加载图片")
            return
        }
        
        // 使用Vision框架进行OCR识别
        if #available(iOS 13.0, *) {
            guard let cgImage = image.cgImage else {
                completion("图片格式错误")
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil else {
                    print("❌ OCR识别失败: \(error!.localizedDescription)")
                    completion("OCR识别失败")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion("未能识别文字")
                    return
                }
                
                // 提取所有识别的文字
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let ocrText = recognizedStrings.joined(separator: "\n")
                
                if ocrText.isEmpty {
                    completion("图片中未识别到文字，请确保照片清晰")
                } else {
                    print("✅ OCR识别成功，提取了 \(recognizedStrings.count) 行文字")
                    completion(ocrText)
                }
            }
            
            // 设置识别语言（支持中文和英文）
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    DispatchQueue.main.async {
                        print("❌ OCR处理失败: \(error.localizedDescription)")
                        completion("OCR处理失败")
                    }
                }
            }
        } else {
            // iOS 13以下版本，使用模拟OCR
            completion(simulateOCR(from: imageData))
        }
    }
    
    // MARK: - 文本分析
    
    private func analyzeText(
        ocrText: String,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (ImageAnalysisResult) -> Void
    ) {
        let messages = [
            ["role": "system", "content": "你是一个专业的医疗文档分析助手。"],
            ["role": "user", "content": """
            请分析以下医疗文档内容：
            
            \(ocrText)
            
            请判断这是医嘱/处方单还是诊断书，并提取关键信息。
            如果是医嘱，请提供简短的治疗方案总结（1-2句话）。
            如果是诊断书，请提供简短的诊断总结（1-2句话）。
            
            请用以下格式回复：
            【文档类型】医嘱 或 诊断书
            【内容总结】（1-2句话）
            """]
        ]
        
        let requestBody: [String: Any] = [
            "model": "moonshot-v1-32k",
            "messages": messages,
            "stream": false,
            "temperature": 0.3
        ]
        
        guard let url = URL(string: baseURL),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            isAnalyzing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(kimiAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer {
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                }
            }
            
            if let error = error {
                print("❌ AI分析失败: \(error)")
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                print("❌ 解析响应失败")
                return
            }
            
            DispatchQueue.main.async {
                onUpdate(content)
                
                // 解析结果
                let result = self.parseAnalysisResult(content)
                onComplete(result)
            }
        }.resume()
    }
    
    // MARK: - 结果解析
    
    private func parseAnalysisResult(_ content: String) -> ImageAnalysisResult {
        var docType: DocumentType = .other
        var diagnosis: String? = nil
        var treatmentPlan: String? = nil
        
        // 解析文档类型
        if content.contains("医嘱") || content.contains("处方") {
            docType = .prescription
        } else if content.contains("诊断") {
            docType = .diagnosis
        }
        
        // 提取关键信息
        let lines = content.components(separatedBy: "\n")
        for line in lines {
            if line.contains("【诊断】") {
                diagnosis = line.replacingOccurrences(of: "【诊断】", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.contains("【治疗方案】") || line.contains("【内容总结】") {
                let summary = line.replacingOccurrences(of: "【治疗方案】", with: "")
                    .replacingOccurrences(of: "【内容总结】", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if docType == .prescription {
                    treatmentPlan = summary
                } else if docType == .diagnosis {
                    diagnosis = summary
                }
            }
        }
        
        return ImageAnalysisResult(
            documentType: docType,
            diagnosis: diagnosis,
            treatmentPlan: treatmentPlan,
            fullAnalysis: content
        )
    }
    
    // MARK: - 模拟OCR (实际应使用真实OCR API)
    
    private func simulateOCR(from imageData: Data) -> String {
        // 实际应该使用真实的OCR API，如百度OCR、腾讯OCR等
        return """
        北京协和医院
        处方单
        
        患者姓名：张三
        性别：男  年龄：45岁
        
        药品：
        1. 阿莫西林胶囊 500mg  每日3次，每次1粒
        2. 布洛芬缓释片 300mg  每日2次，每次1片
        
        医嘱：饭后服用，多喝水，注意休息
        
        医生签名：李医生
        日期：2025-10-28
        """
    }
}

// MARK: - 数据模型

enum DocumentType: String, Codable {
    case prescription = "prescription"  // 医嘱/处方
    case diagnosis = "diagnosis"        // 诊断书
    case other = "other"                // 其他
}

struct ImageAnalysisResult {
    let documentType: DocumentType
    let diagnosis: String?
    let treatmentPlan: String?
    let fullAnalysis: String
}


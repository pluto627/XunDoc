//
//  SpeechRecognitionManager.swift
//  XunDoc
//
//  语音识别管理器 - 将录音转为文字
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognitionManager: ObservableObject {
    static let shared = SpeechRecognitionManager()
    
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0
    @Published var transcriptionError: String?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        // 使用中文识别器
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    }
    
    // MARK: - 权限检查
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("✅ 语音识别权限已授权")
                    completion(true)
                case .denied:
                    print("❌ 用户拒绝了语音识别权限")
                    completion(false)
                case .restricted:
                    print("❌ 语音识别功能受限")
                    completion(false)
                case .notDetermined:
                    print("⚠️ 语音识别权限未确定")
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - 音频转文字
    
    /// 将音频数据转换为文字
    func transcribeAudio(audioData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        // 检查权限
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            requestAuthorization { authorized in
                if authorized {
                    self.performTranscription(audioData: audioData, completion: completion)
                } else {
                    completion(.failure(TranscriptionError.notAuthorized))
                }
            }
            return
        }
        
        performTranscription(audioData: audioData, completion: completion)
    }
    
    private func performTranscription(audioData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            completion(.failure(TranscriptionError.recognizerNotAvailable))
            return
        }
        
        DispatchQueue.main.async {
            self.isTranscribing = true
            self.transcriptionProgress = 0
            self.transcriptionError = nil
        }
        
        // 创建临时音频文件
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        
        do {
            try audioData.write(to: tempURL)
            print("📝 音频文件已写入临时目录: \(tempURL.lastPathComponent)")
        } catch {
            DispatchQueue.main.async {
                self.isTranscribing = false
                completion(.failure(error))
            }
            return
        }
        
        // 创建识别请求
        let request = SFSpeechURLRecognitionRequest(url: tempURL)
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        
        // 如果支持设备上识别（需要 iOS 13+）
        if #available(iOS 13, *) {
            request.requiresOnDeviceRecognition = false // 使用云端识别以获得更好的准确度
        }
        
        var finalTranscription = ""
        
        // 开始识别
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                finalTranscription = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    // 根据是否是最终结果更新进度
                    if result.isFinal {
                        self.transcriptionProgress = 1.0
                    } else {
                        // 估算进度（基于识别的字符数）
                        self.transcriptionProgress = min(0.9, Double(finalTranscription.count) / 200.0)
                    }
                }
                
                print("🎤 识别中: \(finalTranscription)")
                
                // 如果是最终结果
                if result.isFinal {
                    DispatchQueue.main.async {
                        self.isTranscribing = false
                        self.transcriptionProgress = 1.0
                    }
                    
                    // 清理临时文件
                    try? FileManager.default.removeItem(at: tempURL)
                    
                    print("✅ 识别完成: \(finalTranscription)")
                    completion(.success(finalTranscription))
                }
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isTranscribing = false
                    self.transcriptionError = error.localizedDescription
                }
                
                // 清理临时文件
                try? FileManager.default.removeItem(at: tempURL)
                
                print("❌ 识别失败: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // 取消识别
    func cancelTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
        transcriptionProgress = 0
    }
    
    // MARK: - 智能对话分析
    
    /// 智能识别并区分医生和患者的对话
    func transcribeWithSpeakerDetection(audioData: Data, completion: @escaping (Result<[(role: String, text: String)], Error>) -> Void) {
        // 先进行完整转录
        transcribeAudio(audioData: audioData) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fullText):
                // 分析文本,识别对话角色
                let dialogues = self.analyzeDialogueRoles(from: fullText)
                completion(.success(dialogues))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 分析对话文本,识别医生和患者
    private func analyzeDialogueRoles(from text: String) -> [(role: String, text: String)] {
        var dialogues: [(role: String, text: String)] = []
        
        // 按标点符号分割对话
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: "。！？"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // 医生常用词汇
        let doctorKeywords = ["医生", "大夫", "检查", "诊断", "处方", "建议", "治疗", "药物", "症状",
                            "CT", "B超", "化验", "复查", "开药", "吃药", "休息", "注意", "禁忌"]
        
        // 患者常用词汇
        let patientKeywords = ["我", "我的", "不舒服", "疼", "痛", "难受", "头晕", "发烧", "咳嗽",
                              "请问", "医生", "怎么办", "谢谢", "好的", "明白了"]
        
        for sentence in sentences {
            // 统计关键词出现次数
            let doctorScore = doctorKeywords.reduce(0) { count, keyword in
                count + (sentence.contains(keyword) ? 1 : 0)
            }
            
            let patientScore = patientKeywords.reduce(0) { count, keyword in
                count + (sentence.contains(keyword) ? 1 : 0)
            }
            
            // 判断角色
            let role: String
            if doctorScore > patientScore {
                role = "医生"
            } else if patientScore > doctorScore {
                role = "患者"
            } else {
                // 如果无法判断,默认为患者(因为患者通常先说话)
                role = dialogues.isEmpty ? "患者" : "医生"
            }
            
            dialogues.append((role: role, text: sentence))
        }
        
        return dialogues
    }
    
    // MARK: - 错误类型
    
    enum TranscriptionError: LocalizedError {
        case notAuthorized
        case recognizerNotAvailable
        case audioFileError
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "未授权语音识别权限"
            case .recognizerNotAvailable:
                return "语音识别服务不可用"
            case .audioFileError:
                return "音频文件读取失败"
            }
        }
    }
}


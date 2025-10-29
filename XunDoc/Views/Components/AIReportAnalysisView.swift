//
//  AIReportAnalysisView.swift
//  XunDoc
//
//  AI报告解读和问答组件 - 包含自动解读和问答功能
//

import SwiftUI

struct AIReportAnalysisView: View {
    let reportData: String  // 报告原始数据
    let reportType: String  // 报告类型（如："检查报告"、"处方"等）
    let attachmentsHash: String  // 附件的哈希值，用于判断是否有变化
    
    @EnvironmentObject var healthDataManager: HealthDataManager
    @StateObject private var kimiManager = KimiAPIManager.shared
    
    @State private var aiAnalysis = ""  // AI自动生成的解读
    @State private var isAnalyzing = false
    @State private var isAnalysisExpanded = false  // 解读是否展开
    @State private var question = ""
    @State private var showHistory = false
    @State private var conversationPairs: [(question: String, answer: String, isExpanded: Bool)] = []
    @State private var lastAnalyzedHash = ""  // 上次分析时的附件哈希值
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Divider()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. AI解读报告部分（可折叠）
                        AIAnalysisSection(
                            analysis: aiAnalysis,
                            isAnalyzing: isAnalyzing,
                            isExpanded: $isAnalysisExpanded,
                            onGenerate: {
                                generateAnalysis()
                            }
                        )
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // 2. AI问询部分
                        AIQuestionSection(
                            conversationPairs: $conversationPairs,
                            onToggle: { index in
                                conversationPairs[index].isExpanded.toggle()
                                saveConversations()  // 保存状态
                            }
                        )
                    }
                    .padding(.vertical, 16)
                    .padding(.bottom, 120)  // 增加底部间距到120，确保不被键盘遮挡
                }
                .onTapGesture {
                    // 点击ScrollView区域时关闭键盘
                    hideKeyboard()
                }
                
                Divider()
                
                // 底部输入框
                AIInputArea(
                    question: $question,
                    isLoading: kimiManager.isLoading,
                    onSend: sendQuestion
                )
            }
            .background(Color.appBackgroundColor)
        }
        .onAppear {
            loadSavedAnalysis()
            loadSavedConversations()
            loadLastAnalyzedHash()
            
            // 🆕 不再自动分析，只加载已有的分析结果
            // 分析将在用户归档记录时触发
            if !aiAnalysis.isEmpty {
                print("✅ 加载了已保存的AI分析结果")
            } else {
                print("ℹ️ 暂无分析结果，等待用户归档后自动分析")
            }
        }
    }
    
    // 隐藏键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 加载保存的解读
    private func loadSavedAnalysis() {
        let key = "ai_analysis_\(reportData.hashValue)"
        if let saved = UserDefaults.standard.string(forKey: key) {
            aiAnalysis = saved
            print("✅ 加载了保存的AI解读")
        }
    }
    
    // 保存解读到本地
    private func saveAnalysis(_ analysis: String) {
        let key = "ai_analysis_\(reportData.hashValue)"
        UserDefaults.standard.set(analysis, forKey: key)
        
        // 保存当前的附件hash
        saveLastAnalyzedHash(attachmentsHash)
        
        print("💾 保存AI解读到本地（hash: \(attachmentsHash)）")
    }
    
    // 加载上次分析时的hash
    private func loadLastAnalyzedHash() {
        let key = "ai_analysis_hash_\(reportData.hashValue)"
        if let saved = UserDefaults.standard.string(forKey: key) {
            lastAnalyzedHash = saved
            print("✅ 加载了上次分析的hash: \(saved)")
        }
    }
    
    // 保存分析时的hash
    private func saveLastAnalyzedHash(_ hash: String) {
        let key = "ai_analysis_hash_\(reportData.hashValue)"
        UserDefaults.standard.set(hash, forKey: key)
        lastAnalyzedHash = hash
    }
    
    // 生成AI自动解读
    private func generateAnalysis() {
        
        isAnalyzing = true
        
        let analysisPrompt = """
        你是一位资深的医学AI助手。请仔细分析以下医疗数据，并给出专业的医学解读：
        
        【医疗数据】
        \(reportData)
        
        请按以下格式详细分析，用通俗易懂的语言：
        
        ## 📊 异常指标分析
        **重点**：只列出异常或需要注意的指标！正常指标无需说明。
        - 列出所有异常指标的名称、数值和正常范围
        - 解释每个异常指标的临床意义
        - 说明可能的原因和影响
        
        ## 🩺 诊断分析
        - 基于异常指标，分析可能的疾病或健康问题
        - 说明诊断依据（引用具体的异常指标）
        - 评估病情严重程度（轻度/中度/重度）
        - 是否需要进一步检查
        
        ## 💊 治疗方案详细建议
        **必须详细具体**：
        
        1️⃣ **药物治疗**（如报告中有处方）
        - 每种药物的名称和作用机制
        - 为什么需要这个药物（针对哪个问题）
        - 具体用法用量和服用时间
        - 可能的副作用和注意事项
        - 用药期间的监测要求
        
        2️⃣ **非药物治疗**
        - 生活方式调整（具体措施）
        - 饮食建议（什么能吃，什么不能吃）
        - 运动建议（什么运动合适，强度如何）
        - 作息调整
        
        3️⃣ **复查计划**
        - 多久后需要复查
        - 需要复查哪些项目
        - 复查的目的
        
        ## ⚠️ 重要提示
        - 是否需要尽快就医（紧急程度）
        - 特别需要注意的危险信号
        - 日常生活中需要避免的事项
        
        **注意**：
        - 正常指标无需说明，只关注异常项
        - 治疗方案要具体到剂量、时间、方法
        - 用简单易懂的语言，避免过多医学术语
        """
        
        kimiManager.askQuestion(
            question: analysisPrompt,
            context: reportData,
            onUpdate: { answer in
                aiAnalysis = answer
            },
            onComplete: { finalAnswer in
                isAnalyzing = false
                aiAnalysis = finalAnswer
                saveAnalysis(finalAnswer)  // 保存到本地
            }
        )
    }
    
    // 加载保存的对话
    private func loadSavedConversations() {
        let key = "ai_conversations_\(reportData.hashValue)"
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([ConversationPair].self, from: data) {
            conversationPairs = decoded.map { ($0.question, $0.answer, false) }
            print("✅ 加载了 \(conversationPairs.count) 条对话")
        }
    }
    
    // 保存对话到本地
    private func saveConversations() {
        let key = "ai_conversations_\(reportData.hashValue)"
        let pairs = conversationPairs.map { ConversationPair(question: $0.question, answer: $0.answer) }
        if let encoded = try? JSONEncoder().encode(pairs) {
            UserDefaults.standard.set(encoded, forKey: key)
            print("💾 保存了 \(conversationPairs.count) 条对话")
        }
    }
    
    // 发送用户问题
    private func sendQuestion() {
        guard !question.isEmpty else { return }
        
        let userQuestion = question
        question = ""
        
        // 隐藏键盘
        hideKeyboard()
        
        // 添加到对话列表
        conversationPairs.insert((question: userQuestion, answer: "", isExpanded: true), at: 0)
        
        kimiManager.askQuestion(
            question: userQuestion,
            context: reportData,
            onUpdate: { answer in
                if !conversationPairs.isEmpty {
                    conversationPairs[0].answer = answer
                }
            },
            onComplete: { finalAnswer in
                // 完成后保存
                if !conversationPairs.isEmpty {
                    conversationPairs[0].answer = finalAnswer
                    saveConversations()  // 永久保存问答
                }
            }
        )
    }
}

// MARK: - 对话对数据模型（用于持久化）
struct ConversationPair: Codable {
    let question: String
    let answer: String
}

// MARK: - AI解读报告部分（可折叠）
struct AIAnalysisSection: View {
    let analysis: String
    let isAnalyzing: Bool
    @Binding var isExpanded: Bool
    let onGenerate: () -> Void  // 生成分析的回调
    
    private let previewLineLimit = 5  // 折叠时显示的行数
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(.accentPrimary)
                
                Text("AI解读报告")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // 内容
            VStack(alignment: .leading, spacing: 12) {
                if isAnalyzing {
                    // 加载状态
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                        
                        Text("AI正在分析报告内容...")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if analysis.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.textTertiary.opacity(0.6))
                        
                        Text("AI分析生成中...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                        
                        Text("归档时已自动开始分析，请稍后刷新查看")
                            .font(.system(size: 12))
                            .foregroundColor(.textTertiary)
                            .multilineTextAlignment(.center)
                        
                        // 手动生成分析按钮（备用）
                        Button(action: onGenerate) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                Text("手动生成分析")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.accentPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.accentPrimary, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // AI分析内容
                    Text(analysis)
                        .font(.system(size: 14))
                        .foregroundColor(.textPrimary)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                        .lineLimit(isExpanded ? nil : previewLineLimit)
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                    
                    // 查看详情按钮
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(isExpanded ? "收起" : "查看详情")
                                .font(.system(size: 13, weight: .medium))
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.accentPrimary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentPrimary.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondaryBackgroundColor)
            )
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - AI问询部分
struct AIQuestionSection: View {
    @Binding var conversationPairs: [(question: String, answer: String, isExpanded: Bool)]
    let onToggle: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "message")
                    .font(.system(size: 18))
                    .foregroundColor(.accentPrimary)
                
                Text("AI问询")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // 提示区域
            VStack(alignment: .leading, spacing: 8) {
                Text("基于报告内容提问")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textSecondary)
                
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.accentPrimary)
                    
                    Text("您好！我是AI健康助手，我可以基于您的检查报告和处方内容回答相关问题。请问有什么想了解的吗？")
                        .font(.system(size: 14))
                        .foregroundColor(.textPrimary)
                        .lineSpacing(4)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentPrimary.opacity(0.08))
                )
            }
            .padding(.horizontal, 20)
            
            // 对话历史
            if !conversationPairs.isEmpty {
                VStack(spacing: 10) {
                    ForEach(conversationPairs.indices, id: \.self) { index in
                        ConversationPairCard(
                            question: conversationPairs[index].question,
                            answer: conversationPairs[index].answer,
                            isExpanded: conversationPairs[index].isExpanded,
                            onToggle: {
                                onToggle(index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - 对话对卡片
struct ConversationPairCard: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 问题（始终显示）
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    
                    Text(question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .lineLimit(isExpanded ? nil : 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                .padding(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 回答（展开时显示）
            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)
                
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(.accentPrimary)
                    
                    if answer.isEmpty {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                                .scaleEffect(0.8)
                            
                            Text("AI正在回答...")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        Text(answer)
                            .font(.system(size: 14))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(5)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.accentPrimary.opacity(0.05))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.dividerColor, lineWidth: 1)
        )
    }
}

// MARK: - 输入区域
struct AIInputArea: View {
    @Binding var question: String
    let isLoading: Bool
    let onSend: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("请输入您的问题...", text: $question, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(1...3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.secondaryBackgroundColor)
                )
                .focused($isFocused)
                .onSubmit {
                    if !question.isEmpty && !isLoading {
                        onSend()
                        isFocused = false
                    }
                }
            
            // 发送按钮
            Button(action: {
                onSend()
                isFocused = false  // 发送后关闭键盘
            }) {
                ZStack {
                    Circle()
                        .fill(question.isEmpty ? Color.textTertiary : Color.accentPrimary)
                        .frame(width: 44, height: 44)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(question.isEmpty || isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.cardBackgroundColor
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -3)
        )
    }
}

// MARK: - 使用示例
/*
 在报告详情页面底部添加：
 
 struct ReportDetailView: View {
     let report: MedicalReport
     
     var body: some View {
         VStack(spacing: 0) {
             // 报告主要内容
             ScrollView {
                 // ...报告数据展示
             }
             
             // AI解读和问答
             AIReportAnalysisView(
                 reportData: buildReportContext(report),
                 reportType: "检查报告"
             )
             .environmentObject(healthDataManager)
         }
     }
     
     private func buildReportContext(_ report: MedicalReport) -> String {
         var context = ""
         context += "报告类型：\(report.reportType.displayName)\n"
         context += "检查日期：\(formatDate(report.date))\n"
         context += "医院：\(report.hospitalName)\n"
         // ... 添加更多上下文信息
         return context
     }
 }
 */

#Preview {
    AIReportAnalysisView(
        reportData: "血常规检查报告...",
        reportType: "检查报告",
        attachmentsHash: "preview_hash"
    )
    .environmentObject(HealthDataManager.shared)
}


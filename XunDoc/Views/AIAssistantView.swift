//
//  AIAssistantView.swift
//  XunDoc
//
//  AI问答助手视图
//

import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @StateObject private var kimiManager = KimiAPIManager.shared
    @StateObject private var reportManager = MedicalReportManager.shared
    @StateObject private var transcriptionManager = AudioTranscriptionManager.shared
    
    @State private var question = ""
    @State private var currentAnswer = ""
    @State private var showingContextPicker = false
    @State private var selectedContextType: ContextType?
    
    enum ContextType {
        case healthRecord
        case report
        case conversation
        case prescription
    }
    
    var histories: [AIConversationHistory] {
        return kimiManager.conversationHistories
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            AIAssistantHeader()
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            Divider()
            
            // 对话历史
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if histories.isEmpty {
                        AIEmptyHistoryView()
                            .padding(.top, 60)
                    } else {
                        ForEach(histories) { history in
                            AIConversationCard(
                                history: history,
                                onToggleExpand: {
                                    kimiManager.toggleExpand(history.id)
                                },
                                onDelete: {
                                    kimiManager.deleteHistory(history.id)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)  // 为底部输入框留出空间
            }
            
            // 底部问答区域
            VStack(spacing: 0) {
                Divider()
                
                // 当前回答(流式显示)
                if !currentAnswer.isEmpty {
                    StreamingAnswerView(answer: currentAnswer)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }
                
                // 输入框
                HStack(spacing: 12) {
                    // 上下文选择按钮
                    Menu {
                        Button(action: {
                            selectedContextType = .healthRecord
                            showingContextPicker = true
                        }) {
                            Label("病历记录", systemImage: "doc.text")
                        }
                        
                        Button(action: {
                            selectedContextType = .report
                            showingContextPicker = true
                        }) {
                            Label("检查报告", systemImage: "doc.richtext")
                        }
                        
                        Button(action: {
                            selectedContextType = .conversation
                            showingContextPicker = true
                        }) {
                            Label("对话录音", systemImage: "waveform")
                        }
                    } label: {
                        Image(systemName: "paperclip.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentPrimary)
                    }
                    
                    // 输入框
                    TextField("询问您的健康问题...", text: $question, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(1...4)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.secondaryBackgroundColor)
                        )
                    
                    // 发送按钮
                    Button(action: sendQuestion) {
                        ZStack {
                            Circle()
                                .fill(question.isEmpty ? Color.textTertiary : Color.accentPrimary)
                                .frame(width: 44, height: 44)
                            
                            if kimiManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(question.isEmpty || kimiManager.isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color.cardBackgroundColor)
        }
        .background(Color.appBackgroundColor)
    }
    
    private func sendQuestion() {
        let questionText = question
        question = ""  // 清空输入框
        currentAnswer = ""
        
        
        // TODO: 根据selectedContextType构建上下文
        let context = ""
        
        kimiManager.askQuestion(
            question: questionText,
            context: context,
            onUpdate: { answer in
                currentAnswer = answer
            },
            onComplete: { finalAnswer in
                currentAnswer = ""
            }
        )
    }
}

// MARK: - AI助手头部
struct AIAssistantHeader: View {
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentPrimary, Color.accentTertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI健康助手")
                        .font(.appTitle())
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("随时为您解答")
                            .font(.appCaption())
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button(action: {}) {
                    Label("使用说明", systemImage: "questionmark.circle")
                }
                
                Button(role: .destructive, action: {
                    KimiAPIManager.shared.clearAllHistories()
                }) {
                    Label("清空历史", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - 对话卡片
struct AIConversationCard: View {
    let history: AIConversationHistory
    let onToggleExpand: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 问题标题(始终显示)
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentPrimary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(history.question)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .lineLimit(history.isExpanded ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(dateFormatter.string(from: history.timestamp))
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: history.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                .padding(16)
            }
            
            // 回答内容(展开时显示)
            if history.isExpanded && !history.answer.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(.accentPrimary)
                    
                    Text(history.answer)
                        .font(.system(size: 14))
                        .foregroundColor(.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.secondaryBackgroundColor.opacity(0.5))
                
                // 操作按钮
                HStack(spacing: 16) {
                    Button(action: {
                        UIPasteboard.general.string = history.answer
                    }) {
                        Label("复制", systemImage: "doc.on.doc")
                            .font(.system(size: 13))
                            .foregroundColor(.accentPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showDeleteConfirm = true
                    }) {
                        Label("删除", systemImage: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color.cardBackgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dividerColor, lineWidth: 1)
        )
        .alert("删除对话", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除这条对话记录吗?")
        }
    }
}

// MARK: - 流式回答视图
struct StreamingAnswerView: View {
    let answer: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 18))
                .foregroundColor(.accentPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("AI正在回答...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(4)
                
                // 打字指示器
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.accentPrimary)
                            .frame(width: 6, height: 6)
                            .scaleEffect(0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: answer.count
                            )
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.accentPrimary.opacity(0.1))
        )
    }
}

// MARK: - AI助手空状态视图
struct AIEmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentPrimary.opacity(0.2), Color.accentTertiary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.accentPrimary)
            }
            
            VStack(spacing: 8) {
                Text("AI助手随时为您服务")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("您可以询问关于健康记录、检查报告、用药等任何问题")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // 示例问题
            VStack(alignment: .leading, spacing: 12) {
                Text("试试这些问题:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                SampleQuestion(text: "我的血常规报告怎么样?")
                SampleQuestion(text: "这个药物应该怎么吃?")
                SampleQuestion(text: "根据我的症状应该注意什么?")
            }
            .padding(.top, 20)
        }
    }
}

struct SampleQuestion: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondaryBackgroundColor)
        )
    }
}

#Preview {
    AIAssistantView()
        .environmentObject(HealthDataManager.shared)
}


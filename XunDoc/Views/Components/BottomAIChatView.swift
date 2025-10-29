//
//  BottomAIChatView.swift
//  XunDoc
//
//  底部AI问答组件 - 可嵌入任何页面
//

import SwiftUI

struct BottomAIChatView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @StateObject private var kimiManager = KimiAPIManager.shared
    
    @State private var question = ""
    @State private var currentAnswer = ""
    @State private var showHistory = false
    
    let contextData: String  // 页面上下文数据（如病历内容、报告内容等）
    
    var histories: [AIConversationHistory] {
        return Array(kimiManager.conversationHistories.prefix(5))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 对话历史（折叠式）
            if showHistory && !histories.isEmpty {
                VStack(spacing: 0) {
                    // 历史标题栏
                    HStack {
                        Text("最近对话")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showHistory = false
                            }
                        }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.secondaryBackgroundColor)
                    
                    Divider()
                    
                    // 历史列表（最多显示5条）
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(histories) { history in
                                CompactHistoryCard(
                                    history: history,
                                    onToggle: {
                                        kimiManager.toggleExpand(history.id)
                                    }
                                )
                            }
                        }
                        .padding(12)
                    }
                    .frame(maxHeight: 300)
                    .background(Color.appBackgroundColor)
                    
                    Divider()
                }
                .transition(.move(edge: .bottom))
            }
            
            // 流式回答显示
            if !currentAnswer.isEmpty {
                ScrollView(showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.accentPrimary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AI回答")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.textSecondary)
                            
                            Text(currentAnswer)
                                .font(.system(size: 14))
                                .foregroundColor(.textPrimary)
                                .lineSpacing(4)
                                .textSelection(.enabled)
                            
                            // 打字动画
                            HStack(spacing: 3) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(Color.accentPrimary)
                                        .frame(width: 5, height: 5)
                                        .opacity(0.6)
                                        .scaleEffect(kimiManager.isLoading ? 1.0 : 0.6)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                                .repeatForever()
                                                .delay(Double(index) * 0.2),
                                            value: kimiManager.isLoading
                                        )
                                }
                            }
                            .opacity(kimiManager.isLoading ? 1 : 0)
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                }
                .frame(maxHeight: 200)
                .background(Color.accentPrimary.opacity(0.08))
                
                Divider()
            }
            
            // 问答输入区
            VStack(spacing: 10) {
                // 历史按钮（有历史时显示）
                if !histories.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showHistory.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14))
                            
                            Text("\(histories.count) 条历史对话")
                                .font(.system(size: 13))
                            
                            Spacer()
                            
                            Image(systemName: showHistory ? "chevron.down" : "chevron.up")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.secondaryBackgroundColor)
                        )
                    }
                    .padding(.horizontal, 16)
                }
                
                // 输入框和发送按钮
                HStack(spacing: 12) {
                    // AI图标提示
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentPrimary, Color.accentTertiary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    
                    // 输入框
                    TextField("询问AI关于此内容的问题...", text: $question, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(1...3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.secondaryBackgroundColor)
                        )
                    
                    // 发送按钮
                    Button(action: sendQuestion) {
                        ZStack {
                            Circle()
                                .fill(question.isEmpty ? Color.textTertiary : Color.accentPrimary)
                                .frame(width: 36, height: 36)
                            
                            if kimiManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(question.isEmpty || kimiManager.isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .padding(.top, 12)
            .background(Color.cardBackgroundColor)
        }
    }
    
    private func sendQuestion() {
        let questionText = question
        question = ""
        currentAnswer = ""
        
        
        // 将页面上下文数据传递给AI
        kimiManager.askQuestion(
            question: questionText,
            context: contextData,
            onUpdate: { answer in
                currentAnswer = answer
            },
            onComplete: { finalAnswer in
                // 3秒后自动收起回答
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        currentAnswer = ""
                    }
                }
            }
        )
    }
}

// MARK: - 紧凑历史卡片
struct CompactHistoryCard: View {
    let history: AIConversationHistory
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                // 问题
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.accentPrimary)
                    
                    Text(history.question)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .lineLimit(history.isExpanded ? nil : 2)
                }
                
                // 回答（展开时显示）
                if history.isExpanded && !history.answer.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(.accentPrimary)
                        
                        Text(history.answer)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(3)
                    }
                    .padding(.top, 4)
                }
                
                // 时间
                Text(formatDate(history.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(history.isExpanded ? Color.accentPrimary.opacity(0.08) : Color.secondaryBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 使用示例
/*
 在任何页面底部添加：
 
 VStack {
     // 页面主要内容
     ScrollView {
         // ...
     }
     
     // 底部AI问答
     BottomAIChatView(contextData: """
         病历内容：...
         报告数据：...
         """)
         .environmentObject(healthDataManager)
 }
 */


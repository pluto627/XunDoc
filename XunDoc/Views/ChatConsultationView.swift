//
//  ChatConsultationView.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI
import UIKit

struct ChatConsultationView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var apiManager: MoonshotAPIManager
    @StateObject private var chatHistoryManager = ChatHistoryManager.shared
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingHistory = false
    @State private var sidebarOffset: CGFloat = -300 // 侧边栏偏移量
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .leading) {
            // 主内容区域（包含消息列表和输入栏）
            VStack(spacing: 0) {
                // 聊天消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            // 欢迎消息
                            if messages.isEmpty {
                                WelcomeMessage()
                                    .padding(.top, 20)
                            }
                            
                            // 聊天消息
                            ForEach(messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            // AI 正在输入指示器
                            if isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                        .padding(.bottom, 100)
                    }
                    .onTapGesture {
                        // 点击消息区域收起键盘
                        hideKeyboard()
                    }
                    .onChange(of: messages.count) { _ in
                        DispatchQueue.main.async {
                            withAnimation {
                                if let lastMessage = messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: isTyping) { _ in
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 输入栏 - 固定在底部
                ChatInputBar(
                    inputText: $inputText,
                    selectedImage: $selectedImage,
                    showingImagePicker: $showingImagePicker,
                    showingCamera: $showingCamera,
                    onSend: sendMessage,
                    onImageSelected: { image in
                        selectedImage = image
                    }
                )
            }
            .background(Color.appBackground)
            .opacity(showingHistory ? 0.3 : 1.0)
            .allowsHitTesting(!showingHistory)
            
            // 左侧滑入的对话历史侧边栏
            if showingHistory {
                ChatHistorySidebar(
                    isShowing: $showingHistory,
                    sidebarOffset: $sidebarOffset,
                    onClose: {
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingHistory = false
                                sidebarOffset = -300
                            }
                        }
                    }
                )
                .environmentObject(chatHistoryManager)
                .transition(.move(edge: .leading))
            }
        }
        .navigationTitle(chatHistoryManager.currentConversation?.title ?? NSLocalizedString("ai_consultation", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            // 左上角 - 对话历史按钮（三个点图标）
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    DispatchQueue.main.async {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingHistory.toggle()
                            sidebarOffset = showingHistory ? 0 : -300
                        }
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }
            
            // 右上角 - 移除按钮，不显示任何内容
        }
        .onAppear {
            loadCurrentConversation()
        }
        .onChange(of: chatHistoryManager.currentConversation) { _ in
            loadCurrentConversation()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        }
        .navigationViewStyle(.stack)
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil else { return }
        
        // 震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 用户消息
        let userMessage = ChatMessage(
            content: inputText.trimmingCharacters(in: .whitespacesAndNewlines),
            isUser: true,
            image: selectedImage,
            timestamp: Date(),
            isStreaming: false,
            fullContent: ""
        )
        
        messages.append(userMessage)
        chatHistoryManager.addMessage(userMessage)
        
        // 清空输入
        let messageText = inputText
        let messageImage = selectedImage
        inputText = ""
        selectedImage = nil
        
        // AI 回复
        isTyping = true
        
        Task {
            do {
                let response: String
                
                if let image = messageImage {
                    // 图片分析
                    let result = try await apiManager.analyzeSkinCondition(image: image, symptoms: [messageText])
                    response = formatSkinAnalysisResponse(result)
                    
                    // 保存咨询记录
                    let consultation = AIConsultation(
                        date: Date(),
                        symptomImage: image.jpegData(compressionQuality: 0.5),
                        symptoms: [messageText],
                        aiAnalysis: result.description,
                        recommendations: result.recommendations,
                        severity: AIConsultation.Severity(rawValue: result.severity.capitalized) ?? .medium
                    )
                    healthDataManager.addAIConsultation(consultation)
                } else {
                    // 文本分析
                    let result = try await apiManager.analyzeSymptoms(messageText)
                    response = result.fullAnalysis
                }
                
                await MainActor.run {
                    isTyping = false
                    
                    // 震动反馈
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    // 创建流式显示的AI消息
                    var aiMessage = ChatMessage(
                        content: response,
                        isUser: false,
                        image: nil,
                        timestamp: Date(),
                        isStreaming: true,
                        fullContent: response
                    )
                    
                    messages.append(aiMessage)
                    
                    // 在流式显示完成后，将消息标记为非流式并保存到历史记录
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(response.count) * 0.03 + 0.5) {
                        if let index = messages.firstIndex(where: { $0.id == aiMessage.id }) {
                            messages[index].isStreaming = false
                            chatHistoryManager.addMessage(messages[index])
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    
                    // 错误震动反馈
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                    
                    let errorMessage = ChatMessage(
                        content: NSLocalizedString("ai_analysis_failed", comment: "") + ": \(error.localizedDescription)",
                        isUser: false,
                        image: nil,
                        timestamp: Date(),
                        isStreaming: false,
                        fullContent: ""
                    )
                    
                    messages.append(errorMessage)
                    chatHistoryManager.addMessage(errorMessage)
                }
            }
        }
    }
    
    private func formatSkinAnalysisResponse(_ result: SkinAnalysisResult) -> String {
        var response = ""
        
        if !result.possibleConditions.isEmpty {
            response += "🔍 **可能的诊断：**\n"
            for condition in result.possibleConditions {
                response += "• \(condition.name) - \(Int(condition.probability))% 可能性\n"
            }
            response += "\n"
        }
        
        if !result.description.isEmpty {
            response += "📝 **症状分析：**\n\(result.description)\n\n"
        }
        
        if !result.recommendations.isEmpty {
            response += "💡 **建议：**\n"
            for recommendation in result.recommendations {
                response += "• \(recommendation)\n"
            }
            response += "\n"
        }
        
        if !result.dailyCare.isEmpty {
            response += "🏠 **日常护理：**\n"
            for care in result.dailyCare {
                response += "• \(care)\n"
            }
            response += "\n"
        }
        
        if result.needMedicalAttention {
            response += "⚠️ **建议就医**：请咨询专业医生获得准确诊断\n"
        }
        
        return response
    }
    
    private func loadCurrentConversation() {
        DispatchQueue.main.async {
            if let conversation = chatHistoryManager.currentConversation {
                messages = conversation.messages
            } else {
                messages = []
                _ = chatHistoryManager.createNewConversation()
            }
        }
    }
    
    private func createNewConversation() {
        // 震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.async {
            _ = chatHistoryManager.createNewConversation()
            messages = []
        }
    }
    
    private func clearCurrentConversation() {
        // 震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.async {
            if let current = chatHistoryManager.currentConversation {
                chatHistoryManager.deleteConversation(current)
            }
            messages = []
            _ = chatHistoryManager.createNewConversation()
        }
    }
    
    // 隐藏键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - 聊天消息模型
struct ChatMessage: Identifiable {
    let id = UUID()
    var content: String
    let isUser: Bool
    let image: UIImage?
    let timestamp: Date
    var isStreaming: Bool = false
    var fullContent: String = ""
}

// MARK: - 聊天消息视图
struct ChatMessageView: View {
    let message: ChatMessage
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(15)
                    }
                    
                    if !message.content.isEmpty {
                        Text(message.content)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
                
                // 用户头像
                userAvatarView
                    .frame(width: 40, height: 40)
            } else {
                // AI头像
                aiAvatarView
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(NSLocalizedString("ai_doctor_name", comment: ""))
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    
                    FormattedMessageText(content: message.content, isStreaming: message.isStreaming)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(20)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                
                Spacer()
            }
        }
    }
    
    // 用户头像视图
    private var userAvatarView: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            )
    }
    
    // AI头像视图
    private var aiAvatarView: some View {
        Group {
            // 尝试加载名为"AI"的图片
            if let aiImage = UIImage(named: "AI") {
                Image(uiImage: aiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                // 默认AI头像
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "stethoscope")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

// MARK: - 格式化消息文本视图
struct FormattedMessageText: View {
    let content: String
    let isStreaming: Bool
    @State private var displayedContent: String = ""
    @State private var streamingTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseContent(displayedContent), id: \.id) { item in
                if item.isBold {
                    Text(item.text)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                } else {
                    Text(item.text)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
            
            // 流式输出时显示光标
            if isStreaming && displayedContent.count < content.count {
                HStack {
                    Spacer()
                    Text("▋")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .opacity(0.7)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: displayedContent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if isStreaming {
                startStreaming()
            } else {
                displayedContent = content
            }
        }
        .onChange(of: content) { newContent in
            if isStreaming {
                startStreaming()
            } else {
                displayedContent = newContent
            }
        }
    }
    
    private func startStreaming() {
        displayedContent = ""
        streamingTimer?.invalidate()
        
        let characters = Array(content)
        var currentIndex = 0
        
        streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedContent += String(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func parseContent(_ text: String) -> [FormattedTextItem] {
        var items: [FormattedTextItem] = []
        let lines = text.components(separatedBy: "\n")
        
        for line in lines {
            if line.isEmpty {
                // 空行，添加一个小间隔
                continue
            }
            
            // 检查是否是粗体标题（以**开头和结尾）
            if line.hasPrefix("**") && line.hasSuffix("**") {
                let text = line.replacingOccurrences(of: "**", with: "")
                items.append(FormattedTextItem(text: text, isBold: true))
            } else {
                items.append(FormattedTextItem(text: line, isBold: false))
            }
        }
        
        return items
    }
}

struct FormattedTextItem: Identifiable {
    let id = UUID()
    let text: String
    let isBold: Bool
}

// MARK: - 欢迎消息
struct WelcomeMessage: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "stethoscope")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text(NSLocalizedString("welcome_greeting", comment: ""))
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("welcome_features", comment: ""))
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 正在输入指示器
struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI头像
            aiAvatarView
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(NSLocalizedString("ai_analyzing_message", comment: ""))
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 3) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                            .scaleEffect(animating ? 1.0 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animating
                            )
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(20)
            }
            
            Spacer()
        }
        .id("typing")
        .onAppear {
            animating = true
        }
    }
    
    // AI头像视图
    private var aiAvatarView: some View {
        Group {
            // 尝试加载名为"AI"的图片
            if let aiImage = UIImage(named: "AI") {
                Image(uiImage: aiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                // 默认AI头像
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "stethoscope")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

// MARK: - 聊天输入栏（ChatGPT风格）
struct ChatInputBar: View {
    @Binding var inputText: String
    @Binding var selectedImage: UIImage?
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    let onSend: () -> Void
    let onImageSelected: (UIImage) -> Void
    
    @State private var showingActionSheet = false
    @FocusState private var isInputFocused: Bool
    @State private var inputHeight: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            // 图片预览
            if let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedImage = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.cardBackground.opacity(0.9))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            // ChatGPT风格的输入容器
            HStack(alignment: .center, spacing: 0) {
                // 主输入框容器
                HStack(alignment: .center, spacing: 8) {
                    // 附件按钮（在输入框内左侧）
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .confirmationDialog(NSLocalizedString("select_image_title", comment: ""), isPresented: $showingActionSheet) {
                        Button(NSLocalizedString("take_photo_action", comment: "")) {
                            showingCamera = true
                        }
                        Button(NSLocalizedString("from_album_action", comment: "")) {
                            showingImagePicker = true
                        }
                        Button(NSLocalizedString("cancel_action", comment: ""), role: .cancel) { }
                    }
                    
                    // 文本输入区域
                    ZStack(alignment: .leading) {
                        if inputText.isEmpty {
                            Text(NSLocalizedString("message_placeholder", comment: ""))
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        
                        TextEditor(text: $inputText)
                            .font(.system(size: 16))
                            .frame(height: 22)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .focused($isInputFocused)
                    }
                    
                    // 发送按钮（在输入框内右侧）
                    Button(action: {
                        isInputFocused = false
                        onSend()
                    }) {
                        ZStack {
                            Circle()
                                .fill(canSend ? Color.black : Color.gray.opacity(0.3))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.cardBackground)
                .cornerRadius(22)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Color.appBackground
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(
            Color.appBackground
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
    }
    
    private func updateHeight() {
        // 自动调整高度的逻辑已经由TextEditor的maxHeight处理
    }
}

// MARK: - 对话历史侧边栏
struct ChatHistorySidebar: View {
    @EnvironmentObject var chatHistoryManager: ChatHistoryManager
    @Binding var isShowing: Bool
    @Binding var sidebarOffset: CGFloat
    let onClose: () -> Void
    
    @State private var showingDeleteAlert = false
    @State private var conversationToDelete: ChatConversation?
    
    var body: some View {
        HStack(spacing: 0) {
            // 侧边栏内容
            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    Text(NSLocalizedString("chat_history_sidebar_title", comment: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                
                // 新建对话按钮
                Button(action: {
                    createNewConversation()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text(NSLocalizedString("new_conversation_button", comment: ""))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // 对话列表
                if chatHistoryManager.conversations.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text(NSLocalizedString("no_chat_records_message", comment: ""))
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(NSLocalizedString("create_new_hint", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatHistoryManager.conversations) { conversation in
                                SidebarConversationCard(
                                    conversation: conversation,
                                    isSelected: chatHistoryManager.currentConversation?.id == conversation.id,
                                    onSelect: {
                                        selectConversation(conversation)
                                    },
                                    onDelete: {
                                        conversationToDelete = conversation
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .frame(width: 300)
            .background(Color.appBackground)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 0)
            .offset(x: sidebarOffset)
            
            // 点击外部关闭侧边栏
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture {
                    onClose()
                }
        }
        .alert(NSLocalizedString("delete_conversation", comment: ""), isPresented: $showingDeleteAlert) {
            Button(NSLocalizedString("cancel_action", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("delete_button", comment: ""), role: .destructive) {
                if let conversation = conversationToDelete {
                    deleteConversation(conversation)
                }
            }
        } message: {
            Text(NSLocalizedString("delete_conversation_confirm", comment: ""))
        }
    }
    
    private func selectConversation(_ conversation: ChatConversation) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.async {
            chatHistoryManager.selectConversation(conversation)
            onClose()
        }
    }
    
    private func createNewConversation() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.async {
            _ = chatHistoryManager.createNewConversation()
            onClose()
        }
    }
    
    private func deleteConversation(_ conversation: ChatConversation) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.async {
            withAnimation {
                chatHistoryManager.deleteConversation(conversation)
            }
        }
    }
}

// MARK: - 侧边栏对话卡片
struct SidebarConversationCard: View {
    let conversation: ChatConversation
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // 标题和删除按钮
                HStack {
                    HStack(spacing: 6) {
                        Text(conversation.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 预览内容
                if !conversation.preview.isEmpty {
                    Text(conversation.preview)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                // 底部信息
                HStack {
                    Text(formatRelativeTime(conversation.updatedAt))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 10))
                        Text("\(conversation.messages.count)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationView {
        ChatConsultationView()
            .environmentObject(HealthDataManager.shared)
            .environmentObject(MoonshotAPIManager.shared)
    }
}



//
//  ConversationView.swift
//  XunDoc
//
//  医患对话查看器 - 聊天样式展示
//

import SwiftUI
import AVFoundation

struct ConversationView: View {
    let conversation: MedicalConversation
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioPlayer = AudioPlayerManager()
    @State private var showSummary = false
    @State private var selectedMessageId: UUID?
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // 左侧 - 对话区域
                    VStack(spacing: 0) {
                        // 音频播放控制栏
                        if conversation.audioData != nil && !conversation.audioData!.isEmpty {
                            AudioControlBar(
                                conversation: conversation,
                                audioPlayer: audioPlayer,
                                onSeekToMessage: { message in
                                    selectedMessageId = message.id
                                    audioPlayer.seek(to: message.timestamp)
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.cardBackgroundColor)
                            
                            Divider()
                        } else {
                            // 无音频提示
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.orange)
                                
                                Text("此对话暂无音频文件")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.1))
                            
                            Divider()
                        }
                        
                        // 对话列表
                        if conversation.isTranscribed {
                            ScrollViewReader { proxy in
                                ScrollView(showsIndicators: false) {
                                    LazyVStack(spacing: 16) {
                                        ForEach(conversation.sortedMessages) { message in
                                            MessageBubble(
                                                message: message,
                                                isSelected: selectedMessageId == message.id,
                                                onTap: {
                                                    selectedMessageId = message.id
                                                    audioPlayer.seek(to: message.timestamp)
                                                }
                                            )
                                            .id(message.id)
                                        }
                                    }
                                    .padding(20)
                                }
                                .onChange(of: selectedMessageId) { newId in
                                    if let id = newId {
                                        withAnimation {
                                            proxy.scrollTo(id, anchor: .center)
                                        }
                                    }
                                }
                            }
                        } else {
                            TranscribingView(progress: conversation.transcriptionProgress)
                        }
                    }
                    .frame(width: showSummary ? geometry.size.width * 0.65 : geometry.size.width)
                    
                    // 右侧 - 摘要面板 (可折叠)
                    if showSummary {
                        Divider()
                        
                        SummaryPanel(
                            summary: conversation.summary,
                            onClose: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showSummary = false
                                }
                            }
                        )
                        .frame(width: geometry.size.width * 0.35)
                        .transition(.move(edge: .trailing))
                    }
                }
            }
            .background(Color.appBackgroundColor)
            .navigationTitle(conversation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showSummary.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: showSummary ? "text.alignleft" : "text.alignright")
                                .font(.system(size: 16))
                            Text(showSummary ? "隐藏摘要" : "显示摘要")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.accentPrimary)
                    }
                }
            }
        }
        .onAppear {
            print("📱 ConversationView onAppear - 对话: \(conversation.title)")
            if let audioData = conversation.audioData, !audioData.isEmpty {
                print("🎵 加载音频数据: \(audioData.count) 字节")
                audioPlayer.loadAudio(audioData)
            } else {
                print("⚠️ 无音频数据或音频数据为空")
            }
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }
}

// MARK: - 音频控制栏
struct AudioControlBar: View {
    let conversation: MedicalConversation
    @ObservedObject var audioPlayer: AudioPlayerManager
    let onSeekToMessage: (ConversationMessage) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 播放控制
            HStack(spacing: 20) {
                // 播放/暂停按钮
                Button(action: {
                    audioPlayer.togglePlayPause()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.accentPrimary)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentPrimary)
                                .frame(width: geometry.size.width * audioPlayer.progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let progress = value.location.x / UIScreen.main.bounds.width
                                audioPlayer.seek(toProgress: min(max(progress, 0), 1))
                            }
                    )
                    
                    // 时间显示
                    HStack {
                        Text(formatTime(audioPlayer.currentTime))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                        
                        Text(conversation.formattedDuration)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // 快进/快退按钮
                HStack(spacing: 16) {
                    Button(action: {
                        audioPlayer.skip(seconds: -15)
                    }) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 20))
                            .foregroundColor(.textPrimary)
                    }
                    
                    Button(action: {
                        audioPlayer.skip(seconds: 15)
                    }) {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 20))
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 消息气泡
struct MessageBubble: View {
    let message: ConversationMessage
    let isSelected: Bool
    let onTap: () -> Void
    
    var isDoctor: Bool {
        message.role == .doctor
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isDoctor {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isDoctor ? .trailing : .leading, spacing: 6) {
                // 角色标签和时间戳
                HStack(spacing: 8) {
                    if !isDoctor {
                        Label(message.role.displayName, systemImage: "person.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                        
                        Button(action: onTap) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 12))
                                Text(message.formattedTimestamp)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                            }
                            .foregroundColor(.accentPrimary)
                        }
                    }
                    
                    if isDoctor {
                        Button(action: onTap) {
                            HStack(spacing: 4) {
                                Text(message.formattedTimestamp)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.accentPrimary)
                        }
                        
                        Label(message.role.displayName, systemImage: "stethoscope")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // 消息内容
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isDoctor ? .white : .textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isDoctor ? Color.blue : Color.gray.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? Color.accentPrimary : Color.clear, lineWidth: 2)
                    )
            }
            
            if !isDoctor {
                Spacer(minLength: 60)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 转译中视图
struct TranscribingView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 进度环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.accentPrimary, Color.accentTertiary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.accentPrimary)
            }
            
            VStack(spacing: 8) {
                Text("正在转译音频...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("AI正在将语音转换为文字")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 摘要面板
struct SummaryPanel: View {
    let summary: String?
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.accentPrimary)
                    
                    Text("对话摘要")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(16)
            .background(Color.cardBackgroundColor)
            
            Divider()
            
            // 摘要内容
            ScrollView(showsIndicators: false) {
                if let summary = summary {
                    Text(summary)
                        .font(.system(size: 14))
                        .foregroundColor(.textPrimary)
                        .lineSpacing(6)
                        .padding(16)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.textTertiary)
                        
                        Text("暂无摘要")
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
        }
        .background(Color.appBackgroundColor)
    }
}

#Preview {
    // 注意: Preview 中不包含真实音频数据
    // 在实际使用中，audioData 应该包含有效的音频文件数据
    ConversationView(conversation: MedicalConversation(
        memberId: UUID(),
        title: "内科门诊",
        date: Date(),
        hospitalName: "测试医院",
        department: "内科",
        doctorName: "张医生",
        audioData: nil,  // Preview 中不包含音频数据
        audioDuration: 180,
        messages: [
            ConversationMessage(role: .doctor, content: "您好,请问哪里不舒服?", timestamp: 0, duration: 3),
            ConversationMessage(role: .patient, content: "医生您好,我最近总是头疼。", timestamp: 3, duration: 4),
            ConversationMessage(role: .doctor, content: "头疼多久了？有其他症状吗？", timestamp: 7, duration: 4),
            ConversationMessage(role: .patient, content: "大概一周了，有时候还会感到头晕。", timestamp: 11, duration: 5),
            ConversationMessage(role: .doctor, content: "血压正常吗？", timestamp: 16, duration: 2),
            ConversationMessage(role: .patient, content: "不太清楚，没有测过。", timestamp: 18, duration: 3)
        ],
        summary: "患者主诉头痛一周，伴有头晕症状。建议检查血压，进一步评估病因。",
        isTranscribed: true
    ))
}


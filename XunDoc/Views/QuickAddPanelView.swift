//
//  QuickAddPanelView.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI
import Vision
import AVFoundation

struct QuickAddPanelView: View {
    @Binding var isPresented: Bool
    @Binding var showingRecording: Bool
    @Binding var showingReport: Bool
    @Binding var showingMedication: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部拖拽条和标题
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                
                HStack {
                    Text("添加内容")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.secondaryBackgroundColor)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Divider()
                .padding(.top, 16)
            
            // 功能卡片列表
            VStack(spacing: 12) {
                ModernQuickAddCard(
                    icon: "mic",
                    title: "录音记录",
                    description: "医生诊断录音"
                ) {
                    showingRecording = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPresented = false
                    }
                }
                
                ModernQuickAddCard(
                    icon: "doc.text",
                    title: "添加报告",
                    description: "上传报告单照片"
                ) {
                    showingReport = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPresented = false
                    }
                }
                
                ModernQuickAddCard(
                    icon: "list.clipboard",
                    title: "用药提醒",
                    description: "添加用药信息"
                ) {
                    showingMedication = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPresented = false
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            Spacer()
        }
        .background(Color.clear)
    }
}

// MARK: - 现代风格的快速添加卡片
struct ModernQuickAddCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 震动反馈
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 20) {
                // 图标区域
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondaryBackgroundColor)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(.textSecondary)
                }
                
                // 文字区域
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.dividerColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - 缩放按钮样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Recording View
struct RecordingView: View {
    @Environment(\.dismiss) var dismiss
    var onDismiss: (() -> Void)? = nil
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var recordingTitle = ""
    @State private var selectedHospital = ""
    @State private var selectedDepartment = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // 录音动画
                ZStack {
                    if isRecording {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .scaleEffect(isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isRecording)
                    }
                    
                    Circle()
                        .fill(isRecording ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: isRecording ? "mic.fill" : "mic.slash.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                // 录音时间
                Text(timeString(from: recordingTime))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(.textPrimary)
                
                // 录音按钮
                Button(action: toggleRecording) {
                    Text(isRecording ? "停止录音" : "开始录音")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 56)
                        .background(isRecording ? Color.red : Color.textPrimary)
                        .cornerRadius(28)
                }
                
                if recordingTime > 0 && !isRecording {
                    VStack(spacing: 16) {
                        TextField("录音标题（可选）", text: $recordingTitle)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                        
                        TextField("医院名称（可选）", text: $selectedHospital)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                        
                        TextField("科室（可选）", text: $selectedDepartment)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                        
                        Button(action: {
                            // 保存录音
                            dismiss()
                            onDismiss?()
                        }) {
                            Text("保存录音")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.textPrimary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }
                
                Spacer()
            }
            .padding(24)
            .background(Color.appBackgroundColor)
            .navigationTitle("录音记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        stopRecording()
                        dismiss()
                        onDismiss?()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingTime += 1
        }
    }
    
    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Add Report View
struct AddReportView: View {
    @Environment(\.dismiss) var dismiss
    var onDismiss: (() -> Void)? = nil
    @State private var reportTitle = ""
    @State private var hospitalName = ""
    @State private var department = ""
    @State private var reportDate = Date()
    @State private var notes = ""
    @State private var showingImagePicker = false
    @State private var selectedImages: [String] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 添加照片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("报告照片 *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.textSecondary)
                                
                                Text("拍摄或选择照片")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                
                                Text("建议拍摄清晰的报告单正面")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.dividerColor, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            )
                        }
                    }
                    
                    // 报告标题
                    VStack(alignment: .leading, spacing: 8) {
                        Text("报告标题 *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        TextField("如：血常规检查", text: $reportTitle)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                    }
                    
                    // 医院名称
                    VStack(alignment: .leading, spacing: 8) {
                        Text("医院名称 *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        TextField("请输入医院名称", text: $hospitalName)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                    }
                    
                    // 科室
                    VStack(alignment: .leading, spacing: 8) {
                        Text("科室")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        TextField("请输入科室", text: $department)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                    }
                    
                    // 检查日期
                    VStack(alignment: .leading, spacing: 8) {
                        Text("检查日期 *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        DatePicker("", selection: $reportDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(12)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                    }
                    
                    // 备注
                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        TextEditor(text: $notes)
                            .font(.system(size: 15))
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                    }
                    
                    // 保存按钮
                    Button(action: {
                        // 保存报告
                        dismiss()
                        onDismiss?()
                    }) {
                        Text("保存报告")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.textPrimary)
                            .cornerRadius(12)
                    }
                    .disabled(reportTitle.isEmpty || hospitalName.isEmpty)
                    .opacity(reportTitle.isEmpty || hospitalName.isEmpty ? 0.5 : 1.0)
                }
                .padding(24)
            }
            .background(Color.appBackgroundColor)
            .navigationTitle("添加报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                        onDismiss?()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            Text("图片选择器")
        }
    }
}

// MARK: - Medication Modal Wrapper (快捷添加)
struct MedicationModalWrapper: View {
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    @State private var showMedicationPanel = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showMedicationPanel = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresented = false
                        onComplete()
                    }
                }
            
            VStack {
                Spacer()
                if showMedicationPanel {
                    // 使用快捷添加视图替代标准添加视图
                    QuickAddMedicationView(isPresented: $showMedicationPanel)
                        .environmentObject(HealthDataManager.shared)
                        .transition(.move(edge: .bottom))
                        .onChange(of: showMedicationPanel) { newValue in
                            if !newValue {
                                // 延迟关闭，等待动画完成
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isPresented = false
                                    onComplete()
                                }
                            }
                        }
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showMedicationPanel = true
                }
            }
        }
    }
}

// MARK: - 简化的录音半屏弹窗
struct SimpleRecordingSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var isRecording = false
    @State private var isPaused = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var recordingTitle = ""
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // 拖动条
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // 标题区域
            HStack {
                Text("录音记录")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    cleanup()
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.secondaryBackgroundColor)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 录音标题输入 - 缩小
                    VStack(alignment: .leading, spacing: 6) {
                        Text("录音标题")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                        
                        TextField("请输入录音标题（可选）", text: $recordingTitle)
                            .font(.system(size: 14))
                            .padding(10)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(10)
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // 录音时间显示
                    VStack(spacing: 10) {
                        Text(timeString(from: recordingTime))
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                            .foregroundColor(.textPrimary)
                        
                        // 录音状态指示
                        HStack(spacing: 8) {
                            if isRecording {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(isPaused ? 1.0 : 1.3)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPaused ? false : isRecording)
                                
                                Text(isPaused ? "已暂停" : "录音中...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text("准备就绪")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    
                    // 控制按钮
                    HStack(spacing: 24) {
                        // 录制/暂停按钮
                        Button(action: toggleRecording) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(isRecording ? Color.red : Color.blue)
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: isRecording ? (isPaused ? "play.fill" : "pause.fill") : "mic.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                                
                                Text(isRecording ? (isPaused ? "继续" : "暂停") : "开始录音")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        // 保存按钮（仅在有录音时显示）
                        if recordingTime > 0 {
                            Button(action: saveRecording) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 56, height: 56)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("保存")
                                        .font(.system(size: 12))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.appBackgroundColor)
    }
    
    private func toggleRecording() {
        if !isRecording {
            // 开始录音
            startRecording()
        } else {
            if isPaused {
                // 继续录音
                resumeRecording()
            } else {
                // 暂停录音
                pauseRecording()
            }
        }
    }
    
    private func startRecording() {
        // 设置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("❌ 音频会话设置失败: \(error)")
            return
        }
        
        // 创建录音文件URL
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")
        
        guard let url = recordingURL else { return }
        
        // 录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            isPaused = false
            recordingTime = 0
            
            // 启动计时器
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                recordingTime += 1
            }
            
            print("🎤 开始录音: \(url.lastPathComponent)")
        } catch {
            print("❌ 录音失败: \(error)")
        }
    }
    
    private func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        timer?.invalidate()
        timer = nil
        print("⏸️ 暂停录音")
    }
    
    private func resumeRecording() {
        audioRecorder?.record()
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingTime += 1
        }
        print("▶️ 继续录音")
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        print("⏹️ 停止录音")
    }
    
    private func saveRecording() {
        // 停止录音
        audioRecorder?.stop()
        audioRecorder = nil
        timer?.invalidate()
        timer = nil
        
        guard recordingTime > 0,
              let url = recordingURL else {
            print("❌ 保存录音失败：缺少必要信息")
            print("  - 录音时长: \(recordingTime)")
            print("  - 录音URL: \(recordingURL?.absoluteString ?? "无")")
            isPresented = false
            return
        }
        
        // 读取录音文件数据
        guard let audioData = try? Data(contentsOf: url) else {
            print("❌ 无法读取录音文件")
            isPresented = false
            return
        }
        
        print("✅ 录音文件读取成功，大小: \(audioData.count) 字节")
        
        // 使用输入的标题，如果为空则使用默认标题
        let title = recordingTitle.isEmpty ? "录音记录 \(dateFormatter.string(from: Date()))" : recordingTitle
        
        // 创建录音数据
        var audioRecording = HealthRecord.AudioRecording(
            audioData: audioData,
            duration: recordingTime,
            date: Date(),
            title: title
        )
        
        print("🎤 开始自动转录音频...")
        
        // 🆕 自动转录音频
        SpeechRecognitionManager.shared.transcribeAudio(audioData: audioData) { result in
            switch result {
            case .success(let transcription):
                print("✅ 自动转录成功: \(transcription.prefix(100))...")
                
                // 更新录音记录，添加转录文本
                audioRecording.transcribedText = transcription
                audioRecording.isTranscribed = true
                
                // 🆕 自动生成AI诊断（基于转录文本）
                self.generateAIDiagnosisFromAudio(
                    transcription: transcription,
                    audioRecording: audioRecording,
                    title: title
                )
                
            case .failure(let error):
                print("⚠️ 自动转录失败: \(error.localizedDescription)")
                // 即使转录失败，也保存录音
                self.saveRecordWithoutTranscription(audioRecording: audioRecording, title: title)
            }
        }
        
        // 清理临时文件
        try? FileManager.default.removeItem(at: url)
        print("🗑️ 清理临时录音文件")
    }
    
    // 🆕 保存未转录的录音
    private func saveRecordWithoutTranscription(audioRecording: HealthRecord.AudioRecording, title: String) {
        // 直接创建未归档记录
        let record = HealthRecord(
            hospitalName: "待补充",
            department: "待补充",
            date: Date(),
            symptoms: title,
            diagnosis: "⚠️ 参考诊断（仅基于症状，无报告数据）\n\n待AI分析...",
            treatment: nil,
            attachments: [],
            audioRecordings: [audioRecording],
            notes: nil,
            isArchived: false,
            recordType: .outpatient
        )
        
        healthDataManager.addHealthRecord(record)
        
        DispatchQueue.main.async {
            self.isPresented = false
        }
    }
    
    // 🆕 基于音频转录生成AI诊断
    private func generateAIDiagnosisFromAudio(transcription: String, audioRecording: HealthRecord.AudioRecording, title: String) {
        print("🤖 开始基于音频转录生成AI诊断...")
        
        let analysisPrompt = """
        你是一位资深的医学AI助手。请基于以下医患对话录音的转录文本，给出专业的医学分析：
        
        【对话录音转录】
        \(transcription)
        
        ⚠️ 注意：这是仅基于录音的分析，没有检查报告数据支持，请标注为"参考诊断"。
        
        请详细分析：
        
        ## 🩺 参考诊断
        （标注：仅基于对话，无检查报告支持）
        - 根据对话内容，分析可能的疾病
        - 说明诊断依据（引用对话中的症状描述）
        - 评估可信度（低/中/高）
        
        ## 💊 建议的治疗方案
        - 如果对话中提到了处方，详细解释
        - 如果没有，根据症状给出治疗建议
        - 具体到药物、剂量、服用方法
        
        ## ⚠️ 重要提示
        - 是否需要进一步检查（列出具体检查项目）
        - 需要注意的危险信号
        - 复查建议
        
        请用通俗易懂的语言，让患者能够理解。
        """
        
        KimiAPIManager.shared.askQuestion(
            question: analysisPrompt,
            context: transcription,
            onUpdate: { partialAnswer in
                print("📝 AI分析中: \(partialAnswer.prefix(50))...")
            },
            onComplete: { finalAnswer in
                print("✅ AI诊断生成完成")
                
                // 创建包含AI诊断的记录
                DispatchQueue.main.async {
                    let record = HealthRecord(
                        hospitalName: "待补充",
                        department: "待补充",
                        date: Date(),
                        symptoms: title,
                        diagnosis: "⚠️ 参考诊断（仅基于录音对话）\n\n" + finalAnswer,
                        treatment: "详见上方AI分析",
                        attachments: [],
                        audioRecordings: [audioRecording],
                        notes: "此诊断仅基于录音转录，建议上传检查报告以获得更准确的分析。",
                        isArchived: false,
                        recordType: .outpatient
                    )
                    
                    self.healthDataManager.addHealthRecord(record)
                    
                    print("✅ 带AI诊断的录音记录已保存")
                    self.isPresented = false
                }
            }
        )
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 清理函数
    private func cleanup() {
        audioRecorder?.stop()
        audioRecorder = nil
        timer?.invalidate()
        timer = nil
        
        // 清理临时文件
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ 清理临时录音文件")
        }
    }
}

// MARK: - 图片包装器（用于识别）
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - 简化的报告半屏弹窗
struct SimpleReportSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var selectedImages: [IdentifiableImage] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var tempImages: [UIImage] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部拖动条
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)
            
            // 标题区域
            HStack {
                Text("添加报告")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.secondaryBackgroundColor)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            
            Divider()
            
            // 内容区域
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if selectedImages.isEmpty {
                        // 上传区域
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 48))
                                    .foregroundColor(.textTertiary)
                                
                                Text("点击上传报告照片")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                Text("支持批量选择多张照片")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                    .foregroundColor(.dividerColor)
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    } else {
                        // 已选择的照片预览
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("已选择 \(selectedImages.count) 张照片")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                        Text("继续添加")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.accentPrimary)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            
                            // 照片网格预览
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(selectedImages) { item in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: item.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 100)
                                            .clipped()
                                            .cornerRadius(12)
                                        
                                        // 删除按钮
                                        Button(action: {
                                            withAnimation {
                                                selectedImages.removeAll { $0.id == item.id }
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                        .padding(6)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.top, 24)
            
            // 底部按钮
            HStack(spacing: 12) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("取消")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.secondaryBackgroundColor)
                        .cornerRadius(14)
                }
                
                Button(action: {
                    saveReport()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("保存 \(selectedImages.count) 张报告")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        !selectedImages.isEmpty 
                        ? LinearGradient(
                            colors: [Color.accentPrimary, Color.accentTertiary],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                        : LinearGradient(
                            colors: [Color.textTertiary, Color.textTertiary],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
                    .cornerRadius(14)
                }
                .disabled(selectedImages.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.cardBackgroundColor)
        }
        .background(Color.appBackgroundColor)
        .sheet(isPresented: $showingImagePicker) {
            if #available(iOS 14.0, *) {
                MultipleImagePicker(images: $tempImages, maxSelection: 10)
                    .onDisappear {
                        // 将新选择的图片包装成 IdentifiableImage
                        let newImages = tempImages.map { IdentifiableImage(image: $0) }
                        selectedImages.append(contentsOf: newImages)
                        tempImages.removeAll()
                    }
            } else {
                Text("批量选择需要 iOS 14 或更高版本")
            }
        }
    }
    
    private func saveReport() {
        guard !selectedImages.isEmpty else {
            print("❌ 保存报告失败：没有选择照片")
            isPresented = false
            return
        }
        
        // 将所有图片转换为数据
        let attachments = selectedImages.compactMap { item in
            item.image.jpegData(compressionQuality: 0.8)
        }
        
        guard !attachments.isEmpty else {
            print("❌ 无法转换图片数据")
            isPresented = false
            return
        }
        
        print("📸 准备保存 \(attachments.count) 张报告照片")
        print("🔍 开始OCR识别和AI分析...")
        
        // 🆕 自动OCR识别所有照片
        var allOCRText = ""
        let dispatchGroup = DispatchGroup()
        
        for (index, imageData) in attachments.enumerated() {
            dispatchGroup.enter()
            
            // 提取照片中的文字
            extractTextFromImage(imageData) { ocrText in
                if !ocrText.isEmpty {
                    allOCRText += "【报告\(index + 1)】\n\(ocrText)\n\n"
                }
                dispatchGroup.leave()
            }
        }
        
        // 所有OCR完成后，生成AI诊断
        dispatchGroup.notify(queue: .main) {
            if !allOCRText.isEmpty {
                print("✅ OCR识别完成，开始生成AI诊断...")
                self.generateAIDiagnosisFromReport(
                    reportText: allOCRText,
                    attachments: attachments
                )
            } else {
                print("⚠️ OCR未识别到文字，保存报告但不生成诊断")
                self.saveReportWithoutDiagnosis(attachments: attachments)
            }
        }
    }
    
    // 🆕 提取图片中的文字（OCR）
    private func extractTextFromImage(_ imageData: Data, completion: @escaping (String) -> Void) {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        if #available(iOS 13.0, *) {
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion("")
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let ocrText = recognizedStrings.joined(separator: "\n")
                completion(ocrText)
            }
            
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("❌ OCR处理失败: \(error.localizedDescription)")
                    completion("")
                }
            }
        } else {
            completion("")
        }
    }
    
    // 🆕 基于报告生成AI诊断
    private func generateAIDiagnosisFromReport(reportText: String, attachments: [Data]) {
        print("🤖 开始基于报告生成AI诊断...")
        
        let analysisPrompt = """
        你是一位资深的医学AI助手。请基于以下检查报告内容，给出专业的医学分析：
        
        【检查报告内容】
        \(reportText)
        
        ⚠️ 注意：这是仅基于检查报告的分析，没有患者症状描述和录音对话，请标注为"参考诊断"。
        
        请详细分析：
        
        ## 📊 异常指标分析
        - 只列出异常或需要注意的指标
        - 解释每个异常指标的临床意义
        
        ## 🩺 参考诊断
        （标注：仅基于检查报告，无症状描述）
        - 根据报告数据，分析可能的疾病
        - 说明诊断依据
        - 评估病情严重程度
        
        ## 💊 建议的治疗方案
        - 详细的治疗建议
        - 具体到药物、剂量、服用方法
        - 非药物治疗建议
        
        ## ⚠️ 重要提示
        - 是否需要进一步检查
        - 需要注意的事项
        - 复查建议
        
        请用通俗易懂的语言，让患者能够理解。
        """
        
        KimiAPIManager.shared.askQuestion(
            question: analysisPrompt,
            context: reportText,
            onUpdate: { partialAnswer in
                print("📝 AI分析中: \(partialAnswer.prefix(50))...")
            },
            onComplete: { finalAnswer in
                print("✅ AI诊断生成完成")
                
                // 创建包含AI诊断的记录
                DispatchQueue.main.async {
                    let record = HealthRecord(
                        hospitalName: "待补充",
                        department: "待补充",
                        date: Date(),
                        symptoms: "报告照片 (\(attachments.count)张)",
                        diagnosis: "⚠️ 参考诊断（仅基于检查报告）\n\n" + finalAnswer,
                        treatment: "详见上方AI分析",
                        attachments: attachments,
                        audioRecordings: [],
                        notes: "此诊断仅基于检查报告，建议补充症状描述以获得更准确的分析。",
                        isArchived: false,
                        recordType: .physical
                    )
                    
                    self.healthDataManager.addHealthRecord(record)
                    
                    print("✅ 带AI诊断的报告记录已保存")
                    self.isPresented = false
                }
            }
        )
    }
    
    // 🆕 保存没有诊断的报告
    private func saveReportWithoutDiagnosis(attachments: [Data]) {
        let record = HealthRecord(
            hospitalName: "待补充",
            department: "待补充",
            date: Date(),
            symptoms: "报告照片 (\(attachments.count)张)",
            diagnosis: "⚠️ 参考诊断（报告未识别到文字）\n\n请确保照片清晰，或手动补充症状描述。",
            treatment: nil,
            attachments: attachments,
            audioRecordings: [],
            notes: nil,
            isArchived: false,
            recordType: .physical
        )
        
        healthDataManager.addHealthRecord(record)
        
        DispatchQueue.main.async {
            self.isPresented = false
        }
    }
}

#Preview {
    QuickAddPanelView(
        isPresented: .constant(true),
        showingRecording: .constant(false),
        showingReport: .constant(false),
        showingMedication: .constant(false)
    )
}

// MARK: - Record Merge Selection Sheet
struct RecordMergeSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthDataManager: HealthDataManager
    let sourceRecord: HealthRecord
    let onMerge: (HealthRecord) -> Void
    @State private var availableRecords: [HealthRecord] = []
    
    private var targetRecords: [HealthRecord] {
        // 使用 @State 变量，在 onAppear 时更新
        return availableRecords
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if targetRecords.isEmpty {
                    // 空状态
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 64))
                            .foregroundColor(.textSecondary.opacity(0.5))
                        
                        VStack(spacing: 12) {
                            Text("暂无可添加的记录")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            Text("请先从「添加病历报告」创建一个完整的就诊记录，然后再将录音或报告添加进去")
                                .font(.system(size: 15))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("选择要添加到的就诊记录")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            ForEach(targetRecords) { record in
                                Button(action: {
                                    onMerge(record)
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(record.hospitalName)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.textPrimary)
                                            
                                            HStack(spacing: 8) {
                                                Text(record.department)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.textSecondary)
                                                
                                                Text("•")
                                                    .foregroundColor(.textTertiary)
                                                
                                                Text(formatDate(record.date))
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.accentPrimary)
                                    }
                                    .padding(16)
                                    .background(Color.cardBackgroundColor)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.dividerColor, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color.appBackgroundColor)
            .navigationTitle("添加到就诊记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .onAppear {
            loadAvailableRecords()
        }
    }
    
    private func loadAvailableRecords() {
        // 每次显示时重新加载数据
        // 使用 getHealthRecords 而不是 getUnarchivedRecords，因为归档的记录也可以添加内容
        availableRecords = healthDataManager.getHealthRecords()
            .filter { $0.id != sourceRecord.id }
            .filter { record in
                // 过滤掉"待补充"的临时记录，只保留真正创建的完整记录
                !(record.hospitalName == "待补充" && record.department == "待补充")
            }
            .sorted { $0.date > $1.date }
        
        print("🔄 加载可用记录: \(availableRecords.count) 条")
        print("📋 所有记录数: \(healthDataManager.getHealthRecords().count)")
        availableRecords.forEach { record in
            print("  ✅ \(record.hospitalName) - \(record.department) [归档:\(record.isArchived)]")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Record Selection Sheet (deprecated, kept for reference)
struct RecordSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthDataManager: HealthDataManager
    let onSelectRecord: (HealthRecord) -> Void
    let onCreateNew: () -> Void
    
    private var unarchivedRecords: [HealthRecord] {
        return healthDataManager.getUnarchivedRecords()
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if unarchivedRecords.isEmpty {
                    // 空状态 - 只能创建新记录
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 64))
                            .foregroundColor(.textSecondary.opacity(0.5))
                        
                        VStack(spacing: 12) {
                            Text("暂无未归档记录")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            Text("创建一个新的就诊记录来保存这个内容")
                                .font(.system(size: 15))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            onCreateNew()
                            dismiss()
                        }) {
                            Text("创建新记录")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.accentPrimary)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                } else {
                    // 有未归档记录 - 显示列表
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("选择要添加到的就诊记录")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            ForEach(unarchivedRecords) { record in
                                Button(action: {
                                    onSelectRecord(record)
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(record.hospitalName)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.textPrimary)
                                            
                                            HStack(spacing: 8) {
                                                Text(record.department)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.textSecondary)
                                                
                                                Text("•")
                                                    .foregroundColor(.textTertiary)
                                                
                                                Text(formatDate(record.date))
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.textTertiary)
                                    }
                                    .padding(16)
                                    .background(Color.cardBackgroundColor)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.dividerColor, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                            }
                            
                            // 创建新记录选项
                            Button(action: {
                                onCreateNew()
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.accentPrimary)
                                    
                                    Text("创建新的就诊记录")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.accentPrimary)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.accentPrimary.opacity(0.08))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                        .foregroundColor(.accentPrimary.opacity(0.3))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color.appBackgroundColor)
            .navigationTitle("添加到就诊记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

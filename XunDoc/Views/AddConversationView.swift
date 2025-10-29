//
//  AddConversationView.swift
//  XunDoc
//
//  上传医患对话录音
//

import SwiftUI
import AVFoundation

struct AddConversationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthDataManager: HealthDataManager
    @StateObject private var transcriptionManager = AudioTranscriptionManager.shared
    @StateObject private var recorder = AudioRecorder()
    
    @State private var title = ""
    @State private var hospitalName = ""
    @State private var department = ""
    @State private var doctorName = ""
    @State private var conversationDate = Date()
    @State private var showingFilePicker = false
    @State private var audioFileURL: URL?
    @State private var audioFileName: String?
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 录音或上传区域
                    VStack(alignment: .leading, spacing: 16) {
                        Text("音频录制")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        if recorder.hasRecording || audioFileURL != nil {
                            // 已有录音
                            AudioPreviewCard(
                                fileName: audioFileName ?? "录音.m4a",
                                duration: recorder.recordingDuration,
                                onPlay: {
                                    recorder.playRecording()
                                },
                                onStop: {
                                    recorder.stopPlaying()
                                },
                                onRemove: {
                                    recorder.deleteRecording()
                                    audioFileURL = nil
                                    audioFileName = nil
                                },
                                isPlaying: recorder.isPlaying
                            )
                        } else {
                            // 录音控制
                            RecordingControl(
                                isRecording: recorder.isRecording,
                                recordingTime: recorder.recordingTime,
                                onRecord: {
                                    if recorder.isRecording {
                                        recorder.stopRecording()
                                    } else {
                                        recorder.startRecording()
                                    }
                                },
                                onUpload: {
                                    showingFilePicker = true
                                }
                            )
                        }
                    }
                    
                    // 对话信息
                    VStack(spacing: 20) {
                        FormField(label: "对话标题", required: true) {
                            TextField("如：内科门诊", text: $title)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                        
                        FormField(label: "医院名称") {
                            TextField("请输入医院名称", text: $hospitalName)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                        
                        FormField(label: "科室") {
                            TextField("如：内科", text: $department)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                        
                        FormField(label: "医生姓名") {
                            TextField("请输入医生姓名", text: $doctorName)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                        
                        FormField(label: "对话日期", required: true) {
                            DatePicker("", selection: $conversationDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                    }
                    
                    // 提示信息
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text("上传后将自动进行AI转译,生成文字记录和摘要")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.1))
                    )
                    
                    // 保存按钮
                    Button(action: saveConversation) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.up.doc.fill")
                                .font(.system(size: 18))
                            Text("上传并转译")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(canSave() 
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
                        )
                    }
                    .disabled(!canSave())
                }
                .padding(24)
            }
            .background(Color.appBackgroundColor)
            .navigationTitle("上传对话录音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        recorder.stopRecording()
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            AudioFilePicker(fileURL: $audioFileURL, fileName: $audioFileName)
        }
    }
    
    private func canSave() -> Bool {
        return !title.isEmpty && (recorder.hasRecording || audioFileURL != nil)
    }
    
    private func saveConversation() {
        
        // 获取录音数据
        var audioData: Data?
        var duration: TimeInterval = 0
        
        if let url = recorder.recordingURL {
            audioData = try? Data(contentsOf: url)
            duration = recorder.recordingDuration
        } else if let url = audioFileURL {
            audioData = try? Data(contentsOf: url)
            // 获取音频时长
            let asset = AVURLAsset(url: url)
            duration = CMTimeGetSeconds(asset.duration)
        }
        
        guard let data = audioData else {
            print("❌ 无法获取音频数据")
            return
        }
        
        // 创建对话
        let conversation = MedicalConversation(
            memberId: UUID(),  // 使用默认UUID
            title: title,
            date: conversationDate,
            hospitalName: hospitalName.isEmpty ? nil : hospitalName,
            department: department.isEmpty ? nil : department,
            doctorName: doctorName.isEmpty ? nil : doctorName,
            audioData: data,
            audioDuration: duration,
            audioFileName: audioFileName
        )
        
        transcriptionManager.addConversation(conversation)
        
        // 开始转译
        transcriptionManager.transcribeAudio(for: conversation.id) { success in
            if success {
                print("✅ 对话转译成功")
            }
        }
        
        print("🎙️ 对话保存成功:")
        print("  标题: \(title)")
        print("  时长: \(Int(duration))秒")
        
        dismiss()
    }
}

// MARK: - 录音控制
struct RecordingControl: View {
    let isRecording: Bool
    let recordingTime: TimeInterval
    let onRecord: () -> Void
    let onUpload: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 录音时间显示
            if isRecording {
                VStack(spacing: 12) {
                    // 录音动画
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isRecording ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: isRecording
                                )
                        }
                    }
                    
                    Text(formatTime(recordingTime))
                        .font(.system(size: 36, weight: .light, design: .monospaced))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.red.opacity(0.1))
                )
            }
            
            // 控制按钮
            HStack(spacing: 16) {
                // 开始/停止录音
                Button(action: onRecord) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : Color.accentPrimary)
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        
                        Text(isRecording ? "停止录音" : "开始录音")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                if !isRecording {
                    // 上传文件
                    Button(action: onUpload) {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                            
                            Text("上传文件")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 音频预览卡片
struct AudioPreviewCard: View {
    let fileName: String
    let duration: TimeInterval
    let onPlay: () -> Void
    let onStop: () -> Void
    let onRemove: () -> Void
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 播放按钮
            Button(action: isPlaying ? onStop : onPlay) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(fileName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                    Text("时长: \(formatDuration(duration))")
                        .font(.system(size: 13))
                }
                .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 音频录制器
class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var hasRecording = false
    
    var recordingURL: URL?
    var recordingDuration: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("❌ 音频会话设置失败: \(error)")
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingTime = 0
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.recordingTime += 1
            }
            
            print("🎙️ 开始录音: \(audioFilename.lastPathComponent)")
        } catch {
            print("❌ 录音失败: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        if let url = audioRecorder?.url {
            recordingURL = url
            recordingDuration = recordingTime
            hasRecording = true
            print("✅ 录音完成: \(recordingTime)秒")
        }
    }
    
    func playRecording() {
        guard let url = recordingURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + recordingDuration) { [weak self] in
                self?.isPlaying = false
            }
        } catch {
            print("❌ 播放失败: \(error)")
        }
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    func deleteRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        hasRecording = false
        recordingTime = 0
        recordingDuration = 0
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - 音频文件选择器
struct AudioFilePicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?
    @Binding var fileName: String?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: AudioFilePicker
        
        init(_ parent: AudioFilePicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.fileURL = url
            parent.fileName = url.lastPathComponent
            print("🎵 选择音频文件: \(url.lastPathComponent)")
        }
    }
}

#Preview {
    AddConversationView()
        .environmentObject(HealthDataManager.shared)
}


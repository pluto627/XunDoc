//
//  AddCaseStepView.swift
//  XunDoc
//
//  分步引导式添加病历
//

import SwiftUI
import Speech
import AVFoundation

struct AddCaseStepView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    // 表单数据
    @State private var hospitalName = ""
    @State private var department = ""
    @State private var visitDate = Date()
    @State private var symptoms = ""
    
    // 辅助状态
    @State private var showingHospitalSearch = false
    @State private var isRecording = false
    @State private var recognizedText = ""
    
    // 语音识别相关
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 医院信息区域
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "医院信息", icon: "building.2.fill")
                        
                        HStack(spacing: 12) {
                            TextField("请输入医院名称", text: $hospitalName)
                                .font(.system(size: 16))
                                .foregroundColor(.textPrimary)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(16)
                            
                            Button(action: {
                                showingHospitalSearch = true
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 48, height: 48)
                                    .background(Color.accentPrimary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 科室和日期区域
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "就诊信息", icon: "calendar.badge.clock")
                        
                        // 科室选择
                        VStack(alignment: .leading, spacing: 12) {
                            Text("科室")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            DepartmentGridSelector(selectedDepartment: $department)
                        }
                        
                        // 就诊日期
                        VStack(alignment: .leading, spacing: 12) {
                            Text("就诊日期")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            DatePicker("", selection: $visitDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 症状描述区域
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "症状描述", icon: "heart.text.square.fill")
                        
                        VStack(spacing: 12) {
                            TextEditor(text: $symptoms)
                                .font(.system(size: 15))
                                .foregroundColor(.textPrimary)
                                .frame(height: 150)
                                .padding(12)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(12)
                                .overlay(
                                    Group {
                                        if symptoms.isEmpty {
                                            Text("请描述您的症状，如：头痛、发热、咳嗽等")
                                                .font(.system(size: 15))
                                                .foregroundColor(.textSecondary)
                                                .padding(.leading, 16)
                                                .padding(.top, 20)
                                                .allowsHitTesting(false)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                            
                            // 语音识别状态提示
                            if isRecording {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    
                                    Text("正在听...")
                                        .font(.system(size: 13))
                                        .foregroundColor(.accentPrimary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.accentPrimary.opacity(0.1))
                                .cornerRadius(20)
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: toggleRecording) {
                                    HStack(spacing: 8) {
                                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                                            .font(.system(size: 16))
                                        Text(isRecording ? "停止录音" : "语音输入")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(isRecording ? .errorColor : .accentPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(isRecording ? Color.errorColor.opacity(0.1) : Color.accentPrimary.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    symptoms = ""
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                        Text("清空")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.secondaryBackgroundColor)
                                    .cornerRadius(12)
                                }
                            }
                            
                            Text("💡 可选填写，稍后在详情页补充")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // 保存按钮
                    Button(action: {
                        saveCase()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("创建病历")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            canSave() 
                            ? LinearGradient(
                                colors: [Color.accentPrimary, Color.accentTertiary],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [Color.gray, Color.gray],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                        )
                        .cornerRadius(16)
                        .shadow(color: canSave() ? Color.accentPrimary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canSave())
                    .padding(.top, 8)
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color.appBackgroundColor)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("创建病历")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
            .sheet(isPresented: $showingHospitalSearch) {
                HospitalSearchView(selectedHospital: $hospitalName)
            }
        }
    }
    
    private func canSave() -> Bool {
        return !hospitalName.isEmpty && !department.isEmpty
    }
    
    private func saveCase() {
        let record = HealthRecord(
            hospitalName: hospitalName,
            department: department,
            date: visitDate,
            symptoms: symptoms.isEmpty ? "无" : symptoms,
            diagnosis: nil,
            treatment: nil,
            attachments: [],
            audioRecordings: [],
            notes: nil,
            isArchived: true, // 通过表单添加的记录直接标记为已归档
            recordType: .outpatient
        )
        
        print("📝 准备保存病历记录:")
        print("  - 医院: \(hospitalName)")
        print("  - 科室: \(department)")
        print("  - 归档状态: \(record.isArchived)")
        
        healthDataManager.addHealthRecord(record)
        
        print("✅ 病历记录已添加到HealthDataManager")
        print("📊 健康记录总数: \(healthDataManager.getHealthRecords().count)")
        print("📊 已归档记录数: \(healthDataManager.getArchivedRecords().count)")
        
        dismiss()
    }
    
    // 切换录音状态
    private func toggleRecording() {
        if isRecording {
            // 停止录音
            stopRecording()
        } else {
            // 开始录音
            startRecording()
        }
    }
    
    // 开始录音
    private func startRecording() {
        // 请求权限
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                guard authStatus == .authorized else {
                    print("❌ 未获得语音识别权限")
                    return
                }
                
                do {
                    try self.startAudioEngine()
                } catch {
                    print("❌ 启动录音失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func startAudioEngine() throws {
        // 取消之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: nil)
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 获取输入节点
        let inputNode = audioEngine.inputNode
        
        // 创建识别任务
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = text
                    self.symptoms = text
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
        // 配置音频录制
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // 启动音频引擎
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        print("🎤 开始语音识别...")
    }
    
    // 停止录音
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        isRecording = false
        print("⏹️ 停止语音识别")
    }
    
    // 隐藏键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - 辅助组件

// 区域标题
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.accentPrimary)
            }
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
    }
}

// 科室网格选择器
struct DepartmentGridSelector: View {
    @Binding var selectedDepartment: String
    
    let departments = ["内科", "外科", "儿科", "妇科", "骨科", "眼科", "耳鼻喉科", "皮肤科", "神经科", "心血管内科", "呼吸内科", "消化内科", "泌尿科", "肿瘤科", "口腔科", "中医科"]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 10) {
            ForEach(departments, id: \.self) { dept in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDepartment = dept
                    }
                }) {
                    Text(dept)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedDepartment == dept ? .white : .textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedDepartment == dept ? Color.accentPrimary : Color.secondaryBackgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selectedDepartment == dept ? Color.accentPrimary : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - 步骤1: 医院信息
struct CaseStep1HospitalView: View {
    @Binding var hospitalName: String
    @Binding var showingHospitalSearch: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("医院名称")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("请输入就诊的医院名称")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                
                HStack(spacing: 12) {
                    TextField("如：北京协和医院", text: $hospitalName)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color.secondaryBackgroundColor)
                        .cornerRadius(16)
                    
                    Button(action: {
                        showingHospitalSearch = true
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.accentPrimary)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color.appBackgroundColor)
    }
}

// MARK: - 步骤2: 科室和日期
struct CaseStep2DepartmentView: View {
    @Binding var department: String
    @Binding var visitDate: Date
    
    let departments = ["内科", "外科", "儿科", "妇科", "骨科", "眼科", "耳鼻喉科", "皮肤科", "神经科", "心血管内科", "呼吸内科", "消化内科", "泌尿科", "肿瘤科", "口腔科", "中医科"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("科室与日期")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("选择就诊科室和日期")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 40)
                
                // 日期选择 - 放在科室上面
                VStack(alignment: .leading, spacing: 12) {
                    Text("就诊日期")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    DatePicker("", selection: $visitDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(14)
                        .background(Color.secondaryBackgroundColor)
                        .cornerRadius(14)
                }
                
                // 科室选择 - 改为网格布局
                VStack(alignment: .leading, spacing: 12) {
                    Text("科室")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(departments, id: \.self) { dept in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    department = dept
                                }
                            }) {
                                Text(dept)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(department == dept ? .white : .textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(department == dept ? Color.accentPrimary : Color.secondaryBackgroundColor)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(department == dept ? Color.accentPrimary : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .background(Color.appBackgroundColor)
    }
}

// MARK: - 步骤3: 症状描述
struct CaseStep3SymptomsView: View {
    @Binding var symptoms: String
    @Binding var isRecording: Bool
    
    @StateObject private var voiceInputHelper = VoiceInputHelper()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("症状描述")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("详细描述您的症状（可选）")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                
                VStack(spacing: 12) {
                    TextEditor(text: $symptoms)
                        .font(.system(size: 15))
                        .foregroundColor(.textPrimary)
                        .frame(height: 180)
                        .padding(12)
                        .background(Color.secondaryBackgroundColor)
                        .cornerRadius(12)
                        .overlay(
                            Group {
                                if symptoms.isEmpty {
                                    Text("请描述您的症状，如：头痛、发热、咳嗽等")
                                        .font(.system(size: 15))
                                        .foregroundColor(.textSecondary)
                                        .padding(.leading, 16)
                                        .padding(.top, 20)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                    
                    // 语音识别状态提示
                    if isRecording {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text(voiceInputHelper.recognizedText.isEmpty ? "正在听..." : "识别中...")
                                .font(.system(size: 13))
                                .foregroundColor(.accentPrimary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.accentPrimary.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            toggleRecording()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                                    .font(.system(size: 16))
                                Text(isRecording ? "停止录音" : "语音输入")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(isRecording ? .errorColor : .accentPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isRecording ? Color.errorColor.opacity(0.1) : Color.accentPrimary.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            symptoms = ""
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("清空")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                        }
                    }
                    
                    Text("💡 可选择跳过，稍后在详情页补充")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color.appBackgroundColor)
        .onChange(of: voiceInputHelper.recognizedText) { newText in
            if !newText.isEmpty {
                if symptoms.isEmpty {
                    symptoms = newText
                } else {
                    symptoms += " " + newText
                }
            }
        }
        .alert("需要麦克风权限", isPresented: $showingPermissionAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("请在设置中允许访问麦克风以使用语音输入功能")
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            // 停止录音
            voiceInputHelper.stopRecording()
            isRecording = false
        } else {
            // 开始录音
            voiceInputHelper.requestPermission { authorized in
                if authorized {
                    voiceInputHelper.startRecording()
                    isRecording = true
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
}

// MARK: - 实时语音输入助手
import Speech
import AVFoundation

class VoiceInputHelper: NSObject, ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecording = false
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
    
    func startRecording() {
        // 如果已有任务在运行，先停止
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ 音频会话配置失败: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
                self.recognizedText = ""
            }
        } catch {
            print("❌ 音频引擎启动失败: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        if let inputNode = audioEngine.inputNode as AVAudioNode? {
            inputNode.removeTap(onBus: 0)
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}

#Preview {
    AddCaseStepView()
        .environmentObject(HealthDataManager.shared)
}

// MARK: - Hospital Search View
struct HospitalSearchView: View {
    @Binding var selectedHospital: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var hospitalSearchManager = HospitalSearchManager.shared
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0: 附近医院, 1: 常用医院
    @State private var showLocationAlert = false
    
    // 常用医院列表
    private let commonHospitals = [
        "北京协和医院",
        "中国人民解放军总医院",
        "北京大学第一医院",
        "北京大学人民医院",
        "北京大学第三医院",
        "中日友好医院",
        "北京安贞医院",
        "首都医科大学附属北京同仁医院",
        "首都医科大学宣武医院",
        "首都医科大学附属北京天坛医院",
        "复旦大学附属华山医院",
        "上海交通大学医学院附属瑞金医院",
        "上海交通大学医学院附属仁济医院",
        "浙江大学医学院附属第一医院",
        "浙江大学医学院附属第二医院",
        "四川大学华西医院",
        "中山大学附属第一医院",
        "广东省人民医院",
        "南京鼓楼医院",
        "江苏省人民医院"
    ]
    
    private var filteredCommonHospitals: [String] {
        if searchText.isEmpty {
            return commonHospitals
        }
        return commonHospitals.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredNearbyHospitals: [HospitalSearchManager.Hospital] {
        if searchText.isEmpty {
            return hospitalSearchManager.nearbyHospitals
        }
        return hospitalSearchManager.nearbyHospitals.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索框
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    
                    TextField("搜索医院名称", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // 标签页切换
                HStack(spacing: 0) {
                    Button(action: {
                        selectedTab = 0
                        if hospitalSearchManager.nearbyHospitals.isEmpty {
                            searchNearbyHospitals()
                        }
                    }) {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14))
                                Text("附近医院")
                                    .font(.system(size: 15, weight: .medium))
                                
                                if hospitalSearchManager.isSearching {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                            }
                            .foregroundColor(selectedTab == 0 ? .accentPrimary : .textSecondary)
                            
                            Rectangle()
                                .fill(selectedTab == 0 ? Color.accentPrimary : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button(action: {
                        selectedTab = 1
                    }) {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 14))
                                Text("常用医院")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(selectedTab == 1 ? .accentPrimary : .textSecondary)
                            
                            Rectangle()
                                .fill(selectedTab == 1 ? Color.accentPrimary : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                
                Divider()
                
                // 内容区域
                TabView(selection: $selectedTab) {
                    // 附近医院列表
                    nearbyHospitalsView
                        .tag(0)
                    
                    // 常用医院列表
                    commonHospitalsView
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color.appBackgroundColor)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("选择医院")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
            .onAppear {
                // 自动搜索附近医院
                if hospitalSearchManager.nearbyHospitals.isEmpty {
                    searchNearbyHospitals()
                }
            }
            .alert("需要定位权限", isPresented: $showLocationAlert) {
                Button("去设置", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请在设置中允许访问您的位置信息，以便搜索附近的医院")
            }
        }
    }
    
    // MARK: - 附近医院视图
    
    private var nearbyHospitalsView: some View {
        Group {
            if hospitalSearchManager.isSearching {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在搜索附近医院...")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
            } else if let errorMessage = hospitalSearchManager.errorMessage {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        searchNearbyHospitals()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("重新搜索")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentPrimary.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                }
            } else if filteredNearbyHospitals.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "location.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.textSecondary.opacity(0.5))
                    
                    Text("未找到附近的医院")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            selectedHospital = searchText
                            dismiss()
                        }) {
                            Text("使用 \"\(searchText)\"")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.accentPrimary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentPrimary.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredNearbyHospitals) { hospital in
                            Button(action: {
                                selectedHospital = hospital.name
                                dismiss()
                            }) {
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentPrimary.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "cross.case.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.accentPrimary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(hospital.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        
                                        HStack(spacing: 8) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "location.fill")
                                                    .font(.system(size: 11))
                                                Text(hospital.distanceText)
                                                    .font(.system(size: 12))
                                            }
                                            .foregroundColor(.textSecondary)
                                            
                                            if !hospital.address.isEmpty {
                                                Text("•")
                                                    .foregroundColor(.textTertiary)
                                                
                                                Text(hospital.address)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.textSecondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.textTertiary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if hospital.id != filteredNearbyHospitals.last?.id {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 常用医院视图
    
    private var commonHospitalsView: some View {
        Group {
            if filteredCommonHospitals.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.textSecondary.opacity(0.5))
                    
                    Text("未找到匹配的医院")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                    
                    Button(action: {
                        selectedHospital = searchText
                        dismiss()
                    }) {
                        Text("使用 \"\(searchText)\"")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.accentPrimary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentPrimary.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredCommonHospitals, id: \.self) { hospital in
                            Button(action: {
                                selectedHospital = hospital
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentPrimary)
                                        .frame(width: 24)
                                    
                                    Text(hospital)
                                        .font(.system(size: 15))
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                    
                                    if selectedHospital == hospital {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.accentPrimary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            
                            if hospital != filteredCommonHospitals.last {
                                Divider()
                                    .padding(.leading, 64)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 搜索附近医院
    
    private func searchNearbyHospitals() {
        // 检查定位权限
        if hospitalSearchManager.authorizationStatus == .notDetermined {
            hospitalSearchManager.requestLocationPermission()
            
            // 延迟1秒后再搜索，等待权限授权
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if hospitalSearchManager.authorizationStatus == .authorizedWhenInUse ||
                   hospitalSearchManager.authorizationStatus == .authorizedAlways {
                    hospitalSearchManager.searchNearbyHospitals()
                }
            }
        } else if hospitalSearchManager.authorizationStatus == .denied || 
                  hospitalSearchManager.authorizationStatus == .restricted {
            showLocationAlert = true
        } else {
            hospitalSearchManager.searchNearbyHospitals()
        }
    }
}

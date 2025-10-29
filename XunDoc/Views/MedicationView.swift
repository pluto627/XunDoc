//
//  MedicationView.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI
import PhotosUI

struct MedicationView: View {
    @State private var showingAddMedication = false
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var activeMedications: [MedicationReminder] {
        return healthDataManager.getActiveMedicationReminders()
    }
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    MedicationHeader()
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    
                    // Content
                    VStack(spacing: 32) {
                        // My Medications
                        MyMedicationsSection(medications: activeMedications)
                            .padding(.horizontal, 20)
                        
                        // Add New Medication
                        AddMedicationSection(showingAddMedication: $showingAddMedication)
                            .padding(.horizontal, 20)
                        
                        // Statistics
                        StatisticsSection(medications: activeMedications)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color.appBackgroundColor)
            .navigationBarHidden(true)
            
            // 半屏弹窗
            if showingAddMedication {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showingAddMedication = false
                        }
                    }
                
                VStack {
                    Spacer()
                    AddMedicationView(isPresented: $showingAddMedication)
                        .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingAddMedication)
    }
}

// MARK: - Medication Header - 应用新设计
struct MedicationHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("用药管理")
                    .font(.appTitle())
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 8) {
                    PulsingDot(color: .accentPrimary)
                    Text("智能用药提醒")
                        .font(.appCaption())
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.secondaryBackgroundColor)
                    )
            }
        }
    }
}

// MARK: - My Medications Section - 应用新设计
struct MyMedicationsSection: View {
    let medications: [MedicationReminder]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("我的药物")
                .font(.appLabel())
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)
            
            if medications.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.textTertiary.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "pills")
                            .font(.system(size: 38, weight: .light, design: .rounded))
                            .foregroundColor(.textTertiary)
                    }
                    
                    VStack(spacing: 6) {
                        Text("暂无用药记录")
                            .font(.appSubheadline())
                            .foregroundColor(.textSecondary)
                        
                        Text("添加您的第一个药品提醒")
                            .font(.appSmall())
                            .foregroundColor(.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.secondaryBackgroundColor)
                )
                .fadeIn(delay: 0.2)
            } else {
                ForEach(medications) { medication in
                    MedicationListItem(medication: medication)
                }
            }
        }
    }
}

struct MedicationListItem: View {
    let medication: MedicationReminder
    @State private var showingDetail = false
    
    private var timeInfo: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let times = medication.reminderTimes.map { formatter.string(from: $0) }.joined(separator: " · ")
        return "\(times) · \(medication.dosage)"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.medicationName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                
                Text(timeInfo)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "clock")
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
        }
        .padding(16)
        .background(Color.cardBackgroundColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.dividerColor, lineWidth: 1)
        )
        .onLongPressGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            MedicationDetailView(medication: medication)
                .environmentObject(HealthDataManager.shared)
        }
    }
}

// MARK: - Add Medication Section
struct AddMedicationSection: View {
    @Binding var showingAddMedication: Bool
    
    var body: some View {
        Button(action: {
            showingAddMedication = true
        }) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(.textSecondary)
                
                Text("添加新药物")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                Text("可拍照识别药品信息")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.secondaryBackgroundColor)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.dividerColor, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
            )
        }
    }
}

// MARK: - Statistics Section
struct StatisticsSection: View {
    let medications: [MedicationReminder]
    
    private var totalMedications: String {
        "\(medications.count)"
    }
    
    private var activeDoses: String {
        let totalDoses = medications.reduce(0) { $0 + $1.reminderTimes.count }
        return "\(totalDoses)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("本周统计")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
                .tracking(0.05)
            
            HStack(spacing: 20) {
                StatItem(value: totalMedications, label: "当前药物")
                StatItem(value: activeDoses, label: "每日服药次数")
            }
        }
        .padding(24)
        .background(Color.secondaryBackgroundColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.dividerColor, lineWidth: 1)
        )
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Medication View (分步流程 - 半屏弹窗) - 全新设计
struct AddMedicationView: View {
    @Binding var isPresented: Bool
    
    // 当前步骤
    @State private var currentStep = 1
    let totalSteps = 3
    
    // 表单数据
    @State private var medicationName = ""
    @State private var dosageType = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var times: [Date] = [Calendar.current.startOfDay(for: Date()).addingTimeInterval(9*3600)] // 今天上午9点
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7*24*60*60)
    @State private var notes = ""
    @State private var usage = "" // 药物用途
    @State private var instructions = "" // 服用说明
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isSearchingMedication = false // 是否正在搜索药物信息
    
    var progressPercentage: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // 拖动条 - 更精致
                Capsule()
                    .fill(Color.textTertiary.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 14)
                    .padding(.bottom, 18)
                
                // 顶部标题和进度 - 应用新设计（无背景）
                VStack(spacing: 16) {
                    // 标题和关闭按钮
                    HStack {
                        Text("用药提醒")
                            .font(.appTitle())
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // 步骤进度条 - 更现代的设计
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("步骤 \(currentStep)")
                                .font(.appLabel())
                                .foregroundColor(.accentPrimary)
                            
                            Text("/ \(totalSteps)")
                                .font(.appLabel())
                                .foregroundColor(.textTertiary)
                            
                            Spacer()
                            
                            Text(getStepLabel(currentStep))
                                .font(.appCaption())
                                .foregroundColor(.textSecondary)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // 背景进度条
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 8)
                                
                                // 进度
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentPrimary, Color.accentTertiary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progressPercentage, height: 8)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
                
                // 步骤内容（使用整体渐变背景）
                TabView(selection: $currentStep) {
                    // 步骤1：药物基本信息（整合名称、剂型、剂量和自动搜索）
                    Step1MedicationInfoView(
                        medicationName: $medicationName,
                        dosageType: $dosageType,
                        dosage: $dosage,
                        showingImagePicker: $showingImagePicker,
                        showingCamera: $showingCamera,
                        onUsageUpdate: { newUsage in
                            usage = newUsage
                        },
                        onInstructionsUpdate: { newInstructions in
                            instructions = newInstructions
                        }
                    )
                    .tag(1)
                    
                    // 步骤2：服用安排
                    Step2ScheduleView(
                        frequency: $frequency,
                        times: $times
                    )
                    .tag(2)
                    
                    // 步骤3：周期和备注
                    Step3CycleAndNotesView(
                        notes: $notes,
                        startDate: $startDate,
                        endDate: $endDate
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
                .frame(height: UIScreen.main.bounds.height * 0.5) // 限制TabView高度，确保按钮可见
            
            // 底部按钮 - 新设计（添加背景和Divider）
            VStack(spacing: 0) {
                Divider()
                    .background(Color.dividerColor)
                
                HStack(spacing: 12) {
                    if currentStep > 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                currentStep -= 1
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                Text("上一步")
                                    .font(.appSubheadline())
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                    }
                    
                    Button(action: {
                        if currentStep < totalSteps {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                currentStep += 1
                            }
                        } else {
                            // 保存药品信息
                            saveMedication()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentStep < totalSteps ? "下一步" : "保存")
                                .font(.appSubheadline())
                            
                            if currentStep < totalSteps {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(canProceed() 
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
                    .disabled(!canProceed())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(Color.appBackgroundColor)
        }
        .background(Color.appBackgroundColor)
        .sheet(isPresented: $showingImagePicker) {
            MedicationImagePicker(medicationName: $medicationName)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            MedicationCameraView(medicationName: $medicationName)
        }
    }
    
    private func getStepLabel(_ step: Int) -> String {
        switch step {
        case 1: return "药物信息"
        case 2: return "服用安排"
        case 3: return "周期备注"
        default: return ""
        }
    }
    
    private func canProceed() -> Bool {
        switch currentStep {
        case 1: return !medicationName.isEmpty && !dosageType.isEmpty && !dosage.isEmpty
        case 2: return !frequency.isEmpty && !times.isEmpty
        case 3: return true // 备注是可选的
        default: return false
        }
    }
    
    private func saveMedication() {
        // 保存药品信息到数据管理器
        // 转换频率
        let medicationFrequency: MedicationReminder.Frequency
        switch frequency {
        case "once":
            medicationFrequency = .onceDaily
        case "twice":
            medicationFrequency = .twiceDaily
        case "three":
            medicationFrequency = .threeTimesDaily
        case "four":
            medicationFrequency = .fourTimesDaily
        default:
            medicationFrequency = .asNeeded
        }
        
        let reminder = MedicationReminder(
            medicationName: medicationName,
            dosage: dosage,
            frequency: medicationFrequency,
            startDate: startDate,
            endDate: endDate,
            reminderTimes: times,
            notes: notes.isEmpty ? nil : notes,
            isActive: true,
            usage: usage.isEmpty ? nil : usage,
            instructions: instructions.isEmpty ? nil : instructions
        )
        
        HealthDataManager.shared.addMedicationReminder(reminder)
        
        // 创建系统通知
        createMedicationNotifications(for: reminder)
        
        print("💊 保存药品信息成功:")
        print("名称: \(medicationName)")
        print("剂型: \(dosageType)")
        print("剂量: \(dosage)")
        print("频率: \(medicationFrequency.localized)")
        print("时间数量: \(times.count)")
        print("提醒时间:")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        times.forEach { time in
            print("  - \(dateFormatter.string(from: time))")
        }
        
        withAnimation {
            isPresented = false
        }
    }
    
    /// 为用药提醒创建系统通知
    private func createMedicationNotifications(for reminder: MedicationReminder) {
        let notificationManager = MedicalNotificationManager.shared
        
        // 请求通知权限
        Task {
            let authorized = await notificationManager.requestNotificationPermission()
            guard authorized else {
                print("⚠️ 未获得通知权限")
                return
            }
            
            // 为每个提醒时间创建通知
            for reminderTime in reminder.reminderTimes {
                let notification = MedicalNotification.medicationTemplate(
                    memberId: UUID(), // 使用默认成员ID
                    memberName: "用户", // 使用默认名称
                    medicationName: reminder.medicationName,
                    dosage: reminder.dosage,
                    frequency: reminder.frequency.localized,
                    scheduledDate: reminderTime
                )
                
                await MainActor.run {
                    notificationManager.addNotification(notification)
                }
                
                print("🔔 已创建用药提醒通知: \(reminder.medicationName) - \(reminderTime)")
            }
        }
    }
}

// MARK: - 步骤指示器
struct StepIndicator: View {
    let step: Int
    let currentStep: Int
    let label: String
    
    var isActive: Bool { step == currentStep }
    var isCompleted: Bool { step < currentStep }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive || isCompleted ? Color(red: 55/255, green: 53/255, blue: 47/255) : Color(red: 245/255, green: 245/255, blue: 245/255))
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(step)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isActive ? .white : Color(red: 155/255, green: 154/255, blue: 151/255))
                }
            }
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(isActive ? Color(red: 55/255, green: 53/255, blue: 47/255) : Color(red: 155/255, green: 154/255, blue: 151/255))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 步骤1: 药品名称 - 应用新设计
struct Step1NameView: View {
    @Binding var medicationName: String
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)
                
                VStack(spacing: 32) {
                    // 标题区域
                    VStack(spacing: 12) {
                        Text("药品名称")
                            .font(.appLargeTitle())
                            .foregroundColor(.textPrimary)
                        
                        Text("请输入或扫描药品名称")
                            .font(.appBody())
                            .foregroundColor(.textSecondary)
                    }
                    
                    VStack(spacing: 20) {
                        // 输入框 - 更精致的设计
                        TextField("如：阿司匹林肠溶片", text: $medicationName)
                            .font(.appHeadline())
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.gray.opacity(0.08))
                            )
                        
                        // 拍照按钮 - 更精致的设计
                        HStack(spacing: 14) {
                            Button(action: {
                                showingCamera = true
                            }) {
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentPrimary.opacity(0.15))
                                            .frame(width: 56, height: 56)
                                        
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 24, weight: .medium, design: .rounded))
                                            .foregroundColor(.accentPrimary)
                                    }
                                    
                                    Text("拍照识别")
                                        .font(.appCaption())
                                        .foregroundColor(.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.gray.opacity(0.08))
                                )
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentSecondary.opacity(0.15))
                                            .frame(width: 56, height: 56)
                                        
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 24, weight: .medium, design: .rounded))
                                            .foregroundColor(.accentSecondary)
                                    }
                                    
                                    Text("从相册选择")
                                        .font(.appCaption())
                                        .foregroundColor(.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.gray.opacity(0.08))
                                )
                            }
                        }
                        
                        // 提示信息
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.warningColor)
                            
                            Text("提示：可以拍摄药品包装盒自动识别")
                                .font(.appSmall())
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.warningColor.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 28)
                
                Spacer().frame(height: 32)
            }
        }
        .background(Color.clear)
    }
}

// MARK: - 步骤2: 剂型选择 - 应用新设计
struct Step2DosageTypeView: View {
    @Binding var dosageType: String
    
    let dosageTypes = [
        ("tablet", "💊", "片剂"),
        ("capsule", "💊", "胶囊"),
        ("liquid", "🧪", "液体"),
        ("powder", "📦", "粉剂"),
        ("cream", "🧴", "乳膏"),
        ("injection", "💉", "注射")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)
                
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text("剂型")
                            .font(.appLargeTitle())
                            .foregroundColor(.textPrimary)
                        
                        Text("选择药品的剂型")
                            .font(.appBody())
                            .foregroundColor(.textSecondary)
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(dosageTypes, id: \.0) { type in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dosageType = type.0
                                }
                            }) {
                                VStack(spacing: 14) {
                                    Text(type.1)
                                        .font(.system(size: 48))
                                    
                                    Text(type.2)
                                        .font(.appSubheadline())
                                        .foregroundColor(.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(dosageType == type.0 
                                              ? Color.accentPrimary.opacity(0.12)
                                              : Color.gray.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(dosageType == type.0 ? Color.accentPrimary : Color.clear, lineWidth: 2.5)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                
                Spacer().frame(height: 32)
            }
        }
        .background(Color.clear)
    }
}

// MARK: - 步骤3: 规格/剂量 - 应用新设计
struct Step3DosageView: View {
    @Binding var dosage: String
    let dosageType: String
    
    var placeholder: String {
        switch dosageType {
        case "tablet", "capsule": return "如：1片 或 100mg"
        case "liquid": return "如：10ml"
        case "powder": return "如：1包"
        case "cream": return "如：适量"
        case "injection": return "如：1支"
        default: return "请输入剂量"
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)
                
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text("规格/剂量")
                            .font(.appLargeTitle())
                            .foregroundColor(.textPrimary)
                        
                        Text("请输入每次服用的剂量")
                            .font(.appBody())
                            .foregroundColor(.textSecondary)
                    }
                    
                    TextField(placeholder, text: $dosage)
                        .font(.appHeadline())
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.gray.opacity(0.08))
                        )
                }
                .padding(.horizontal, 28)
                
                Spacer().frame(height: 32)
            }
        }
        .background(Color.clear)
    }
}

// MARK: - 步骤4: 服用频率 - 应用新设计
struct Step4FrequencyView: View {
    @Binding var frequency: String
    @Binding var times: [Date]
    
    let frequencies = [
        ("once", "每天1次"),
        ("twice", "每天2次"),
        ("three", "每天3次"),
        ("four", "每天4次"),
        ("weekly", "每周1次"),
        ("custom", "自定义")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)
                
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text("服用频率")
                            .font(.appLargeTitle())
                            .foregroundColor(.textPrimary)
                        
                        Text("选择服用频率")
                            .font(.appBody())
                            .foregroundColor(.textSecondary)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(frequencies, id: \.0) { freq in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    frequency = freq.0
                                    updateTimesForFrequency(freq.0)
                                }
                            }) {
                                HStack {
                                    Text(freq.1)
                                        .font(.appSubheadline())
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                    
                                    if frequency == freq.0 {
                                        ZStack {
                                            Circle()
                                                .fill(Color.accentPrimary)
                                                .frame(width: 24, height: 24)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                    } else {
                                        Circle()
                                            .stroke(Color.dividerColor, lineWidth: 2)
                                            .frame(width: 24, height: 24)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(frequency == freq.0 
                                              ? Color.accentPrimary.opacity(0.08)
                                              : Color.gray.opacity(0.08))
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                
                Spacer().frame(height: 32)
            }
        }
    }
    
    private func updateTimesForFrequency(_ freq: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch freq {
        case "once":
            times = [today.addingTimeInterval(9*3600)] // 9:00
        case "twice":
            times = [
                today.addingTimeInterval(9*3600),  // 9:00
                today.addingTimeInterval(21*3600)  // 21:00
            ]
        case "three":
            times = [
                today.addingTimeInterval(8*3600),  // 8:00
                today.addingTimeInterval(14*3600), // 14:00
                today.addingTimeInterval(20*3600)  // 20:00
            ]
        case "four":
            times = [
                today.addingTimeInterval(8*3600),  // 8:00
                today.addingTimeInterval(12*3600), // 12:00
                today.addingTimeInterval(16*3600), // 16:00
                today.addingTimeInterval(20*3600)  // 20:00
            ]
        default:
            break
        }
    }
}

// MARK: - 步骤5: 服用时间
struct Step5TimeView: View {
    @Binding var times: [Date]
    let frequency: String
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("服用时间")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                    
                    Text("设置每次服用的具体时间")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                }
                .padding(.top, 40)
                
                VStack(spacing: 12) {
                    ForEach(times.indices, id: \.self) { index in
                        HStack(spacing: 16) {
                            Text("第 \(index + 1) 次")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                                .frame(width: 60, alignment: .leading)
                            
                            DatePicker("", selection: $times[index], displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
            }
        }
        .background(Color.clear)
    }
}

// MARK: - 步骤6: 备注和周期
struct Step6NotesView: View {
    @Binding var notes: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 40)
                
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("补充信息")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                        
                        Text("可选：添加备注和服药周期")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                    }
                    
                    // 服药周期
                    VStack(alignment: .leading, spacing: 12) {
                        Text("服药周期")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("开始日期")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                                
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            .padding(12)
                            .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                            .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("结束日期")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                                
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            .padding(12)
                            .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                            .cornerRadius(12)
                        }
                    }
                    
                    // 备注
                    VStack(alignment: .leading, spacing: 12) {
                        Text("备注")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                        
                        TextEditor(text: $notes)
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                            .frame(height: 120)
                            .padding(12)
                            .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                            .cornerRadius(12)
                            .overlay(
                                Group {
                                    if notes.isEmpty {
                                        Text("如：饭后服用、避免与某些食物同服等")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                                            .padding(.leading, 16)
                                            .padding(.top, 20)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer().frame(height: 40)
            }
        }
    }
}


// MARK: - 药品图片选择器
struct MedicationImagePicker: UIViewControllerRepresentable {
    @Binding var medicationName: String
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MedicationImagePicker
        
        init(_ parent: MedicationImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // TODO: 这里可以调用OCR识别药品名称
                // 暂时模拟识别结果
                recognizeMedicationName(from: image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        private func recognizeMedicationName(from image: UIImage) {
            // TODO: 集成OCR或者调用识别API
            // 这里暂时模拟一个识别结果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 模拟识别结果
                print("📸 正在识别药品...")
                // parent.medicationName = "识别到的药品名称"
            }
        }
    }
}

// MARK: - 药品相机视图
struct MedicationCameraView: UIViewControllerRepresentable {
    @Binding var medicationName: String
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MedicationCameraView
        
        init(_ parent: MedicationCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // TODO: 这里可以调用OCR识别药品名称
                recognizeMedicationName(from: image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        private func recognizeMedicationName(from image: UIImage) {
            // TODO: 集成OCR或者调用识别API
            // 这里暂时模拟一个识别结果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("📸 正在识别药品...")
                // 模拟识别结果 - 可以在这里设置识别到的药品名称
                // parent.medicationName = "阿司匹林肠溶片"
            }
        }
    }
}

// MARK: - Medication Detail View
struct MedicationDetailView: View {
    let medication: MedicationReminder
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var isEditMode = false
    @State private var showingDeleteConfirm = false
    
    // 编辑状态的数据
    @State private var editMedicationName = ""
    @State private var editDosage = ""
    @State private var editFrequency: MedicationReminder.Frequency = .onceDaily
    @State private var editNotes = ""
    
    private var timeInfo: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return medication.reminderTimes.map { formatter.string(from: $0) }.joined(separator: ", ")
    }
    
    private var dateInfo: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if let endDate = medication.endDate {
            return "从 \(formatter.string(from: medication.startDate)) 至 \(formatter.string(from: endDate))"
        } else {
            return "从 \(formatter.string(from: medication.startDate)) 开始"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // 药物名称
                    MedicationDetailSection(label: "药物名称") {
                        if isEditMode {
                            TextField("药物名称", text: $editMedicationName)
                                .font(.system(size: 16))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(12)
                        } else {
                            HStack {
                                Text(medication.medicationName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // 规格/剂量
                    MedicationDetailSection(label: "规格/剂量") {
                        if isEditMode {
                            TextField("剂量", text: $editDosage)
                                .font(.system(size: 16))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(12)
                        } else {
                            HStack {
                                Text(medication.dosage)
                                    .font(.system(size: 16))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // 服用频率
                    MedicationDetailSection(label: "服用频率") {
                        if isEditMode {
                            Picker("频率", selection: $editFrequency) {
                                ForEach(MedicationReminder.Frequency.allCases, id: \.self) { freq in
                                    Text(freq.localized).tag(freq)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(12)
                        } else {
                            HStack {
                                Text(medication.frequency.localized)
                                    .font(.system(size: 16))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // 服用时间
                    MedicationDetailSection(label: "服用时间") {
                        HStack {
                            Text(timeInfo)
                                .font(.system(size: 16))
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 服用周期
                    MedicationDetailSection(label: "服用周期") {
                        HStack {
                            Text(dateInfo)
                                .font(.system(size: 16))
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 备注
                    if let notes = medication.notes, !notes.isEmpty || isEditMode {
                        MedicationDetailSection(label: "备注") {
                            if isEditMode {
                                TextEditor(text: $editNotes)
                                    .font(.system(size: 16))
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.secondaryBackgroundColor)
                                    .cornerRadius(12)
                            } else {
                                HStack {
                                    Text(notes ?? "")
                                        .font(.system(size: 16))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(Color.appBackgroundColor)
            .navigationTitle("药物详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "保存" : "编辑") {
                        if isEditMode {
                            saveMedication()
                        } else {
                            enterEditMode()
                        }
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !isEditMode {
                    Button(action: {
                        showingDeleteConfirm = true
                    }) {
                        Text("删除药物")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.appBackgroundColor)
                }
            }
            .alert("删除药物", isPresented: $showingDeleteConfirm) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteMedication()
                }
            } message: {
                Text("确定要删除这个药物提醒吗？此操作无法撤销。")
            }
        }
        .onAppear {
            initializeEditData()
        }
    }
    
    private func initializeEditData() {
        editMedicationName = medication.medicationName
        editDosage = medication.dosage
        editFrequency = medication.frequency
        editNotes = medication.notes ?? ""
    }
    
    private func enterEditMode() {
        isEditMode = true
    }
    
    private func saveMedication() {
        var updatedMedication = medication
        updatedMedication.medicationName = editMedicationName
        updatedMedication.dosage = editDosage
        updatedMedication.frequency = editFrequency
        updatedMedication.notes = editNotes.isEmpty ? nil : editNotes
        
        healthDataManager.updateMedicationReminder(updatedMedication)
        isEditMode = false
    }
    
    private func deleteMedication() {
        // 从数据管理器中删除这个药物提醒
        if let index = healthDataManager.medicationReminders.firstIndex(where: { $0.id == medication.id }) {
            healthDataManager.medicationReminders.remove(at: index)
            healthDataManager.saveData()
        }
        dismiss()
    }
}

// MARK: - Medication Detail Section Helper
struct MedicationDetailSection<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MedicationView()
}


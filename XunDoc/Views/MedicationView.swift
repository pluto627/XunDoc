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
    @State private var selectedMedication: MedicationReminder?
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
                        MyMedicationsSection(
                            medications: activeMedications,
                            onSelectMedication: { medication in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedMedication = medication
                                }
                            }
                        )
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
            
            // 添加药物弹窗
            if showingAddMedication {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingAddMedication = false
                        }
                    }
                
                VStack {
                    Spacer()
                    AddMedicationFormView(isPresented: $showingAddMedication)
                        .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
            }
            
            // 药物详情弹窗
            if let medication = selectedMedication {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedMedication = nil
                        }
                    }
                    .transition(.opacity)
                
                VStack {
                    Spacer()
                    MedicationDetailPopup(
                        medication: medication,
                        isPresented: Binding(
                            get: { selectedMedication != nil },
                            set: { if !$0 { selectedMedication = nil } }
                        )
                    )
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingAddMedication)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedMedication != nil)
    }
}

// MARK: - Medication Header - 应用新设计
struct MedicationHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("medication_management", comment: ""))
                .font(.appTitle())
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 8) {
                PulsingDot(color: .accentPrimary)
                Text(NSLocalizedString("smart_medication_reminder", comment: ""))
                    .font(.appCaption())
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - My Medications Section - 应用新设计
struct MyMedicationsSection: View {
    let medications: [MedicationReminder]
    let onSelectMedication: (MedicationReminder) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("my_medications", comment: ""))
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
                        Text(NSLocalizedString("no_medications_yet", comment: ""))
                            .font(.appSubheadline())
                            .foregroundColor(.textSecondary)
                        
                        Text(NSLocalizedString("add_first_medication", comment: ""))
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
                    MedicationListItem(
                        medication: medication,
                        onTap: {
                            onSelectMedication(medication)
                        }
                    )
                }
            }
        }
    }
}

struct MedicationListItem: View {
    let medication: MedicationReminder
    let onTap: () -> Void
    
    private var timeInfo: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let times = medication.reminderTimes.map { formatter.string(from: $0) }.joined(separator: " · ")
        return "\(times) · \(medication.dosage)"
    }
    
    var body: some View {
        Button(action: onTap) {
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
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .background(Color.cardBackgroundColor)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.dividerColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
                
                Text(NSLocalizedString("add_new_medication", comment: ""))
                    .font(.appCaption())
                    .foregroundColor(.textSecondary)
                
                Text(NSLocalizedString("quick_add_medication", comment: ""))
                    .font(.appSmall())
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
            Text(NSLocalizedString("weekly_statistics", comment: ""))
                .font(.appCaption())
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
                .tracking(0.05)
            
            HStack(spacing: 20) {
                StatItem(value: totalMedications, label: NSLocalizedString("current_medications", comment: ""))
                StatItem(value: activeDoses, label: NSLocalizedString("daily_doses", comment: ""))
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
                .font(.appLargeNumber())
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(.appSmall())
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Medication Detail Popup (悬浮弹窗版本)
struct MedicationDetailPopup: View {
    let medication: MedicationReminder
    @Binding var isPresented: Bool
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var showingInventory = false
    @State private var inventory: Int = 100
    @State private var showingDeleteAlert = false
    @State private var showingEditForm = false
    
    // 获取药物类型（从notes中提取）
    private var medicationType: String {
        if let notes = medication.notes, notes.contains("药品类型:") {
            return notes.replacingOccurrences(of: "药品类型: ", with: "")
        }
        return "片剂"
    }
    
    // 获取剂量单位
    private var dosageUnit: String {
        let dosageStr = medication.dosage
        if dosageStr.contains("丸") { return "丸" }
        if dosageStr.contains("片") { return "片" }
        if dosageStr.contains("粒") { return "粒" }
        if dosageStr.contains("mg") { return "mg" }
        if dosageStr.contains("ml") { return "ml" }
        return "片"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // 顶部拖动条
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.textTertiary)
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // 标题栏
                HStack {
                    Spacer()
                    
                    Text(medication.medicationName)
                        .font(.appHeadline())
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingEditForm = true
                    }) {
                        Text("编辑")
                            .font(.appSubheadline())
                            .foregroundColor(.accentPrimary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 药物信息卡片
                        medicationInfoCard
                            .padding(.horizontal, 20)
                        
                        // 剂余数量
                        Button(action: {
                            showingInventory = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(NSLocalizedString("remaining_quantity", comment: ""))
                                        .font(.appCaption())
                                        .foregroundColor(.textSecondary)
                                    
                                    Text("\(inventory) \(dosageUnit)")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundColor(.accentPrimary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textTertiary)
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.secondaryBackgroundColor)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.65)
            }
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.cardBackgroundColor)
            )
            .floatingShadow()
        }
        .sheet(isPresented: $showingInventory) {
            inventorySheet
        }
        .sheet(isPresented: $showingEditForm) {
            EditMedicationFormView(medication: medication, isPresented: $showingEditForm)
                .environmentObject(healthDataManager)
        }
        .onAppear {
            loadMedicationData()
        }
    }
    
    // MARK: - 药物信息卡片
    private var medicationInfoCard: some View {
        VStack(spacing: 16) {
            // 药物基本信息
            HStack(spacing: 16) {
                // 药片图标
                IconBackground(
                    icon: "pills.fill",
                    color: .accentPrimary,
                    size: 56
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(medication.medicationName)
                        .font(.appHeadline())
                        .foregroundColor(.textPrimary)
                    
                    Text(medicationType)
                        .font(.appCaption())
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.secondaryBackgroundColor)
            )
            
            // 两列网格布局
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // 规格/剂量
                detailCard(icon: "pills.circle.fill", label: NSLocalizedString("medication_spec", comment: ""), value: medication.dosage)
                
                // 服用频率
                detailCard(icon: "clock.fill", label: NSLocalizedString("medication_frequency", comment: ""), value: frequencyText)
                
                // 服用时间
                if !medication.reminderTimes.isEmpty {
                    detailCard(icon: "alarm.fill", label: NSLocalizedString("medication_time", comment: ""), value: reminderTimesText)
                }
                
                // 剂型
                detailCard(icon: "capsule.fill", label: NSLocalizedString("medication_form", comment: ""), value: medicationType)
                
                // 药物用途（跨两列）
                if let usage = medication.usage {
                    detailCard(icon: "heart.text.square.fill", label: NSLocalizedString("medication_usage", comment: ""), value: usage, isWide: true)
                }
                
                // 服用说明（跨两列）
                if let instructions = medication.instructions {
                    detailCard(icon: "doc.text.fill", label: NSLocalizedString("medication_instructions", comment: ""), value: instructions, isWide: true)
                }
            }
        }
    }
    
    // MARK: - 详情卡片
    private func detailCard(icon: String, label: String, value: String, isWide: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentPrimary)
                
                Text(label)
                    .font(.appSmall())
                    .foregroundColor(.textSecondary)
            }
            
            Text(value)
                .font(.appBody())
                .foregroundColor(.textPrimary)
                .lineLimit(isWide ? nil : 2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondaryBackgroundColor)
        )
        .if(isWide) { view in
            view.gridCellColumns(2)
        }
    }
    
    // 获取服用频率文本
    private var frequencyText: String {
        switch medication.frequency {
        case .onceDaily: return "每日一次"
        case .twiceDaily: return "每日两次"
        case .threeTimesDaily: return "每日三次"
        case .fourTimesDaily: return "每日四次"
        case .asNeeded: return "按需服用"
        }
    }
    
    // 获取提醒时间文本
    private var reminderTimesText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return medication.reminderTimes.map { formatter.string(from: $0) }.joined(separator: " · ")
    }
    
    
    // MARK: - 库存编辑弹窗
    private var inventorySheet: some View {
        NavigationView {
            ZStack {
                Color(hex: "0A0A0A").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text("编辑库存")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            TextField("", value: $inventory, format: .number)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(hex: "1C1C1E"))
                                .cornerRadius(12)
                            
                            Text(dosageUnit)
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 24)
                        
                        Button(action: {
                            saveInventory()
                        }) {
                            Text("保存")
                                .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                                .background(Color(hex: "7B8FF7"))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 32)
                    .background(Color(hex: "1C1C1E"))
                    .cornerRadius(24)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        showingInventory = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func loadMedicationData() {
        // TODO: 从本地存储加载库存数据和服药记录
        // 这里可以使用 UserDefaults 或其他持久化方案
    }
    
    private func saveInventory() {
        // TODO: 保存库存数据到本地
        showingInventory = false
    }
    
    private func deleteMedication() {
        if let index = healthDataManager.medicationReminders.firstIndex(where: { $0.id == medication.id }) {
            healthDataManager.medicationReminders.remove(at: index)
            healthDataManager.saveData()
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// MARK: - View 扩展
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Edit Medication Form View
struct EditMedicationFormView: View {
    let medication: MedicationReminder
    @Binding var isPresented: Bool
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    @State private var medicationName: String = ""
    @State private var dosage: String = ""
    @State private var frequency: MedicationReminder.Frequency = .onceDaily
    @State private var reminderTimes: [Date] = []
    @State private var usage: String = ""
    @State private var instructions: String = ""
    @State private var notes: String = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        medicationNameSection
                        dosageSection
                        frequencySection
                        reminderTimesSection
                        usageSection
                        instructionsSection
                        notesSection
                        saveButton
                        deleteButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle(NSLocalizedString("edit_medication", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        isPresented = false
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .alert(NSLocalizedString("confirm_delete", comment: ""), isPresented: $showingDeleteAlert) {
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("delete", comment: ""), role: .destructive) {
                deleteMedication()
            }
        } message: {
            Text(String(format: NSLocalizedString("confirm_delete_medication_format", comment: ""), medicationName))
        }
        .onAppear {
            loadMedicationData()
        }
    }
    
    // MARK: - View Components
    
    private var medicationNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("medication_name", comment: ""))
                .font(.appLabel())
                .foregroundColor(.textSecondary)
            
            TextField(NSLocalizedString("medication_name_placeholder", comment: ""), text: $medicationName)
                .font(.appBody())
                .foregroundColor(.textPrimary)
                .padding(16)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(12)
        }
    }
    
    private var dosageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("dosage", comment: ""))
                .font(.appLabel())
                .foregroundColor(.textSecondary)
            
            TextField(NSLocalizedString("dosage_placeholder", comment: ""), text: $dosage)
                .font(.appBody())
                .foregroundColor(.textPrimary)
                .padding(16)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(12)
        }
    }
    
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("frequency", comment: ""))
                .font(.appLabel())
                .foregroundColor(.textSecondary)
            
            Picker(NSLocalizedString("frequency", comment: ""), selection: $frequency) {
                Text(NSLocalizedString("frequency_once_daily", comment: "")).tag(MedicationReminder.Frequency.onceDaily)
                Text(NSLocalizedString("frequency_twice_daily", comment: "")).tag(MedicationReminder.Frequency.twiceDaily)
                Text(NSLocalizedString("frequency_three_times_daily", comment: "")).tag(MedicationReminder.Frequency.threeTimesDaily)
                Text(NSLocalizedString("frequency_four_times_daily", comment: "")).tag(MedicationReminder.Frequency.fourTimesDaily)
                Text(NSLocalizedString("frequency_as_needed", comment: "")).tag(MedicationReminder.Frequency.asNeeded)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var reminderTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("reminder_times", comment: ""))
                .font(.appLabel())
                .foregroundColor(.textSecondary)
            
            ForEach(Array(reminderTimes.enumerated()), id: \.offset) { index, time in
                HStack {
                    DatePicker("", selection: Binding(
                        get: { reminderTimes[index] },
                        set: { reminderTimes[index] = $0 }
                    ), displayedComponents: .hourAndMinute)
                    .font(.appBody())
                    .foregroundColor(.textPrimary)
                    
                    Button(action: {
                        reminderTimes.remove(at: index)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(16)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(12)
            }
            
            Button(action: {
                reminderTimes.append(Date())
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(NSLocalizedString("add_reminder_time", comment: ""))
                }
                .font(.appBody())
                .foregroundColor(.accentPrimary)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(12)
            }
        }
    }
    
    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("usage_condition", comment: ""))
                .font(.appLabel())
                .foregroundColor(.textSecondary)
            
            TextField(NSLocalizedString("enter_condition", comment: ""), text: $usage)
                .font(.appBody())
                .foregroundColor(.textPrimary)
                .padding(16)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(12)
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("medication_guidance_hint", comment: ""))
                .font(.appLabel())
                .foregroundColor(.textSecondary)
            
            TextField(NSLocalizedString("add_notes", comment: ""), text: $instructions)
                .font(.appBody())
                .foregroundColor(.textPrimary)
                .padding(16)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(12)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("notes_label", comment: ""))
                .font(.appLabel())
                .foregroundColor(.textSecondary)
            
            TextEditor(text: $notes)
                .font(.appBody())
                .foregroundColor(.textPrimary)
                .frame(height: 100)
                .padding(12)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(12)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveMedication) {
            Text(NSLocalizedString("save", comment: ""))
                .font(.appSubheadline())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentPrimary)
                .cornerRadius(16)
        }
        .padding(.top, 8)
    }
    
    private var deleteButton: some View {
        Button(action: {
            showingDeleteAlert = true
        }) {
            HStack {
                Image(systemName: "trash")
                Text(NSLocalizedString("delete", comment: ""))
            }
            .font(.appSubheadline())
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.1))
            .cornerRadius(16)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Data Management
    
    private func loadMedicationData() {
        medicationName = medication.medicationName
        dosage = medication.dosage
        frequency = medication.frequency
        reminderTimes = medication.reminderTimes
        usage = medication.usage ?? ""
        instructions = medication.instructions ?? ""
        notes = medication.notes ?? ""
    }
    
    private func saveMedication() {
        // 验证输入
        guard !medicationName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        guard !dosage.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // 查找并更新药物
        if let index = healthDataManager.medicationReminders.firstIndex(where: { $0.id == medication.id }) {
            // 创建更新后的药物对象
            healthDataManager.medicationReminders[index].medicationName = medicationName
            healthDataManager.medicationReminders[index].dosage = dosage
            healthDataManager.medicationReminders[index].frequency = frequency
            healthDataManager.medicationReminders[index].reminderTimes = reminderTimes
            healthDataManager.medicationReminders[index].usage = usage.isEmpty ? nil : usage
            healthDataManager.medicationReminders[index].instructions = instructions.isEmpty ? nil : instructions
            healthDataManager.medicationReminders[index].notes = notes.isEmpty ? nil : notes
            
            healthDataManager.saveData()
        }
        
        isPresented = false
    }
    
    private func deleteMedication() {
        if let index = healthDataManager.medicationReminders.firstIndex(where: { $0.id == medication.id }) {
            healthDataManager.medicationReminders.remove(at: index)
            healthDataManager.saveData()
        }
        isPresented = false
    }
}

#Preview {
    MedicationView()
}


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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - My Medications Section - 应用新设计
struct MyMedicationsSection: View {
    let medications: [MedicationReminder]
    let onSelectMedication: (MedicationReminder) -> Void
    
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

// MARK: - Medication Detail Popup (悬浮弹窗版本)
struct MedicationDetailPopup: View {
    let medication: MedicationReminder
    @Binding var isPresented: Bool
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var showingInventory = false
    @State private var inventory: Int = 100
    @State private var showingDeleteAlert = false
    
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
                        // TODO: 编辑功能
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
                                    Text("剩余数量")
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
                detailCard(icon: "pills.circle.fill", label: "规格/剂量", value: medication.dosage)
                
                // 服用频率
                detailCard(icon: "clock.fill", label: "服用频率", value: frequencyText)
                
                // 服用时间
                if !medication.reminderTimes.isEmpty {
                    detailCard(icon: "alarm.fill", label: "服用时间", value: reminderTimesText)
                }
                
                // 剂型
                detailCard(icon: "capsule.fill", label: "剂型", value: medicationType)
                
                // 药物用途（跨两列）
                if let usage = medication.usage {
                    detailCard(icon: "heart.text.square.fill", label: "药物用途", value: usage, isWide: true)
                }
                
                // 服用说明（跨两列）
                if let instructions = medication.instructions {
                    detailCard(icon: "doc.text.fill", label: "服用说明", value: instructions, isWide: true)
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

#Preview {
    MedicationView()
}


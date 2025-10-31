//
//  HomeView.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var notificationManager = MedicalNotificationManager.shared
    @State private var showingHealthRecords = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HomeHeader()
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    
                    // Main Content
                    VStack(spacing: 32) {
                        // 数据概览
                        OverviewSection()
                            .padding(.horizontal, 20)
                        
                        // 今日用药
                        TodayMedicationSection()
                            .padding(.horizontal, 20)
                        
                        // 最近病历
                        RecentRecordsSection(showingHealthRecords: $showingHealthRecords)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color.appBackgroundColor)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingHealthRecords) {
                RecordsView()
                    .environmentObject(healthDataManager)
            }
        }
    }
}

// MARK: - Header - 优雅的标题设计
struct HomeHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("health_assistant", comment: ""))
                    .font(.appTitle()) // 使用衬线字体，更优雅
                    .foregroundColor(.textPrimary)
                    .fadeIn(delay: 0.1)
                
                HStack(spacing: 8) {
                    PulsingDot(color: .accentPrimary)
                    Text(NSLocalizedString("personal_health_center", comment: ""))
                        .font(.appCaption())
                        .foregroundColor(.textSecondary)
                }
                .fadeIn(delay: 0.3)
            }
            
            Spacer()
        }
    }
}

// MARK: - Overview Section
struct OverviewSection: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    private var pendingMedicationsCount: String {
        let todayMeds = healthDataManager.getTodayMedications()
        let totalCount = todayMeds.reduce(0) { $0 + $1.times.count }
        return "\(totalCount)"
    }
    
    private var totalRecordsCount: String {
        let count = healthDataManager.getHealthRecords().count
        return "\(count)"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                OverviewCard(
                    icon: "pills.fill",
                    label: NSLocalizedString("pending_medications", comment: ""),
                    value: pendingMedicationsCount
                )
                
                OverviewCard(
                    icon: "doc.text.fill",
                    label: NSLocalizedString("total_records", comment: ""),
                    value: totalRecordsCount
                )
            }
        }
    }
}

struct OverviewCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.12))
                    .frame(width: 54, height: 54)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.accentPrimary)
            }
            .slideIn(from: .top, delay: 0.2)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.appLargeNumber().weight(.bold))
                    .foregroundColor(.textPrimary)
                    .fadeIn(delay: 0.4)
                
                Text(label)
                    .font(.appSmall())
                    .foregroundColor(.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .fadeIn(delay: 0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackgroundColor)
        )
        .cardShadow()
    }
}

// MARK: - Today Medication Section
struct TodayMedicationSection: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var completedMedications: Set<String> = []  // 改用 String 来存储组合ID
    @State private var showingMedicationView = false
    
    // 生成唯一标识符：medicationId + scheduledTime
    private func makeItemId(medication: MedicationReminder, time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm"
        return "\(medication.id.uuidString)-\(formatter.string(from: time))"
    }
    
    private var todayMedications: [(medication: MedicationReminder, time: Date, itemId: String)] {
        return healthDataManager.getTodayMedications()
            .flatMap { item in
                item.times.map { time in
                    let itemId = makeItemId(medication: item.medication, time: time)
                    return (medication: item.medication, time: time, itemId: itemId)
                }
            }
            .filter { !completedMedications.contains($0.itemId) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("today_medications", comment: ""))
                    .font(.appHeadline())
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    showingMedicationView = true
                }) {
                    HStack(spacing: 4) {
                        Text(NSLocalizedString("view_all", comment: ""))
                            .font(.appCaption())
                        Image(systemName: "chevron.right")
                            .font(.appSmall())
                    }
                    .foregroundColor(.accentPrimary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if todayMedications.isEmpty {
                VStack(spacing: 20) {
                    // 插画式图标
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.successColor.opacity(0.15), Color.successColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40, weight: .medium, design: .rounded))
                            .foregroundColor(.successColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .shadow(color: Color.successColor.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("medications_completed", comment: ""))
                            .font(.appSubheadline())
                            .foregroundColor(.textPrimary)
                        
                        Text(NSLocalizedString("good_medication_habits", comment: ""))
                            .font(.appCaption())
                            .foregroundColor(.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.cardBackgroundColor)
                )
                .cardShadow()
                .fadeIn(delay: 0.2)
            } else {
                ForEach(todayMedications, id: \.itemId) { item in
                    TodayMedicationRow(
                        medication: item.medication,
                        time: item.time,
                        onComplete: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                _ = completedMedications.insert(item.itemId)
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .asymmetric(
                            insertion: .identity,
                            removal: .move(edge: .leading)
                                .combined(with: .opacity)
                                .combined(with: .scale(scale: 0.8))
                        )
                    ))
                }
            }
        }
        .sheet(isPresented: $showingMedicationView) {
            MedicationView()
                .environmentObject(healthDataManager)
        }
    }
}

struct TodayMedicationRow: View {
    let medication: MedicationReminder
    let time: Date
    let onComplete: () -> Void
    @State private var isCompleted = false
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧时间标记
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isCompleted ? .textTertiary : .accentPrimary)
                    .monospacedDigit()
                
                Circle()
                    .fill(isCompleted ? Color.textTertiary : Color.accentPrimary)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 60)
            
            // 中间药品信息
            VStack(alignment: .leading, spacing: 6) {
                Text(medication.medicationName)
                    .font(.appSubheadline())
                    .foregroundColor(isCompleted ? .textSecondary : .textPrimary)
                    .strikethrough(isCompleted)
                
                Text(medication.dosage)
                    .font(.appCaption())
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // 右侧完成按钮
            Button(action: {
                // 先显示完成动画
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isCompleted = true
                }
                
                // 记录服药
                healthDataManager.recordMedicationTaken(
                    medicationId: medication.id,
                    scheduledTime: time
                )
                
                // 延迟后触发消失动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onComplete()
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color.successColor : Color.dividerColor, lineWidth: 2.5)
                        .frame(width: 32, height: 32)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.successColor)
                            .clipShape(Circle())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackgroundColor)
        )
        .cardShadow()
        .opacity(isCompleted ? 0.6 : 1.0)
    }
}

// MARK: - Recent Records Section
struct RecentRecordsSection: View {
    @Binding var showingHealthRecords: Bool
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    // 获取最近的病历（最多3条，优先显示未归档，且只显示有医院信息的病例）
    private var recentArchivedRecords: [HealthRecord] {
        let allRecords = healthDataManager.getHealthRecords()
            .filter { record in
                // 过滤条件：医院名不为空、不包含"补充"、不为"待补充"
                !record.hospitalName.isEmpty &&
                !record.hospitalName.contains("补充") &&
                record.hospitalName != "待补充"
            }
            .sorted { $0.date > $1.date } // 按日期倒序
        
        // 优先显示未归档的，然后是已归档的
        let unarchivedRecords = allRecords.filter { !$0.isArchived }
        let archivedRecords = allRecords.filter { $0.isArchived }
        
        return (unarchivedRecords + archivedRecords)
            .prefix(3) // 最多显示3条
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("recent_cases", comment: ""))
                    .font(.appHeadline())
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    showingHealthRecords = true
                }) {
                    HStack(spacing: 4) {
                        Text(NSLocalizedString("view_all", comment: ""))
                            .font(.appCaption())
                        Image(systemName: "chevron.right")
                            .font(.appSmall())
                    }
                    .foregroundColor(.accentPrimary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if recentArchivedRecords.isEmpty {
                // 空状态 - 插画式设计
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentPrimary.opacity(0.15), Color.accentPrimary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)
                        
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 42, weight: .light, design: .rounded))
                            .foregroundColor(.accentPrimary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .shadow(color: Color.accentPrimary.opacity(0.15), radius: 12, x: 0, y: 6)
                    
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("start_health_records", comment: ""))
                            .font(.appSubheadline())
                            .foregroundColor(.textPrimary)
                        
                        Text(NSLocalizedString("create_first_record", comment: ""))
                            .font(.appCaption())
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.appCaption())
                            .foregroundColor(.successColor)
                        
                        Text(NSLocalizedString("easy_manage_anytime", comment: ""))
                            .font(.appSmall())
                            .foregroundColor(.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.cardBackgroundColor)
                )
                .cardShadow()
                .fadeIn(delay: 0.2)
            } else {
                ForEach(recentArchivedRecords) { record in
                    RealCaseFileCard(record: record)
                }
            }
        }
    }
}

// MARK: - 真实病历卡片（用于显示HealthRecord数据）
struct RealCaseFileCard: View {
    let record: HealthRecord
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: record.date)
    }
    
    private var hasContent: Bool {
        !record.audioRecordings.isEmpty || !record.attachments.isEmpty
    }
    
    private var contentSummary: String {
        var parts: [String] = []
        
        if !record.audioRecordings.isEmpty {
            let format = NSLocalizedString("recordings_count", comment: "")
            parts.append(String(format: format, record.audioRecordings.count))
        }
        
        if !record.attachments.isEmpty {
            let format = NSLocalizedString("reports_count", comment: "")
            parts.append(String(format: format, record.attachments.count))
        }
        
        return parts.joined(separator: " · ")
    }
    
    var body: some View {
        NavigationLink(destination: RecordDetailView(record: record)
            .environmentObject(healthDataManager)) {
            VStack(alignment: .leading, spacing: 0) {
                // 上半部分：医院和科室信息
                HStack(alignment: .center, spacing: 12) {
                    // 左侧医院图标
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentPrimary.opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.accentPrimary)
                    }
                    
                    // 中间医院和日期信息
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.hospitalName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(.textTertiary)
                            
                            Text(dateString)
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 右侧科室标签
                    Text(record.department)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentPrimary.opacity(0.12))
                        )
                }
                .padding(16)
                
                // 分割线
                if hasContent {
                    Divider()
                        .background(Color.dividerColor)
                    
                    // 下半部分：内容摘要
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.textTertiary)
                        
                        Text(contentSummary)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(Color.cardBackgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.dividerColor.opacity(0.5), lineWidth: 1)
            )
            .cardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 真实记录详情视图包装器
struct RecordDetailViewWrapper: View {
    let record: HealthRecord
    @Environment(\.dismiss) var dismiss
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 就诊"
        return formatter.string(from: record.date)
    }
    
    var body: some View {
        ZStack {
            Color.appBackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 自定义导航栏
                HStack(alignment: .center, spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    
                    Text("就诊详情")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.appBackgroundColor)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 医院和科室信息
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(record.department)
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                
                                Spacer()
                                
                                Text(dateString)
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Text(record.hospitalName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.cardBackgroundColor)
                        .cornerRadius(16)
                        .cardShadow()
                        
                        // 记录内容
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("record_content", comment: ""))
                                .font(.appSubheadline())
                                .foregroundColor(.textPrimary)
                            
                            // 录音记录
                            if !record.audioRecordings.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(record.audioRecordings, id: \.date) { audio in
                                        HStack(spacing: 12) {
                                            Image(systemName: "mic.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.textSecondary)
                                                .frame(width: 16, height: 16)
                                            
                                            Text(audio.title ?? NSLocalizedString("recording", comment: ""))
                                                .font(.appCaption())
                                                .foregroundColor(.textSecondary)
                                            
                                            Spacer()
                                            
                                            Text(String(format: NSLocalizedString("minutes_format_short", comment: ""), Int(audio.duration / 60)))
                                                .font(.appSmall())
                                                .foregroundColor(.textTertiary)
                                        }
                                        .padding(12)
                                        .background(Color.secondaryBackgroundColor)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            
                            // 报告照片
                            if !record.attachments.isEmpty {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.textSecondary)
                                        .frame(width: 16, height: 16)
                                    
                                    Text(String(format: NSLocalizedString("reports_count", comment: ""), record.attachments.count))
                                        .font(.appCaption())
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(12)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(12)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.cardBackgroundColor)
                        .cornerRadius(16)
                        .cardShadow()
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct CaseFileCard: View {
    let hospital: String
    let department: String
    let date: String
    let items: [CaseItem]
    
    var body: some View {
        NavigationLink(destination: StaticRecordDetailView(
            hospital: hospital,
            department: department,
            date: date,
            items: items
        )) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hospital)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text(date)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(department)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondaryBackgroundColor)
                        .cornerRadius(6)
                }
                
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                                .frame(width: 16, height: 16)
                            
                            Text(item.text)
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(12)
                        .background(Color.secondaryBackgroundColor)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(20)
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

struct CaseItem: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

// MARK: - 静态记录详情视图
struct StaticRecordDetailView: View {
    let hospital: String
    let department: String
    let date: String
    let items: [CaseItem]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 自定义导航栏
                HStack(alignment: .center, spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    
                    Text(NSLocalizedString("visit_details", comment: ""))
                        .font(.appHeadline())
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.appBackgroundColor)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 医院和科室信息
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(department)
                                    .font(.appCaption())
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                
                                Spacer()
                                
                                Text(date)
                                    .font(.appCaption())
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Text(hospital)
                                .font(.appTitle())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.cardBackgroundColor)
                        .cornerRadius(16)
                        .cardShadow()
                        
                        // 记录项目
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("record_content", comment: ""))
                                .font(.appSubheadline())
                                .foregroundColor(.textPrimary)
                            
                            VStack(spacing: 8) {
                                ForEach(items) { item in
                                    HStack(spacing: 12) {
                                        Image(systemName: item.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(.textSecondary)
                                            .frame(width: 16, height: 16)
                                        
                                        Text(item.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(12)
                                    .background(Color.secondaryBackgroundColor)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.cardBackgroundColor)
                        .cornerRadius(16)
                        .cardShadow()
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(HealthDataManager.shared)
        .environmentObject(LanguageManager.shared)
}

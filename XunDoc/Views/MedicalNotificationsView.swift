//
//  MedicalNotificationsView.swift
//  XunDoc
//
//  医疗通知提醒视图
//

import SwiftUI

struct MedicalNotificationsView: View {
    @EnvironmentObject var notificationManager: MedicalNotificationManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedFilter: NotificationFilter = .all
    @State private var showingAddNotification = false
    @State private var notificationToEdit: MedicalNotification?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选器
                NotificationFilterBar(selectedFilter: $selectedFilter)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                
                // 通知列表
                if filteredNotifications.isEmpty {
                    EmptyNotificationView(filter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredNotifications) { notification in
                                NotificationCard(
                                    notification: notification,
                                    onComplete: {
                                        notificationManager.completeNotification(notification)
                                    },
                                    onToggle: {
                                        notificationManager.toggleNotification(notification)
                                    },
                                    onEdit: {
                                        notificationToEdit = notification
                                    },
                                    onDelete: {
                                        notificationManager.deleteNotification(notification)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("医疗提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // 添加按钮
                        Button(action: { showingAddNotification = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        // 菜单按钮
                        Menu {
                            Button(action: { 
                                notificationManager.deleteCompletedNotifications(for: UUID())
                            }) {
                                Label("清除已完成", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddNotification) {
                AddNotificationView()
                    .environmentObject(notificationManager)
                    .environmentObject(healthDataManager)
            }
            .sheet(item: $notificationToEdit) { notification in
                EditNotificationView(notification: notification)
                    .environmentObject(notificationManager)
                    .environmentObject(healthDataManager)
            }
        }
    }
    
    private var filteredNotifications: [MedicalNotification] {
        let allNotifications = notificationManager.notifications
        let defaultMemberId = UUID() // 使用默认成员ID
        
        switch selectedFilter {
        case .all:
            return allNotifications.filter { !$0.isCompleted }
        case .today:
            return notificationManager.getTodayNotifications(for: defaultMemberId)
        case .upcoming:
            return notificationManager.getUpcomingNotifications(for: defaultMemberId)
        case .overdue:
            return notificationManager.getOverdueNotifications(for: defaultMemberId)
        case .completed:
            return allNotifications.filter { $0.isCompleted }
        case .type(let type):
            return allNotifications.filter { $0.type == type && !$0.isCompleted }
        }
    }
}

// MARK: - 通知筛选枚举
enum NotificationFilter: Hashable {
    case all
    case today
    case upcoming
    case overdue
    case completed
    case type(MedicalNotificationType)
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .today: return "今天"
        case .upcoming: return "即将到来"
        case .overdue: return "已过期"
        case .completed: return "已完成"
        case .type(let type): return type.displayName
        }
    }
}

// MARK: - 筛选栏
struct NotificationFilterBar: View {
    @Binding var selectedFilter: NotificationFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                NotificationFilterChip(
                    title: NotificationFilter.all.displayName,
                    isSelected: selectedFilter == .all,
                    action: { selectedFilter = .all }
                )
                
                NotificationFilterChip(
                    title: NotificationFilter.today.displayName,
                    isSelected: selectedFilter == .today,
                    action: { selectedFilter = .today }
                )
                
                NotificationFilterChip(
                    title: NotificationFilter.upcoming.displayName,
                    isSelected: selectedFilter == .upcoming,
                    action: { selectedFilter = .upcoming }
                )
                
                NotificationFilterChip(
                    title: NotificationFilter.overdue.displayName,
                    isSelected: selectedFilter == .overdue,
                    color: .red,
                    action: { selectedFilter = .overdue }
                )
                
                NotificationFilterChip(
                    title: NotificationFilter.completed.displayName,
                    isSelected: selectedFilter == .completed,
                    color: .green,
                    action: { selectedFilter = .completed }
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Notification Filter Chip
struct NotificationFilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - 通知卡片
struct NotificationCard: View {
    let notification: MedicalNotification
    let onComplete: () -> Void
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：类型图标、标题和优先级
            HStack(alignment: .top, spacing: 12) {
                // 类型图标
                ZStack {
                    Circle()
                        .fill(notification.type.color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(notification.type.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 标题和优先级
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 优先级标签
                        if notification.priority == .high || notification.priority == .urgent {
                            Text(notification.priority.displayName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(notification.priority.color)
                                .cornerRadius(10)
                        }
                    }
                    
                    // 类型标签
                    Text(notification.type.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(notification.type.color)
                }
            }
            
            // 消息内容
            Text(notification.message)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // 详细信息（根据类型显示）
            if let details = notificationDetails {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(details, id: \.0) { detail in
                        HStack(spacing: 8) {
                            Image(systemName: detail.icon)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .frame(width: 16)
                            
                            Text(detail.text)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // 底部：时间和操作按钮
            HStack {
                // 时间显示
                HStack(spacing: 6) {
                    Image(systemName: notification.isCompleted ? "checkmark.circle.fill" : (isOverdue ? "exclamationmark.triangle.fill" : "clock.fill"))
                        .font(.system(size: 14))
                        .foregroundColor(notification.isCompleted ? .green : (isOverdue ? .red : .blue))
                    
                    Text(timeText)
                        .font(.system(size: 13))
                        .foregroundColor(notification.isCompleted ? .green : (isOverdue ? .red : .gray))
                }
                
                Spacer()
                
                // 操作按钮
                if !notification.isCompleted {
                    HStack(spacing: 16) {
                        Button(action: onComplete) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: { showingActionSheet = true }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding()
        .background(notification.isCompleted ? Color.green.opacity(0.05) : Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(notification.isCompleted ? Color.green.opacity(0.3) : Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .opacity(notification.isEnabled ? 1.0 : 0.5)
        .confirmationDialog("选择操作", isPresented: $showingActionSheet) {
            if !notification.isCompleted {
                Button("编辑") {
                    onEdit()
                }
                
                Button(notification.isEnabled ? "禁用提醒" : "启用提醒") {
                    onToggle()
                }
            }
            
            Button("删除", role: .destructive) {
                onDelete()
            }
            
            Button("取消", role: .cancel) { }
        }
    }
    
    private var isOverdue: Bool {
        !notification.isCompleted && notification.scheduledDate < Date()
    }
    
    private var timeText: String {
        if notification.isCompleted {
            return "已完成"
        } else if isOverdue {
            let interval = Date().timeIntervalSince(notification.scheduledDate)
            let days = Int(interval / 86400)
            if days > 0 {
                return "已逾期 \(days) 天"
            } else {
                let hours = Int(interval / 3600)
                return "已逾期 \(hours) 小时"
            }
        } else {
            return formatDate(notification.scheduledDate)
        }
    }
    
    private var notificationDetails: [(icon: String, text: String)]? {
        var details: [(icon: String, text: String)] = []
        
        switch notification.type {
        case .medication:
            if let name = notification.medicationName {
                details.append(("pills.fill", "药物: \(name)"))
            }
            if let dosage = notification.dosage {
                details.append(("number", "剂量: \(dosage)"))
            }
            if let frequency = notification.frequency {
                details.append(("clock.arrow.circlepath", frequency))
            }
            
        case .appointment, .followUp:
            if let hospital = notification.hospitalName {
                details.append(("building.2.fill", hospital))
            }
            if let department = notification.departmentName {
                details.append(("cross.case", department))
            }
            if let doctor = notification.doctorName {
                details.append(("person.fill", "医生: \(doctor)"))
            }
            
        case .vaccination:
            if let vaccine = notification.vaccineName {
                details.append(("cross.vial.fill", vaccine))
            }
            if let site = notification.vaccinationSite {
                details.append(("location.fill", site))
            }
            
        default:
            break
        }
        
        if let notes = notification.notes, !notes.isEmpty {
            details.append(("note.text", notes))
        }
        
        return details.isEmpty ? nil : details
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "今天 \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "明天 \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日 HH:mm"
            return formatter.string(from: date)
        }
    }
}

// MARK: - 空通知视图
struct EmptyNotificationView: View {
    let filter: NotificationFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: emptyIcon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(emptyTitle)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var emptyIcon: String {
        switch filter {
        case .completed:
            return "checkmark.circle"
        case .overdue:
            return "exclamationmark.triangle"
        default:
            return "bell.slash"
        }
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all:
            return "暂无提醒"
        case .today:
            return "今天没有提醒"
        case .upcoming:
            return "暂无即将到来的提醒"
        case .overdue:
            return "没有过期的提醒"
        case .completed:
            return "暂无已完成的提醒"
        case .type(let type):
            return "暂无\(type.displayName)"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all:
            return "点击右上角添加新的医疗提醒"
        case .today:
            return "今天没有安排提醒事项"
        case .upcoming:
            return "未来一周内没有安排的提醒"
        case .overdue:
            return "太棒了！没有逾期的提醒"
        case .completed:
            return "还没有完成任何提醒"
        case .type:
            return "点击右上角添加新的提醒"
        }
    }
}

// MARK: - 添加通知视图（简化版）
struct AddNotificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var notificationManager: MedicalNotificationManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    @State private var selectedType: MedicalNotificationType = .medication
    @State private var title = ""
    @State private var message = ""
    @State private var scheduledDate = Date()
    @State private var priority: NotificationPriority = .normal
    @State private var isRecurring = false
    @State private var recurrenceInterval: RecurrenceInterval = .daily
    
    var body: some View {
        NavigationView {
            Form {
                Section("通知类型") {
                    Picker("类型", selection: $selectedType) {
                        ForEach(MedicalNotificationType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section("基本信息") {
                    TextField("标题", text: $title)
                    TextField("消息内容", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("时间设置") {
                    DatePicker("提醒时间", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("重复提醒", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("重复频率", selection: $recurrenceInterval) {
                            ForEach(RecurrenceInterval.allCases, id: \.self) { interval in
                                Text(interval.displayName).tag(interval)
                            }
                        }
                    }
                }
                
                Section("优先级") {
                    Picker("优先级", selection: $priority) {
                        ForEach([NotificationPriority.low, .normal, .high, .urgent], id: \.self) { p in
                            HStack {
                                Circle()
                                    .fill(p.color)
                                    .frame(width: 12, height: 12)
                                Text(p.displayName)
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("添加提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveNotification()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !title.isEmpty && !message.isEmpty
    }
    
    private func saveNotification() {
        let notification = MedicalNotification(
            memberId: UUID(),  // 使用默认UUID
            type: selectedType,
            title: title,
            message: message,
            scheduledDate: scheduledDate,
            priority: priority,
            isRecurring: isRecurring,
            recurrenceInterval: isRecurring ? recurrenceInterval : nil
        )
        
        notificationManager.addNotification(notification)
        dismiss()
    }
}

// MARK: - 编辑通知视图
struct EditNotificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var notificationManager: MedicalNotificationManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    let notification: MedicalNotification
    
    @State private var title = ""
    @State private var message = ""
    @State private var scheduledDate = Date()
    @State private var priority: NotificationPriority = .normal
    @State private var isRecurring = false
    @State private var recurrenceInterval: RecurrenceInterval = .daily
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                    TextField("消息内容", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("时间设置") {
                    DatePicker("提醒时间", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("重复提醒", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("重复频率", selection: $recurrenceInterval) {
                            ForEach(RecurrenceInterval.allCases, id: \.self) { interval in
                                Text(interval.displayName).tag(interval)
                            }
                        }
                    }
                }
                
                Section("优先级") {
                    Picker("优先级", selection: $priority) {
                        ForEach([NotificationPriority.low, .normal, .high, .urgent], id: \.self) { p in
                            HStack {
                                Circle()
                                    .fill(p.color)
                                    .frame(width: 12, height: 12)
                                Text(p.displayName)
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("编辑提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                loadNotificationData()
            }
        }
    }
    
    private var canSave: Bool {
        !title.isEmpty && !message.isEmpty
    }
    
    private func loadNotificationData() {
        title = notification.title
        message = notification.message
        scheduledDate = notification.scheduledDate
        priority = notification.priority
        isRecurring = notification.isRecurring
        recurrenceInterval = notification.recurrenceInterval ?? .daily
    }
    
    private func saveChanges() {
        var updated = notification
        updated.title = title
        updated.message = message
        updated.scheduledDate = scheduledDate
        updated.priority = priority
        updated.isRecurring = isRecurring
        updated.recurrenceInterval = isRecurring ? recurrenceInterval : nil
        
        notificationManager.updateNotification(updated)
        dismiss()
    }
}

#Preview {
    MedicalNotificationsView()
        .environmentObject(MedicalNotificationManager.shared)
        .environmentObject(HealthDataManager.shared)
        .environmentObject(LanguageManager.shared)
}


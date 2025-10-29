//
//  使用示例代码.swift
//  XunDoc
//
//  新功能使用示例
//
//  注意：这是一个示例文件，展示如何使用新功能的API
//  请不要将此文件添加到项目中，仅供参考
//

import SwiftUI
import Foundation

// MARK: - 示例1：创建各种类型的医疗通知

func createMedicationReminderExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 使用预设模板创建药物提醒
    let medicationReminder = MedicalNotification.medicationTemplate(
        memberId: member.id,
        memberName: member.name,
        medicationName: "阿莫西林",
        dosage: "一次一片",
        frequency: "一日三次，饭后服用",
        scheduledDate: Date().addingTimeInterval(3600) // 1小时后
    )
    
    notificationManager.addNotification(medicationReminder)
}

func createFollowUpReminderExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 创建复查提醒
    let followUpDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    
    let followUpReminder = MedicalNotification.followUpTemplate(
        memberId: member.id,
        checkupItem: "血压复查",
        date: followUpDate,
        hospitalName: "北京协和医院",
        departmentName: "心血管内科"
    )
    
    notificationManager.addNotification(followUpReminder)
}

func createAppointmentReminderExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 创建预约提醒
    let appointmentDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    
    let appointmentReminder = MedicalNotification.appointmentTemplate(
        memberId: member.id,
        doctorName: "张医生",
        date: appointmentDate,
        hospitalName: "北京协和医院",
        departmentName: "内科门诊"
    )
    
    notificationManager.addNotification(appointmentReminder)
}

func createHealthCheckReminderExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 创建健康检查提醒
    let checkDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
    
    let healthCheckReminder = MedicalNotification.healthCheckTemplate(
        memberId: member.id,
        memberName: member.name,
        checkType: "年度体检",
        scheduledDate: checkDate
    )
    
    notificationManager.addNotification(healthCheckReminder)
}

func createVaccinationReminderExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 创建疫苗接种提醒
    let vaccinationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    
    let vaccinationReminder = MedicalNotification.vaccinationTemplate(
        memberId: member.id,
        memberName: member.name,
        vaccineName: "流感疫苗",
        date: vaccinationDate,
        vaccinationSite: "社区卫生服务中心"
    )
    
    notificationManager.addNotification(vaccinationReminder)
}

// MARK: - 示例2：手动创建自定义通知

func createCustomNotificationExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 手动创建完全自定义的通知
    let customNotification = MedicalNotification(
        memberId: member.id,
        type: .symptomTracking,
        title: "记录血压",
        message: "请记录今日早晨的血压数据，保持每日监测有助于了解健康状况。",
        scheduledDate: Date().addingTimeInterval(86400), // 明天同一时间
        priority: .normal,
        isRecurring: true,
        recurrenceInterval: .daily,
        notes: "空腹测量，连续测量3次取平均值"
    )
    
    notificationManager.addNotification(customNotification)
}

// MARK: - 示例3：查询通知

func queryNotificationsExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 获取所有通知
    let allNotifications = notificationManager.getNotifications(for: member.id)
    print("总共有 \(allNotifications.count) 个通知")
    
    // 获取今天的通知
    let todayNotifications = notificationManager.getTodayNotifications(for: member.id)
    print("今天有 \(todayNotifications.count) 个提醒")
    
    // 获取即将到来的通知（未来7天）
    let upcomingNotifications = notificationManager.getUpcomingNotifications(for: member.id, days: 7)
    print("未来7天有 \(upcomingNotifications.count) 个提醒")
    
    // 获取过期的通知
    let overdueNotifications = notificationManager.getOverdueNotifications(for: member.id)
    print("有 \(overdueNotifications.count) 个过期提醒")
    
    // 获取特定类型的通知
    let medicationNotifications = notificationManager.getNotificationsByType(
        for: member.id,
        type: .medication
    )
    print("有 \(medicationNotifications.count) 个药物提醒")
    
    // 获取统计信息
    let stats = notificationManager.getNotificationStats(for: member.id)
    print("""
        统计信息:
        - 总数: \(stats.total)
        - 活跃: \(stats.active)
        - 已完成: \(stats.completed)
        - 过期: \(stats.overdue)
        - 今天: \(stats.today)
        - 即将到来: \(stats.upcoming)
        """)
}

// MARK: - 示例4：更新和管理通知

func updateNotificationExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 获取第一个通知
    guard var notification = notificationManager.getNotifications(for: member.id).first else {
        return
    }
    
    // 修改通知属性
    notification.title = "更新后的标题"
    notification.message = "更新后的消息内容"
    notification.scheduledDate = Date().addingTimeInterval(7200) // 2小时后
    notification.priority = .high
    
    // 保存更新
    notificationManager.updateNotification(notification)
    print("通知已更新")
}

func completeNotificationExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 获取今天的第一个未完成通知
    guard let notification = notificationManager.getTodayNotifications(for: member.id)
        .filter({ !$0.isCompleted })
        .first else {
        return
    }
    
    // 标记为完成
    notificationManager.completeNotification(notification)
    print("通知已完成")
    
    // 如果是重复通知，会自动创建下一次提醒
}

func toggleNotificationExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 获取第一个通知
    guard let notification = notificationManager.getNotifications(for: member.id).first else {
        return
    }
    
    // 切换启用/禁用状态
    notificationManager.toggleNotification(notification)
    print("通知状态已切换: \(notification.isEnabled ? "已启用" : "已禁用")")
}

func deleteNotificationExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 获取第一个通知
    guard let notification = notificationManager.getNotifications(for: member.id).first else {
        return
    }
    
    // 删除通知
    notificationManager.deleteNotification(notification)
    print("通知已删除")
}

// MARK: - 示例5：批量操作

func batchOperationsExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 清除所有已完成的通知
    notificationManager.deleteCompletedNotifications(for: member.id)
    print("已清除所有已完成的通知")
    
    // 清理30天前的旧通知
    notificationManager.cleanupOldNotifications(olderThanDays: 30)
    print("已清理30天前的旧通知")
    
    // 删除某个成员的所有通知
    // 警告：此操作不可逆！
    // notificationManager.deleteAllNotifications(for: member.id)
}

// MARK: - 示例6：在SwiftUI视图中使用

struct NotificationExampleView: View {
    @EnvironmentObject var notificationManager: MedicalNotificationManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        VStack {
            // 显示今天的通知数量
            if let member = healthDataManager.currentMember {
                let todayCount = notificationManager.getTodayNotifications(for: member.id).count
                
                Text("今天有 \(todayCount) 个提醒")
                    .font(.headline)
                
                // 创建药物提醒按钮
                Button("创建药物提醒") {
                    createMedicationReminder(for: member.id)
                }
                .buttonStyle(.borderedProminent)
                
                // 显示通知列表
                List {
                    ForEach(notificationManager.getActiveNotifications(for: member.id)) { notification in
                        NotificationRowView(notification: notification)
                    }
                }
            }
        }
    }
    
    private func createMedicationReminder(for memberId: UUID) {
        guard let member = healthDataManager.currentMember else { return }
        
        let reminder = MedicalNotification.medicationTemplate(
            memberId: memberId,
            memberName: member.name,
            medicationName: "示例药物",
            dosage: "一次一片",
            frequency: "一日三次",
            scheduledDate: Date().addingTimeInterval(3600)
        )
        
        notificationManager.addNotification(reminder)
    }
}

struct NotificationRowView: View {
    let notification: MedicalNotification
    @EnvironmentObject var notificationManager: MedicalNotificationManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(notification.title)
                    .font(.headline)
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                notificationManager.completeNotification(notification)
            }) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - 示例7：权限管理

func requestNotificationPermissionExample() async {
    let notificationManager = MedicalNotificationManager.shared
    
    // 请求通知权限
    let granted = await notificationManager.requestNotificationPermission()
    
    if granted {
        print("✅ 通知权限已授权")
    } else {
        print("❌ 通知权限被拒绝")
    }
}

func checkNotificationPermissionExample() {
    let notificationManager = MedicalNotificationManager.shared
    
    if notificationManager.hasPermission {
        print("✅ 已有通知权限")
    } else {
        print("❌ 没有通知权限，需要用户授权")
    }
}

// MARK: - 示例8：高级功能

func createRecurringNotificationExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 创建每天重复的提醒
    let dailyReminder = MedicalNotification(
        memberId: member.id,
        type: .medication,
        title: "早晨用药提醒",
        message: "请在早餐后30分钟服用降压药",
        scheduledDate: getNextMorning8AM(),
        priority: .high,
        isRecurring: true,
        recurrenceInterval: .daily
    )
    
    notificationManager.addNotification(dailyReminder)
}

func createUrgentNotificationExample() {
    let notificationManager = MedicalNotificationManager.shared
    let healthDataManager = HealthDataManager.shared
    
    guard let member = healthDataManager.currentMember else { return }
    
    // 创建紧急提醒
    let urgentReminder = MedicalNotification(
        memberId: member.id,
        type: .appointment,
        title: "紧急就诊提醒",
        message: "您的急诊预约将在30分钟后开始，请尽快前往医院",
        scheduledDate: Date().addingTimeInterval(1800), // 30分钟后
        priority: .urgent
    )
    
    notificationManager.addNotification(urgentReminder)
}

// MARK: - 辅助函数

func getNextMorning8AM() -> Date {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 8
    components.minute = 0
    components.second = 0
    
    if let date = calendar.date(from: components), date > Date() {
        return date
    } else {
        // 如果今天8点已过，返回明天8点
        return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)!
    }
}

// MARK: - 使用说明

/*
 
 如何在您的代码中使用这些功能：
 
 1. 在需要使用通知功能的视图中，添加环境对象：
    @EnvironmentObject var notificationManager: MedicalNotificationManager
    @EnvironmentObject var healthDataManager: HealthDataManager
 
 2. 调用上述示例函数来创建、查询、更新通知
 
 3. 主要API方法：
    - addNotification(_:)           // 添加通知
    - updateNotification(_:)        // 更新通知
    - deleteNotification(_:)        // 删除通知
    - completeNotification(_:)      // 完成通知
    - toggleNotification(_:)        // 切换启用状态
    - getNotifications(for:)        // 获取所有通知
    - getTodayNotifications(for:)   // 获取今天的通知
    - getUpcomingNotifications(for:days:) // 获取即将到来的通知
    - getOverdueNotifications(for:) // 获取过期通知
    - getNotificationStats(for:)    // 获取统计信息
 
 4. 通知模板方法：
    - MedicalNotification.medicationTemplate(...)
    - MedicalNotification.followUpTemplate(...)
    - MedicalNotification.appointmentTemplate(...)
    - MedicalNotification.healthCheckTemplate(...)
    - MedicalNotification.vaccinationTemplate(...)
 
 5. 权限管理：
    - requestNotificationPermission() // 请求权限
    - hasPermission                   // 检查权限状态
 
 完整的使用示例请参考 MedicalNotificationsView.swift 和 HomeView.swift
 
 */


//
//  MedicalNotificationManager.swift
//  XunDoc
//
//  医疗通知管理器
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
class MedicalNotificationManager: ObservableObject {
    static let shared = MedicalNotificationManager()
    
    @Published var notifications: [MedicalNotification] = []
    @Published var hasPermission: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let notificationsKey = "MedicalNotifications"
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        loadNotifications()
        checkNotificationPermission()
    }
    
    // MARK: - 权限管理
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                hasPermission = granted
            }
            return granted
        } catch {
            print("通知权限请求失败: \(error)")
            await MainActor.run {
                hasPermission = false
            }
            return false
        }
    }
    
    private func checkNotificationPermission() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - 通知管理
    func addNotification(_ notification: MedicalNotification) {
        notifications.append(notification)
        saveNotifications()
        
        if notification.isEnabled {
            scheduleNotification(notification)
        }
    }
    
    func updateNotification(_ notification: MedicalNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification
            saveNotifications()
            
            // 取消旧的通知并重新调度
            cancelNotification(notification.id)
            if notification.isEnabled && !notification.isCompleted {
                scheduleNotification(notification)
            }
        }
    }
    
    func deleteNotification(_ notification: MedicalNotification) {
        notifications.removeAll { $0.id == notification.id }
        saveNotifications()
        cancelNotification(notification.id)
    }
    
    func deleteNotifications(_ notificationsToDelete: [MedicalNotification]) {
        for notification in notificationsToDelete {
            deleteNotification(notification)
        }
    }
    
    func toggleNotification(_ notification: MedicalNotification) {
        var updated = notification
        updated.isEnabled.toggle()
        updateNotification(updated)
    }
    
    func completeNotification(_ notification: MedicalNotification) {
        var updated = notification
        updated.isCompleted = true
        updated.completedDate = Date()
        
        // 如果是重复通知，创建下一次提醒
        if updated.isRecurring, let interval = updated.recurrenceInterval,
           let nextDate = interval.nextDate(from: updated.scheduledDate) {
            // 创建新的通知实例（不能修改id，因为它是let常量）
            let nextNotification = MedicalNotification(
                memberId: updated.memberId,
                type: updated.type,
                title: updated.title,
                message: updated.message,
                scheduledDate: nextDate,
                priority: updated.priority,
                isRecurring: updated.isRecurring,
                recurrenceInterval: updated.recurrenceInterval,
                isCompleted: false,
                completedDate: nil,
                isEnabled: updated.isEnabled,
                notes: updated.notes,
                medicationName: updated.medicationName,
                dosage: updated.dosage,
                frequency: updated.frequency,
                hospitalName: updated.hospitalName,
                departmentName: updated.departmentName,
                doctorName: updated.doctorName,
                appointmentDate: updated.appointmentDate,
                vaccineName: updated.vaccineName,
                vaccinationSite: updated.vaccinationSite
            )
            addNotification(nextNotification)
        }
        
        updateNotification(updated)
    }
    
    // MARK: - 通知调度
    private func scheduleNotification(_ notification: MedicalNotification) {
        guard hasPermission else {
            print("没有通知权限")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = .default
        content.badge = 1
        
        // 根据优先级设置不同的通知样式
        switch notification.priority {
        case .urgent:
            content.sound = .defaultCritical
        case .high:
            content.interruptionLevel = .timeSensitive
        default:
            content.interruptionLevel = .active
        }
        
        // 添加通知类型信息到userInfo
        content.userInfo = [
            "notificationId": notification.id.uuidString,
            "type": notification.type.rawValue,
            "priority": notification.priority.rawValue
        ]
        
        // 计算触发时间
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notification.scheduledDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        // 添加到通知中心
        notificationCenter.add(request) { error in
            if let error = error {
                print("通知调度失败: \(error)")
            } else {
                print("通知已调度: \(notification.title) at \(notification.scheduledDate)")
            }
        }
    }
    
    private func cancelNotification(_ id: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [id.uuidString])
    }
    
    // MARK: - 查询方法
    func getNotifications(for memberId: UUID) -> [MedicalNotification] {
        return notifications
            .filter { $0.memberId == memberId }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    func getActiveNotifications(for memberId: UUID) -> [MedicalNotification] {
        return notifications
            .filter { $0.memberId == memberId && $0.isEnabled && !$0.isCompleted }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    func getNotificationsByType(for memberId: UUID, type: MedicalNotificationType) -> [MedicalNotification] {
        return notifications
            .filter { $0.memberId == memberId && $0.type == type }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    func getUpcomingNotifications(for memberId: UUID, days: Int = 7) -> [MedicalNotification] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return notifications
            .filter { 
                $0.memberId == memberId && 
                $0.isEnabled && 
                !$0.isCompleted &&
                $0.scheduledDate >= Date() && 
                $0.scheduledDate <= endDate 
            }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    func getTodayNotifications(for memberId: UUID) -> [MedicalNotification] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        return notifications
            .filter { 
                $0.memberId == memberId && 
                $0.isEnabled && 
                !$0.isCompleted &&
                $0.scheduledDate >= startOfDay && 
                $0.scheduledDate < endOfDay 
            }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    func getOverdueNotifications(for memberId: UUID) -> [MedicalNotification] {
        return notifications
            .filter { 
                $0.memberId == memberId && 
                $0.isEnabled && 
                !$0.isCompleted &&
                $0.scheduledDate < Date()
            }
            .sorted { $0.scheduledDate > $1.scheduledDate }
    }
    
    // MARK: - 统计信息
    func getNotificationStats(for memberId: UUID) -> NotificationStats {
        let memberNotifications = notifications.filter { $0.memberId == memberId }
        
        return NotificationStats(
            total: memberNotifications.count,
            active: memberNotifications.filter { $0.isEnabled && !$0.isCompleted }.count,
            completed: memberNotifications.filter { $0.isCompleted }.count,
            overdue: getOverdueNotifications(for: memberId).count,
            today: getTodayNotifications(for: memberId).count,
            upcoming: getUpcomingNotifications(for: memberId).count
        )
    }
    
    // MARK: - 持久化
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            userDefaults.set(encoded, forKey: notificationsKey)
        }
    }
    
    private func loadNotifications() {
        if let data = userDefaults.data(forKey: notificationsKey),
           let decoded = try? JSONDecoder().decode([MedicalNotification].self, from: data) {
            notifications = decoded
            
            // 重新调度所有启用且未完成的通知
            Task {
                for notification in notifications where notification.isEnabled && !notification.isCompleted {
                    scheduleNotification(notification)
                }
            }
        }
    }
    
    // MARK: - 批量操作
    func deleteCompletedNotifications(for memberId: UUID) {
        let completedNotifications = notifications.filter { 
            $0.memberId == memberId && $0.isCompleted 
        }
        deleteNotifications(completedNotifications)
    }
    
    func deleteAllNotifications(for memberId: UUID) {
        let memberNotifications = notifications.filter { $0.memberId == memberId }
        deleteNotifications(memberNotifications)
    }
    
    // MARK: - 清理过期通知
    func cleanupOldNotifications(olderThanDays days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let oldNotifications = notifications.filter { 
            $0.isCompleted && 
            ($0.completedDate ?? $0.scheduledDate) < cutoffDate 
        }
        deleteNotifications(oldNotifications)
    }
}

// MARK: - 通知统计模型
struct NotificationStats {
    let total: Int
    let active: Int
    let completed: Int
    let overdue: Int
    let today: Int
    let upcoming: Int
}


//
//  HealthDataManager.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HealthDataManager: ObservableObject {
    static let shared = HealthDataManager()
    
    @Published var healthRecords: [HealthRecord] = []
    @Published var chronicDiseaseData: [ChronicDiseaseData] = []
    @Published var aiConsultations: [AIConsultation] = []
    @Published var medicationReminders: [MedicationReminder] = []
    @Published var medicationTakenRecords: [MedicationTakenRecord] = []
    
    private let userDefaults = UserDefaults.standard
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    init() {
        loadData()
    }
    
    // MARK: - 数据持久化
    func saveData() {
        print("💾 HealthDataManager.saveData 开始...")
        
        // 保存健康记录
        if let encoded = try? JSONEncoder().encode(healthRecords) {
            userDefaults.set(encoded, forKey: "healthRecords")
            print("  ✅ 已保存 \(healthRecords.count) 条健康记录")
        } else {
            print("  ❌ 健康记录编码失败")
        }
        
        // 保存慢性病数据
        if let encoded = try? JSONEncoder().encode(chronicDiseaseData) {
            userDefaults.set(encoded, forKey: "chronicDiseaseData")
        }
        
        // 保存AI咨询记录
        if let encoded = try? JSONEncoder().encode(aiConsultations) {
            userDefaults.set(encoded, forKey: "aiConsultations")
        }
        
        // 保存用药提醒
        if let encoded = try? JSONEncoder().encode(medicationReminders) {
            userDefaults.set(encoded, forKey: "medicationReminders")
        }
        
        // 保存服药记录
        if let encoded = try? JSONEncoder().encode(medicationTakenRecords) {
            userDefaults.set(encoded, forKey: "medicationTakenRecords")
            print("  ✅ 已保存 \(medicationTakenRecords.count) 条服药记录")
        }
        
        print("💾 HealthDataManager.saveData 完成")
    }
    
    func loadData() {
        // 加载健康记录
        if let data = userDefaults.data(forKey: "healthRecords"),
           let decoded = try? JSONDecoder().decode([HealthRecord].self, from: data) {
            healthRecords = decoded
        }
        
        // 加载慢性病数据
        if let data = userDefaults.data(forKey: "chronicDiseaseData"),
           let decoded = try? JSONDecoder().decode([ChronicDiseaseData].self, from: data) {
            chronicDiseaseData = decoded
        }
        
        // 加载AI咨询记录
        if let data = userDefaults.data(forKey: "aiConsultations"),
           let decoded = try? JSONDecoder().decode([AIConsultation].self, from: data) {
            aiConsultations = decoded
        }
        
        // 加载用药提醒
        if let data = userDefaults.data(forKey: "medicationReminders"),
           let decoded = try? JSONDecoder().decode([MedicationReminder].self, from: data) {
            medicationReminders = decoded
        }
        
        // 加载服药记录
        if let data = userDefaults.data(forKey: "medicationTakenRecords"),
           let decoded = try? JSONDecoder().decode([MedicationTakenRecord].self, from: data) {
            medicationTakenRecords = decoded
            print("📋 已加载 \(medicationTakenRecords.count) 条服药记录")
        }
    }
    
    // MARK: - 健康记录管理
    func addHealthRecord(_ record: HealthRecord) {
        healthRecords.append(record)
        print("💾 HealthDataManager.addHealthRecord:")
        print("  - 记录ID: \(record.id)")
        print("  - 医院: \(record.hospitalName)")
        print("  - 科室: \(record.department)")
        print("  - 归档: \(record.isArchived)")
        print("  - 总记录数: \(healthRecords.count)")
        saveData()
        print("  - 保存完成")
    }
    
    func updateHealthRecord(_ record: HealthRecord) {
        if let index = healthRecords.firstIndex(where: { $0.id == record.id }) {
            healthRecords[index] = record
            saveData()
        }
    }
    
    func deleteHealthRecord(_ record: HealthRecord) {
        healthRecords.removeAll { $0.id == record.id }
        saveData()
    }
    
    func getHealthRecords() -> [HealthRecord] {
        return healthRecords.sorted { $0.date > $1.date }
    }
    
    func getUnarchivedRecords() -> [HealthRecord] {
        return healthRecords.filter { !$0.isArchived }
            .sorted { $0.date > $1.date }
    }
    
    func getArchivedRecords() -> [HealthRecord] {
        return healthRecords.filter { $0.isArchived }
            .sorted { $0.date > $1.date }
    }
    
    func getTodayMedications() -> [(medication: MedicationReminder, times: [Date])] {
        let activeMedications = getActiveMedicationReminders()
        let calendar = Calendar.current
        let today = Date()
        
        print("📅 获取今日用药:")
        print("活跃药物数量: \(activeMedications.count)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        var todayMeds: [(medication: MedicationReminder, times: [Date])] = []
        
        for medication in activeMedications {
            print("\n检查药物: \(medication.medicationName)")
            print("提醒时间数量: \(medication.reminderTimes.count)")
            
            // 将reminderTimes中的时间部分（小时:分钟）应用到今天
            let todayTimes = medication.reminderTimes.compactMap { originalTime -> Date? in
                let hour = calendar.component(.hour, from: originalTime)
                let minute = calendar.component(.minute, from: originalTime)
                
                // 创建今天的该时间
                var components = calendar.dateComponents([.year, .month, .day], from: today)
                components.hour = hour
                components.minute = minute
                
                return calendar.date(from: components)
            }
            
            // 过滤掉已服用的时间
            let unTakenTimes = todayTimes.filter { scheduledTime in
                !isMedicationTaken(medicationId: medication.id, scheduledTime: scheduledTime)
            }
            
            print("  - 总服药次数: \(todayTimes.count)")
            print("  - 未服用次数: \(unTakenTimes.count)")
            
            if !unTakenTimes.isEmpty {
                print("✅ 添加到今日用药列表，共 \(unTakenTimes.count) 次")
                todayMeds.append((medication: medication, times: unTakenTimes))
            } else {
                print("❌ 无待服用时间")
            }
        }
        
        print("\n今日用药总数: \(todayMeds.count)")
        return todayMeds
    }
    
    // MARK: - 服药记录管理
    
    /// 记录服药
    func recordMedicationTaken(medicationId: UUID, scheduledTime: Date) {
        let record = MedicationTakenRecord(
            medicationId: medicationId,
            takenDate: Date(),
            scheduledTime: scheduledTime
        )
        medicationTakenRecords.append(record)
        saveData()
        
        print("✅ 已记录服药: \(scheduledTime)")
        print("📊 当前服药记录总数: \(medicationTakenRecords.count)")
    }
    
    /// 检查某个药物在某个时间是否已服用
    func isMedicationTaken(medicationId: UUID, scheduledTime: Date) -> Bool {
        let calendar = Calendar.current
        
        // 查找是否有匹配的服药记录
        let taken = medicationTakenRecords.contains { record in
            record.medicationId == medicationId &&
            calendar.isDate(record.scheduledTime, equalTo: scheduledTime, toGranularity: .minute)
        }
        
        return taken
    }
    
    /// 清理过期的服药记录（保留最近7天）
    func cleanOldMedicationRecords() {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let oldCount = medicationTakenRecords.count
        medicationTakenRecords.removeAll { record in
            record.takenDate < sevenDaysAgo
        }
        
        if medicationTakenRecords.count != oldCount {
            saveData()
            print("🗑️ 已清理 \(oldCount - medicationTakenRecords.count) 条过期服药记录")
        }
    }
    
    // MARK: - 慢性病数据管理
    func addChronicDiseaseData(_ data: ChronicDiseaseData) {
        chronicDiseaseData.append(data)
        saveData()
    }
    
    func getChronicDiseaseData(type: ChronicDiseaseData.DiseaseType) -> [ChronicDiseaseData] {
        return chronicDiseaseData
            .filter { $0.diseaseType == type }
            .sorted { $0.date < $1.date }
    }
    
    func getLatestChronicDiseaseData() -> [ChronicDiseaseData.DiseaseType: ChronicDiseaseData] {
        var latestData: [ChronicDiseaseData.DiseaseType: ChronicDiseaseData] = [:]
        
        for type in ChronicDiseaseData.DiseaseType.allCases {
            if let latest = chronicDiseaseData
                .filter({ $0.diseaseType == type })
                .sorted(by: { $0.date > $1.date })
                .first {
                latestData[type] = latest
            }
        }
        
        return latestData
    }
    
    // MARK: - AI咨询管理
    func addAIConsultation(_ consultation: AIConsultation) {
        aiConsultations.append(consultation)
        saveData()
    }
    
    func getAIConsultations() -> [AIConsultation] {
        return aiConsultations.sorted { $0.date > $1.date }
    }
    
    // MARK: - 用药提醒管理
    func addMedicationReminder(_ reminder: MedicationReminder) {
        medicationReminders.append(reminder)
        saveData()
        
        // 自动创建通知
        Task {
            await createNotificationsForMedication(reminder)
        }
    }
    
    func updateMedicationReminder(_ reminder: MedicationReminder) {
        if let index = medicationReminders.firstIndex(where: { $0.id == reminder.id }) {
            medicationReminders[index] = reminder
            saveData()
            
            // 更新通知
            Task {
                await createNotificationsForMedication(reminder)
            }
        }
    }
    
    func deleteMedicationReminder(_ reminder: MedicationReminder) {
        medicationReminders.removeAll { $0.id == reminder.id }
        saveData()
        
        // 取消通知
        Task {
            await cancelNotificationsForMedication(reminder.id)
        }
    }
    
    func getActiveMedicationReminders() -> [MedicationReminder] {
        return medicationReminders.filter { $0.isActive }
    }
    
    // MARK: - 药物通知管理
    
    /// 为药物创建通知
    private func createNotificationsForMedication(_ medication: MedicationReminder) async {
        let notificationManager = await MedicalNotificationManager.shared
        await notificationManager.scheduleMedicationReminders(medication: medication)
    }
    
    /// 取消药物的所有通知
    private func cancelNotificationsForMedication(_ medicationId: UUID) async {
        let notificationManager = await MedicalNotificationManager.shared
        await notificationManager.cancelMedicationReminders(medicationId: medicationId)
    }
    
    /// 同步所有活跃药物的通知
    func syncAllMedicationNotifications() async {
        let notificationManager = await MedicalNotificationManager.shared
        
        // 请求通知权限
        let hasPermission = await notificationManager.requestNotificationPermission()
        
        if hasPermission {
            // 为所有活跃药物创建通知
            let activeMeds = getActiveMedicationReminders()
            await notificationManager.scheduleMedicationReminders(medications: activeMeds)
            print("✅ 已同步 \(activeMeds.count) 个药物的通知")
        } else {
            print("❌ 通知权限被拒绝")
        }
    }
    
    // MARK: - 数据分析
    func generateHealthReport(dateRange: DateInterval) -> HealthReport {
        let records = healthRecords.filter { dateRange.contains($0.date) }
        let chronicData = chronicDiseaseData.filter { dateRange.contains($0.date) }
        let consultations = aiConsultations.filter { dateRange.contains($0.date) }
        
        return HealthReport(
            dateRange: dateRange,
            recordCount: records.count,
            chronicDataCount: chronicData.count,
            consultationCount: consultations.count,
            averageBloodPressure: calculateAverage(for: chronicData.filter { $0.diseaseType == .bloodPressure }),
            averageBloodSugar: calculateAverage(for: chronicData.filter { $0.diseaseType == .bloodSugar }),
            trends: analyzeTrends(chronicData)
        )
    }
    
    private func calculateAverage(for data: [ChronicDiseaseData]) -> Double? {
        guard !data.isEmpty else { return nil }
        let sum = data.reduce(0) { $0 + $1.value }
        return sum / Double(data.count)
    }
    
    private func analyzeTrends(_ data: [ChronicDiseaseData]) -> [String] {
        // 简单的趋势分析逻辑
        var trends: [String] = []
        
        for type in ChronicDiseaseData.DiseaseType.allCases {
            let typeData = data.filter { $0.diseaseType == type }.sorted { $0.date < $1.date }
            guard typeData.count >= 2 else { continue }
            
            let recent = typeData.suffix(5)
            let older = typeData.dropLast(5).suffix(5)
            
            if !recent.isEmpty && !older.isEmpty {
                let recentAvg = recent.reduce(0) { $0 + $1.value } / Double(recent.count)
                let olderAvg = older.reduce(0) { $0 + $1.value } / Double(older.count)
                
                if recentAvg > olderAvg * 1.1 {
                    trends.append("\(type.localized) " + NSLocalizedString("trend_increasing", comment: ""))
                } else if recentAvg < olderAvg * 0.9 {
                    trends.append("\(type.localized) " + NSLocalizedString("trend_decreasing", comment: ""))
                } else {
                    trends.append("\(type.localized) " + NSLocalizedString("trend_stable", comment: ""))
                }
            }
        }
        
        return trends
    }
    
}

// MARK: - 健康报告模型
struct HealthReport {
    let dateRange: DateInterval
    let recordCount: Int
    let chronicDataCount: Int
    let consultationCount: Int
    let averageBloodPressure: Double?
    let averageBloodSugar: Double?
    let trends: [String]
}


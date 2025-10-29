//
//  MedicalNotification.swift
//  XunDoc
//
//  医疗通知系统数据模型
//

import Foundation
import SwiftUI

// MARK: - 医疗通知类型枚举
enum MedicalNotificationType: String, Codable, CaseIterable {
    case medication = "medication"           // 药物提醒
    case followUp = "follow_up"             // 复查提醒
    case appointment = "appointment"         // 预约提醒
    case healthCheck = "health_check"       // 健康检查提醒
    case symptomTracking = "symptom_tracking" // 症状追踪提醒
    case vaccination = "vaccination"        // 疫苗接种提醒
    
    var displayName: String {
        switch self {
        case .medication: return "药物提醒"
        case .followUp: return "复查提醒"
        case .appointment: return "预约提醒"
        case .healthCheck: return "健康检查"
        case .symptomTracking: return "症状追踪"
        case .vaccination: return "疫苗接种"
        }
    }
    
    var icon: String {
        switch self {
        case .medication: return "pills.fill"
        case .followUp: return "clock.arrow.circlepath"
        case .appointment: return "calendar.badge.clock"
        case .healthCheck: return "heart.text.square.fill"
        case .symptomTracking: return "chart.line.uptrend.xyaxis.circle.fill"
        case .vaccination: return "cross.vial.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .medication: return .blue
        case .followUp: return .orange
        case .appointment: return .purple
        case .healthCheck: return .green
        case .symptomTracking: return .pink
        case .vaccination: return .teal
        }
    }
}

// MARK: - 医疗通知优先级
enum NotificationPriority: String, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "普通"
        case .normal: return "正常"
        case .high: return "重要"
        case .urgent: return "紧急"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - 医疗通知模型
struct MedicalNotification: Identifiable, Codable {
    let id: UUID
    let memberId: UUID                      // 关联的家庭成员ID
    var type: MedicalNotificationType       // 通知类型
    var title: String                       // 通知标题
    var message: String                     // 通知内容
    var scheduledDate: Date                 // 计划通知时间
    var priority: NotificationPriority      // 优先级
    var isRecurring: Bool                   // 是否重复
    var recurrenceInterval: RecurrenceInterval? // 重复间隔
    var isCompleted: Bool                   // 是否已完成
    var completedDate: Date?                // 完成时间
    var isEnabled: Bool                     // 是否启用
    var notes: String?                      // 备注
    
    // 药物提醒相关字段
    var medicationName: String?             // 药品名称
    var dosage: String?                     // 剂量
    var frequency: String?                  // 用法
    
    // 预约/复查相关字段
    var hospitalName: String?               // 医院名称
    var departmentName: String?             // 科室名称
    var doctorName: String?                 // 医生姓名
    var appointmentDate: Date?              // 预约时间
    
    // 疫苗接种相关字段
    var vaccineName: String?                // 疫苗名称
    var vaccinationSite: String?            // 接种地点
    
    init(
        id: UUID = UUID(),
        memberId: UUID,
        type: MedicalNotificationType,
        title: String,
        message: String,
        scheduledDate: Date,
        priority: NotificationPriority = .normal,
        isRecurring: Bool = false,
        recurrenceInterval: RecurrenceInterval? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        isEnabled: Bool = true,
        notes: String? = nil,
        medicationName: String? = nil,
        dosage: String? = nil,
        frequency: String? = nil,
        hospitalName: String? = nil,
        departmentName: String? = nil,
        doctorName: String? = nil,
        appointmentDate: Date? = nil,
        vaccineName: String? = nil,
        vaccinationSite: String? = nil
    ) {
        self.id = id
        self.memberId = memberId
        self.type = type
        self.title = title
        self.message = message
        self.scheduledDate = scheduledDate
        self.priority = priority
        self.isRecurring = isRecurring
        self.recurrenceInterval = recurrenceInterval
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.isEnabled = isEnabled
        self.notes = notes
        self.medicationName = medicationName
        self.dosage = dosage
        self.frequency = frequency
        self.hospitalName = hospitalName
        self.departmentName = departmentName
        self.doctorName = doctorName
        self.appointmentDate = appointmentDate
        self.vaccineName = vaccineName
        self.vaccinationSite = vaccinationSite
    }
}

// MARK: - 重复间隔枚举
enum RecurrenceInterval: String, Codable, CaseIterable {
    case daily = "daily"
    case twiceDaily = "twice_daily"
    case threeTimesDaily = "three_times_daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return "每天"
        case .twiceDaily: return "每天两次"
        case .threeTimesDaily: return "每天三次"
        case .weekly: return "每周"
        case .biweekly: return "每两周"
        case .monthly: return "每月"
        case .quarterly: return "每季度"
        case .yearly: return "每年"
        }
    }
    
    func nextDate(from date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .twiceDaily:
            return calendar.date(byAdding: .hour, value: 12, to: date)
        case .threeTimesDaily:
            return calendar.date(byAdding: .hour, value: 8, to: date)
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}

// MARK: - 预设通知模板
extension MedicalNotification {
    // 药物提醒模板
    static func medicationTemplate(
        memberId: UUID,
        memberName: String,
        medicationName: String,
        dosage: String,
        frequency: String,
        scheduledDate: Date
    ) -> MedicalNotification {
        let message = "您好，\(memberName)。提醒您按时服用 \(medicationName)，\(dosage)。\(frequency)。请遵医嘱。"
        
        return MedicalNotification(
            memberId: memberId,
            type: .medication,
            title: "用药提醒",
            message: message,
            scheduledDate: scheduledDate,
            priority: .high,
            isRecurring: true,
            medicationName: medicationName,
            dosage: dosage,
            frequency: frequency
        )
    }
    
    // 复查提醒模板
    static func followUpTemplate(
        memberId: UUID,
        checkupItem: String,
        date: Date,
        hospitalName: String,
        departmentName: String
    ) -> MedicalNotification {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        let dateString = dateFormatter.string(from: date)
        
        let message = "温馨提示：您预约的 \(checkupItem) 将于 \(dateString) 进行，请提前做好准备，按时前往 \(hospitalName) \(departmentName)。"
        
        return MedicalNotification(
            memberId: memberId,
            type: .followUp,
            title: "复查提醒",
            message: message,
            scheduledDate: Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date,
            priority: .high,
            hospitalName: hospitalName,
            departmentName: departmentName,
            appointmentDate: date
        )
    }
    
    // 预约提醒模板
    static func appointmentTemplate(
        memberId: UUID,
        doctorName: String,
        date: Date,
        hospitalName: String,
        departmentName: String
    ) -> MedicalNotification {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        let dateString = dateFormatter.string(from: date)
        
        let message = "提醒您，您与 \(doctorName) 医生的门诊预约安排在 \(dateString)，地点：\(hospitalName) \(departmentName)，请不要忘记。"
        
        return MedicalNotification(
            memberId: memberId,
            type: .appointment,
            title: "就诊预约提醒",
            message: message,
            scheduledDate: Calendar.current.date(byAdding: .hour, value: -2, to: date) ?? date,
            priority: .high,
            hospitalName: hospitalName,
            departmentName: departmentName,
            doctorName: doctorName,
            appointmentDate: date
        )
    }
    
    // 健康检查提醒模板
    static func healthCheckTemplate(
        memberId: UUID,
        memberName: String,
        checkType: String,
        scheduledDate: Date
    ) -> MedicalNotification {
        let message = "您好，\(memberName)。您的\(checkType)时间快到了，建议您近期安排一次全面的身体检查，关注自身健康。"
        
        return MedicalNotification(
            memberId: memberId,
            type: .healthCheck,
            title: "健康检查提醒",
            message: message,
            scheduledDate: scheduledDate,
            priority: .normal,
            isRecurring: true,
            recurrenceInterval: .yearly
        )
    }
    
    // 症状追踪提醒模板
    static func symptomTrackingTemplate(
        memberId: UUID,
        memberName: String,
        symptomName: String,
        scheduledDate: Date
    ) -> MedicalNotification {
        let message = "提醒您记录今日的\(symptomName)情况，坚持追踪有助于医生更好地了解您的健康状况。"
        
        return MedicalNotification(
            memberId: memberId,
            type: .symptomTracking,
            title: "症状追踪提醒",
            message: message,
            scheduledDate: scheduledDate,
            priority: .normal,
            isRecurring: true,
            recurrenceInterval: .daily
        )
    }
    
    // 疫苗接种提醒模板
    static func vaccinationTemplate(
        memberId: UUID,
        memberName: String,
        vaccineName: String,
        date: Date,
        vaccinationSite: String
    ) -> MedicalNotification {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        let dateString = dateFormatter.string(from: date)
        
        let message = "\(memberName)，提醒您 \(dateString) 前往 \(vaccinationSite) 接种 \(vaccineName)。请携带相关证件，注意接种前后事项。"
        
        return MedicalNotification(
            memberId: memberId,
            type: .vaccination,
            title: "疫苗接种提醒",
            message: message,
            scheduledDate: Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date,
            priority: .high,
            appointmentDate: date,
            vaccineName: vaccineName,
            vaccinationSite: vaccinationSite
        )
    }
}


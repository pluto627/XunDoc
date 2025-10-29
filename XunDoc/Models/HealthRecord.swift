//
//  HealthRecord.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import Foundation
import SwiftUI

// MARK: - 健康记录模型（就诊记录）
struct HealthRecord: Identifiable, Codable {
    let id = UUID()
    var hospitalName: String // 医院名称
    var department: String // 科室
    var date: Date
    var symptoms: String // 主要症状
    var diagnosis: String? // 诊断结果
    var treatment: String? // 治疗方案
    var attachments: [Data] // 报告照片
    var audioRecordings: [AudioRecording] = [] // 录音记录
    var medicalReports: [MedicalReportRef] = [] // 医疗报告引用
    var notes: String? // 备注
    var isArchived: Bool = false // 是否已归档
    
    // 向后兼容的字段
    var recordType: RecordType = .outpatient
    var title: String {
        return hospitalName
    }
    var description: String {
        return symptoms
    }
    var tags: [String] = []
    
    // 录音记录结构
    struct AudioRecording: Identifiable, Codable {
        let id = UUID()
        var audioData: Data
        var duration: TimeInterval
        var date: Date
        var title: String?
        var transcribedText: String? // 转录文本
        var isTranscribed: Bool = false // 是否已转录
    }
    
    // 医疗报告引用（关联到MedicalReport）
    struct MedicalReportRef: Identifiable, Codable {
        let id: UUID // 对应MedicalReport的ID
        var title: String
        var reportType: String
        var fileType: String
        
        init(id: UUID, title: String, reportType: String, fileType: String) {
            self.id = id
            self.title = title
            self.reportType = reportType
            self.fileType = fileType
        }
    }
    
    enum RecordType: String, Codable, CaseIterable {
        case outpatient = "Outpatient" // 门诊
        case emergency = "Emergency" // 急诊
        case inpatient = "Inpatient" // 住院
        case physical = "Physical" // 体检
        case other = "Other"
        
        var icon: String {
            switch self {
            case .outpatient: return "stethoscope"
            case .emergency: return "cross.case.fill"
            case .inpatient: return "bed.double.fill"
            case .physical: return "heart.text.square.fill"
            case .other: return "doc.text.fill"
            }
        }
        
        var localized: String {
            switch self {
            case .outpatient: return NSLocalizedString("record_outpatient", comment: "")
            case .emergency: return NSLocalizedString("record_emergency", comment: "")
            case .inpatient: return NSLocalizedString("record_inpatient", comment: "")
            case .physical: return NSLocalizedString("record_physical", comment: "")
            case .other: return NSLocalizedString("record_other", comment: "")
            }
        }
    }
}

// MARK: - 慢性病数据模型
struct ChronicDiseaseData: Identifiable, Codable {
    let id = UUID()
    var diseaseType: DiseaseType
    var date: Date
    var value: Double
    var unit: String
    var notes: String?
    
    enum DiseaseType: String, Codable, CaseIterable {
        case bloodPressure = "Blood Pressure"
        case bloodSugar = "Blood Sugar"
        case heartRate = "Heart Rate"
        case weight = "Weight"
        case temperature = "Temperature"
        case oxygenSaturation = "Oxygen Saturation"
        
        var icon: String {
            switch self {
            case .bloodPressure: return "heart.fill"
            case .bloodSugar: return "drop.fill"
            case .heartRate: return "waveform.path.ecg"
            case .weight: return "scalemass.fill"
            case .temperature: return "thermometer"
            case .oxygenSaturation: return "lungs.fill"
            }
        }
        
        var unit: String {
            switch self {
            case .bloodPressure: return "mmHg"
            case .bloodSugar: return "mg/dL"
            case .heartRate: return "bpm"
            case .weight: return "kg"
            case .temperature: return "°C"
            case .oxygenSaturation: return "%"
            }
        }
        
        var localized: String {
            switch self {
            case .bloodPressure: return NSLocalizedString("disease_blood_pressure", comment: "")
            case .bloodSugar: return NSLocalizedString("disease_blood_sugar", comment: "")
            case .heartRate: return NSLocalizedString("disease_heart_rate", comment: "")
            case .weight: return NSLocalizedString("disease_weight", comment: "")
            case .temperature: return NSLocalizedString("disease_temperature", comment: "")
            case .oxygenSaturation: return NSLocalizedString("disease_oxygen", comment: "")
            }
        }
    }
}

// MARK: - AI咨询记录
struct AIConsultation: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var symptomImage: Data?
    var symptoms: [String]
    var aiAnalysis: String
    var recommendations: [String]
    var severity: Severity
    
    enum Severity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .urgent: return .red
            }
        }
        
        var localized: String {
            switch self {
            case .low: return NSLocalizedString("severity_low", comment: "")
            case .medium: return NSLocalizedString("severity_medium", comment: "")
            case .high: return NSLocalizedString("severity_high", comment: "")
            case .urgent: return NSLocalizedString("severity_urgent", comment: "")
            }
        }
    }
}

// MARK: - 用药提醒
struct MedicationReminder: Identifiable, Codable {
    let id = UUID()
    var medicationName: String
    var dosage: String
    var frequency: Frequency
    var startDate: Date
    var endDate: Date?
    var reminderTimes: [Date]
    var notes: String?
    var isActive: Bool
    var usage: String? // 药物用途
    var instructions: String? // 服用说明
    
    enum Frequency: String, Codable, CaseIterable {
        case onceDaily = "Once Daily"
        case twiceDaily = "Twice Daily"
        case threeTimesDaily = "Three Times Daily"
        case fourTimesDaily = "Four Times Daily"
        case asNeeded = "As Needed"
        
        var localized: String {
            switch self {
            case .onceDaily: return NSLocalizedString("frequency_once_daily", comment: "")
            case .twiceDaily: return NSLocalizedString("frequency_twice_daily", comment: "")
            case .threeTimesDaily: return NSLocalizedString("frequency_three_times_daily", comment: "")
            case .fourTimesDaily: return NSLocalizedString("frequency_four_times_daily", comment: "")
            case .asNeeded: return NSLocalizedString("frequency_as_needed", comment: "")
            }
        }
    }
}


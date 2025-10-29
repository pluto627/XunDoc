//
//  MedicalPrescription.swift
//  XunDoc
//
//  医嘱/处方模型
//

import Foundation

// MARK: - 医嘱类型
enum PrescriptionType: String, Codable {
    case handwritten = "handwritten"     // 手写处方
    case electronic = "electronic"       // 电子处方
    case structured = "structured"       // 结构化医嘱
    
    var displayName: String {
        switch self {
        case .handwritten: return "手写处方"
        case .electronic: return "电子处方"
        case .structured: return "结构化医嘱"
        }
    }
}

// MARK: - 处方项目
struct PrescriptionItem: Identifiable, Codable {
    let id: UUID
    var medicationName: String      // 药品名称
    var dosage: String              // 剂量
    var frequency: String           // 频次
    var duration: String            // 疗程
    var instructions: String?       // 用法说明
    var quantity: Int?              // 数量
    var unit: String?               // 单位
    
    init(
        id: UUID = UUID(),
        medicationName: String,
        dosage: String,
        frequency: String,
        duration: String,
        instructions: String? = nil,
        quantity: Int? = nil,
        unit: String? = nil
    ) {
        self.id = id
        self.medicationName = medicationName
        self.dosage = dosage
        self.frequency = frequency
        self.duration = duration
        self.instructions = instructions
        self.quantity = quantity
        self.unit = unit
    }
}

// MARK: - 医嘱/处方
struct MedicalPrescription: Identifiable, Codable {
    let id: UUID
    let memberId: UUID
    var type: PrescriptionType
    var date: Date
    var hospitalName: String
    var department: String?
    var doctorName: String
    var diagnosis: String?          // 诊断
    
    // 手写处方图片
    var prescriptionImages: [Data]
    
    // 结构化处方数据
    var items: [PrescriptionItem]
    
    // 元数据
    var notes: String?
    var isProcessed: Bool           // 是否已处理(识别/归档)
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        memberId: UUID,
        type: PrescriptionType,
        date: Date,
        hospitalName: String,
        department: String? = nil,
        doctorName: String,
        diagnosis: String? = nil,
        prescriptionImages: [Data] = [],
        items: [PrescriptionItem] = [],
        notes: String? = nil,
        isProcessed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.memberId = memberId
        self.type = type
        self.date = date
        self.hospitalName = hospitalName
        self.department = department
        self.doctorName = doctorName
        self.diagnosis = diagnosis
        self.prescriptionImages = prescriptionImages
        self.items = items
        self.notes = notes
        self.isProcessed = isProcessed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 是否包含结构化数据
    var hasStructuredData: Bool {
        !items.isEmpty
    }
    
    // 是否包含图片
    var hasImages: Bool {
        !prescriptionImages.isEmpty
    }
}


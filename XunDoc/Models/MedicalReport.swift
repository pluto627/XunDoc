//
//  MedicalReport.swift
//  XunDoc
//
//  医疗报告模型 - 支持Excel和图片
//

import Foundation
import SwiftUI

// MARK: - 报告类型
enum ReportType: String, Codable {
    case bloodTest = "blood_test"           // 血常规
    case urineTest = "urine_test"           // 尿常规
    case ctScan = "ct_scan"                 // CT扫描
    case mriScan = "mri_scan"               // MRI扫描
    case xray = "xray"                      // X光
    case ultrasound = "ultrasound"          // 超声
    case ecg = "ecg"                        // 心电图
    case liverFunction = "liver_function"   // 肝功能
    case kidneyFunction = "kidney_function" // 肾功能
    case bloodSugar = "blood_sugar"         // 血糖
    case bloodLipids = "blood_lipids"       // 血脂
    case thyroidFunction = "thyroid"        // 甲状腺功能
    case tumorMarker = "tumor_marker"       // 肿瘤标志物
    case other = "other"                    // 其他
    
    var displayName: String {
        switch self {
        case .bloodTest: return "血常规"
        case .urineTest: return "尿常规"
        case .ctScan: return "CT扫描"
        case .mriScan: return "MRI扫描"
        case .xray: return "X光片"
        case .ultrasound: return "超声检查"
        case .ecg: return "心电图"
        case .liverFunction: return "肝功能"
        case .kidneyFunction: return "肾功能"
        case .bloodSugar: return "血糖检查"
        case .bloodLipids: return "血脂检查"
        case .thyroidFunction: return "甲状腺功能"
        case .tumorMarker: return "肿瘤标志物"
        case .other: return "其他检查"
        }
    }
    
    var icon: String {
        switch self {
        case .bloodTest: return "drop.fill"
        case .urineTest: return "drop"
        case .ctScan, .mriScan, .xray: return "scan.fill"
        case .ultrasound: return "waveform.path.ecg"
        case .ecg: return "waveform.path.ecg.rectangle"
        case .liverFunction, .kidneyFunction: return "cross.case.fill"
        case .bloodSugar, .bloodLipids: return "chart.line.uptrend.xyaxis"
        case .thyroidFunction: return "pills.circle.fill"
        case .tumorMarker: return "staroflife.fill"
        case .other: return "doc.text.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bloodTest: return .red
        case .urineTest: return .yellow
        case .ctScan, .mriScan, .xray: return .blue
        case .ultrasound: return .cyan
        case .ecg: return .green
        case .liverFunction, .kidneyFunction: return .orange
        case .bloodSugar: return .purple
        case .bloodLipids: return .pink
        case .thyroidFunction: return .indigo
        case .tumorMarker: return .red
        case .other: return .gray
        }
    }
    
    // 智能分类关键词
    var keywords: [String] {
        switch self {
        case .bloodTest: return ["血常规", "white blood cell", "WBC", "红细胞", "RBC", "血红蛋白", "HGB", "血小板"]
        case .urineTest: return ["尿常规", "尿液", "urine", "尿检"]
        case .ctScan: return ["CT", "计算机断层", "computed tomography"]
        case .mriScan: return ["MRI", "核磁共振", "magnetic resonance"]
        case .xray: return ["X光", "X-ray", "胸片", "chest"]
        case .ultrasound: return ["超声", "B超", "ultrasound", "彩超"]
        case .ecg: return ["心电图", "ECG", "EKG", "electrocardiogram"]
        case .liverFunction: return ["肝功能", "liver function", "ALT", "AST", "转氨酶"]
        case .kidneyFunction: return ["肾功能", "kidney function", "肌酐", "creatinine", "尿素"]
        case .bloodSugar: return ["血糖", "glucose", "GLU", "糖化血红蛋白", "HbA1c"]
        case .bloodLipids: return ["血脂", "lipid", "胆固醇", "cholesterol", "甘油三酯", "triglyceride"]
        case .thyroidFunction: return ["甲状腺", "thyroid", "TSH", "T3", "T4"]
        case .tumorMarker: return ["肿瘤标志物", "tumor marker", "癌胚抗原", "CEA", "AFP"]
        case .other: return []
        }
    }
    
    // 智能分类函数
    static func classify(from text: String) -> ReportType {
        let lowercasedText = text.lowercased()
        
        // 按优先级检查关键词
        for reportType in allCases where reportType != .other {
            for keyword in reportType.keywords {
                if lowercasedText.contains(keyword.lowercased()) {
                    return reportType
                }
            }
        }
        
        return .other
    }
    
    static var allCases: [ReportType] {
        return [.bloodTest, .urineTest, .ctScan, .mriScan, .xray, .ultrasound, .ecg,
                .liverFunction, .kidneyFunction, .bloodSugar, .bloodLipids,
                .thyroidFunction, .tumorMarker, .other]
    }
}

// MARK: - 报告文件类型
enum ReportFileType: String, Codable {
    case excel = "excel"
    case image = "image"
    case pdf = "pdf"
    
    var displayName: String {
        switch self {
        case .excel: return "Excel表格"
        case .image: return "图片"
        case .pdf: return "PDF文档"
        }
    }
}

// MARK: - 医疗报告模型
struct MedicalReport: Identifiable, Codable {
    let id: UUID
    let memberId: UUID                  // 关联的家庭成员ID
    var title: String                   // 报告标题
    var reportType: ReportType          // 报告类型（自动分类）
    var fileType: ReportFileType        // 文件类型
    var date: Date                      // 报告日期
    var hospitalName: String            // 医院名称
    var department: String?             // 科室
    var doctorName: String?             // 医生姓名
    var notes: String?                  // 备注
    
    // 文件数据
    var excelData: Data?                // Excel文件数据
    var excelFileName: String?          // Excel文件名
    var imageData: Data?                // 图片数据（压缩后）
    var pdfData: Data?                  // PDF数据
    
    // 元数据
    var isStarred: Bool                 // 是否标星
    var tags: [String]                  // 标签
    var createdAt: Date                 // 创建时间
    var updatedAt: Date                 // 更新时间
    
    init(
        id: UUID = UUID(),
        memberId: UUID,
        title: String,
        reportType: ReportType = .other,
        fileType: ReportFileType,
        date: Date,
        hospitalName: String,
        department: String? = nil,
        doctorName: String? = nil,
        notes: String? = nil,
        excelData: Data? = nil,
        excelFileName: String? = nil,
        imageData: Data? = nil,
        pdfData: Data? = nil,
        isStarred: Bool = false,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.memberId = memberId
        self.title = title
        self.reportType = reportType
        self.fileType = fileType
        self.date = date
        self.hospitalName = hospitalName
        self.department = department
        self.doctorName = doctorName
        self.notes = notes
        self.excelData = excelData
        self.excelFileName = excelFileName
        self.imageData = imageData
        self.pdfData = pdfData
        self.isStarred = isStarred
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 自动分类报告类型
    mutating func autoClassify() {
        let combinedText = "\(title) \(hospitalName) \(department ?? "") \(notes ?? "")"
        self.reportType = ReportType.classify(from: combinedText)
    }
}


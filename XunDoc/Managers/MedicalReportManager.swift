//
//  MedicalReportManager.swift
//  XunDoc
//
//  医疗报告管理器
//

import Foundation
import SwiftUI
import UIKit

class MedicalReportManager: ObservableObject {
    static let shared = MedicalReportManager()
    
    @Published var reports: [MedicalReport] = []
    
    private let reportsKey = "medical_reports"
    
    init() {
        loadReports()
    }
    
    // MARK: - 数据持久化
    
    private func loadReports() {
        if let data = UserDefaults.standard.data(forKey: reportsKey),
           let decoded = try? JSONDecoder().decode([MedicalReport].self, from: data) {
            reports = decoded
            print("✅ 加载了 \(reports.count) 份报告")
        }
    }
    
    func saveReports() {
        if let encoded = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(encoded, forKey: reportsKey)
            print("💾 保存了 \(reports.count) 份报告")
        }
    }
    
    // MARK: - 报告管理
    
    func addReport(_ report: MedicalReport) {
        var newReport = report
        newReport.autoClassify() // 自动分类
        reports.append(newReport)
        saveReports()
    }
    
    func updateReport(_ report: MedicalReport) {
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            var updatedReport = report
            updatedReport.updatedAt = Date()
            updatedReport.autoClassify() // 重新分类
            reports[index] = updatedReport
            saveReports()
        }
    }
    
    func deleteReport(_ report: MedicalReport) {
        reports.removeAll { $0.id == report.id }
        saveReports()
    }
    
    func toggleStar(_ report: MedicalReport) {
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index].isStarred.toggle()
            saveReports()
        }
    }
    
    // MARK: - 查询功能
    
    func getReports(for memberId: UUID) -> [MedicalReport] {
        return reports.filter { $0.memberId == memberId }
            .sorted { $0.date > $1.date }
    }
    
    func getReports(for memberId: UUID, type: ReportType) -> [MedicalReport] {
        return reports.filter { $0.memberId == memberId && $0.reportType == type }
            .sorted { $0.date > $1.date }
    }
    
    func getStarredReports(for memberId: UUID) -> [MedicalReport] {
        return reports.filter { $0.memberId == memberId && $0.isStarred }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - 文件处理
    
    /// 压缩图片
    func compressImage(_ image: UIImage, maxSizeKB: Int = 500) -> Data? {
        var compression: CGFloat = 0.9
        var imageData = image.jpegData(compressionQuality: compression)
        
        let maxBytes = maxSizeKB * 1024
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        if let data = imageData {
            print("📸 图片压缩完成: \(data.count / 1024)KB (压缩率: \(Int(compression * 100))%)")
        }
        
        return imageData
    }
    
    /// 从Excel文件名自动识别报告类型
    func detectReportType(from fileName: String) -> ReportType {
        return ReportType.classify(from: fileName)
    }
}


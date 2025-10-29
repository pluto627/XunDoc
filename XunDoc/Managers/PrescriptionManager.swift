//
//  PrescriptionManager.swift
//  XunDoc
//
//  医嘱/处方管理器
//

import Foundation
import UIKit

class PrescriptionManager: ObservableObject {
    static let shared = PrescriptionManager()
    
    @Published var prescriptions: [MedicalPrescription] = []
    
    private let prescriptionsKey = "medical_prescriptions"
    
    init() {
        loadPrescriptions()
    }
    
    // MARK: - 数据持久化
    
    private func loadPrescriptions() {
        if let data = UserDefaults.standard.data(forKey: prescriptionsKey),
           let decoded = try? JSONDecoder().decode([MedicalPrescription].self, from: data) {
            prescriptions = decoded
            print("✅ 加载了 \(prescriptions.count) 份处方")
        }
    }
    
    func savePrescriptions() {
        if let encoded = try? JSONEncoder().encode(prescriptions) {
            UserDefaults.standard.set(encoded, forKey: prescriptionsKey)
            print("💾 保存了 \(prescriptions.count) 份处方")
        }
    }
    
    // MARK: - 处方管理
    
    func addPrescription(_ prescription: MedicalPrescription) {
        var newPrescription = prescription
        
        // 如果有结构化数据，自动归档到病历
        if newPrescription.hasStructuredData {
            archiveToHealthRecord(newPrescription)
            newPrescription.isProcessed = true
        }
        
        prescriptions.append(newPrescription)
        savePrescriptions()
    }
    
    func updatePrescription(_ prescription: MedicalPrescription) {
        if let index = prescriptions.firstIndex(where: { $0.id == prescription.id }) {
            var updated = prescription
            updated.updatedAt = Date()
            prescriptions[index] = updated
            savePrescriptions()
        }
    }
    
    func deletePrescription(_ prescription: MedicalPrescription) {
        prescriptions.removeAll { $0.id == prescription.id }
        savePrescriptions()
    }
    
    func getPrescriptions(for memberId: UUID) -> [MedicalPrescription] {
        return prescriptions.filter { $0.memberId == memberId }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - 智能处理
    
    /// 将手写处方图片转换为结构化数据(模拟OCR)
    func processHandwrittenPrescription(_ prescription: MedicalPrescription, completion: @escaping (Bool) -> Void) {
        guard prescription.type == .handwritten else {
            completion(false)
            return
        }
        
        // 模拟异步OCR识别
        DispatchQueue.global().async { [weak self] in
            Thread.sleep(forTimeInterval: 2.0)
            
            // 生成模拟的结构化数据
            let items = self?.generateMockPrescriptionItems() ?? []
            
            DispatchQueue.main.async {
                if let index = self?.prescriptions.firstIndex(where: { $0.id == prescription.id }) {
                    self?.prescriptions[index].items = items
                    self?.prescriptions[index].isProcessed = true
                    self?.prescriptions[index].type = .structured
                    
                    // 归档到病历
                    if let updatedPrescription = self?.prescriptions[index] {
                        self?.archiveToHealthRecord(updatedPrescription)
                    }
                    
                    self?.savePrescriptions()
                    completion(true)
                }
            }
        }
    }
    
    /// 归档到电子病历
    private func archiveToHealthRecord(_ prescription: MedicalPrescription) {
        // 将结构化医嘱数据整合到病历系统
        // 这里可以创建一个新的健康记录或更新现有记录
        
        print("📋 归档处方到病历:")
        print("  医院: \(prescription.hospitalName)")
        print("  医生: \(prescription.doctorName)")
        print("  药品数量: \(prescription.items.count)")
        
        // TODO: 集成到 HealthDataManager 的病历系统
    }
    
    /// 生成模拟处方数据(用于演示)
    private func generateMockPrescriptionItems() -> [PrescriptionItem] {
        return [
            PrescriptionItem(
                medicationName: "阿莫西林胶囊",
                dosage: "0.5g",
                frequency: "每日3次",
                duration: "7天",
                instructions: "饭后服用",
                quantity: 21,
                unit: "粒"
            ),
            PrescriptionItem(
                medicationName: "布洛芬缓释胶囊",
                dosage: "0.3g",
                frequency: "每日2次",
                duration: "5天",
                instructions: "疼痛时服用",
                quantity: 10,
                unit: "粒"
            ),
            PrescriptionItem(
                medicationName: "复方甘草片",
                dosage: "3片",
                frequency: "每日3次",
                duration: "3天",
                instructions: "含服",
                quantity: 27,
                unit: "片"
            )
        ]
    }
    
    // TODO: 集成真实的OCR API
    // func recognizePrescriptionWithOCR(imageData: Data) async throws -> [PrescriptionItem]
}


//
//  UserProfile.swift
//  XunDoc
//
//  用户个人信息模型
//

import Foundation
import UIKit

struct UserProfile: Codable {
    var id: UUID
    var name: String  // 姓名
    var avatarData: Data?  // 头像照片数据
    var phoneNumber: String  // 手机号
    var age: Int?  // 年龄
    var weight: Double?  // 体重(kg)
    var height: Double?  // 身高(cm)
    var chronicDiseases: [String]  // 基础病/慢性病列表
    var medicalHistory: String  // 历史疾病
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String = "",
        avatarData: Data? = nil,
        phoneNumber: String = "",
        age: Int? = nil,
        weight: Double? = nil,
        height: Double? = nil,
        chronicDiseases: [String] = [],
        medicalHistory: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.avatarData = avatarData
        self.phoneNumber = phoneNumber
        self.age = age
        self.weight = weight
        self.height = height
        self.chronicDiseases = chronicDiseases
        self.medicalHistory = medicalHistory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 是否已完成基本信息填写
    var isProfileComplete: Bool {
        return !name.isEmpty &&
               !phoneNumber.isEmpty &&
               age != nil &&
               weight != nil &&
               height != nil
    }
    
    // 获取BMI
    var bmi: Double? {
        guard let weight = weight, let height = height, height > 0 else {
            return nil
        }
        let heightInMeters = height / 100.0
        return weight / (heightInMeters * heightInMeters)
    }
    
    // 获取BMI状态
    var bmiStatus: String? {
        guard let bmi = bmi else { return nil }
        
        if bmi < 18.5 {
            return "偏瘦"
        } else if bmi < 24 {
            return "正常"
        } else if bmi < 28 {
            return "偏胖"
        } else {
            return "肥胖"
        }
    }
    
    // 生成AI分析时需要的用户信息上下文
    func buildAIContext() -> String {
        var context = "【患者基本信息】\n"
        
        if let age = age {
            context += "年龄：\(age)岁\n"
        }
        
        if let weight = weight, let height = height {
            context += "身高：\(height)cm\n"
            context += "体重：\(weight)kg\n"
            
            if let bmi = bmi, let bmiStatus = bmiStatus {
                context += "BMI：\(String(format: "%.1f", bmi))（\(bmiStatus)）\n"
            }
        }
        
        if !chronicDiseases.isEmpty {
            context += "慢性病/基础病：\(chronicDiseases.joined(separator: "、"))\n"
        }
        
        if !medicalHistory.isEmpty {
            context += "既往病史：\(medicalHistory)\n"
        }
        
        context += "\n"
        return context
    }
}

// MARK: - 用户信息管理器
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var userProfile: UserProfile
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "user_profile"
    
    init() {
        // 加载保存的用户信息
        if let data = userDefaults.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = decoded
            print("✅ 加载了用户信息")
        } else {
            self.userProfile = UserProfile()
            print("📝 创建新的用户信息")
        }
    }
    
    // 保存用户信息
    func saveProfile() {
        userProfile.updatedAt = Date()
        
        if let encoded = try? JSONEncoder().encode(userProfile) {
            userDefaults.set(encoded, forKey: profileKey)
            print("💾 用户信息已保存")
        }
    }
    
    // 更新头像
    func updateAvatar(_ imageData: Data) {
        userProfile.avatarData = imageData
        saveProfile()
    }
    
    // 添加慢性病
    func addChronicDisease(_ disease: String) {
        if !disease.isEmpty && !userProfile.chronicDiseases.contains(disease) {
            userProfile.chronicDiseases.append(disease)
            saveProfile()
        }
    }
    
    // 移除慢性病
    func removeChronicDisease(_ disease: String) {
        userProfile.chronicDiseases.removeAll { $0 == disease }
        saveProfile()
    }
    
    // 是否需要显示首次引导
    var shouldShowOnboarding: Bool {
        return !userProfile.isProfileComplete
    }
}


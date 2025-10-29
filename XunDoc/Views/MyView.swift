//
//  MyView.swift
//  XunDoc
//
//  个人信息页面 - 用户填写和编辑个人健康信息
//

import SwiftUI
import PhotosUI

struct MyView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingAddDisease = false
    @State private var newDisease = ""
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                MyHeader()
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                
                VStack(spacing: 24) {
                    // 头像卡片
                    AvatarCard(
                        avatarData: profileManager.userProfile.avatarData,
                        name: profileManager.userProfile.name,
                        phoneNumber: profileManager.userProfile.phoneNumber,
                        onTapAvatar: { showingImagePicker = true }
                    )
                    .padding(.horizontal, 20)
                    
                    // 基本信息卡片
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.accentColor)
                            
                            Text("基本信息")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            // 第一行：姓名 + 手机号
                            HStack(spacing: 12) {
                                // 姓名（左）
                                CompactInfoField(
                                    icon: "person.fill",
                                    iconColor: .purple,
                                    title: "姓名",
                                    placeholder: "输入姓名",
                                    text: Binding(
                                        get: { profileManager.userProfile.name },
                                        set: { 
                                            profileManager.userProfile.name = $0
                                            profileManager.saveProfile()
                                        }
                                    )
                                )
                                
                                // 手机号（右）
                                CompactInfoField(
                                    icon: "phone.fill",
                                    iconColor: .blue,
                                    title: "手机号",
                                    placeholder: "输入手机号",
                                    text: Binding(
                                        get: { profileManager.userProfile.phoneNumber },
                                        set: { 
                                            profileManager.userProfile.phoneNumber = $0
                                            profileManager.saveProfile()
                                        }
                                    ),
                                    keyboardType: .phonePad
                                )
                            }
                            
                            // 第二行：年龄 + （预留空间或其他字段）
                            HStack(spacing: 12) {
                                // 年龄（左）
                                CompactInfoField(
                                    icon: "calendar",
                                    iconColor: .orange,
                                    title: "年龄",
                                    placeholder: "输入年龄",
                                    text: Binding(
                                        get: { 
                                            if let age = profileManager.userProfile.age {
                                                return "\(age)"
                                            }
                                            return ""
                                        },
                                        set: { 
                                            if let age = Int($0) {
                                                profileManager.userProfile.age = age
                                                profileManager.saveProfile()
                                            } else if $0.isEmpty {
                                                profileManager.userProfile.age = nil
                                                profileManager.saveProfile()
                                            }
                                        }
                                    ),
                                    keyboardType: .numberPad,
                                    suffix: "岁"
                                )
                                
                                // 空白占位
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                            
                            // 第二行：身高 + 体重
                            HStack(spacing: 12) {
                                // 身高（左）
                                CompactInfoField(
                                    icon: "ruler",
                                    iconColor: .green,
                                    title: "身高",
                                    placeholder: "输入身高",
                                    text: Binding(
                                        get: { 
                                            if let height = profileManager.userProfile.height {
                                                return String(format: "%.0f", height)
                                            }
                                            return ""
                                        },
                                        set: { 
                                            if let height = Double($0) {
                                                profileManager.userProfile.height = height
                                                profileManager.saveProfile()
                                            } else if $0.isEmpty {
                                                profileManager.userProfile.height = nil
                                                profileManager.saveProfile()
                                            }
                                        }
                                    ),
                                    keyboardType: .decimalPad,
                                    suffix: "cm"
                                )
                                
                                // 体重（右）
                                CompactInfoField(
                                    icon: "scalemass",
                                    iconColor: .purple,
                                    title: "体重",
                                    placeholder: "输入体重",
                                    text: Binding(
                                        get: { 
                                            if let weight = profileManager.userProfile.weight {
                                                return String(format: "%.1f", weight)
                                            }
                                            return ""
                                        },
                                        set: { 
                                            if let weight = Double($0) {
                                                profileManager.userProfile.weight = weight
                                                profileManager.saveProfile()
                                            } else if $0.isEmpty {
                                                profileManager.userProfile.weight = nil
                                                profileManager.saveProfile()
                                            }
                                        }
                                    ),
                                    keyboardType: .decimalPad,
                                    suffix: "kg"
                                )
                            }
                            
                            // BMI 显示
                            if let bmi = profileManager.userProfile.bmi,
                               let bmiStatus = profileManager.userProfile.bmiStatus {
                                HStack(spacing: 8) {
                                    Image(systemName: "heart.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(bmiStatusColor(bmiStatus))
                                    
                                    Text("BMI")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                    
                                    Text(String(format: "%.1f", bmi))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("·")
                                        .foregroundColor(.textSecondary)
                                    
                                    Text(bmiStatus)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(bmiStatusColor(bmiStatus))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(bmiStatusColor(bmiStatus).opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondaryBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .background(Color.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                    
                    // 基础病/慢性病卡片（整行）
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "cross.case.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                            
                            Text("基础病/慢性病")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Button(action: { showingAddDisease = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                    Text("添加")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        if profileManager.userProfile.chronicDiseases.isEmpty {
                            HStack {
                                Image(systemName: "heart.slash")
                                    .foregroundColor(.textSecondary.opacity(0.5))
                                
                                Text("暂无慢性病记录")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            FlowLayout(spacing: 8) {
                                ForEach(profileManager.userProfile.chronicDiseases, id: \.self) { disease in
                                    ModernDiseaseTag(
                                        disease: disease,
                                        onDelete: {
                                            profileManager.removeChronicDisease(disease)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 16)
                    }
                    .padding(.bottom, 20)
                    .background(Color.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                    
                    // 既往病史卡片（整行）
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            
                            Text("既往病史")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: Binding(
                                get: { profileManager.userProfile.medicalHistory },
                                set: { 
                                    profileManager.userProfile.medicalHistory = $0
                                    profileManager.saveProfile()
                                }
                            ))
                            .font(.system(size: 14))
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color.secondaryBackground)
                            .cornerRadius(12)
                            .scrollContentBackground(.hidden)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("完成") {
                                        hideKeyboard()
                                    }
                                    .foregroundColor(.accentColor)
                                    .fontWeight(.semibold)
                                }
                            }
                            
                            if profileManager.userProfile.medicalHistory.isEmpty {
                                Text("点击输入既往病史，如手术史、过敏史等...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary.opacity(0.6))
                                    .padding(.leading, 16)
                                    .padding(.top, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .background(Color.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.appBackground)
        .navigationBarHidden(true)
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    hideKeyboard()
                }
        )
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker.photoLibrary(image: $selectedImage)
                .onDisappear {
                    if let image = selectedImage,
                       let imageData = image.jpegData(compressionQuality: 0.8) {
                        profileManager.updateAvatar(imageData)
                        selectedImage = nil
                    }
                }
        }
        .alert("添加慢性病", isPresented: $showingAddDisease) {
            TextField("疾病名称", text: $newDisease)
            Button("取消", role: .cancel) {
                newDisease = ""
            }
            Button("添加") {
                profileManager.addChronicDisease(newDisease)
                newDisease = ""
            }
        }
    }
    
    // BMI 状态颜色
    private func bmiStatusColor(_ status: String) -> Color {
        switch status {
        case "偏瘦": return .blue
        case "正常": return .green
        case "偏胖": return .orange
        case "肥胖": return .red
        default: return .gray
        }
    }
    
    // 收起键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - My Header
struct MyHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("我的")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("个人健康档案")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 头像卡片
struct AvatarCard: View {
    let avatarData: Data?
    let name: String
    let phoneNumber: String
    let onTapAvatar: () -> Void
    
    var displayName: String {
        if !name.isEmpty {
            return name
        } else if !phoneNumber.isEmpty {
            return phoneNumber
        } else {
            return "点击设置个人信息"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 头像
            Button(action: onTapAvatar) {
                if let data = avatarData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.accentColor.opacity(0.6), .accentColor.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.accentColor.opacity(0.6))
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 信息
            VStack(alignment: .leading, spacing: 8) {
                Text(displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text("健康档案")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            // 编辑提示
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textSecondary.opacity(0.5))
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.cardBackground, Color.cardBackground.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

// MARK: - 紧凑信息字段（左右排列用）
struct CompactInfoField: View {
    let icon: String
    let iconColor: Color
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var suffix: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack(spacing: 6) {
            Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
            
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            
            // 输入框
            HStack(spacing: 4) {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15, weight: .medium))
                    .keyboardType(keyboardType)
                    .foregroundColor(.textPrimary)
                
                if let suffix = suffix {
                    Text(suffix)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.secondaryBackground)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 现代化疾病标签
struct ModernDiseaseTag: View {
    let disease: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.orange)
            
            Text(disease)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.08), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

// 注意：FlowLayout 定义在 AIConsultationView.swift 中
// 注意：ImagePicker 定义在 Views/Components/ImagePicker.swift 中

#Preview {
    MyView()
}

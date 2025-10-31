//
//  ProfileEditView.swift
//  XunDoc
//
//  个人信息编辑页面 - 详细编辑个人健康信息
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingAddDisease = false
    @State private var newDisease = ""
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 头像卡片
                AvatarEditCard(
                    avatarData: profileManager.userProfile.avatarData,
                    name: profileManager.userProfile.name,
                    phoneNumber: profileManager.userProfile.phoneNumber,
                    onTapAvatar: { showingImagePicker = true }
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // 基本信息卡片
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                        
                        Text(NSLocalizedString("basic_info", comment: ""))
                            .font(.appSubheadline())
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
                                title: NSLocalizedString("name_label", comment: ""),
                                placeholder: NSLocalizedString("name_placeholder", comment: ""),
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
                                title: NSLocalizedString("phone_label", comment: ""),
                                placeholder: NSLocalizedString("phone_placeholder", comment: ""),
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
                        
                        // 第二行：年龄
                        HStack(spacing: 12) {
                            // 年龄（左）
                            CompactInfoField(
                                icon: "calendar",
                                iconColor: .orange,
                                title: NSLocalizedString("age_label", comment: ""),
                                placeholder: NSLocalizedString("age_placeholder", comment: ""),
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
                                suffix: NSLocalizedString("age_unit", comment: "")
                            )
                            
                            // 空白占位
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                        
                        // 第三行：身高 + 体重
                        HStack(spacing: 12) {
                            // 身高（左）
                            CompactInfoField(
                                icon: "ruler",
                                iconColor: .green,
                                title: NSLocalizedString("height_label", comment: ""),
                                placeholder: NSLocalizedString("height_placeholder", comment: ""),
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
                                title: NSLocalizedString("weight_label", comment: ""),
                                placeholder: NSLocalizedString("weight_placeholder", comment: ""),
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
                
                // 基础病/慢性病卡片
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        
                        Text(NSLocalizedString("chronic_diseases", comment: ""))
                            .font(.appSubheadline())
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
                            
                            Text(NSLocalizedString("no_chronic_diseases", comment: ""))
                                .font(.appCaption())
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
                
                // 既往病史卡片
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        
                        Text(NSLocalizedString("medical_history_title", comment: ""))
                            .font(.appSubheadline())
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
                            Text(NSLocalizedString("medical_history_placeholder_hint", comment: ""))
                                .font(.appCaption())
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
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("个人信息")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
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
        .alert(NSLocalizedString("add_chronic_disease", comment: ""), isPresented: $showingAddDisease) {
            TextField(NSLocalizedString("disease_name", comment: ""), text: $newDisease)
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {
                newDisease = ""
            }
            Button(NSLocalizedString("add", comment: "")) {
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

// MARK: - 头像编辑卡片
struct AvatarEditCard: View {
    let avatarData: Data?
    let name: String
    let phoneNumber: String
    let onTapAvatar: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 头像
            Button(action: onTapAvatar) {
                if let data = avatarData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
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
                        .overlay(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )
                                .opacity(0.8)
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
                            .frame(width: 100, height: 100)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor.opacity(0.6))
                            
                            Text("添加头像")
                                .font(.system(size: 12))
                                .foregroundColor(.accentColor.opacity(0.8))
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("点击更换头像")
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
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
    NavigationView {
        ProfileEditView()
    }
}


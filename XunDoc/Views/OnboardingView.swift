//
//  OnboardingView.swift
//  XunDoc
//
//  首次使用引导页面 - 分步引导用户填写基本信息
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @Binding var isPresented: Bool
    
    @State private var currentStep = 1
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var age = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var chronicDiseases: [String] = []
    @State private var medicalHistory = ""
    @State private var showingAddDisease = false
    @State private var newDisease = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    // 第一步验证
    var step1Valid: Bool {
        !name.isEmpty &&
        !phoneNumber.isEmpty &&
        !age.isEmpty &&
        !weight.isEmpty &&
        !height.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部进度条和跳过按钮
                HStack {
                    // 步骤指示器
                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { step in
                            Circle()
                                .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(width: step == currentStep ? 10 : 8, height: step == currentStep ? 10 : 8)
                                .animation(.spring(), value: currentStep)
                        }
                    }
                    
                    Spacer()
                    
                    // 跳过按钮（第2、3步显示）
                    if currentStep > 1 {
                        Button(action: skipToNext) {
                            HStack(spacing: 4) {
                                Text("跳过")
                                    .font(.system(size: 15, weight: .semibold))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.6))
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                // 内容区域
                TabView(selection: $currentStep) {
                    // 第一步：基本信息（必填）
                    Step1BasicInfoView(
                        name: $name,
                        phoneNumber: $phoneNumber,
                        age: $age,
                        height: $height,
                        weight: $weight,
                        isValid: step1Valid,
                        onNext: { withAnimation { currentStep = 2 } }
                    )
                    .tag(1)
                    
                    // 第二步：上传头像（选填）
                    Step2AvatarView(
                        selectedImage: $selectedImage,
                        showingImagePicker: $showingImagePicker,
                        onNext: { withAnimation { currentStep = 3 } }
                    )
                    .tag(2)
                    
                    // 第三步：健康信息（选填）
                    Step3HealthInfoView(
                        chronicDiseases: $chronicDiseases,
                        medicalHistory: $medicalHistory,
                        showingAddDisease: $showingAddDisease,
                        newDisease: $newDisease,
                        onComplete: saveAndFinish
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .gesture(DragGesture()) // 拦截滑动手势，只能通过按钮切换
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
        }
        .alert("添加慢性病", isPresented: $showingAddDisease) {
            TextField("疾病名称", text: $newDisease)
            Button("取消", role: .cancel) {
                newDisease = ""
            }
            Button("添加") {
                if !newDisease.isEmpty {
                    chronicDiseases.append(newDisease)
                    newDisease = ""
                }
            }
        }
    }
    
    // 跳过到下一步
    private func skipToNext() {
        withAnimation {
            if currentStep == 2 {
                currentStep = 3
            } else if currentStep == 3 {
                saveAndFinish()
            }
        }
    }
    
    // 收起键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 保存并完成
    private func saveAndFinish() {
        // 保存头像
        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            profileManager.userProfile.avatarData = imageData
        }
        
        // 保存基本信息
        profileManager.userProfile.name = name
        profileManager.userProfile.phoneNumber = phoneNumber
        profileManager.userProfile.age = Int(age)
        profileManager.userProfile.height = Double(height)
        profileManager.userProfile.weight = Double(weight)
        
        // 保存健康信息
        profileManager.userProfile.chronicDiseases = chronicDiseases
        profileManager.userProfile.medicalHistory = medicalHistory
        
        // 保存到UserDefaults
        profileManager.saveProfile()
        
        // 关闭引导页
        isPresented = false
    }
}

// MARK: - 第一步：基本信息
struct Step1BasicInfoView: View {
    @Binding var name: String
    @Binding var phoneNumber: String
    @Binding var age: String
    @Binding var height: String
    @Binding var weight: String
    let isValid: Bool
    let onNext: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // 标题
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(spacing: 8) {
                        Text("基本信息")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.textPrimary)
                        
                        Text("帮助我们更好地了解您")
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.top, 40)
                
                // 表单
                VStack(spacing: 20) {
                    // 第一行：姓名 + 手机号
                    HStack(spacing: 12) {
                        OnboardingCompactField(
                            icon: "person.fill",
                            iconColor: .purple,
                            title: "姓名",
                            placeholder: "输入姓名",
                            text: $name,
                            isRequired: true
                        )
                        
                        OnboardingCompactField(
                            icon: "phone.fill",
                            iconColor: .blue,
                            title: "手机号",
                            placeholder: "输入手机号",
                            text: $phoneNumber,
                            keyboardType: .phonePad,
                            isRequired: true
                        )
                    }
                    
                    // 第二行：年龄 + 身高
                    HStack(spacing: 12) {
                        OnboardingCompactField(
                            icon: "calendar",
                            iconColor: .orange,
                            title: "年龄",
                            placeholder: "输入年龄",
                            text: $age,
                            keyboardType: .numberPad,
                            suffix: "岁",
                            isRequired: true
                        )
                        
                        OnboardingCompactField(
                            icon: "ruler",
                            iconColor: .green,
                            title: "身高",
                            placeholder: "输入身高",
                            text: $height,
                            keyboardType: .decimalPad,
                            suffix: "cm",
                            isRequired: true
                        )
                    }
                    
                    // 第三行：体重
                    HStack(spacing: 12) {
                        OnboardingCompactField(
                            icon: "scalemass",
                            iconColor: .pink,
                            title: "体重",
                            placeholder: "输入体重",
                            text: $weight,
                            keyboardType: .decimalPad,
                            suffix: "kg",
                            isRequired: true
                        )
                        
                        // 空白占位
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                
                // 提示
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accentColor.opacity(0.6))
                    
                    Text("这些信息将帮助AI为您提供个性化的健康建议")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 下一步按钮
                Button(action: onNext) {
                    HStack(spacing: 8) {
                        Text("下一步")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: isValid ? 
                                [Color.accentColor, Color.accentColor.opacity(0.8)] :
                                [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: isValid ? Color.accentColor.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                }
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - 第二步：上传头像
struct Step2AvatarView: View {
    @Binding var selectedImage: UIImage?
    @Binding var showingImagePicker: Bool
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 标题
            VStack(spacing: 16) {
                Text("设置头像")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("让您的健康档案更有个性")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
            }
            
            // 头像上传
            Button(action: { showingImagePicker = true }) {
                if let uiImage = selectedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.accentColor.opacity(0.6), .accentColor.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                        )
                        .shadow(color: Color.accentColor.opacity(0.2), radius: 20, x: 0, y: 10)
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.accentColor.opacity(0.6))
                            
                            Text("点击上传头像")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 提示
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("支持从相册选择照片")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                
                Text("(此步骤可选)")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary.opacity(0.7))
            }
            
            Spacer()
            
            // 下一步按钮
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text(selectedImage != nil ? "继续" : "跳过此步")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - 第三步：健康信息
struct Step3HealthInfoView: View {
    @Binding var chronicDiseases: [String]
    @Binding var medicalHistory: String
    @Binding var showingAddDisease: Bool
    @Binding var newDisease: String
    let onComplete: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // 标题
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 8) {
                        Text("健康信息")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.textPrimary)
                        
                        Text("帮助AI提供更准确的建议")
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.top, 40)
                
                // 基础病/慢性病
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
                    
                    if chronicDiseases.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.textSecondary.opacity(0.5))
                            
                            Text("暂无慢性病记录")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.secondaryBackground.opacity(0.5))
                        .cornerRadius(12)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(chronicDiseases, id: \.self) { disease in
                                ModernDiseaseTag(
                                    disease: disease,
                                    onDelete: {
                                        chronicDiseases.removeAll { $0 == disease }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 20)
                
                // 既往病史
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        
                        Text("既往病史")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $medicalHistory)
                            .font(.system(size: 14))
                            .frame(height: 120)
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
                        
                        if medicalHistory.isEmpty {
                            Text("点击输入既往病史，如手术史、过敏史等...")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary.opacity(0.6))
                                .padding(.leading, 16)
                                .padding(.top, 20)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(20)
                .background(Color.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 20)
                
                // 提示
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accentColor.opacity(0.6))
                    
                    Text("这些信息将保密且仅用于健康分析")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 20)
                
                // 完成按钮
                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        Text("完成设置")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - 引导页紧凑输入框
struct OnboardingCompactField: View {
    let icon: String
    let iconColor: Color
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var suffix: String? = nil
    var isRequired: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                if isRequired {
                    Text("*")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                }
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
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isRequired && text.isEmpty ? Color.red.opacity(0.3) : Color.divider, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}

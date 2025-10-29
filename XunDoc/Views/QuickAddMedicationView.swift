//
//  QuickAddMedicationView.swift
//  XunDoc
//
//  快捷添加药物视图 - 精简版本,与标准添加统一设计
//

import SwiftUI

struct QuickAddMedicationView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    // 表单数据
    @State private var medicationName = ""
    @State private var dosageType = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var times: [Date] = [Calendar.current.startOfDay(for: Date()).addingTimeInterval(9*3600)]
    @State private var notes = ""
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    let dosageTypes = [
        ("tablet", "片剂", "pills.fill"),
        ("capsule", "胶囊", "capsule.fill"),
        ("liquid", "口服液", "drop.fill"),
        ("injection", "注射剂", "syringe.fill"),
        ("powder", "颗粒", "bag.fill"),
        ("other", "其他", "cross.vial.fill")
    ]
    
    let frequencies = [
        ("once", "每天1次", "1"),
        ("twice", "每天2次", "2"),
        ("three", "每天3次", "3"),
        ("four", "每天4次", "4"),
        ("asNeeded", "按需服用", "?")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 拖动条
            Capsule()
                .fill(Color.textTertiary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 14)
                .padding(.bottom, 18)
            
            // 顶部标题栏
            HStack {
                Text("快捷添加用药")
                    .font(.appTitle())
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // 内容区域
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 药品名称
                    VStack(alignment: .leading, spacing: 10) {
                        Text("药品名称 *")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        TextField("如：阿司匹林肠溶片", text: $medicationName)
                            .font(.appHeadline())
                            .foregroundColor(.textPrimary)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.gray.opacity(0.08))
                            )
                        
                        // 识别按钮
                        HStack(spacing: 10) {
                            Button(action: {
                                showingCamera = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                    Text("拍照识别")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.accentPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.accentPrimary.opacity(0.1))
                                )
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 14))
                                    Text("相册选择")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.accentPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.accentPrimary.opacity(0.1))
                                )
                            }
                        }
                    }
                    
                    // 剂型选择
                    VStack(alignment: .leading, spacing: 10) {
                        Text("剂型 *")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(dosageTypes, id: \.0) { type in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dosageType = type.0
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: type.2)
                                            .font(.system(size: 20))
                                            .foregroundColor(dosageType == type.0 ? .accentPrimary : .textSecondary)
                                        
                                        Text(type.1)
                                            .font(.system(size: 11, weight: dosageType == type.0 ? .semibold : .regular))
                                            .foregroundColor(dosageType == type.0 ? .textPrimary : .textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(dosageType == type.0 ? Color.accentPrimary.opacity(0.15) : Color.gray.opacity(0.08))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(dosageType == type.0 ? Color.accentPrimary : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // 剂量输入
                    VStack(alignment: .leading, spacing: 10) {
                        Text("规格/剂量 *")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        TextField(dosageType.isEmpty ? "如：100mg" : dosagePlaceholder(for: dosageType), text: $dosage)
                            .font(.appHeadline())
                            .foregroundColor(.textPrimary)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.gray.opacity(0.08))
                            )
                    }
                    
                    // 服用频率
                    VStack(alignment: .leading, spacing: 10) {
                        Text("服用频率 *")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(frequencies, id: \.0) { freq in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        frequency = freq.0
                                        updateTimesForFrequency(freq.0)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(frequency == freq.0 ? Color.accentPrimary.opacity(0.15) : Color.gray.opacity(0.08))
                                                .frame(width: 28, height: 28)
                                            
                                            Text(freq.2)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(frequency == freq.0 ? .accentPrimary : .textSecondary)
                                        }
                                        
                                        Text(freq.1)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.textPrimary)
                                        
                                        Spacer(minLength: 0)
                                        
                                        if frequency == freq.0 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.accentPrimary)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(frequency == freq.0 ? Color.accentPrimary.opacity(0.08) : Color.gray.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(frequency == freq.0 ? Color.accentPrimary : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // 服用时间
                    if !times.isEmpty && frequency != "asNeeded" {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("服用时间")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(times.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("第 \(index + 1) 次")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.textSecondary)
                                        
                                        DatePicker("", selection: $times[index], displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .frame(maxWidth: .infinity)
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.gray.opacity(0.08))
                                    )
                                }
                            }
                        }
                    }
                    
                    // 备注
                    VStack(alignment: .leading, spacing: 10) {
                        Text("备注（可选）")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        TextEditor(text: $notes)
                            .font(.appBody())
                            .foregroundColor(.textPrimary)
                            .frame(height: 80)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.gray.opacity(0.08))
                            )
                            .overlay(
                                Group {
                                    if notes.isEmpty {
                                        Text("如：饭后30分钟服用")
                                            .font(.appBody())
                                            .foregroundColor(.textSecondary)
                                            .padding(.leading, 14)
                                            .padding(.top, 18)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 100) // 为底部按钮留出空间
            }
            
            // 底部保存按钮 - 固定在底部
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("取消")
                            .font(.appSubheadline())
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    
                    Button(action: saveMedication) {
                        HStack(spacing: 6) {
                            Text("保存用药")
                                .font(.appSubheadline())
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(canSave() 
                                      ? LinearGradient(
                                          colors: [Color.accentPrimary, Color.accentTertiary],
                                          startPoint: .leading,
                                          endPoint: .trailing
                                      )
                                      : LinearGradient(
                                          colors: [Color.textTertiary, Color.textTertiary],
                                          startPoint: .leading,
                                          endPoint: .trailing
                                      )
                                )
                        )
                    }
                    .disabled(!canSave())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(Color.appBackgroundColor)
        }
        .background(Color.appBackgroundColor)
        .sheet(isPresented: $showingImagePicker) {
            MedicationImagePicker(medicationName: $medicationName)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            MedicationCameraView(medicationName: $medicationName)
        }
    }
    
    private func dosagePlaceholder(for type: String) -> String {
        switch type {
        case "tablet": return "如：100mg"
        case "capsule": return "如：50mg"
        case "liquid": return "如：10ml"
        case "injection": return "如：2ml"
        case "powder": return "如：5g"
        default: return "请输入剂量"
        }
    }
    
    private func updateTimesForFrequency(_ freq: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch freq {
        case "once":
            times = [today.addingTimeInterval(9*3600)] // 9:00
        case "twice":
            times = [
                today.addingTimeInterval(9*3600),  // 9:00
                today.addingTimeInterval(21*3600)  // 21:00
            ]
        case "three":
            times = [
                today.addingTimeInterval(8*3600),  // 8:00
                today.addingTimeInterval(14*3600), // 14:00
                today.addingTimeInterval(20*3600)  // 20:00
            ]
        case "four":
            times = [
                today.addingTimeInterval(8*3600),  // 8:00
                today.addingTimeInterval(12*3600), // 12:00
                today.addingTimeInterval(16*3600), // 16:00
                today.addingTimeInterval(20*3600)  // 20:00
            ]
        case "asNeeded":
            times = [] // 按需服用不设置固定时间
        default:
            break
        }
    }
    
    private func canSave() -> Bool {
        return !medicationName.isEmpty && !dosageType.isEmpty && !dosage.isEmpty && !frequency.isEmpty
    }
    
    private func saveMedication() {
        // 转换频率
        let medicationFrequency: MedicationReminder.Frequency
        switch frequency {
        case "once":
            medicationFrequency = .onceDaily
        case "twice":
            medicationFrequency = .twiceDaily
        case "three":
            medicationFrequency = .threeTimesDaily
        case "four":
            medicationFrequency = .fourTimesDaily
        default:
            medicationFrequency = .asNeeded
        }
        
        let reminder = MedicationReminder(
            medicationName: medicationName,
            dosage: dosage,
            frequency: medicationFrequency,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7*24*60*60),
            reminderTimes: times,
            notes: notes.isEmpty ? nil : notes,
            isActive: true,
            usage: nil, // 快捷添加暂不搜索药物信息
            instructions: nil
        )
        
        healthDataManager.addMedicationReminder(reminder)
        
        print("💊 快捷保存药品信息成功:")
        print("名称: \(medicationName)")
        print("剂型: \(dosageType)")
        print("剂量: \(dosage)")
        print("频率: \(medicationFrequency.localized)")
        
        withAnimation {
            isPresented = false
        }
    }
}


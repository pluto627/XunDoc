//
//  NewMedicationSteps.swift
//  XunDoc
//
//  精简的3步用药流程
//

import SwiftUI

// MARK: - 步骤1: 药物基本信息（合并：名称、剂型、剂量）
struct Step1MedicationInfoView: View {
    @Binding var medicationName: String
    @Binding var dosageType: String
    @Binding var dosage: String
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    
    // 用于向父视图传递药物信息的回调
    var onUsageUpdate: ((String) -> Void)?
    var onInstructionsUpdate: ((String) -> Void)?
    
    @State private var usage = "" // 药物用途
    @State private var instructions = "" // 服用说明
    @State private var isSearching = false
    
    let dosageTypes = [
        ("tablet", "片剂", "pills.fill"),
        ("capsule", "胶囊", "capsule.fill"),
        ("liquid", "口服液", "drop.fill"),
        ("injection", "注射剂", "syringe.fill"),
        ("powder", "颗粒", "bag.fill"),
        ("other", "其他", "cross.vial.fill")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("药物信息")
                        .font(.appLargeTitle())
                        .foregroundColor(.textPrimary)
                    
                    Text("输入药物名称、剂型和剂量")
                        .font(.appBody())
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 32)
                
                VStack(alignment: .leading, spacing: 24) {
                    // 药品名称
                    VStack(alignment: .leading, spacing: 12) {
                        Text("药品名称")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        TextField("如：阿司匹林肠溶片", text: $medicationName)
                            .font(.appHeadline())
                            .foregroundColor(.textPrimary)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.08))
                            )
                            .onChange(of: medicationName) { newValue in
                                // 当药品名称改变时，自动搜索药物信息
                                if newValue.count >= 2 {
                                    searchMedicationInfo(newValue)
                                }
                            }
                        
                        // 识别按钮
                        HStack(spacing: 12) {
                            Button(action: {
                                showingCamera = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                    Text("拍照识别")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.accentPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.accentPrimary.opacity(0.1))
                                )
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 16))
                                    Text("相册选择")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.accentPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.accentPrimary.opacity(0.1))
                                )
                            }
                        }
                    }
                    
                    // 剂型选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("剂型")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(dosageTypes, id: \.0) { type in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dosageType = type.0
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: type.2)
                                            .font(.system(size: 24))
                                            .foregroundColor(dosageType == type.0 ? .accentPrimary : .textSecondary)
                                        
                                        Text(type.1)
                                            .font(.system(size: 13, weight: dosageType == type.0 ? .semibold : .regular))
                                            .foregroundColor(dosageType == type.0 ? .textPrimary : .textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(dosageType == type.0 ? Color.accentPrimary.opacity(0.15) : Color.gray.opacity(0.08))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(dosageType == type.0 ? Color.accentPrimary : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // 剂量输入
                    VStack(alignment: .leading, spacing: 12) {
                        Text("规格/剂量")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        TextField(dosageType.isEmpty ? "如：100mg" : dosagePlaceholder(for: dosageType), text: $dosage)
                            .font(.appHeadline())
                            .foregroundColor(.textPrimary)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.08))
                            )
                    }
                    
                    // 药物用途（自动填充）
                    if !usage.isEmpty || isSearching {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("药物用途")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                if isSearching {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            
                            Text(usage.isEmpty ? "正在搜索..." : usage)
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.accentPrimary.opacity(0.08))
                                )
                        }
                    }
                    
                    // 服用说明（自动填充）
                    if !instructions.isEmpty || isSearching {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("服用说明")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            Text(instructions.isEmpty ? "正在搜索..." : instructions)
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.accentPrimary.opacity(0.08))
                                )
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .background(Color.clear)
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
    
    private func searchMedicationInfo(_ name: String) {
        isSearching = true
        
        // 调用Kimi API搜索药物信息
        KimiAPIManager.shared.searchMedicationInfo(medicationName: name) { [self] result in
            switch result {
            case .success(let info):
                // 成功获取药物信息
                self.usage = info.usage
                self.instructions = info.instructions
                
                print("✅ 搜索到药物信息:")
                print("   用途: \(info.usage)")
                print("   服用说明: \(info.instructions)")
                
                // 调用回调函数，将值传递给父视图
                self.onUsageUpdate?(info.usage)
                self.onInstructionsUpdate?(info.instructions)
                
            case .failure(let error):
                // 搜索失败，使用默认值
                print("❌ 药物信息搜索失败: \(error.localizedDescription)")
                self.usage = "请查看药品说明书"
                self.instructions = "请遵医嘱服用"
                
                self.onUsageUpdate?(self.usage)
                self.onInstructionsUpdate?(self.instructions)
            }
            
            self.isSearching = false
        }
    }
}

// MARK: - 步骤2: 服用安排（合并：频率和时间）- 优化紧凑布局
struct Step2ScheduleView: View {
    @Binding var frequency: String
    @Binding var times: [Date]
    
    let frequencies = [
        ("once", "每天1次", "1"),
        ("twice", "每天2次", "2"),
        ("three", "每天3次", "3"),
        ("four", "每天4次", "4"),
        ("asNeeded", "按需服用", "?")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("服用安排")
                        .font(.appLargeTitle())
                        .foregroundColor(.textPrimary)
                    
                    Text("设置服用频率和时间")
                        .font(.appBody())
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    // 服用频率 - 使用网格布局更紧凑
                    VStack(alignment: .leading, spacing: 10) {
                        Text("服用频率")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        // 使用2列网格布局
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
                                    HStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(frequency == freq.0 ? Color.accentPrimary.opacity(0.15) : Color.gray.opacity(0.08))
                                                .frame(width: 32, height: 32)
                                            
                                            Text(freq.2)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(frequency == freq.0 ? .accentPrimary : .textSecondary)
                                        }
                                        
                                        Text(freq.1)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.textPrimary)
                                        
                                        Spacer(minLength: 0)
                                        
                                        if frequency == freq.0 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.accentPrimary)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(frequency == freq.0 ? Color.accentPrimary.opacity(0.08) : Color.gray.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(frequency == freq.0 ? Color.accentPrimary : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // 服用时间 - 更紧凑的网格布局
                    if !times.isEmpty && frequency != "asNeeded" {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("服用时间")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            // 使用网格布局,每行2个时间选择器
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(times.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("第 \(index + 1) 次")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.textSecondary)
                                        
                                        DatePicker("", selection: $times[index], displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .frame(maxWidth: .infinity)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.gray.opacity(0.08))
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .background(Color.clear)
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
}

// MARK: - 步骤3: 周期和备注
struct Step3CycleAndNotesView: View {
    @Binding var notes: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("服药周期")
                        .font(.appLargeTitle())
                        .foregroundColor(.textPrimary)
                    
                    Text("设置开始和结束日期（可选）")
                        .font(.appBody())
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 32)
                
                VStack(alignment: .leading, spacing: 24) {
                    // 服药周期
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("开始日期")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.08))
                            )
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("结束日期")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                
                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.08))
                            )
                        }
                    }
                    
                    // 备注
                    VStack(alignment: .leading, spacing: 12) {
                        Text("备注（可选）")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        TextEditor(text: $notes)
                            .font(.appBody())
                            .foregroundColor(.textPrimary)
                            .frame(height: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.08))
                            )
                            .overlay(
                                Group {
                                    if notes.isEmpty {
                                        Text("如：饭后30分钟服用")
                                            .font(.appBody())
                                            .foregroundColor(.textSecondary)
                                            .padding(.leading, 16)
                                            .padding(.top, 20)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .background(Color.clear)
    }
}


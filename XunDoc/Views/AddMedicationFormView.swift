//
//  AddMedicationFormView.swift
//  XunDoc
//
//  添加药品表单视图 - 一体化表单设计
//

import SwiftUI

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AddMedicationFormView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var healthDataManager: HealthDataManager
    @FocusState private var focusedField: Field?
    
    // 基本信息
    @State private var medicationName = ""
    @State private var medicationType = "胶囊"
    
    // 剂量信息
    @State private var dosageAmount = ""
    @State private var dosageUnit = "丸"
    @State private var usageTiming = "餐后服用"
    @State private var mealTime = "早餐"  // 新增：具体哪一餐
    @State private var showingMealPicker = false
    
    // 药物用途
    @State private var medicationUsage = ""
    
    // 库存信息
    @State private var inventory = ""
    
    let medicationTypes = ["片剂", "胶囊", "口服液", "注射剂", "颗粒", "其他"]
    let dosageUnits = ["丸", "片", "粒", "mg", "ml", "g"]
    let usageTimings = ["餐前服用", "餐后服用", "饭中服用", "睡前服用", "按需服用"]
    let mealTimes = ["早餐", "午餐", "晚餐"]
    
    enum Field {
        case name, dosage, inventory
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackgroundColor.ignoresSafeArea()
                    .onTapGesture {
                        // 点击任何地方隐藏键盘
                        focusedField = nil
                    }
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // 基本信息
                            sectionHeader(title: "基本信息")
                            
                            VStack(spacing: 0) {
                                // 名称
                                formRow(title: "名称") {
                                    TextField("请输入", text: $medicationName)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.textSecondary)
                                        .focused($focusedField, equals: .name)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            focusedField = nil
                                        }
                                }
                                
                                Divider()
                                    .padding(.leading, 60)
                                
                                // 类型
                                formRow(title: "类型") {
                                    Menu {
                                        ForEach(medicationTypes, id: \.self) { type in
                                            Button(action: {
                                                medicationType = type
                                            }) {
                                                HStack {
                                                    Text(type)
                                                    if medicationType == type {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(medicationType)
                                                .foregroundColor(Color(hex: "7B8FF7"))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(hex: "7B8FF7"))
                                        }
                                    }
                                }
                            }
                            .background(Color.cardBackgroundColor)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                        
                            // 剂量信息
                            sectionHeader(title: "剂量信息")
                            
                            VStack(spacing: 0) {
                                // 用药剂量
                                formRow(title: "用药剂量") {
                                    TextField("请输入", text: $dosageAmount)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.textSecondary)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .dosage)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            focusedField = nil
                                        }
                                }
                                
                                Divider()
                                    .padding(.leading, 60)
                                
                                // 剂量单位
                                formRow(title: "剂量单位") {
                                    Menu {
                                        ForEach(dosageUnits, id: \.self) { unit in
                                            Button(action: {
                                                dosageUnit = unit
                                            }) {
                                                HStack {
                                                    Text(unit)
                                                    if dosageUnit == unit {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(dosageUnit)
                                                .foregroundColor(Color(hex: "7B8FF7"))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(hex: "7B8FF7"))
                                        }
                                    }
                                }
                                
                                Divider()
                                    .padding(.leading, 60)
                                
                                // 用药时机
                                formRow(title: "用药时机") {
                                    Menu {
                                        ForEach(usageTimings, id: \.self) { timing in
                                            Button(action: {
                                                usageTiming = timing
                                                // 如果选择餐前或餐后，显示具体哪一餐
                                                if timing == "餐前服用" || timing == "餐后服用" {
                                                    showingMealPicker = true
                                                }
                                            }) {
                                                HStack {
                                                    Text(timing)
                                                    if usageTiming == timing {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            // 显示完整的用药时机信息
                                            if usageTiming == "餐前服用" || usageTiming == "餐后服用" {
                                                Text("\(mealTime)\(usageTiming)")
                                                    .foregroundColor(Color(hex: "7B8FF7"))
                                            } else {
                                                Text(usageTiming)
                                                    .foregroundColor(Color(hex: "7B8FF7"))
                                            }
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(hex: "7B8FF7"))
                                        }
                                    }
                                }
                            }
                            .background(Color.cardBackgroundColor)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                            
                            // 药物用途
                            sectionHeader(title: "药物用途")
                            
                            VStack(spacing: 0) {
                                TextEditor(text: $medicationUsage)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color.cardBackgroundColor)
                                    .cornerRadius(16)
                                    .overlay(
                                        Group {
                                            if medicationUsage.isEmpty {
                                                Text("请输入药物用途（如：抗血小板聚集，预防心血管事件）")
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.textTertiary)
                                                    .padding(.horizontal, 16)
                                                    .padding(.top, 20)
                                                    .allowsHitTesting(false)
                                            }
                                        }
                                        , alignment: .topLeading
                                    )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                            
                            // 库存信息
                            sectionHeader(title: "库存信息")
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("库存")
                                        .font(.system(size: 16))
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                    
                                    TextField("请输入", text: $inventory)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.textSecondary)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .inventory)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            focusedField = nil
                                        }
                                    
                                    Text(dosageUnit)
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(16)
                                .background(Color.cardBackgroundColor)
                                .cornerRadius(16)
                                
                                Text("XunDoc 会在你的药用完之前提醒你。")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                        }
                        .padding(.top, 8)
                    }
                    
                    // 底部保存按钮 - 固定在底部
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button(action: saveMedication) {
                            Text("保存")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(hex: "7B8FF7"))
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                    }
                    .background(Color.appBackgroundColor)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("添加药品")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.15))
                            )
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        focusedField = nil
                    }
                    .foregroundColor(.accentPrimary)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
            .sheet(isPresented: $showingMealPicker) {
                mealPickerView
            }
        }
    }
    
    // MARK: - 辅助视图
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
    }
    
    private func formRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            content()
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
    }
    
    // 餐次选择器
    private var mealPickerView: some View {
        NavigationView {
            List {
                ForEach(mealTimes, id: \.self) { meal in
                    Button(action: {
                        mealTime = meal
                        showingMealPicker = false
                    }) {
                        HStack {
                            Text(meal)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if mealTime == meal {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentPrimary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择用餐时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showingMealPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - 保存功能
    
    private func saveMedication() {
        // 验证必填字段
        guard !medicationName.isEmpty else {
            print("⚠️ 药品名称不能为空")
            return
        }
        
        // 构建完整的用药时机描述
        let fullUsageTiming = (usageTiming == "餐前服用" || usageTiming == "餐后服用") 
            ? "\(mealTime)\(usageTiming)" 
            : usageTiming
        
        // 构建剂量描述
        let dosageDescription = dosageAmount.isEmpty 
            ? "按医嘱" 
            : "\(dosageAmount)\(dosageUnit)"
        
        // 转换频率（根据用药时机）
        let frequency: MedicationReminder.Frequency
        if usageTiming == "按需服用" {
            frequency = .asNeeded
        } else {
            frequency = .onceDaily // 默认每天一次，可以根据需求调整
        }
        
        // 设置默认提醒时间（设置未来30天的每日提醒）
        let calendar = Calendar.current
        var reminderTimes: [Date] = []
        
        // 确定每天的提醒小时数
        var hourOfDay = 9 // 默认早上9点
        if usageTiming.contains("早餐") {
            hourOfDay = 8 // 早上8点
        } else if usageTiming.contains("午餐") {
            hourOfDay = 12 // 中午12点
        } else if usageTiming.contains("晚餐") {
            hourOfDay = 18 // 下午6点
        } else if usageTiming == "睡前服用" {
            hourOfDay = 22 // 晚上10点
        }
        
        // 为未来30天设置每日提醒
        for dayOffset in 0..<30 {
            if let reminderDate = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: calendar.startOfDay(for: Date())
            ) {
                let reminderTime = reminderDate.addingTimeInterval(Double(hourOfDay) * 3600)
                reminderTimes.append(reminderTime)
            }
        }
        
        // 创建用药提醒对象
        let reminder = MedicationReminder(
            medicationName: medicationName,
            dosage: dosageDescription,
            frequency: frequency,
            startDate: Date(),
            endDate: Date().addingTimeInterval(30*24*60*60), // 默认30天
            reminderTimes: reminderTimes,
            notes: "药品类型: \(medicationType)",
            isActive: true,
            usage: medicationUsage.isEmpty ? nil : medicationUsage,
            instructions: fullUsageTiming
        )
        
        // 保存到 HealthDataManager
        healthDataManager.addMedicationReminder(reminder)
        
        print("💊 保存药品信息成功:")
        print("   名称: \(medicationName)")
        print("   类型: \(medicationType)")
        print("   剂量: \(dosageDescription)")
        print("   用药时机: \(fullUsageTiming)")
        print("   药物用途: \(medicationUsage)")
        print("   库存: \(inventory)")
        print("   提醒时间: \(reminderTimes)")
        
        // 隐藏键盘
        focusedField = nil
        
        // 关闭视图
        withAnimation {
            isPresented = false
        }
    }
}

// MARK: - Preview
struct AddMedicationFormView_Previews: PreviewProvider {
    static var previews: some View {
        AddMedicationFormView(isPresented: .constant(true))
            .environmentObject(HealthDataManager())
    }
}

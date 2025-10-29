//
//  RecordsView.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI
import Vision

struct RecordsView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var searchText = ""
    @State private var showingAddCase = false
    
    // 🔍 添加搜索过滤功能
    private var unarchivedRecords: [HealthRecord] {
        let records = healthDataManager.getUnarchivedRecords()
        print("🔍 RecordsView: 未归档记录数 = \(records.count)")
        
        // 如果有搜索文本，进行过滤
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let filtered = records.filter { record in
                searchRecord(record, with: searchText)
            }
            print("🔍 搜索 '\(searchText)': 找到 \(filtered.count) 条未归档记录")
            return filtered
        }
        
        return records
    }
    
    private var archivedRecords: [HealthRecord] {
        let records = healthDataManager.getArchivedRecords()
        print("🔍 RecordsView: 已归档记录数 = \(records.count)")
        
        // 如果有搜索文本，进行过滤
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let filtered = records.filter { record in
                searchRecord(record, with: searchText)
            }
            print("🔍 搜索 '\(searchText)': 找到 \(filtered.count) 条已归档记录")
            return filtered
        }
        
        return records
    }
    
    // 🔍 搜索记录的辅助函数
    private func searchRecord(_ record: HealthRecord, with searchText: String) -> Bool {
        let text = searchText.lowercased()
        
        // 搜索医院名称
        if record.hospitalName.lowercased().contains(text) {
            return true
        }
        
        // 搜索科室
        if record.department.lowercased().contains(text) {
            return true
        }
        
        // 搜索日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: record.date)
        if dateString.contains(text) {
            return true
        }
        
        // 搜索症状
        if record.symptoms.lowercased().contains(text) {
            return true
        }
        
        // 搜索诊断
        if let diagnosis = record.diagnosis, diagnosis.lowercased().contains(text) {
            return true
        }
        
        // 搜索治疗方案
        if let treatment = record.treatment, treatment.lowercased().contains(text) {
            return true
        }
        
        return false
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    RecordsHeader(showingAddCase: $showingAddCase)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    
                    // Search Bar
                    SearchBar(searchText: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // 未归档记录（待整理）
                    if !unarchivedRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("待归档")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.05)
                                
                                Spacer()
                                
                                Text("\(unarchivedRecords.count)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 20)
                            
                            ForEach(unarchivedRecords) { record in
                                SwipeableRecordCard(record: record)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    
                    // 已归档记录
                    if !archivedRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("就诊记录")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.05)
                                .padding(.horizontal, 20)
                            
                            ForEach(archivedRecords) { record in
                                SwipeableRecordCard(record: record)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // 空状态
                    if unarchivedRecords.isEmpty && archivedRecords.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundColor(.textSecondary.opacity(0.5))
                            
                            Text("暂无就诊记录")
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                            
                            Text("点击右上角 + 号添加记录")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    }
                }
            }
            .background(Color.appBackgroundColor)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddCase) {
                AddCaseStepView()
                    .environmentObject(healthDataManager)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Records Header
struct RecordsHeader: View {
    @Binding var showingAddCase: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("就诊记录")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("病历与档案管理")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Button(action: {
                showingAddCase = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentPrimary, Color.accentTertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.accentPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundColor(.textSecondary)
            
            TextField("搜索医院、科室、日期...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.textPrimary)
        }
        .padding(12)
        .background(Color.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Record Card View
struct RecordCardView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    let record: HealthRecord
    @State private var showingMergeSelection = false
    @State private var showingDeleteConfirm = false
    @State private var refreshID = UUID()
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 就诊"
        return formatter.string(from: record.date)
    }
    
    private var items: [CaseItem] {
        var itemList: [CaseItem] = []
        
        // 添加录音记录
        for (index, audio) in record.audioRecordings.enumerated() {
            let minutes = Int(audio.duration) / 60
            let title = audio.title ?? "录音记录 \(index + 1)"
            itemList.append(CaseItem(icon: "mic.fill", text: "\(title) (\(minutes)分钟)"))
        }
        
        // 添加附件
        if !record.attachments.isEmpty {
            itemList.append(CaseItem(icon: "doc.fill", text: "检查报告 - \(record.attachments.count)张"))
        }
        
        // 添加诊断
        if let diagnosis = record.diagnosis, !diagnosis.isEmpty {
            itemList.append(CaseItem(icon: "stethoscope", text: "诊断: \(diagnosis)"))
        }
        
        // 如果没有任何内容，显示症状
        if itemList.isEmpty {
            itemList.append(CaseItem(icon: "doc.text", text: record.symptoms))
        }
        
        return itemList
    }
    
    var body: some View {
        NavigationLink(destination: RecordDetailView(record: record)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.hospitalName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text(dateString)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text(record.department)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(6)
                        
                        if !record.isArchived {
                            // 添加按钮
                            Button(action: {
                                showingMergeSelection = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .padding(6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 删除按钮
                            Button(action: {
                                showingDeleteConfirm = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(6)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items) { item in
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                                .frame(width: 20, height: 20)
                            
                            Text(item.text)
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.secondaryBackgroundColor)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .background(Color.cardBackgroundColor)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(record.isArchived ? Color.dividerColor : Color.orange.opacity(0.3), lineWidth: record.isArchived ? 1 : 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingMergeSelection) {
            RecordMergeSelectionSheet(
                sourceRecord: record,
                onMerge: mergeToRecord
            )
            .environmentObject(healthDataManager)
            .id(refreshID) // 强制刷新
            .onAppear {
                // 每次打开时刷新
                refreshID = UUID()
            }
        }
        .alert("删除记录", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("确定要删除这条记录吗？此操作无法撤销。")
        }
    }
    
    private func mergeToRecord(_ targetRecord: HealthRecord) {
        var updatedTarget = targetRecord
        
        // 合并录音
        updatedTarget.audioRecordings.append(contentsOf: record.audioRecordings)
        
        // 合并附件
        updatedTarget.attachments.append(contentsOf: record.attachments)
        
        // 合并症状信息（如果目标记录的症状为空或为"待补充"）
        if updatedTarget.symptoms.isEmpty || updatedTarget.symptoms == "待补充" || updatedTarget.symptoms.contains("录音记录") || updatedTarget.symptoms.contains("报告照片") {
            if !record.symptoms.isEmpty && record.symptoms != "待补充" && !record.symptoms.contains("录音记录") && !record.symptoms.contains("报告照片") {
                updatedTarget.symptoms = record.symptoms
            }
        }
        
        // 更新目标记录
        healthDataManager.updateHealthRecord(updatedTarget)
        
        // 删除源记录
        healthDataManager.deleteHealthRecord(record)
    }
    
    private func deleteRecord() {
        healthDataManager.deleteHealthRecord(record)
    }
}

// MARK: - Case Record Card
struct CaseRecordCard: View {
    let hospital: String
    let department: String
    let date: String
    let items: [CaseItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hospital)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(date)
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Text(department)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondaryBackgroundColor)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items) { item in
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                                .frame(width: 20, height: 20)
                            
                            Text(item.text)
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.secondaryBackgroundColor)
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.dividerColor, lineWidth: 1)
        )
    }
}

// MARK: - Add Case View (分步引导式)
struct AddCaseView: View {
    @Environment(\.dismiss) var dismiss
    
    // 当前步骤
    @State private var currentStep = 1
    let totalSteps = 5
    
    // 表单数据
    @State private var hospitalName = ""
    @State private var department = ""
    @State private var doctorName = ""
    @State private var visitDate = Date()
    @State private var symptoms = ""
    @State private var diagnosis = ""
    @State private var treatment = ""
    @State private var prescription = ""
    @State private var notes = ""
    @State private var showingImagePicker = false
    @State private var selectedImages: [String] = []
    
    var progressPercentage: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部进度条
                VStack(spacing: 0) {
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondaryBackgroundColor)
                                .frame(height: 4)
                            
                            Rectangle()
                                .fill(Color.textPrimary)
                                .frame(width: geometry.size.width * progressPercentage, height: 4)
                                .animation(.easeInOut(duration: 0.3), value: currentStep)
                        }
                    }
                    .frame(height: 4)
                    
                    // 步骤指示
                    HStack {
                        Text("第 \(currentStep) 步，共 \(totalSteps) 步")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color.appBackgroundColor)
                
                // 步骤内容
                TabView(selection: $currentStep) {
                    // 基本信息
                    VStack(alignment: .leading, spacing: 16) {
                        Text("基本信息")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("医院名称 *")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                            
                            TextField("请输入医院名称", text: $hospitalName)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("科室 *")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                            
                            TextField("请输入科室", text: $department)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("医生姓名")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                            
                            TextField("请输入医生姓名", text: $doctorName)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("就诊日期 *")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                            
                            DatePicker("", selection: $visitDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding(12)
                                .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                                .cornerRadius(12)
                        }
                    }
                    
                    Divider()
                    
                    // 就诊详情
                    VStack(alignment: .leading, spacing: 16) {
                        Text("就诊详情")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("主要症状 *")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                            
                            TextEditor(text: $symptoms)
                                .font(.system(size: 15))
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("诊断结果")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                            
                            TextEditor(text: $diagnosis)
                                .font(.system(size: 15))
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("治疗方案")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                            
                            TextEditor(text: $treatment)
                                .font(.system(size: 15))
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("处方药物")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                            
                            TextEditor(text: $prescription)
                                .font(.system(size: 15))
                                .frame(minHeight: 60)
                                .padding(12)
                                .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                                .cornerRadius(12)
                        }
                    }
                    
                    Divider()
                    
                    // 附件
                    VStack(alignment: .leading, spacing: 12) {
                        Text("附件")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                                
                                Text("添加检查报告或照片")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 120/255, green: 119/255, blue: 116/255))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(red: 233/255, green: 233/255, blue: 231/255), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            )
                        }
                    }
                    
                    Divider()
                    
                    // 备注
                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                        
                        TextEditor(text: $notes)
                            .font(.system(size: 15))
                            .frame(minHeight: 80)
                            .padding(12)
                            .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                            .cornerRadius(12)
                    }
                    
                    // 保存按钮
                    Button(action: {
                        // 保存病历
                        dismiss()
                    }) {
                        Text("保存病历")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 55/255, green: 53/255, blue: 47/255))
                            .cornerRadius(12)
                    }
                    .disabled(hospitalName.isEmpty || department.isEmpty || symptoms.isEmpty)
                    .opacity(hospitalName.isEmpty || department.isEmpty || symptoms.isEmpty ? 0.5 : 1.0)
                }
                .padding(24)
            }
            .background(Color.appBackgroundColor)
            .navigationTitle("创建新病历")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 120/255, green: 119/255, blue: 116/255))
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            Text("图片选择器")
        }
    }
}

// MARK: - Case Detail View
struct CaseDetailView: View {
    let hospital: String
    let department: String
    let date: String
    let items: [CaseItem]
    @Environment(\.dismiss) var dismiss
    @State private var isEditMode = false
    
    var body: some View {
        ZStack {
            Color.appBackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 自定义导航栏
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .frame(width: 32, height: 32)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hospital)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                        
                        HStack(spacing: 12) {
                            Text(department)
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                            
                            Text(date)
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { isEditMode.toggle() }) {
                        Image(systemName: isEditMode ? "checkmark" : "square.and.pencil")
                            .font(.system(size: 16))
                            .foregroundColor(isEditMode ? .white : Color(red: 120/255, green: 119/255, blue: 116/255))
                            .frame(width: 32, height: 32)
                            .background(isEditMode ? Color(red: 55/255, green: 53/255, blue: 47/255) : Color.clear)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(red: 255/255, green: 255/255, blue: 255/255))
                .overlay(
                    Rectangle()
                        .fill(Color(red: 241/255, green: 241/255, blue: 239/255))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        // 病例基本信息
                        RecordDetailSection(
                            icon: "doc.text",
                            title: "病例信息"
                        ) {
                            EmptyView()
                        }
                        
                        // 录音记录
                        RecordDetailSection(
                            icon: "mic",
                            title: "录音记录"
                        ) {
                            AudioPlayerView(
                                title: "张医生诊断录音",
                                duration: "5分钟",
                                date: "2025-10-20"
                            )
                        }
                        
                        // 检查报告
                        RecordDetailSection(
                            icon: "doc.text",
                            title: "检查报告"
                        ) {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ReportImageCard(imageName: "血常规报告")
                                ReportImageCard(imageName: "心电图报告")
                            }
                        }
                        
                        // 处方单
                        RecordDetailSection(
                            icon: "doc.on.clipboard",
                            title: "处方单"
                        ) {
                            VStack(alignment: .leading, spacing: 16) {
                                PrescriptionImageCard()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("OCR识别文本")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                                    
                                    Text("""
                                    北京协和医院处方单
                                    
                                    患者姓名：张三
                                    性别：男
                                    年龄：58岁
                                    科室：心血管科
                                    日期：2025-10-20
                                    
                                    药品名称               规格        数量    用法用量
                                    阿司匹林肠溶片        100mg       30片    每日一次，每次1片
                                    降压药片              5mg         30片    每日一次，每次1片
                                    
                                    医生签名：张医生
                                    """)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 120/255, green: 119/255, blue: 116/255))
                                    .lineSpacing(4)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        // AI解读报告
                        RecordDetailSection(
                            icon: "lightbulb",
                            title: "AI解读报告"
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("智能分析")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                                
                                Text("""
                                根据您的检查报告和处方，AI分析如下：
                                
                                1. 血常规检查结果正常，各项指标均在正常范围内，说明整体健康状况良好。
                                
                                2. 心电图显示轻微ST段改变，建议定期复查。可能与心血管疾病相关，需要注意休息，避免过度劳累。
                                
                                3. 处方用药合理：
                                   - 阿司匹林用于抗血小板聚集，预防心血管事件
                                   - 降压药用于控制血压
                                   两项药物搭配使用，有助于心血管健康管理。
                                
                                建议：保持规律作息，适度运动，按时服药，3个月后复查。
                                """)
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 120/255, green: 119/255, blue: 116/255))
                                .lineSpacing(6)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                            .cornerRadius(16)
                        }
                        
                        // AI问询
                        RecordDetailSection(
                            icon: "message",
                            title: "AI问询"
                        ) {
                            AIChatView()
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Record Detail Section Component
struct RecordDetailSection<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
            }
            
            content
        }
    }
}

// MARK: - Audio Player Component
struct AudioPlayerView: View {
    let title: String
    let duration: String
    let date: String
    @State private var isPlaying = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { isPlaying.toggle() }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color(red: 55/255, green: 53/255, blue: 47/255))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
                
                Text("\(duration) · \(date)")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(red: 250/255, green: 250/255, blue: 250/255))
        .cornerRadius(16)
    }
}

// MARK: - Report Image Card
struct ReportImageCard: View {
    let imageName: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 245/255, green: 245/255, blue: 243/255))
                .aspectRatio(3/4, contentMode: .fit)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 233/255, green: 233/255, blue: 231/255), lineWidth: 1)
                )
            
            VStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                
                Text(imageName)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 120/255, green: 119/255, blue: 116/255))
            }
        }
    }
}

// MARK: - Prescription Image Card
struct PrescriptionImageCard: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 245/255, green: 245/255, blue: 243/255))
                .aspectRatio(4/3, contentMode: .fit)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 233/255, green: 233/255, blue: 231/255), lineWidth: 1)
                )
            
            VStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 155/255, green: 154/255, blue: 151/255))
                
                Text("处方单")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 120/255, green: 119/255, blue: 116/255))
            }
        }
    }
}

// MARK: - AI Chat View
struct AIChatView: View {
    @State private var messages: [AIChatMessage] = [
        AIChatMessage(text: "您好！我是AI健康助手，我可以基于您的检查报告和处方内容回答相关问题。请问有什么想了解的吗？", isUser: false)
    ]
    @State private var inputText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基于报告内容提问")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 55/255, green: 53/255, blue: 47/255))
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(messages) { message in
                    HStack {
                        if message.isUser {
                            Spacer()
                        }
                        
                        Text(message.text)
                            .font(.system(size: 14))
                            .foregroundColor(message.isUser ? .white : Color(red: 55/255, green: 53/255, blue: 47/255))
                            .padding(12)
                            .background(message.isUser ? Color(red: 55/255, green: 53/255, blue: 47/255) : Color(red: 245/255, green: 245/255, blue: 243/255))
                            .cornerRadius(12)
                        
                        if !message.isUser {
                            Spacer()
                        }
                    }
                }
            }
            
            HStack(spacing: 8) {
                TextField("输入您的问题...", text: $inputText)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color(red: 250/255, green: 250/255, blue: 250/255))
                    .cornerRadius(12)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color(red: 55/255, green: 53/255, blue: 47/255))
                        .cornerRadius(12)
                }
                .disabled(inputText.isEmpty)
                .opacity(inputText.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(20)
        .background(Color(red: 250/255, green: 250/255, blue: 250/255))
        .cornerRadius(16)
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        messages.append(AIChatMessage(text: inputText, isUser: true))
        inputText = ""
        
        // 模拟AI回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            messages.append(AIChatMessage(text: "感谢您的提问！这是一个模拟的AI回复。在实际应用中，这里会显示基于您的医疗记录的智能分析结果。", isUser: false))
        }
    }
}

// MARK: - AI Chat Message Model
struct AIChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

#Preview {
    RecordsView()
}

// MARK: - Record Detail View (适配器)
struct RecordDetailView: View {
    let record: HealthRecord
    @EnvironmentObject var healthDataManager: HealthDataManager
    @Environment(\.dismiss) var dismiss
    @State private var isEditMode = false
    @State private var selectedReport: MedicalReport?
    @State private var showExcelViewer = false
    @State private var showImageViewer = false
    @State private var selectedImageData: Data?
    
    // 编辑状态的字段
    @State private var editedSymptoms: String = ""
    @State private var editedDiagnosis: String = ""
    @State private var editedTreatment: String = ""
    @State private var editedNotes: String = ""
    
    // 图片分析
    @StateObject private var imageAnalyzer = ImageAnalysisManager.shared
    @State private var analyzingImageIndex: Int? = nil
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: record.date)
    }
    
    var body: some View {
        ZStack {
            Color.appBackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 自定义导航栏
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .frame(width: 32, height: 32)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.hospitalName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 12) {
                            Text(record.department)
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                            
                            Text(dateString)
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 编辑/保存按钮
                    if isEditMode {
                        // 保存按钮
                        Button(action: {
                            saveEdits()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14))
                                Text("保存")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentPrimary)
                            .cornerRadius(8)
                        }
                    } else {
                        // 编辑按钮
                        Button(action: {
                            enterEditMode()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 14))
                                Text("编辑")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.accentPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentPrimary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 归档状态
                        if !record.isArchived {
                            Button(action: {
                                archiveRecord()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "archivebox")
                                        .font(.system(size: 14))
                                    Text("归档")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.cardBackgroundColor)
                .overlay(
                    Rectangle()
                        .fill(Color.dividerColor)
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // 症状
                        RecordDetailSection(icon: "heart.text.square", title: "症状") {
                            if isEditMode {
                                TextEditor(text: $editedSymptoms)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color.cardBackgroundColor)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            } else if !record.symptoms.isEmpty {
                                Text(record.symptoms)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.secondaryBackgroundColor)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // 诊断
                        RecordDetailSection(icon: "stethoscope", title: "诊断") {
                            if isEditMode {
                                TextEditor(text: $editedDiagnosis)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color.cardBackgroundColor)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            } else if let diagnosis = record.diagnosis, !diagnosis.isEmpty {
                                Text(diagnosis)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.secondaryBackgroundColor)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // 治疗方案
                        RecordDetailSection(icon: "cross.case", title: "治疗方案") {
                            if isEditMode {
                                TextEditor(text: $editedTreatment)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color.cardBackgroundColor)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            } else if let treatment = record.treatment, !treatment.isEmpty {
                                Text(treatment)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.secondaryBackgroundColor)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Excel报告（新增）
                        if !record.medicalReports.isEmpty {
                            let excelReports = record.medicalReports.filter { $0.fileType == "excel" }
                            if !excelReports.isEmpty {
                                RecordDetailSection(icon: "tablecells", title: "Excel报告") {
                                    VStack(spacing: 12) {
                                        ForEach(excelReports) { reportRef in
                                            if let report = loadMedicalReport(id: reportRef.id) {
                                                ExcelReportCard(report: report) {
                                                    selectedReport = report
                                                    showExcelViewer = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 录音记录（含转文本）
                        if !record.audioRecordings.isEmpty {
                            RecordDetailSection(icon: "mic", title: "录音记录") {
                                VStack(spacing: 12) {
                                    ForEach(record.audioRecordings) { audio in
                                        AudioRecordingCard(
                                            audio: audio,
                                            onPlayToggle: {
                                                // 播放/暂停音频
                                            },
                                            onTranscribe: { transcription in
                                                // 保存转录结果
                                                saveTranscription(for: audio.id, text: transcription)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        
                        // 附件（图片）- 缩小显示 + AI分析
                        if !record.attachments.isEmpty {
                            RecordDetailSection(icon: "photo", title: "图片附件") {
                                VStack(spacing: 12) {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 8),
                                        GridItem(.flexible(), spacing: 8),
                                        GridItem(.flexible(), spacing: 8)  // 改为3列，图片更小
                                    ], spacing: 8) {
                                        ForEach(Array(record.attachments.enumerated()), id: \.offset) { index, imageData in
                                            ZStack(alignment: .topTrailing) {
                                                Button(action: {
                                                    selectedImageData = imageData
                                                    showImageViewer = true
                                                }) {
                                                    if let image = UIImage(data: imageData) {
                                                        Image(uiImage: image)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(height: 100)  // 从150降到100
                                                            .clipped()
                                                            .cornerRadius(8)
                                                    } else {
                                                        ZStack {
                                                            Rectangle()
                                                                .fill(Color.secondaryBackgroundColor)
                                                                .frame(height: 100)
                                                                .cornerRadius(8)
                                                            
                                                            Image(systemName: "photo")
                                                                .font(.system(size: 24))
                                                                .foregroundColor(.textSecondary)
                                                        }
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                
                                                // AI分析按钮
                                                Button(action: {
                                                    analyzeImage(imageData, at: index)
                                                }) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(Color.accentPrimary)
                                                            .frame(width: 28, height: 28)
                                                        
                                                        if analyzingImageIndex == index {
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                                .scaleEffect(0.6)
                                                        } else {
                                                            Image(systemName: "sparkles")
                                                                .font(.system(size: 12))
                                                                .foregroundColor(.white)
                                                        }
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .padding(6)
                                            }
                                        }
                                    }
                                    
                                    // 提示
                                    if !record.attachments.isEmpty {
                                        HStack(spacing: 6) {
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 12))
                                            Text("点击右上角✨按钮，AI将自动识别医嘱或诊断书")
                                                .font(.system(size: 11))
                                        }
                                        .foregroundColor(.textTertiary)
                                        .padding(.top, 4)
                                    }
                                }
                            }
                        }
                        
                        // 备注
                        RecordDetailSection(icon: "note.text", title: "备注") {
                            if isEditMode {
                                TextEditor(text: $editedNotes)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color.cardBackgroundColor)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            } else if let notes = record.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.secondaryBackgroundColor)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // AI报告分析（底部）
                        if hasAnyData {
                            RecordDetailSection(icon: "sparkles", title: "AI智能分析") {
                                AIReportAnalysisView(
                                    reportData: buildReportContext(),
                                    reportType: "就诊记录",
                                    attachmentsHash: calculateAttachmentsHash()
                                )
                                .environmentObject(healthDataManager)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showExcelViewer) {
            if let report = selectedReport {
                ExcelViewerView(report: report)
            }
        }
        .sheet(isPresented: $showImageViewer) {
            if let imageData = selectedImageData, let image = UIImage(data: imageData) {
                ImageDetailView(image: image)
            }
        }
    }
    
    private var hasAnyData: Bool {
        return !record.medicalReports.isEmpty || !record.audioRecordings.isEmpty || !record.attachments.isEmpty
    }
    
    private func buildReportContext() -> String {
        var context = ""
        context += "医院：\(record.hospitalName)\n"
        context += "科室：\(record.department)\n"
        context += "就诊日期：\(dateString)\n\n"
        
        // 自动提取照片中的文字（OCR）
        if !record.attachments.isEmpty {
            context += "【报告照片内容】\n"
            for (index, imageData) in record.attachments.enumerated() {
                let ocrText = extractTextFromImage(imageData)
                if !ocrText.isEmpty && ocrText != "图片中未识别到文字，请确保照片清晰" {
                    context += "报告\(index + 1)：\n\(ocrText)\n\n"
                }
            }
        }
        
        if !record.symptoms.isEmpty && record.symptoms != "待补充" && !record.symptoms.contains("报告照片") {
            context += "症状：\(record.symptoms)\n\n"
        }
        
        if let diagnosis = record.diagnosis, !diagnosis.isEmpty {
            context += "诊断：\(diagnosis)\n\n"
        }
        
        if let treatment = record.treatment, !treatment.isEmpty {
            context += "治疗方案：\(treatment)\n\n"
        }
        
        // 添加转录文本
        for audio in record.audioRecordings {
            if let transcription = audio.transcribedText, audio.isTranscribed {
                context += "录音转录：\(transcription)\n\n"
            }
        }
        
        if let notes = record.notes, !notes.isEmpty {
            context += "备注：\(notes)\n"
        }
        
        return context
    }
    
    // 计算附件的哈希值（用于判断附件是否有变化）
    private func calculateAttachmentsHash() -> String {
        // 基于附件的数量和每个附件的大小来生成hash
        var hashString = "\(record.attachments.count)"
        for imageData in record.attachments {
            hashString += "_\(imageData.count)"
        }
        return String(hashString.hashValue)
    }
    
    // 从图片中提取文字（OCR）
    private func extractTextFromImage(_ imageData: Data) -> String {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return ""
        }
        
        var extractedText = ""
        let semaphore = DispatchSemaphore(value: 0)
        
        if #available(iOS 13.0, *) {
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    semaphore.signal()
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                extractedText = recognizedStrings.joined(separator: "\n")
                semaphore.signal()
            }
            
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("❌ OCR处理失败: \(error.localizedDescription)")
                    semaphore.signal()
                }
            }
            
            // 等待OCR完成（最多3秒）
            _ = semaphore.wait(timeout: .now() + 3)
        }
        
        if extractedText.isEmpty {
            print("⚠️ 图片中未识别到文字")
        } else {
            print("✅ OCR识别成功，提取了文字：\(extractedText.prefix(100))...")
        }
        
        return extractedText
    }
    
    private func loadMedicalReport(id: UUID) -> MedicalReport? {
        // 从MedicalReportManager加载报告
        // 这需要在HealthDataManager中添加对MedicalReportManager的引用
        return nil // 临时返回nil,需要实现
    }
    
    // 进入编辑模式
    private func enterEditMode() {
        editedSymptoms = record.symptoms
        editedDiagnosis = record.diagnosis ?? ""
        editedTreatment = record.treatment ?? ""
        editedNotes = record.notes ?? ""
        
        withAnimation {
            isEditMode = true
        }
    }
    
    // 保存编辑
    private func saveEdits() {
        var updatedRecord = record
        updatedRecord.symptoms = editedSymptoms
        updatedRecord.diagnosis = editedDiagnosis.isEmpty ? nil : editedDiagnosis
        updatedRecord.treatment = editedTreatment.isEmpty ? nil : editedTreatment
        updatedRecord.notes = editedNotes.isEmpty ? nil : editedNotes
        
        healthDataManager.updateHealthRecord(updatedRecord)
        
        withAnimation {
            isEditMode = false
        }
        
        print("✅ 保存了编辑内容")
    }
    
    private func archiveRecord() {
        var updatedRecord = record
        updatedRecord.isArchived = true
        healthDataManager.updateHealthRecord(updatedRecord)
        dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // 分析图片
    private func analyzeImage(_ imageData: Data, at index: Int) {
        analyzingImageIndex = index
        
        imageAnalyzer.analyzeImage(
            imageData: imageData,
            onUpdate: { partialResult in
                print("📄 AI分析中: \(partialResult)")
            },
            onComplete: { result in
                analyzingImageIndex = nil
                
                // 根据分析结果自动填充
                var updatedRecord = record
                
                switch result.documentType {
                case .prescription:
                    // 医嘱/处方 - 保存到治疗方案
                    if let treatmentPlan = result.treatmentPlan {
                        let currentTreatment = updatedRecord.treatment ?? ""
                        let newTreatment = currentTreatment.isEmpty ? treatmentPlan : "\(currentTreatment)\n\n\(treatmentPlan)"
                        updatedRecord.treatment = newTreatment
                        
                        // 如果在编辑模式，同步更新编辑字段
                        if isEditMode {
                            editedTreatment = newTreatment
                        }
                        
                        print("✅ 识别为医嘱，治疗方案已保存")
                    }
                    
                case .diagnosis:
                    // 诊断书 - 保存到诊断
                    if let diagnosis = result.diagnosis {
                        let currentDiagnosis = updatedRecord.diagnosis ?? ""
                        let newDiagnosis = currentDiagnosis.isEmpty ? diagnosis : "\(currentDiagnosis)\n\n\(diagnosis)"
                        updatedRecord.diagnosis = newDiagnosis
                        
                        // 如果在编辑模式，同步更新编辑字段
                        if isEditMode {
                            editedDiagnosis = newDiagnosis
                        }
                        
                        print("✅ 识别为诊断书，诊断已保存")
                    }
                    
                case .other:
                    print("ℹ️ 未识别为医嘱或诊断书")
                }
                
                // 保存更新
                healthDataManager.updateHealthRecord(updatedRecord)
            }
        )
    }
    
    // 保存转录结果
    private func saveTranscription(for audioId: UUID, text: String) {
        var updatedRecord = record
        
        // 找到对应的录音记录并更新
        if let index = updatedRecord.audioRecordings.firstIndex(where: { $0.id == audioId }) {
            updatedRecord.audioRecordings[index].transcribedText = text
            updatedRecord.audioRecordings[index].isTranscribed = true
            
            print("✅ 转录文本已保存到录音记录")
            print("📝 转录内容: \(text)")
            
            // 保存更新的记录
            healthDataManager.updateHealthRecord(updatedRecord)
        }
    }
}

// MARK: - Excel Report Card
struct ExcelReportCard: View {
    let report: MedicalReport
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Excel图标
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "tablecells.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(report.reportType.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        
                        if let fileName = report.excelFileName {
                            Text("•")
                                .foregroundColor(.textTertiary)
                            Text(fileName)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.textTertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondaryBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Audio Recording Card with Transcription
struct AudioRecordingCard: View {
    let audio: HealthRecord.AudioRecording
    let onPlayToggle: () -> Void
    let onTranscribe: ((String) -> Void)? // 转录完成回调
    
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    @StateObject private var speechRecognizer = SpeechRecognitionManager.shared
    @State private var showTranscription = false
    @State private var isTranscribing = false
    
    private var durationString: String {
        let minutes = Int(audio.duration) / 60
        let seconds = Int(audio.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: audio.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 播放器部分
            HStack(spacing: 12) {
                // 播放按钮
                Button(action: {
                    audioPlayer.play(audioData: audio.audioData, audioId: audio.id)
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.textPrimary)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(audio.title ?? "录音记录")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(durationString)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        
                        Text("•")
                            .foregroundColor(.textTertiary)
                        
                        Text(dateString)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                // 转文本按钮/标签
                if isTranscribing {
                    // 转录中
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("转录中...")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                } else if audio.isTranscribed {
                    // 已转录 - 查看文本
                    Button(action: {
                        showTranscription.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showTranscription ? "chevron.up" : "text.bubble.fill")
                                .font(.system(size: 12))
                            Text(showTranscription ? "收起" : "查看文本")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // 未转录 - 转文字按钮
                    Button(action: {
                        startTranscription()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform.and.mic")
                                .font(.system(size: 12))
                            Text("转文字")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentPrimary.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // 转文本内容（可展开）
            if audio.isTranscribed && showTranscription {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    HStack {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                        
                        Text("转录文本")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                    }
                    
                    if let transcription = audio.transcribedText {
                        Text(transcription)
                            .font(.system(size: 14))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    } else {
                        Text("暂无转录内容")
                            .font(.system(size: 14))
                            .foregroundColor(.textTertiary)
                            .italic()
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondaryBackgroundColor)
        )
    }
    
    // MARK: - 转录功能
    
    private func startTranscription() {
        guard !audio.audioData.isEmpty else {
            print("❌ 音频数据为空，无法转录")
            return
        }
        
        isTranscribing = true
        print("🎤 开始转录音频，大小: \(audio.audioData.count) 字节")
        
        speechRecognizer.transcribeAudio(audioData: audio.audioData) { result in
            DispatchQueue.main.async {
                self.isTranscribing = false
                
                switch result {
                case .success(let transcription):
                    print("✅ 转录成功: \(transcription)")
                    // 调用回调保存转录结果
                    self.onTranscribe?(transcription)
                    // 自动展开显示文本
                    self.showTranscription = true
                    
                case .failure(let error):
                    print("❌ 转录失败: \(error.localizedDescription)")
                    // 可以显示错误提示
                }
            }
        }
    }
}

// MARK: - Image Detail Viewer
struct ImageDetailView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1 {
                                    withAnimation {
                                        scale = 1
                                        lastScale = 1
                                    }
                                } else if scale > 5 {
                                    withAnimation {
                                        scale = 5
                                        lastScale = 5
                                    }
                                }
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            saveImageToPhotos(image)
                        }) {
                            Label("保存到相册", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: {
                            shareImage(image)
                        }) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private func saveImageToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    private func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Swipeable Record Card
struct SwipeableRecordCard: View {
    let record: HealthRecord
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var offset: CGFloat = 0
    @State private var showingDeleteConfirm = false
    @State private var isDragging = false
    
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 删除按钮（背景）
            HStack(spacing: 0) {
                Spacer()
                Button(action: {
                    showingDeleteConfirm = true
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("删除")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteButtonWidth)
                    .frame(maxHeight: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxHeight: .infinity)
            .background(Color.red)
            .cornerRadius(20)
            
            // 卡片内容
            RecordCardView(record: record)
                .background(Color.appBackgroundColor)
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 15)
                        .onChanged { value in
                            isDragging = true
                            let translation = value.translation.width
                            
                            // 只允许向左滑动显示删除按钮
                            if translation < 0 {
                                // 向左滑动
                                offset = max(translation, -deleteButtonWidth)
                            } else if offset < 0 {
                                // 已经打开，允许向右滑动关闭
                                offset = min(0, offset + translation)
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            let velocity = value.predictedEndTranslation.width - value.translation.width
                            
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                // 根据滑动距离和速度决定是否打开
                                if value.translation.width < -40 || velocity < -100 {
                                    // 滑动超过40点或快速向左滑，显示删除按钮
                                    offset = -deleteButtonWidth
                                } else {
                                    // 否则回弹
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .clipped()
        .alert("删除记录", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    offset = 0
                }
            }
            Button("删除", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("确定要删除这条就诊记录吗？此操作无法撤销。")
        }
    }
    
    private func deleteRecord() {
        withAnimation {
            healthDataManager.deleteHealthRecord(record)
        }
    }
}

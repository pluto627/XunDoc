//
//  AddPrescriptionView.swift
//  XunDoc
//
//  医嘱上传视图
//

import SwiftUI
import PhotosUI

struct AddPrescriptionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthDataManager: HealthDataManager
    @StateObject private var prescriptionManager = PrescriptionManager.shared
    
    @State private var prescriptionType: PrescriptionType = .handwritten
    @State private var hospitalName = ""
    @State private var department = ""
    @State private var doctorName = ""
    @State private var diagnosis = ""
    @State private var prescriptionDate = Date()
    @State private var notes = ""
    
    // 图片上传
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    // 结构化数据
    @State private var prescriptionItems: [PrescriptionItem] = []
    @State private var showingAddItem = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 类型选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("处方类型")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack(spacing: 12) {
                            TypeButton(
                                title: "手写处方",
                                icon: "doc.text.image",
                                isSelected: prescriptionType == .handwritten
                            ) {
                                prescriptionType = .handwritten
                            }
                            
                            TypeButton(
                                title: "电子医嘱",
                                icon: "doc.text",
                                isSelected: prescriptionType == .electronic
                            ) {
                                prescriptionType = .electronic
                            }
                        }
                    }
                    
                    // 图片上传区域 (手写/电子处方都支持)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("处方图片" + (prescriptionType == .handwritten ? " *" : ""))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        if selectedImages.isEmpty {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                VStack(spacing: 16) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.textTertiary)
                                    
                                    Text("拍摄或选择处方照片")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                    
                                    Text(prescriptionType == .handwritten 
                                         ? "上传后将自动识别处方内容"
                                         : "作为备份保存")
                                        .font(.system(size: 13))
                                        .foregroundColor(.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                        .foregroundColor(.dividerColor)
                                )
                            }
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(selectedImages.indices, id: \.self) { index in
                                        ImageThumbnail(image: selectedImages[index]) {
                                            selectedImages.remove(at: index)
                                        }
                                    }
                                    
                                    // 添加更多图片
                                    Button(action: {
                                        showingImagePicker = true
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 24))
                                                .foregroundColor(.textSecondary)
                                        }
                                        .frame(width: 100, height: 100)
                                        .background(Color.secondaryBackgroundColor)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    
                    // 电子医嘱 - 结构化数据输入
                    if prescriptionType == .electronic {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("药品列表")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAddItem = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("添加药品")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.accentPrimary)
                                }
                            }
                            
                            if prescriptionItems.isEmpty {
                                Text("暂无药品，点击上方添加")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                                    .background(Color.secondaryBackgroundColor)
                                    .cornerRadius(12)
                            } else {
                                ForEach(prescriptionItems) { item in
                                    PrescriptionItemCard(item: item) {
                                        if let index = prescriptionItems.firstIndex(where: { $0.id == item.id }) {
                                            prescriptionItems.remove(at: index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // 基本信息
                    VStack(spacing: 20) {
                        FormField(label: "医院名称", required: true) {
                            TextField("请输入医院名称", text: $hospitalName)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                        
                        FormField(label: "科室") {
                            TextField("如：内科", text: $department)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                        
                        FormField(label: "医生姓名", required: true) {
                            TextField("请输入医生姓名", text: $doctorName)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                        
                        FormField(label: "诊断") {
                            TextField("如：上呼吸道感染", text: $diagnosis)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                        
                        FormField(label: "处方日期", required: true) {
                            DatePicker("", selection: $prescriptionDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding(14)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                        
                        FormField(label: "备注") {
                            TextEditor(text: $notes)
                                .font(.system(size: 15))
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(Color.secondaryBackgroundColor)
                                .cornerRadius(14)
                        }
                    }
                    
                    // 保存按钮
                    Button(action: savePrescription) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text(prescriptionType == .handwritten ? "上传并识别" : "保存医嘱")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                .padding(24)
            }
            .background(Color.appBackgroundColor)
            .navigationTitle("上传医嘱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            MultiImagePicker(images: $selectedImages)
        }
        .sheet(isPresented: $showingAddItem) {
            AddPrescriptionItemSheet(items: $prescriptionItems)
        }
    }
    
    private func canSave() -> Bool {
        let hasRequiredInfo = !hospitalName.isEmpty && !doctorName.isEmpty
        let hasContent = (prescriptionType == .handwritten && !selectedImages.isEmpty) ||
                        (prescriptionType == .electronic && (!prescriptionItems.isEmpty || !selectedImages.isEmpty))
        return hasRequiredInfo && hasContent
    }
    
    private func savePrescription() {
        
        // 转换图片为Data
        let imageDataArray = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        
        let prescription = MedicalPrescription(
            memberId: UUID(),  // 使用默认UUID
            type: prescriptionType,
            date: prescriptionDate,
            hospitalName: hospitalName,
            department: department.isEmpty ? nil : department,
            doctorName: doctorName,
            diagnosis: diagnosis.isEmpty ? nil : diagnosis,
            prescriptionImages: imageDataArray,
            items: prescriptionItems,
            notes: notes.isEmpty ? nil : notes
        )
        
        prescriptionManager.addPrescription(prescription)
        
        // 如果是手写处方，启动识别
        if prescriptionType == .handwritten {
            prescriptionManager.processHandwrittenPrescription(prescription) { success in
                if success {
                    print("✅ 处方识别成功")
                }
            }
        }
        
        print("💊 处方保存成功:")
        print("  类型: \(prescriptionType.displayName)")
        print("  医院: \(hospitalName)")
        print("  药品: \(prescriptionItems.count)")
        
        dismiss()
    }
}

// MARK: - 类型按钮
struct TypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.accentPrimary : Color.secondaryBackgroundColor)
            )
        }
    }
}

// MARK: - 图片缩略图
struct ImageThumbnail: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .cornerRadius(12)
                .clipped()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                    )
            }
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - 处方项目卡片
struct PrescriptionItemCard: View {
    let item: PrescriptionItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.medicationName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 12) {
                    Label(item.dosage, systemImage: "pills")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                    
                    Label(item.frequency, systemImage: "clock")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
        }
        .padding(14)
        .background(Color.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - 多图片选择器
struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MultiImagePicker
        
        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 添加处方项目Sheet
struct AddPrescriptionItemSheet: View {
    @Binding var items: [PrescriptionItem]
    @Environment(\.dismiss) var dismiss
    
    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var duration = ""
    @State private var instructions = ""
    @State private var quantity = ""
    @State private var unit = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("药品信息") {
                    TextField("药品名称", text: $medicationName)
                    TextField("剂量 (如: 0.5g)", text: $dosage)
                }
                
                Section("用法用量") {
                    TextField("频次 (如: 每日3次)", text: $frequency)
                    TextField("疗程 (如: 7天)", text: $duration)
                    TextField("用法说明", text: $instructions)
                }
                
                Section("数量") {
                    TextField("数量", text: $quantity)
                        .keyboardType(.numberPad)
                    TextField("单位 (如: 片/盒)", text: $unit)
                }
            }
            .navigationTitle("添加药品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        saveItem()
                    }
                    .disabled(medicationName.isEmpty || dosage.isEmpty || frequency.isEmpty || duration.isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        let item = PrescriptionItem(
            medicationName: medicationName,
            dosage: dosage,
            frequency: frequency,
            duration: duration,
            instructions: instructions.isEmpty ? nil : instructions,
            quantity: Int(quantity),
            unit: unit.isEmpty ? nil : unit
        )
        
        items.append(item)
        dismiss()
    }
}

#Preview {
    AddPrescriptionView()
        .environmentObject(HealthDataManager.shared)
}


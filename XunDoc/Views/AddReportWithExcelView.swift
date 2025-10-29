//
//  AddReportWithExcelView.swift
//  XunDoc
//
//  报告上传视图 - 支持Excel和图片
//

import SwiftUI
import UniformTypeIdentifiers

struct AddReportWithExcelView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthDataManager: HealthDataManager
    @StateObject private var reportManager = MedicalReportManager.shared
    
    @State private var title = ""
    @State private var hospitalName = ""
    @State private var department = ""
    @State private var doctorName = ""
    @State private var reportDate = Date()
    @State private var notes = ""
    @State private var selectedFileType: ReportFileType = .excel
    @State private var detectedReportType: ReportType = .other
    
    // Excel相关
    @State private var showingExcelPicker = false
    @State private var excelFileURL: URL?
    @State private var excelFileName: String?
    @State private var excelData: Data?
    
    // 图片相关
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var compressedImageData: Data?
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 文件类型选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("上传类型")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack(spacing: 12) {
                            FileTypeButton(
                                icon: "tablecells",
                                title: "Excel表格",
                                isSelected: selectedFileType == .excel
                            ) {
                                selectedFileType = .excel
                            }
                            
                            FileTypeButton(
                                icon: "photo",
                                title: "图片",
                                isSelected: selectedFileType == .image
                            ) {
                                selectedFileType = .image
                            }
                        }
                    }
                    
                    // 文件上传区域
                    if selectedFileType == .excel {
                        ExcelUploadArea(
                            fileName: excelFileName,
                            onUpload: {
                                showingExcelPicker = true
                            },
                            onRemove: {
                                excelFileURL = nil
                                excelFileName = nil
                                excelData = nil
                                title = ""
                            }
                        )
                    } else {
                        ImageUploadArea(
                            image: selectedImage,
                            onUpload: {
                                showingImagePicker = true
                            },
                            onRemove: {
                                selectedImage = nil
                                compressedImageData = nil
                            }
                        )
                    }
                    
                    // 自动识别的报告类型显示
                    if detectedReportType != .other {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundColor(.accentPrimary)
                            
                            Text("智能识别: \(detectedReportType.displayName)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.accentPrimary)
                            
                            Spacer()
                            
                            Image(systemName: detectedReportType.icon)
                                .font(.system(size: 16))
                                .foregroundColor(detectedReportType.color)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.accentPrimary.opacity(0.1))
                        )
                    }
                    
                    // 报告标题
                    FormField(label: "报告标题", required: true) {
                        TextField("如：血常规检查报告", text: $title)
                            .font(.system(size: 15))
                            .padding(14)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(14)
                            .onChange(of: title) { newValue in
                                updateReportTypeDetection()
                            }
                    }
                    
                    // 医院名称
                    FormField(label: "医院名称", required: true) {
                        TextField("请输入医院名称", text: $hospitalName)
                            .font(.system(size: 15))
                            .padding(14)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(14)
                            .onChange(of: hospitalName) { _ in
                                updateReportTypeDetection()
                            }
                    }
                    
                    // 科室
                    FormField(label: "科室") {
                        TextField("请输入科室", text: $department)
                            .font(.system(size: 15))
                            .padding(14)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(14)
                            .onChange(of: department) { _ in
                                updateReportTypeDetection()
                            }
                    }
                    
                    // 医生姓名
                    FormField(label: "医生姓名") {
                        TextField("请输入医生姓名", text: $doctorName)
                            .font(.system(size: 15))
                            .padding(14)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(14)
                    }
                    
                    // 检查日期
                    FormField(label: "检查日期", required: true) {
                        DatePicker("", selection: $reportDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(14)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(14)
                    }
                    
                    // 备注
                    FormField(label: "备注") {
                        TextEditor(text: $notes)
                            .font(.system(size: 15))
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color.secondaryBackgroundColor)
                            .cornerRadius(14)
                            .onChange(of: notes) { _ in
                                updateReportTypeDetection()
                            }
                    }
                    
                    // 保存按钮
                    Button(action: saveReport) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("保存报告")
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
            .navigationTitle("上传报告")
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
        .sheet(isPresented: $showingExcelPicker) {
            DocumentPicker(fileURL: $excelFileURL, fileName: $excelFileName, fileData: $excelData) {
                if let fileName = excelFileName {
                    // 从文件名自动设置标题和类型
                    if title.isEmpty {
                        title = fileName.replacingOccurrences(of: ".xlsx", with: "")
                                       .replacingOccurrences(of: ".xls", with: "")
                    }
                    updateReportTypeDetection()
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ReportImagePicker(image: $selectedImage) {
                if let image = selectedImage {
                    compressedImageData = reportManager.compressImage(image, maxSizeKB: 500)
                }
            }
        }
    }
    
    private func updateReportTypeDetection() {
        let combinedText = "\(title) \(hospitalName) \(department) \(notes) \(excelFileName ?? "")"
        detectedReportType = ReportType.classify(from: combinedText)
    }
    
    private func canSave() -> Bool {
        let hasFile = (selectedFileType == .excel && excelData != nil) || 
                     (selectedFileType == .image && compressedImageData != nil)
        return !title.isEmpty && !hospitalName.isEmpty && hasFile
    }
    
    private func saveReport() {
        
        let report = MedicalReport(
            memberId: UUID(),  // 使用默认UUID
            title: title,
            reportType: detectedReportType,
            fileType: selectedFileType,
            date: reportDate,
            hospitalName: hospitalName,
            department: department.isEmpty ? nil : department,
            doctorName: doctorName.isEmpty ? nil : doctorName,
            notes: notes.isEmpty ? nil : notes,
            excelData: excelData,
            excelFileName: excelFileName,
            imageData: compressedImageData
        )
        
        reportManager.addReport(report)
        
        print("📊 报告保存成功:")
        print("  标题: \(title)")
        print("  类型: \(detectedReportType.displayName)")
        print("  文件: \(selectedFileType.displayName)")
        
        dismiss()
    }
}

// MARK: - 文件类型按钮
struct FileTypeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
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

// MARK: - Excel上传区域
struct ExcelUploadArea: View {
    let fileName: String?
    let onUpload: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if let name = fileName {
                // 已上传状态
                HStack(spacing: 16) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                        
                        Text("Excel文件已上传")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.green.opacity(0.1))
                )
            } else {
                // 上传按钮
                Button(action: onUpload) {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.accentPrimary)
                        
                        Text("点击上传Excel文件")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("支持 .xlsx 和 .xls 格式")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.secondaryBackgroundColor)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            .foregroundColor(.dividerColor)
                    )
                }
            }
        }
    }
}

// MARK: - 图片上传区域
struct ImageUploadArea: View {
    let image: UIImage?
    let onUpload: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if let img = image {
                // 已上传状态
                VStack(spacing: 12) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(16)
                    
                    Button(action: onRemove) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("删除图片")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
            } else {
                // 上传按钮
                Button(action: onUpload) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.accentPrimary)
                        
                        Text("点击上传图片")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("支持拍照或从相册选择\n图片将自动压缩以节省空间")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(Color.secondaryBackgroundColor)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            .foregroundColor(.dividerColor)
                    )
                }
            }
        }
    }
}

// MARK: - 表单字段
struct FormField<Content: View>: View {
    let label: String
    var required: Bool = false
    let content: Content
    
    init(label: String, required: Bool = false, @ViewBuilder content: () -> Content) {
        self.label = label
        self.required = required
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                if required {
                    Text("*")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            
            content
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?
    @Binding var fileName: String?
    @Binding var fileData: Data?
    var onComplete: () -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType(filenameExtension: "xlsx")!,
            UTType(filenameExtension: "xls")!
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            parent.fileURL = url
            parent.fileName = url.lastPathComponent
            
            // 读取文件数据
            do {
                let data = try Data(contentsOf: url)
                parent.fileData = data
                print("📄 Excel文件加载成功: \(url.lastPathComponent), 大小: \(data.count / 1024)KB")
                parent.onComplete()
            } catch {
                print("❌ 读取Excel文件失败: \(error)")
            }
        }
    }
}

// MARK: - Report Image Picker
struct ReportImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onComplete: () -> Void
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
        let parent: ReportImagePicker
        
        init(_ parent: ReportImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onComplete()
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


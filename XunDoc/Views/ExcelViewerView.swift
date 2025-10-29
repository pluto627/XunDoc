//
//  ExcelViewerView.swift
//  XunDoc
//
//  Excel文件查看器
//

import SwiftUI
import WebKit

struct ExcelViewerView: View {
    let report: MedicalReport
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 报告信息卡片
                ReportInfoCard(report: report)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                Divider()
                
                // Excel预览区域
                if let excelData = report.excelData {
                    ExcelPreviewView(excelData: excelData, fileName: report.excelFileName ?? "report.xlsx")
                } else {
                    EmptyExcelView()
                }
            }
            .background(Color.appBackgroundColor)
            .navigationTitle("查看报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = report.excelData, let fileName = report.excelFileName {
                ShareSheet(activityItems: [createTempFileURL(data: data, fileName: fileName)])
            }
        }
    }
    
    private func createTempFileURL(data: Data, fileName: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - 报告信息卡片
struct ReportInfoCard: View {
    let report: MedicalReport
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // 类型图标
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(report.reportType.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: report.reportType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(report.reportType.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(report.hospitalName)
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                        
                        if let department = report.department {
                            Text("•")
                                .foregroundColor(.textTertiary)
                            Text(department)
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                Label(report.reportType.displayName, systemImage: "tag.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                
                Label(dateFormatter.string(from: report.date), systemImage: "calendar")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackgroundColor)
        )
    }
}

// MARK: - Excel预览视图
struct ExcelPreviewView: View {
    let excelData: Data
    let fileName: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Excel图标和提示
            VStack(spacing: 20) {
                Image(systemName: "tablecells.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text(fileName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("文件大小: \(ByteCountFormatter.string(fromByteCount: Int64(excelData.count), countStyle: .file))")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                
                Text("提示：点击右上角分享图标可导出文件\n在Excel应用中打开以查看完整内容")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 60)
            
            Spacer()
            
            // 操作按钮
            VStack(spacing: 12) {
                Button(action: {
                    openInExcel()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 18))
                        Text("在Excel中打开")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.green)
                    )
                }
                
                Text("需要安装Microsoft Excel或WPS应用")
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    private func openInExcel() {
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try excelData.write(to: fileURL)
            
            // 尝试打开文件
            if UIApplication.shared.canOpenURL(fileURL) {
                UIApplication.shared.open(fileURL)
            }
        } catch {
            print("❌ 无法打开Excel文件: \(error)")
        }
    }
}

// MARK: - 空状态视图
struct EmptyExcelView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)
            
            Text("无法加载Excel文件")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text("文件数据丢失或损坏")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 分享Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExcelViewerView(report: MedicalReport(
        memberId: UUID(),
        title: "血常规检查",
        reportType: .bloodTest,
        fileType: .excel,
        date: Date(),
        hospitalName: "测试医院",
        department: "检验科",
        excelFileName: "blood_test.xlsx"
    ))
}


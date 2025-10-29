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
    @State private var showFullImage = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 报告信息卡片
                ReportInfoCard(report: report)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                Divider()
                
                // 预览区域
                if report.fileType == .image, let imageData = report.imageData {
                    ImageReportView(imageData: imageData, report: report, showFullImage: $showFullImage)
                } else if let excelData = report.excelData {
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
            } else if let imageData = report.imageData, let image = UIImage(data: imageData) {
                ShareSheet(activityItems: [image])
            }
        }
        .fullScreenCover(isPresented: $showFullImage) {
            if let imageData = report.imageData, let image = UIImage(data: imageData) {
                FullScreenImageView(image: image, isPresented: $showFullImage)
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

// MARK: - 图片报告视图（电子化显示）
struct ImageReportView: View {
    let imageData: Data
    let report: MedicalReport
    @Binding var showFullImage: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 左上角缩略图
                HStack {
                    if let image = UIImage(data: imageData) {
                        Button(action: {
                            showFullImage = true
                        }) {
                            VStack(spacing: 8) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 2)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 12))
                                    Text("点击放大")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.accentPrimary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // 电子化表格数据
                VStack(spacing: 16) {
                    // 表格标题
                    HStack {
                        Image(systemName: "tablecells.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.accentPrimary)
                        
                        Text("电子化数据")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // 模拟表格数据
                    ReportTableView(reportType: report.reportType)
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - 报告表格视图
struct ReportTableView: View {
    let reportType: ReportType
    
    // 根据报告类型生成模拟数据
    private var tableData: [(item: String, value: String, reference: String, status: String)] {
        switch reportType {
        case .bloodTest:
            return [
                ("白细胞计数 (WBC)", "6.5", "3.5-9.5 10^9/L", "正常"),
                ("红细胞计数 (RBC)", "4.8", "4.3-5.8 10^12/L", "正常"),
                ("血红蛋白 (HGB)", "145", "130-175 g/L", "正常"),
                ("血小板计数 (PLT)", "220", "125-350 10^9/L", "正常"),
                ("中性粒细胞百分比", "62", "40-75%", "正常")
            ]
        case .urineTest:
            return [
                ("尿蛋白 (PRO)", "阴性", "阴性", "正常"),
                ("尿糖 (GLU)", "阴性", "阴性", "正常"),
                ("尿酮体 (KET)", "阴性", "阴性", "正常"),
                ("尿潜血 (BLD)", "阴性", "阴性", "正常"),
                ("白细胞 (LEU)", "阴性", "阴性", "正常")
            ]
        case .liverFunction:
            return [
                ("谷丙转氨酶 (ALT)", "28", "7-40 U/L", "正常"),
                ("谷草转氨酶 (AST)", "24", "13-35 U/L", "正常"),
                ("总胆红素 (TBIL)", "14.2", "3.4-20.5 μmol/L", "正常"),
                ("白蛋白 (ALB)", "45", "40-55 g/L", "正常")
            ]
        default:
            return [
                ("检查项目 1", "数值", "参考范围", "状态"),
                ("检查项目 2", "数值", "参考范围", "状态"),
                ("检查项目 3", "数值", "参考范围", "状态")
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 表头
            HStack(spacing: 0) {
                TableHeaderCell(text: "检查项目", width: nil)
                TableHeaderCell(text: "检测值", width: 80)
                TableHeaderCell(text: "参考范围", width: 100)
                TableHeaderCell(text: "状态", width: 60)
            }
            .background(Color.accentPrimary.opacity(0.1))
            
            // 表格内容
            ForEach(Array(tableData.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 0) {
                    TableDataCell(text: row.item, width: nil, isFirst: true)
                    TableDataCell(text: row.value, width: 80)
                    TableDataCell(text: row.reference, width: 100)
                    TableDataCell(text: row.status, width: 60, 
                                 color: row.status == "正常" ? .successColor : .errorColor)
                }
                .background(index % 2 == 0 ? Color.cardBackgroundColor : Color.secondaryBackgroundColor)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.dividerColor, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

struct TableHeaderCell: View {
    let text: String
    let width: CGFloat?
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.accentPrimary)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : width)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
    }
}

struct TableDataCell: View {
    let text: String
    let width: CGFloat?
    var isFirst: Bool = false
    var color: Color = .textPrimary
    
    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(color)
            .frame(width: width, alignment: isFirst ? .leading : .center)
            .frame(maxWidth: width == nil ? .infinity : width, alignment: isFirst ? .leading : .center)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
    }
}

// MARK: - 全屏图片查看器
struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1.0), 5.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1.0 {
                                withAnimation {
                                    scale = 1.0
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(20)
                }
                
                Spacer()
                
                // 缩放提示
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                    Text("双指缩放查看详情")
                        .font(.system(size: 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)
                .padding(.bottom, 40)
            }
        }
    }
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


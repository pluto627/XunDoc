//
//  MedicalReportsListView.swift
//  XunDoc
//
//  医疗报告列表视图
//

import SwiftUI

struct MedicalReportsListView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @StateObject private var reportManager = MedicalReportManager.shared
    @State private var showingAddReport = false
    @State private var selectedFilter: ReportType?
    @State private var showingExcelViewer = false
    @State private var selectedReport: MedicalReport?
    
    private var filteredReports: [MedicalReport] {
        let memberReports = reportManager.reports
        
        if let filter = selectedFilter {
            return memberReports.filter { $0.reportType == filter }
        }
        return memberReports
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            ReportsHeader()
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            // 类型筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ReportFilterChip(title: "全部", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }
                    
                    ForEach(ReportType.allCases.filter { $0 != .other }, id: \.self) { type in
                        ReportFilterChip(
                            title: type.displayName,
                            icon: type.icon,
                            color: type.color,
                            isSelected: selectedFilter == type,
                            action: {
                                selectedFilter = type
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)
            
            // 报告列表
            if filteredReports.isEmpty {
                EmptyReportsView()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredReports) { report in
                            ReportCard(report: report) {
                                selectedReport = report
                                if report.fileType == .excel {
                                    showingExcelViewer = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // 添加按钮
            AddReportButton {
                showingAddReport = true
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.appBackgroundColor)
        .sheet(isPresented: $showingAddReport) {
            AddReportWithExcelView()
                .environmentObject(healthDataManager)
        }
        .sheet(isPresented: $showingExcelViewer) {
            if let report = selectedReport {
                ExcelViewerView(report: report)
            }
        }
    }
}

// MARK: - 报告头部
struct ReportsHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("检查报告")
                    .font(.appTitle())
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 8) {
                    PulsingDot(color: .accentPrimary)
                    Text("智能分类管理")
                        .font(.appCaption())
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.secondaryBackgroundColor)
                    )
            }
        }
    }
}

// MARK: - 报告筛选芯片
struct ReportFilterChip: View {
    let title: String
    var icon: String?
    var color: Color?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : .textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? (color ?? Color.accentPrimary) : Color.secondaryBackgroundColor)
            )
        }
    }
}

// MARK: - 报告卡片
struct ReportCard: View {
    let report: MedicalReport
    let action: () -> Void
    @StateObject private var reportManager = MedicalReportManager.shared
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 类型图标
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(report.reportType.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: report.reportType.icon)
                        .font(.system(size: 26))
                        .foregroundColor(report.reportType.color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(report.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label(report.hospitalName, systemImage: "building.2")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 10) {
                        // 文件类型标签
                        HStack(spacing: 4) {
                            Image(systemName: report.fileType == .excel ? "tablecells" : "photo")
                                .font(.system(size: 11))
                            Text(report.fileType.displayName)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.accentPrimary.opacity(0.15))
                        )
                        
                        Text(dateFormatter.string(from: report.date))
                            .font(.system(size: 12))
                            .foregroundColor(.textTertiary)
                    }
                }
                
                Spacer(minLength: 0)
                
                VStack(spacing: 12) {
                    Button(action: {
                        reportManager.toggleStar(report)
                    }) {
                        Image(systemName: report.isStarred ? "star.fill" : "star")
                            .font(.system(size: 20))
                            .foregroundColor(report.isStarred ? .yellow : .textTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.dividerColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 空状态视图
struct EmptyReportsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.textTertiary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.textTertiary)
            }
            
            VStack(spacing: 8) {
                Text("暂无检查报告")
                    .font(.appSubheadline())
                    .foregroundColor(.textSecondary)
                
                Text("点击下方按钮上传您的检查报告")
                    .font(.appSmall())
                    .foregroundColor(.textTertiary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 添加按钮
struct AddReportButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text("上传新报告")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentPrimary, Color.accentTertiary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Color.accentPrimary.opacity(0.3), radius: 15, x: 0, y: 8)
        }
    }
}

#Preview {
    MedicalReportsListView()
        .environmentObject(HealthDataManager.shared)
}


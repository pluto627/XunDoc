//
//  GeneralSettingsView.swift
//  XunDoc
//
//  通用设置页面
//

import SwiftUI

// MARK: - 字体大小枚举
enum AppFontSize: String, CaseIterable {
    case small = "小"
    case medium = "中"
    case large = "大"
    
    var scale: CGFloat {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.15
        }
    }
}

struct GeneralSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var languageManager = LanguageManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("appFontSize") private var fontSizeString = AppFontSize.medium.rawValue
    @State private var showBackupAlert = false
    @State private var showExportAlert = false
    
    private var currentFontSize: AppFontSize {
        AppFontSize.allCases.first(where: { $0.rawValue == fontSizeString }) ?? .medium
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                languageSection
                fontSizeSection
                darkModeSection
                dataExportSection
                backupSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground)
        .navigationTitle("通用设置")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .alert("待开发", isPresented: $showBackupAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("目前您的健康数据全部保存在本地")
        }
        .alert("功能开发中", isPresented: $showExportAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("数据导出功能正在开发中，敬请期待")
        }
    }
    
    // MARK: - 子视图
    
    private var languageSection: some View {
        SettingToggleCard(
            icon: "globe",
            iconColor: .blue,
            title: "语言",
            subtitle: languageManager.currentLanguage.displayName
        ) {
            languageMenu
        }
    }
    
    private var languageMenu: some View {
        Menu {
            ForEach(LanguageManager.AppLanguage.allCases) { language in
                Button {
                    languageManager.setLanguage(language)
                } label: {
                    HStack {
                        Text(language.fullDisplayName)
                        if language == languageManager.currentLanguage {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(languageManager.currentLanguage.flag)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    private var fontSizeSection: some View {
        SettingToggleCard(
            icon: "textformat.size",
            iconColor: .purple,
            title: "字体大小",
            subtitle: currentFontSize.rawValue
        ) {
            fontSizePicker
        }
    }
    
    private var fontSizePicker: some View {
        Picker("", selection: $fontSizeString) {
            ForEach(AppFontSize.allCases, id: \.rawValue) { size in
                Text(size.rawValue).tag(size.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 120)
    }
    
    private var darkModeSection: some View {
        SettingToggleCard(
            icon: "moon.fill",
            iconColor: .indigo,
            title: "深色模式",
            subtitle: isDarkMode ? "已开启" : "已关闭"
        ) {
            Toggle("", isOn: $isDarkMode)
                .labelsHidden()
                .tint(.indigo)
        }
    }
    
    private var dataExportSection: some View {
        SettingButtonCard(
            icon: "square.and.arrow.up",
            iconColor: .orange,
            title: "数据导出",
            subtitle: "导出您的健康数据"
        ) {
            exportHealthData()
        }
    }
    
    private var backupSection: some View {
        SettingButtonCard(
            icon: "arrow.down.doc.fill",
            iconColor: .green,
            title: "备份数据",
            subtitle: "备份您的健康数据"
        ) {
            showBackupAlert = true
        }
    }
    
    // 导出健康数据
    private func exportHealthData() {
        showExportAlert = true
    }
}

// MARK: - 设置卡片（带开关或选择器）
struct SettingToggleCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let control: Content
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder control: () -> Content
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // 文字
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // 控制组件
            control
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 设置卡片（可点击按钮）
struct SettingButtonCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                // 文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
            .padding(20)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        GeneralSettingsView()
    }
}


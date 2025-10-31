//
//  GeneralSettingsView.swift
//  XunDoc
//
//  通用设置页面
//

import SwiftUI

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
        .background(Color.appBackgroundColor)
        .navigationTitle(NSLocalizedString("general_settings", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .alert(NSLocalizedString("under_development", comment: ""), isPresented: $showBackupAlert) {
            Button(NSLocalizedString("ok", comment: ""), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("data_stored_locally", comment: ""))
        }
        .alert(NSLocalizedString("feature_under_development", comment: ""), isPresented: $showExportAlert) {
            Button(NSLocalizedString("ok", comment: ""), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("export_feature_coming", comment: ""))
        }
    }
    
    // MARK: - 子视图
    
    private var languageSection: some View {
        SettingToggleCard(
            icon: "globe",
            iconColor: .blue,
            title: NSLocalizedString("language", comment: ""),
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
            title: NSLocalizedString("font_size", comment: ""),
            subtitle: currentFontSize.localizedName
        ) {
            fontSizePicker
        }
    }
    
    private var fontSizePicker: some View {
        Picker("", selection: $fontSizeString) {
            ForEach(AppFontSize.allCases, id: \.rawValue) { size in
                Text(size.localizedName).tag(size.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 120)
    }
    
    private var darkModeSection: some View {
        SettingToggleCard(
            icon: "moon.fill",
            iconColor: .indigo,
            title: NSLocalizedString("dark_mode", comment: ""),
            subtitle: isDarkMode ? NSLocalizedString("enabled", comment: "") : NSLocalizedString("disabled", comment: "")
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
            title: NSLocalizedString("data_export", comment: ""),
            subtitle: NSLocalizedString("export_your_health_data", comment: "")
        ) {
            exportHealthData()
        }
    }
    
    private var backupSection: some View {
        SettingButtonCard(
            icon: "arrow.down.doc.fill",
            iconColor: .green,
            title: NSLocalizedString("data_backup", comment: ""),
            subtitle: NSLocalizedString("backup_your_health_data", comment: "")
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
                    .font(.appSubheadline())
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.appSmall())
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // 控制组件
            control
        }
        .padding(20)
        .background(Color.cardBackgroundColor)
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
                        .font(.appSubheadline())
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.appSmall())
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.appCaption())
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
            .padding(20)
            .background(Color.cardBackgroundColor)
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


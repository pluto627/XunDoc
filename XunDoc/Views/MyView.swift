//
//  MyView.swift
//  XunDoc
//
//  个人中心页面 - 简洁的个人中心，参考 health_app(2).html 设计
//

import SwiftUI

struct MyView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var showingProfileEdit = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    MyHeader()
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    
                    VStack(spacing: 24) {
                        // 用户头像卡片（整合个人信息）
                        NavigationLink(destination: ProfileEditView()) {
                            MyProfileCard(
                                avatarData: profileManager.userProfile.avatarData,
                                name: profileManager.userProfile.name,
                                phoneNumber: profileManager.userProfile.phoneNumber
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                        
                        // 设置
                        VStack(alignment: .leading, spacing: 12) {
                            // 节标题
                            Text(NSLocalizedString("settings", comment: ""))
                                .font(.appLabel())
                                .foregroundColor(.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 4)
                                .fadeIn(delay: 0.4)
                            
                            // 通用设置（独立卡片）
                            NavigationLink(destination: GeneralSettingsView()) {
                                MenuItemCard(
                                    icon: "gearshape.fill",
                                    iconColor: .accentSecondary,
                                    title: NSLocalizedString("general_settings", comment: "")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)
                            .fadeIn(delay: 0.5)
                            
                            // 关于（独立卡片）
                            NavigationLink(destination: AboutView()) {
                                MenuItemCard(
                                    icon: "info.circle.fill",
                                    iconColor: .accentTertiary,
                                    title: NSLocalizedString("about", comment: "")
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)
                            .fadeIn(delay: 0.6)
                        }
                    }
                    
                    // 底部问候语和版本号
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        
                        // 应用图标
                        if let appIcon = UIImage(named: "AppIcon") {
                            Image(uiImage: appIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .cornerRadius(16)
                                .shadow(color: Color.accentPrimary.opacity(0.2), radius: 8, x: 0, y: 4)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentPrimary, Color.accentTertiary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // 问候语
                        VStack(spacing: 6) {
                            Text(NSLocalizedString("thank_you_xundoc", comment: ""))
                                .font(.appSubheadline())
                                .foregroundColor(.textPrimary)
                            
                            Text(NSLocalizedString("your_health_assistant", comment: ""))
                                .font(.appCaption())
                                .foregroundColor(.textSecondary)
                        }
                        
                        // 版本号
                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                            Text(String(format: NSLocalizedString("version_format", comment: ""), version, build))
                                .font(.appSmall())
                                .foregroundColor(.textTertiary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                    .fadeIn(delay: 0.7)
                }
            }
            .background(Color.appBackgroundColor)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - My Header
struct MyHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("my", comment: ""))
                    .font(.appTitle())
                    .foregroundColor(.textPrimary)
                    .fadeIn(delay: 0.1)
                
                HStack(spacing: 8) {
                    PulsingDot(color: .accentPrimary)
                    Text(NSLocalizedString("personal_center", comment: ""))
                        .font(.appCaption())
                        .foregroundColor(.textSecondary)
                }
                .fadeIn(delay: 0.3)
            }
            
            Spacer()
        }
    }
}

// MARK: - 用户头像卡片
struct MyProfileCard: View {
    let avatarData: Data?
    let name: String
    let phoneNumber: String
    
    var displayName: String {
        if !name.isEmpty {
            return name
        } else {
            return NSLocalizedString("not_set", comment: "")
        }
    }
    
    var displayPhone: String {
        if !phoneNumber.isEmpty {
            // 隐藏中间4位
            if phoneNumber.count == 11 {
                let prefix = phoneNumber.prefix(3)
                let suffix = phoneNumber.suffix(4)
                return "\(prefix)****\(suffix)"
            }
            return phoneNumber
        } else {
            return NSLocalizedString("phone_not_set", comment: "")
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 头像
            if let data = avatarData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 68, height: 68)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.accentPrimary.opacity(0.2), lineWidth: 3)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentPrimary.opacity(0.15), Color.accentSecondary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.accentPrimary)
                }
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.appSubheadline())
                    .foregroundColor(.textPrimary)
                
                Text(displayPhone)
                    .font(.appCaption())
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // 点击修改提示
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textTertiary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardBackgroundColor)
        )
        .cardShadow()
        .fadeIn(delay: 0.2)
    }
}

// MARK: - 菜单项卡片
struct MenuItemCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 14) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // 文字
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appSubheadline())
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.appSmall())
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            // 箭头
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.cardBackgroundColor)
        )
        .cardShadow()
        .contentShape(Rectangle())
    }
}

#Preview {
    MyView()
}

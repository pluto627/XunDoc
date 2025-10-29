//
//  AboutView.swift
//  XunDoc
//
//  关于页面
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showPrivacyPolicy = false
    @State private var showUserAgreement = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // App Logo 和版本信息
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 20)
                    
                    Text("寻医")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("版本 \(appVersion) (\(buildNumber))")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                
                // AI 免责声明
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("重要提示")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                    
                    Text("本应用提供的AI健康分析功能仅供参考，不能替代专业医疗建议、诊断或治疗。如有健康问题，请及时咨询专业医生，以医生的诊断和建议为准。")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(16)
                
                // 联系方式
                VStack(alignment: .leading, spacing: 12) {
                    Text("联系我们")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 4)
                    
                    AboutItemCard(
                        icon: "envelope.fill",
                        iconColor: .blue,
                        title: "联系邮箱",
                        subtitle: "plutoguogg@gmail.com"
                    )
                }
                
                // 法律条款
                VStack(alignment: .leading, spacing: 12) {
                    Text("法律条款")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 4)
                    
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        AboutItemCard(
                            icon: "hand.raised.fill",
                            iconColor: .purple,
                            title: "隐私政策",
                            subtitle: "了解我们如何保护您的隐私",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        showUserAgreement = true
                    } label: {
                        AboutItemCard(
                            icon: "doc.text.fill",
                            iconColor: .green,
                            title: "用户协议",
                            subtitle: "查看使用条款和条件",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 版权信息
                Text("© 2025 寻医. 保留所有权利.")
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.appBackground)
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showUserAgreement) {
            UserAgreementView()
        }
    }
}

// MARK: - 关于项卡片
struct AboutItemCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var showChevron: Bool = false
    
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
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 箭头
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 隐私政策详情页
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PolicySection(
                        title: "隐私政策",
                        content: """
                        欢迎使用寻医应用。我们非常重视您的隐私保护和个人信息安全。
                        """
                    )
                    
                    PolicySection(
                        title: "1. 信息收集",
                        content: """
                        • 健康数据：您的所有健康记录、体检报告、用药记录等数据完全存储在您的设备本地。
                        • 个人信息：我们仅收集您主动提供的基本信息（如姓名、年龄等），用于提供个性化服务。
                        • 使用数据：我们不会收集或上传您的使用行为数据。
                        """
                    )
                    
                    PolicySection(
                        title: "2. 数据存储与安全",
                        content: """
                        • 本地存储：您的所有健康数据均存储在设备本地，我们无法访问。
                        • 数据加密：敏感数据在本地进行加密存储。
                        • 数据备份：您可以选择将数据备份到iCloud（需要您的授权）。
                        """
                    )
                    
                    PolicySection(
                        title: "3. AI功能说明",
                        content: """
                        • 免责声明：本应用的AI分析功能仅供参考，不构成医疗建议。
                        • 数据处理：AI分析在调用第三方API时会传输相关数据，但不会永久存储您的个人健康信息。
                        • 专业咨询：任何健康问题请咨询专业医生，以医生诊断为准。
                        """
                    )
                    
                    PolicySection(
                        title: "4. 信息使用",
                        content: """
                        我们承诺：
                        • 不会出售您的个人信息
                        • 不会将您的健康数据用于商业目的
                        • 不会与第三方分享您的隐私数据（除非法律要求或获得您的明确同意）
                        """
                    )
                    
                    PolicySection(
                        title: "5. 您的权利",
                        content: """
                        • 访问权：您可以随时查看您的所有数据
                        • 删除权：您可以随时删除您的个人信息和健康记录
                        • 导出权：您可以导出您的健康数据
                        """
                    )
                    
                    PolicySection(
                        title: "6. 联系我们",
                        content: """
                        如有任何隐私相关问题，请联系：
                        plutoguogg@gmail.com
                        """
                    )
                    
                    Text("最后更新：2025年1月")
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 用户协议详情页
struct UserAgreementView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PolicySection(
                        title: "用户协议",
                        content: """
                        欢迎使用寻医应用。在使用本应用前，请仔细阅读以下条款。
                        """
                    )
                    
                    PolicySection(
                        title: "1. 服务说明",
                        content: """
                        • 寻医是一款个人健康管理工具
                        • 提供健康记录管理、用药提醒、AI健康咨询等功能
                        • 所有功能仅供参考，不替代专业医疗服务
                        """
                    )
                    
                    PolicySection(
                        title: "2. AI功能免责声明",
                        content: """
                        重要提示：
                        • 本应用的AI分析功能基于人工智能技术，仅供健康参考
                        • AI分析结果不能作为医疗诊断依据
                        • AI建议不能替代专业医生的诊断和治疗方案
                        • 如有任何健康问题，请及时就医，听从专业医生的建议
                        • 对于因依赖AI分析结果而产生的任何后果，本应用不承担责任
                        """
                    )
                    
                    PolicySection(
                        title: "3. 用户责任",
                        content: """
                        • 您应确保提供的健康信息真实准确
                        • 您应妥善保管个人账户和设备安全
                        • 您不得将本应用用于任何非法目的
                        • 您理解并同意AI分析仅供参考
                        """
                    )
                    
                    PolicySection(
                        title: "4. 服务变更",
                        content: """
                        • 我们保留随时修改或中断服务的权利
                        • 我们会尽可能提前通知重大变更
                        • 继续使用服务即表示接受新条款
                        """
                    )
                    
                    PolicySection(
                        title: "5. 知识产权",
                        content: """
                        • 本应用的所有内容、功能、界面设计等归开发者所有
                        • 您的健康数据归您个人所有
                        • 未经许可，不得复制、修改或传播本应用
                        """
                    )
                    
                    PolicySection(
                        title: "6. 责任限制",
                        content: """
                        • 本应用按"现状"提供，不提供任何明示或暗示的保证
                        • 我们不对服务中断、数据丢失等问题承担责任
                        • 我们不对AI分析的准确性、可靠性提供保证
                        • 所有健康决策应咨询专业医生
                        """
                    )
                    
                    PolicySection(
                        title: "7. 联系方式",
                        content: """
                        如有任何问题，请联系：
                        plutoguogg@gmail.com
                        """
                    )
                    
                    Text("最后更新：2025年1月")
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("用户协议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 政策章节组件
struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .lineSpacing(6)
        }
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}



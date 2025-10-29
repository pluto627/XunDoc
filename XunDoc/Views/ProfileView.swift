//
//  ProfileView.swift
//  XunDoc
//
//  Created by pluto guo on 10/23/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @StateObject private var notificationManager = MedicalNotificationManager.shared
    @State private var showingHealthReport = false
    @State private var showingNotifications = false
    @State private var showingHelp = false
    @State private var showingAbout = false
    @State private var showingMedicationManagement = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 黑色背景
                Color.black
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 顶部标题
                        HStack {
                            Text("我的")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 50)
                        .padding(.bottom, 30)
                        
                        VStack(spacing: 20) {
                            // 用户信息卡片
                            UserProfileCard()
                                .padding(.horizontal, 20)
                            
                            // 数据统计
                            DataStatisticsSection()
                                .padding(.horizontal, 20)
                            
                            // 功能列表
                            VStack(spacing: 0) {
                                ProfileMenuItem(
                                    icon: "doc.text.fill",
                                    iconColor: .red,
                                    title: "健康报告"
                                ) {
                                    showingHealthReport = true
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                    .padding(.horizontal, 20)
                                
                                ProfileMenuItem(
                                    icon: "bell.fill",
                                    iconColor: .orange,
                                    title: "消息通知"
                                ) {
                                    showingNotifications = true
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                    .padding(.horizontal, 20)
                                
                                ProfileMenuItem(
                                    icon: "doc.fill",
                                    iconColor: .blue,
                                    title: "使用帮助"
                                ) {
                                    showingHelp = true
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                    .padding(.horizontal, 20)
                                
                                ProfileMenuItem(
                                    icon: "info.circle.fill",
                                    iconColor: .purple,
                                    title: "关于我们"
                                ) {
                                    showingAbout = true
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // 用药管理卡片
                            MedicationManagementCard {
                                showingMedicationManagement = true
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingHealthReport) {
            RecordsView()
                .environmentObject(healthDataManager)
        }
        .sheet(isPresented: $showingNotifications) {
            MedicalNotificationsView()
                .environmentObject(notificationManager)
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingMedicationManagement) {
            MedicalNotificationsView()
                .environmentObject(notificationManager)
        }
    }
}

// MARK: - 用户信息卡片
struct UserProfileCard: View {
    @State private var showingSettings = false
    
    var body: some View {
        Button(action: {
            showingSettings = true
        }) {
            HStack(spacing: 16) {
                // 头像
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                // 用户信息
                VStack(alignment: .leading, spacing: 6) {
                    Text("pluto")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("正式用户")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 设置按钮
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .padding(20)
            .background(Color(white: 0.15))
            .cornerRadius(16)
        }
    }
}

// MARK: - 数据统计区域
struct DataStatisticsSection: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var recordsCount: Int {
        return healthDataManager.getHealthRecords().count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("数据统计")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "folder.fill",
                    iconColor: .green,
                    value: "\(recordsCount)",
                    label: "健康档案"
                )
                
                StatCard(
                    icon: "pills.fill",
                    iconColor: .orange,
                    value: "0",
                    label: "用药提醒"
                )
                
                StatCard(
                    icon: "calendar.badge.clock",
                    iconColor: .blue,
                    value: "0",
                    label: "使用天数"
                )
            }
        }
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

// MARK: - 功能菜单项
struct ProfileMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - 用药管理卡片
struct MedicationManagementCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "pills.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("用药管理")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("管理您的用药提醒和记录")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(Color(white: 0.1))
            .cornerRadius(16)
        }
    }
}

// MARK: - 帮助视图
struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("使用帮助")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HelpSection(
                                title: "如何添加健康档案",
                                content: "在首页点击'健康档案'卡片，然后点击右上角的'+'按钮即可添加新的健康记录。"
                            )
                            
                            HelpSection(
                                title: "如何使用AI问诊",
                                content: "点击底部导航栏的'AI问诊'，输入您的健康问题，AI助手会为您提供专业的健康建议。"
                            )
                            
                            HelpSection(
                                title: "如何设置用药提醒",
                                content: "进入'用药管理'页面，添加您的用药信息和提醒时间，系统会按时提醒您服药。"
                            )
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct HelpSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

// MARK: - 关于我们视图
#Preview {
    ProfileView()
        .environmentObject(HealthDataManager.shared)
}


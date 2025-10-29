//
//  ContentView.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var apiManager = MoonshotAPIManager.shared
    @StateObject private var chatHistoryManager = ChatHistoryManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var notificationManager = MedicalNotificationManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var selectedTab = 0
    @State private var showingQuickAdd = false
    @State private var showingOnboarding = false
    
    // 快捷添加弹窗状态
    @State private var showingRecording = false
    @State private var showingReport = false
    @State private var showingMedication = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 内容区域
                Group {
                    if selectedTab == 0 {
                        HomeView()
                    } else if selectedTab == 1 {
                        RecordsView()
                    } else if selectedTab == 2 {
                        MedicationView()
                    } else if selectedTab == 3 {
                        MyView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onChange(of: selectedTab) { _ in
                    // 当切换Tab时，自动关闭快速添加面板
                    if showingQuickAdd {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showingQuickAdd = false
                        }
                    }
                }
                
                // 底部半屏面板 - 固定在屏幕下半部分，遮住底部导航栏
                if showingQuickAdd {
                    ZStack {
                        // 半透明背景遮罩
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showingQuickAdd = false
                                }
                            }
                            .transition(.opacity)
                        
                        VStack(spacing: 0) {
                            Spacer()
                            
                            // 快速添加面板 - 固定高度，从底部上升到屏幕50%位置
                            QuickAddPanelView(
                                isPresented: $showingQuickAdd,
                                showingRecording: $showingRecording,
                                showingReport: $showingReport,
                                showingMedication: $showingMedication
                            )
                            .frame(height: geometry.size.height * 0.5)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.cardBackgroundColor)
                                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -8)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .transition(.move(edge: .bottom))
                        }
                        .ignoresSafeArea()
                    }
                    .zIndex(1001) // 面板在最上层
                    .transition(.opacity)
                }
                
                // 底部导航栏 - 紧贴屏幕底部
                CustomTabBar(selectedTab: $selectedTab, showingQuickAdd: $showingQuickAdd)
                    .ignoresSafeArea(.all, edges: .bottom)
                    .zIndex(1000) // TabBar在面板下层
            }
        }
        .environmentObject(healthDataManager)
        .environmentObject(apiManager)
        .environmentObject(chatHistoryManager)
        .environmentObject(languageManager)
        .environmentObject(notificationManager)
        .environmentObject(profileManager)
        .environment(\.locale, languageManager.currentLanguage.locale)
        .accentColor(Color(red: 55/255, green: 53/255, blue: 47/255))
        .onAppear {
            // 请求通知权限并同步药物通知
            Task {
                let granted = await notificationManager.requestNotificationPermission()
                if granted {
                    // 权限获取成功后，同步所有活跃药物的通知
                    await healthDataManager.syncAllMedicationNotifications()
                }
            }
            
            // 检查是否需要显示首次引导
            if profileManager.shouldShowOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingOnboarding = true
                }
            }
        }
        .sheet(isPresented: $showingRecording) {
            SimpleRecordingSheet(isPresented: $showingRecording)
                .environmentObject(healthDataManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingReport) {
            SimpleReportSheet(isPresented: $showingReport)
                .environmentObject(healthDataManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingMedication) {
            AddMedicationFormView(isPresented: $showingMedication)
                .environmentObject(healthDataManager)
                .presentationDetents([.height(650), .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
    }
}


#Preview {
    ContentView()
}

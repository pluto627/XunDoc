//
//  CustomTabBar.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showingQuickAdd: Bool
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let tabContentHeight: CGFloat = 85
            
            VStack(spacing: 0) {
                Spacer()
                
                // TabBar 底部区域
                ZStack(alignment: .top) {
                    // TabBar背景 - 延伸到安全区域
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.cardBackgroundColor)
                            .frame(height: tabContentHeight + safeAreaBottom + 3)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -2)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    
                    // 按钮内容区域
                    VStack(spacing: 0) {
                        Spacer()
                        
                        HStack(spacing: 0) {
                            // 首页
                            TabBarButton(
                                icon: selectedTab == 0 ? "house.fill" : "house",
                                label: "首页",
                                isSelected: selectedTab == 0,
                                action: { selectedTab = 0 }
                            )
                            .frame(maxWidth: .infinity)
                            
                            // 就诊记录
                            TabBarButton(
                                icon: selectedTab == 1 ? "book.fill" : "book",
                                label: "就诊记录",
                                isSelected: selectedTab == 1,
                                action: { selectedTab = 1 }
                            )
                            .frame(maxWidth: .infinity)
                            
                            // 中间的加号按钮
                            Button(action: {
                                // 震动反馈
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                
                                if !showingQuickAdd {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        rotationAngle = 90 // 向右旋转90度
                                    }
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        showingQuickAdd = true
                                    }
                                } else {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        rotationAngle = 0 // 向左旋转回到0度
                                    }
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        showingQuickAdd = false
                                    }
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 55/255, green: 53/255, blue: 47/255))
                                        .frame(width: 56, height: 56)
                                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.white)
                                        .rotationEffect(.degrees(rotationAngle))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .offset(y: -14)
                            
                            // 用药
                            TabBarButton(
                                icon: selectedTab == 2 ? "pills.fill" : "pills",
                                label: "用药",
                                isSelected: selectedTab == 2,
                                action: { selectedTab = 2 }
                            )
                            .frame(maxWidth: .infinity)
                            
                            // 我的
                            TabBarButton(
                                icon: selectedTab == 3 ? "person.fill" : "person",
                                label: "我的",
                                isSelected: selectedTab == 3,
                                action: { selectedTab = 3 }
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: tabContentHeight)
                        .padding(.bottom, 8)
                        .offset(y: -10) // 向上移动5个单位（原来-5，现在-10）
                        
                        // 安全区域填充
                        Color.clear
                            .frame(height: safeAreaBottom)
                    }
                }
                .frame(height: tabContentHeight + safeAreaBottom)
            }
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // 震动反馈
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(0), showingQuickAdd: .constant(false))
}

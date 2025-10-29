//
//  LaunchScreenView.swift
//  XunDoc
//
//  启动页面 - 显示Loading图片
//

import SwiftUI

struct LaunchScreenView: View {
    @Binding var isActive: Bool
    @State private var opacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            // Loading图片 - 填满屏幕宽度，保持比例
            Image("Loading")
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width)
                .frame(maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .opacity(opacity)
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            print("🚀 启动页面已显示，当前 isActive = \(isActive)")
            
            // 淡入动画
            withAnimation(.easeInOut(duration: 0.8)) {
                opacity = 1.0
            }
            
            // 3秒后跳转到主应用
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                print("⏱️ 3秒已到，准备跳转，当前 isActive = \(self.isActive)")
                self.isActive = false
                print("✅ isActive已设置为false (隐藏启动页): \(self.isActive)")
            }
        }
    }
}

#Preview {
    LaunchScreenView(isActive: .constant(false))
}


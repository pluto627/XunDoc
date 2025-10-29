//
//  XunDocApp.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI
import UserNotifications

@main
struct XunDocApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Root View with Launch Screen
struct RootView: View {
    @State private var showLaunchScreen = true
    
    var body: some View {
        Group {
            if showLaunchScreen {
                LaunchScreenView(isActive: $showLaunchScreen)
            } else {
                ContentView()
            }
        }
        .onChange(of: showLaunchScreen) { oldValue, newValue in
            print("📱 showLaunchScreen 状态改变: \(oldValue) -> \(newValue)")
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 设置通知中心代理
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // 在前台显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 在前台也显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    // 用户点击通知时调用
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // 从userInfo中提取通知信息
        if let notificationIdString = userInfo["notificationId"] as? String,
           let notificationId = UUID(uuidString: notificationIdString) {
            // 处理通知点击事件
            print("用户点击了通知: \(notificationId)")
            
            // 可以在这里添加导航逻辑，跳转到相关页面
        }
        
        completionHandler()
    }
}

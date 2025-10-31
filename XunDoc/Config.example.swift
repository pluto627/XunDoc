import Foundation

/// API 配置示例文件
/// 使用说明：
/// 1. 复制此文件并重命名为 Config.swift
/// 2. 将 YOUR_KIMI_API_KEY 和 YOUR_MOONSHOT_API_KEY 替换为你的实际 API Key
/// 3. Config.swift 已被添加到 .gitignore，不会被上传到 Git

struct APIConfig {
    /// Kimi API Key
    /// 获取地址：https://platform.moonshot.cn/console/api-keys
    static let kimiAPIKey = "YOUR_KIMI_API_KEY"
    
    /// Moonshot API Key
    /// 获取地址：https://platform.moonshot.cn/console/api-keys
    static let moonshotAPIKey = "YOUR_MOONSHOT_API_KEY"
}


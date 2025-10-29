//
//  LanguageManager.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//  升级版 - 支持18种语言

import Foundation
import SwiftUI
import ObjectiveC

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.code, forKey: "selectedLanguage")
            // 通知系统更新语言
            Bundle.setLanguage(currentLanguage.code)
            // 强制更新界面
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    // 支持的所有语言
    enum AppLanguage: String, CaseIterable, Identifiable {
        case english = "en"
        case chinese = "zh-Hans"
        case japanese = "ja"
        case korean = "ko"
        case french = "fr"
        case german = "de"
        case spanish = "es"
        case portuguese = "pt"
        case russian = "ru"
        case arabic = "ar"
        case italian = "it"
        case dutch = "nl"
        case turkish = "tr"
        case vietnamese = "vi"
        case thai = "th"
        case indonesian = "id"
        case malay = "ms"
        case hindi = "hi"
        
        var id: String { rawValue }
        
        var code: String {
            self.rawValue
        }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .chinese: return "简体中文"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .spanish: return "Español"
            case .portuguese: return "Português"
            case .russian: return "Русский"
            case .arabic: return "العربية"
            case .italian: return "Italiano"
            case .dutch: return "Nederlands"
            case .turkish: return "Türkçe"
            case .vietnamese: return "Tiếng Việt"
            case .thai: return "ไทย"
            case .indonesian: return "Bahasa Indonesia"
            case .malay: return "Bahasa Melayu"
            case .hindi: return "हिन्दी"
            }
        }
        
        var locale: Locale {
            Locale(identifier: code)
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .chinese: return "🇨🇳"
            case .japanese: return "🇯🇵"
            case .korean: return "🇰🇷"
            case .french: return "🇫🇷"
            case .german: return "🇩🇪"
            case .spanish: return "🇪🇸"
            case .portuguese: return "🇵🇹"
            case .russian: return "🇷🇺"
            case .arabic: return "🇸🇦"
            case .italian: return "🇮🇹"
            case .dutch: return "🇳🇱"
            case .turkish: return "🇹🇷"
            case .vietnamese: return "🇻🇳"
            case .thai: return "🇹🇭"
            case .indonesian: return "🇮🇩"
            case .malay: return "🇲🇾"
            case .hindi: return "🇮🇳"
            }
        }
        
        // 是否是从右到左的语言
        var isRTL: Bool {
            switch self {
            case .arabic:
                return true
            default:
                return false
            }
        }
        
        // 获取显示名称（用于列表显示）
        var fullDisplayName: String {
            return "\(flag) \(displayName)"
        }
    }
    
    private init() {
        // 读取用户保存的语言偏好
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // 根据系统语言自动选择
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            
            // 尝试匹配系统语言
            if systemLanguage.hasPrefix("zh") {
                self.currentLanguage = .chinese
            } else if systemLanguage.hasPrefix("ja") {
                self.currentLanguage = .japanese
            } else if systemLanguage.hasPrefix("ko") {
                self.currentLanguage = .korean
            } else if systemLanguage.hasPrefix("fr") {
                self.currentLanguage = .french
            } else if systemLanguage.hasPrefix("de") {
                self.currentLanguage = .german
            } else if systemLanguage.hasPrefix("es") {
                self.currentLanguage = .spanish
            } else if systemLanguage.hasPrefix("pt") {
                self.currentLanguage = .portuguese
            } else if systemLanguage.hasPrefix("ru") {
                self.currentLanguage = .russian
            } else if systemLanguage.hasPrefix("ar") {
                self.currentLanguage = .arabic
            } else if systemLanguage.hasPrefix("it") {
                self.currentLanguage = .italian
            } else if systemLanguage.hasPrefix("nl") {
                self.currentLanguage = .dutch
            } else if systemLanguage.hasPrefix("tr") {
                self.currentLanguage = .turkish
            } else if systemLanguage.hasPrefix("vi") {
                self.currentLanguage = .vietnamese
            } else if systemLanguage.hasPrefix("th") {
                self.currentLanguage = .thai
            } else if systemLanguage.hasPrefix("id") {
                self.currentLanguage = .indonesian
            } else if systemLanguage.hasPrefix("ms") {
                self.currentLanguage = .malay
            } else if systemLanguage.hasPrefix("hi") {
                self.currentLanguage = .hindi
            } else {
                self.currentLanguage = .english
            }
        }
        
        Bundle.setLanguage(currentLanguage.code)
    }
    
    func setLanguage(_ language: AppLanguage) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentLanguage = language
        }
    }
    
    func localizedString(_ key: String, comment: String = "") -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: comment)
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

// MARK: - Bundle扩展，用于动态切换语言
private var bundleKey: UInt8 = 0

extension Bundle {
    class func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, AnyLanguageBundle.self)
        }
        objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle.main.path(forResource: language, ofType: "lproj"), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private class AnyLanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let path = objc_getAssociatedObject(self, &bundleKey) as? String,
              let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

# XunDoc - 智能医疗健康管理系统

<div align="center">

![XunDoc Logo](XunDoc/Assets.xcassets/AppIcon.appiconset/730969218856b0e4020d197fd792bb31.png)

**您的智能健康管家，AI驱动的全方位医疗健康管理应用**

[![Platform](https://img.shields.io/badge/platform-iOS-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[简体中文](README.md) | [English](README_EN.md)

</div>

---

## 📱 项目简介

**XunDoc（巡医）** 是一款基于 AI 技术的智能医疗健康管理 iOS 应用，致力于为用户提供全方位、个性化的健康管理服务。通过整合先进的人工智能技术，XunDoc 帮助用户更好地管理健康数据、就医记录、用药提醒等，让健康管理变得简单高效。

### 🎯 核心价值

- **AI 智能分析**：基于 Moonshot AI 和 Kimi AI 的智能医疗咨询
- **全面健康管理**：就诊记录、用药提醒、健康数据一站式管理
- **智能语音交互**：支持语音输入和语音转文字功能
- **多语言支持**：完整的中英文国际化支持
- **隐私安全**：本地数据存储，保护用户隐私

---

## ✨ 核心功能

### 🤖 AI 智能助手

- **智能问诊**：24/7 AI 医疗咨询服务，即时解答健康疑问
- **报告分析**：上传医疗报告，AI 自动解读并提供专业建议
- **照片诊断**：拍照上传症状图片，AI 辅助初步诊断
- **语音交互**：支持语音提问，更自然的交互体验

### 📋 就诊记录管理

- **完整记录**：记录就诊时间、医院、科室、医生等详细信息
- **病历管理**：保存诊断结果、处方、检查报告等
- **照片存档**：支持拍照保存医疗报告和处方
- **历史查询**：快速查找历史就诊记录

### 💊 智能用药提醒

- **定时提醒**：自定义用药时间和频率
- **剂量管理**：记录每次用药剂量和库存
- **服药记录**：追踪用药依从性
- **到期提醒**：药品有效期提醒

### 📊 健康数据追踪

- **多维数据**：血压、血糖、体重、心率等健康指标
- **趋势分析**：数据可视化，一目了然了解健康趋势
- **Excel 导入**：支持批量导入健康数据
- **数据导出**：方便与医生分享

### 🏥 附近医院搜索

- **智能定位**：自动获取当前位置
- **医院推荐**：推荐附近优质医疗机构
- **导航功能**：一键导航到医院
- **医院信息**：查看医院详情和联系方式

---

## 🛠 技术架构

### 开发环境

- **开发语言**：Swift 5.0+
- **最低支持**：iOS 14.0+
- **开发工具**：Xcode 14.0+
- **界面框架**：SwiftUI

### 核心技术

```
XunDoc/
├── 📱 SwiftUI - 现代化 UI 框架
├── 🤖 AI 集成
│   ├── Moonshot AI - 智能对话
│   └── Kimi AI - 医疗分析
├── 🗣 语音识别 - Speech Framework
├── 🎙 语音合成 - AVFoundation
├── 📍 地图服务 - MapKit
├── 📸 相机和相册 - AVFoundation & PhotoKit
├── 💾 数据持久化 - UserDefaults & FileManager
└── 🌍 国际化 - 完整中英文支持
```

### 项目结构

```
XunDoc/
├── XunDoc/
│   ├── Models/              # 数据模型
│   │   ├── HealthRecord.swift
│   │   ├── MedicalPrescription.swift
│   │   ├── MedicalReport.swift
│   │   └── UserProfile.swift
│   ├── Views/               # 视图界面
│   │   ├── HomeView.swift
│   │   ├── AIConsultationView.swift
│   │   ├── MedicationView.swift
│   │   └── RecordsView.swift
│   ├── Managers/            # 业务逻辑管理
│   │   ├── MoonshotAPIManager.swift
│   │   ├── KimiAPIManager.swift
│   │   ├── HealthDataManager.swift
│   │   └── SpeechRecognitionManager.swift
│   ├── Extensions/          # 扩展和工具
│   │   └── DesignSystem.swift
│   └── Resources/           # 资源文件
│       ├── en.lproj/        # 英文资源
│       └── zh-Hans.lproj/   # 中文资源
├── API KEY/                 # AI 模型和数据
│   └── Kimi XunDoc/
│       ├── mimic-code/      # 医学数据集
│       └── jmed_data/       # 医疗训练数据
└── Documentation/           # 项目文档
```

---

## 🚀 快速开始

### 环境要求

- macOS 12.0 或更高版本
- Xcode 14.0 或更高版本
- iOS 14.0 或更高版本的设备或模拟器

### 安装步骤

1. **克隆仓库**
```bash
git clone https://github.com/pluto627/XunDoc.git
cd XunDoc
```

2. **配置 API Key**

在使用 AI 功能前，需要配置您的 API Key：

- 在 `MoonshotAPIManager.swift` 中配置 Moonshot AI API Key
- 在 `KimiAPIManager.swift` 中配置 Kimi AI API Key

```swift
// MoonshotAPIManager.swift
private let apiKey = "YOUR_MOONSHOT_API_KEY"

// KimiAPIManager.swift  
private let apiKey = "YOUR_KIMI_API_KEY"
```

3. **打开项目**
```bash
open XunDoc.xcodeproj
```

4. **运行应用**
- 选择目标设备或模拟器
- 按 `Cmd + R` 运行项目

---

## 📖 使用指南

### AI 智能咨询

1. 打开应用，点击底部"AI"标签
2. 选择"智能问诊"或"报告分析"
3. 输入问题或上传报告图片
4. AI 将实时提供专业建议

### 用药提醒设置

1. 进入"用药"页面
2. 点击"+"添加新药品
3. 填写药品信息和提醒时间
4. 系统将按时推送用药提醒

### 就诊记录管理

1. 进入"记录"页面
2. 点击"添加记录"
3. 填写就诊详情并可拍照保存
4. 支持后续编辑和查看

---

## 🎨 界面展示

<div align="center">

### 主界面
现代化的 SwiftUI 设计，简洁美观

### AI 咨询
智能对话界面，支持文字和语音输入

### 用药提醒
直观的用药管理，不错过每一次服药

### 健康数据
可视化的健康趋势，了解身体状况

</div>

---

## 🔒 隐私安全

XunDoc 高度重视用户隐私：

- ✅ 所有健康数据本地加密存储
- ✅ AI 对话不保存敏感个人信息
- ✅ 照片和文件仅存储在设备本地
- ✅ 无第三方数据共享
- ✅ 用户可随时删除所有数据

---

## 📝 更新日志

### Version 1.0.0 (2025-10-29)

#### 🎉 核心功能
- ✨ AI 智能问诊和报告分析
- 💊 智能用药提醒系统
- 📋 就诊记录管理
- 📊 健康数据追踪
- 🏥 附近医院搜索

#### 🌟 特色功能
- 🗣 语音输入和语音转文字
- 🌍 完整中英文国际化
- 🎨 现代化 UI 设计系统
- 📸 照片诊断功能
- 📱 优化的用户体验

详见 [完整更新日志](✅%20五大核心功能实施完成报告.md)

---

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

### 开发规范

- 遵循 Swift 官方编码规范
- 提交前确保代码通过编译
- 添加必要的注释和文档
- 保持代码简洁和可维护性

---

## 📄 开源协议

本项目采用 MIT 协议开源 - 查看 [LICENSE](LICENSE) 文件了解详情

---

## 👨‍💻 作者

**Pluto Guo**

- GitHub: [@pluto627](https://github.com/pluto627)
- Email: your.email@example.com

---

## 🙏 致谢

- [Moonshot AI](https://www.moonshot.cn/) - 提供强大的 AI 对话能力
- [Kimi AI](https://kimi.moonshot.cn/) - 提供专业的医疗分析服务
- [MIMIC-III](https://mimic.mit.edu/) - 提供医疗数据集支持
- SwiftUI 社区的所有贡献者

---

## 📞 联系我们

如有任何问题或建议，欢迎通过以下方式联系：

- 提交 [Issue](https://github.com/pluto627/XunDoc/issues)
- 发送邮件至 your.email@example.com
- 关注项目获取最新动态

---

<div align="center">

**让健康管理更智能，让生活更美好** ❤️

Made with ❤️ by Pluto Guo

</div>


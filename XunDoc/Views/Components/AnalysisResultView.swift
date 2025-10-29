//
//  AnalysisResultView.swift
//  XunDoc
//
//  Created by pluto guo on 9/16/25.
//

import SwiftUI

struct AnalysisResultView: View {
    let analysisText: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 分析结果标题
                    HStack {
                        Image(systemName: "waveform.path.ecg.rectangle")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("AI分析结果")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    
                    // 分析内容
                    VStack(alignment: .leading, spacing: 16) {
                        MarkdownText(text: analysisText)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 免责声明
                    DisclaimerView()
                        .padding(.horizontal)
                    
                    // 操作按钮
                    VStack(spacing: 12) {
                        Button(action: {
                            saveAnalysisResult()
                        }) {
                            Label("保存到健康档案", systemImage: "folder.badge.plus")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            shareAnalysisResult()
                        }) {
                            Label("分享给医生", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("分析报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // 解析分析文本
    private func parseAnalysisText(_ text: String) -> [AnalysisSection] {
        var sections: [AnalysisSection] = []
        
        // 根据文本内容创建不同的分析部分
        if text.contains("症状") || text.contains("表现") {
            sections.append(AnalysisSection(
                title: "症状分析",
                icon: "stethoscope",
                content: extractSection(from: text, keywords: ["症状", "表现"]),
                severity: .medium
            ))
        }
        
        if text.contains("可能") || text.contains("诊断") {
            sections.append(AnalysisSection(
                title: "可能原因",
                icon: "magnifyingglass",
                content: extractSection(from: text, keywords: ["可能", "诊断", "原因"]),
                severity: .low
            ))
        }
        
        if text.contains("建议") || text.contains("治疗") {
            sections.append(AnalysisSection(
                title: "建议措施",
                icon: "list.bullet.clipboard",
                content: extractSection(from: text, keywords: ["建议", "治疗", "措施"]),
                severity: .info
            ))
        }
        
        if text.contains("注意") || text.contains("警告") {
            sections.append(AnalysisSection(
                title: "注意事项",
                icon: "exclamationmark.triangle",
                content: extractSection(from: text, keywords: ["注意", "警告", "避免"]),
                severity: .high
            ))
        }
        
        // 如果没有解析出特定部分，将整个文本作为一个部分
        if sections.isEmpty {
            sections.append(AnalysisSection(
                title: "分析结果",
                icon: "doc.text",
                content: text,
                severity: .medium
            ))
        }
        
        return sections
    }
    
    private func extractSection(from text: String, keywords: [String]) -> String {
        // 简单的文本提取逻辑，实际应用中可以使用更复杂的算法
        for keyword in keywords {
            if text.contains(keyword) {
                // 找到关键词后，提取相关段落
                let components = text.components(separatedBy: "\n")
                for component in components {
                    if component.contains(keyword) {
                        return component
                    }
                }
            }
        }
        return text
    }
    
    private func saveAnalysisResult() {
        // 保存分析结果到健康档案
        // 这里应该调用 HealthDataManager 来保存数据
    }
    
    private func shareAnalysisResult() {
        // 分享分析结果
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let shareText = "AI健康分析报告\n\n\(analysisText)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        window.rootViewController?.present(activityVC, animated: true)
    }
}

// MARK: - 分析部分视图
struct AnalysisSectionView: View {
    let section: AnalysisSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: section.icon)
                    .foregroundColor(section.severity.color)
                    .font(.title3)
                
                Text(section.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 严重程度标签
                if section.severity != .info {
                    Text(section.severity.label)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(section.severity.color.opacity(0.2))
                        .foregroundColor(section.severity.color)
                        .cornerRadius(6)
                }
            }
            
            Text(section.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(red: 253/255, green: 250/255, blue: 245/255))
        .cornerRadius(12)
    }
}

// MARK: - 免责声明视图
struct DisclaimerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                Text("重要提示")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("本分析结果仅供参考，不能替代专业医生的诊断。如有严重症状或紧急情况，请立即就医。")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - 数据模型
struct AnalysisSection {
    let title: String
    let icon: String
    let content: String
    let severity: SeverityLevel
}

enum SeverityLevel {
    case low, medium, high, info
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .info: return .blue
        }
    }
    
    var label: String {
        switch self {
        case .low: return "轻度"
        case .medium: return "中度"
        case .high: return "重度"
        case .info: return "信息"
        }
    }
}

#Preview {
    AnalysisResultView(analysisText: """
    根据您提供的症状图片分析：
    
    症状表现：皮肤出现红疹，伴有轻微瘙痒。
    
    可能原因：可能是过敏性皮炎或接触性皮炎。
    
    建议措施：
    1. 避免接触可能的过敏原
    2. 保持皮肤清洁干燥
    3. 可使用抗过敏药物缓解症状
    
    注意事项：如症状持续加重或出现其他不适，请及时就医。
    """)
}

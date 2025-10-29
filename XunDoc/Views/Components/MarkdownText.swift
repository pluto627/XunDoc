//
//  MarkdownText.swift
//  XunDoc
//
//  支持Markdown格式的文本显示组件
//

import SwiftUI

struct MarkdownText: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseMarkdown(text), id: \.id) { element in
                switch element.type {
                case .heading:
                    Text(element.content)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, element.level == 1 ? 16 : 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                case .boldText:
                    Text(element.content)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                case .bulletPoint:
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text(element.content)
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                case .bulletPointBold:
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text(element.content)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                case .normalText:
                    Text(element.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(2)
                }
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 跳过空行
            if trimmedLine.isEmpty {
                continue
            }
            
            // 解析标题 (## 或 ###)
            if trimmedLine.hasPrefix("###") {
                let content = trimmedLine.replacingOccurrences(of: "###", with: "").trimmingCharacters(in: .whitespaces)
                elements.append(MarkdownElement(id: index, type: .heading, content: content, level: 3))
            } else if trimmedLine.hasPrefix("##") {
                let content = trimmedLine.replacingOccurrences(of: "##", with: "").trimmingCharacters(in: .whitespaces)
                elements.append(MarkdownElement(id: index, type: .heading, content: content, level: 2))
            }
            // 解析包含加粗文本的行
            else if trimmedLine.contains("**") {
                elements.append(contentsOf: parseMixedText(trimmedLine, index: index))
            }
            // 解析列表项 (- 或 •)
            else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("• ") {
                let content = trimmedLine.replacingOccurrences(of: "^[•-]\\s+", with: "", options: .regularExpression)
                // 检查列表项中是否有加粗文本
                if content.contains("**") {
                    elements.append(contentsOf: parseMixedText(content, index: index, isBulletPoint: true))
                } else {
                    elements.append(MarkdownElement(id: index, type: .bulletPoint, content: content, level: 0))
                }
            }
            // 普通文本
            else {
                elements.append(MarkdownElement(id: index, type: .normalText, content: trimmedLine, level: 0))
            }
        }
        
        return elements
    }
    
    private func parseBoldText(_ text: String) -> String {
        // 移除 ** 标记，但保留文本
        return text.replacingOccurrences(of: "**", with: "")
    }
    
    // 解析包含加粗和普通文本混合的行
    private func parseMixedText(_ text: String, index: Int, isBulletPoint: Bool = false) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        var currentText = text
        var elementIndex = index
        
        // 使用正则表达式找到所有 **text** 模式
        let pattern = "\\*\\*(.*?)\\*\\*"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: currentText, options: [], range: NSRange(location: 0, length: currentText.count))
        
        var lastEnd = 0
        
        for match in matches {
            // 添加加粗文本前的普通文本
            if match.range.location > lastEnd {
                let normalRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                if let normalText = Range(normalRange, in: currentText) {
                    let content = String(currentText[normalText]).trimmingCharacters(in: .whitespaces)
                    if !content.isEmpty {
                        let type: MarkdownElementType = isBulletPoint ? .bulletPoint : .normalText
                        elements.append(MarkdownElement(id: elementIndex, type: type, content: content, level: 0))
                        elementIndex += 1
                    }
                }
            }
            
            // 添加加粗文本
            if let boldRange = Range(match.range(at: 1), in: currentText) {
                let boldContent = String(currentText[boldRange])
                let type: MarkdownElementType = isBulletPoint ? .bulletPointBold : .boldText
                elements.append(MarkdownElement(id: elementIndex, type: type, content: boldContent, level: 0))
                elementIndex += 1
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        // 添加最后剩余的普通文本
        if lastEnd < currentText.count {
            let remainingRange = NSRange(location: lastEnd, length: currentText.count - lastEnd)
            if let remainingText = Range(remainingRange, in: currentText) {
                let content = String(currentText[remainingText]).trimmingCharacters(in: .whitespaces)
                if !content.isEmpty {
                    let type: MarkdownElementType = isBulletPoint ? .bulletPoint : .normalText
                    elements.append(MarkdownElement(id: elementIndex, type: type, content: content, level: 0))
                }
            }
        }
        
        // 如果没有找到任何加粗文本，返回整行作为普通文本
        if elements.isEmpty {
            let type: MarkdownElementType = isBulletPoint ? .bulletPoint : .normalText
            elements.append(MarkdownElement(id: index, type: type, content: text, level: 0))
        }
        
        return elements
    }
}

struct MarkdownElement {
    let id: Int
    let type: MarkdownElementType
    let content: String
    let level: Int
}

enum MarkdownElementType {
    case heading
    case boldText
    case bulletPoint
    case bulletPointBold
    case normalText
}

#Preview {
    ScrollView {
        MarkdownText(text: """
        根据您提供的图片，我仔细观察了皮肤病变的特征。从专业角度来看，这个病变呈现出一些值得关注的特点。
        
        **病变特征观察**
        
        我注意到患处有明显的 **红色炎症反应**，边界相对清晰，这提示可能是 **接触性皮炎** 或 **过敏性反应**。病变区域没有明显的渗出或破溃，这是一个好的征象。
        
        **可能的诊断分析**
        
        基于这些观察，我认为最可能的诊断是：
        
        - **接触性皮炎**：这是最常见的原因，通常由接触刺激性物质引起
        - **过敏性皮炎**：可能是对某种 **过敏原** 的反应
        - **湿疹**：如果有反复发作的历史，需要考虑这个可能
        
        **治疗建议**
        
        我建议您采取以下措施：
        
        - 立即停止接触可能的 **刺激物质**
        - 用 **温和的清水** 轻柔清洁患处
        - 可以使用 **炉甘石洗剂** 来缓解瘙痒
        - 如果症状持续或加重，请 **及时就医**
        
        **重要提醒**
        
        请注意观察病变的变化，如果出现 **发热**、**化脓** 或 **范围扩大** 等情况，需要立即到医院就诊。
        """)
        .padding()
    }
}

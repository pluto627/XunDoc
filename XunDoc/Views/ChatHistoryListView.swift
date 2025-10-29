//
//  ChatHistoryListView.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI

struct ChatHistoryListView: View {
    @EnvironmentObject var chatHistoryManager: ChatHistoryManager
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var conversationToDelete: ChatConversation?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部统计信息
                if !chatHistoryManager.conversations.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("对话记录")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("共 \(chatHistoryManager.conversations.count) 个对话")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            createNewConversation()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("新建")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                }
                
                // 对话列表
                if chatHistoryManager.conversations.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatHistoryManager.conversations) { conversation in
                                ConversationCard(
                                    conversation: conversation,
                                    isSelected: chatHistoryManager.currentConversation?.id == conversation.id,
                                    onSelect: {
                                        selectConversation(conversation)
                                    },
                                    onDelete: {
                                        conversationToDelete = conversation
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("对话目录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
            .alert(NSLocalizedString("delete_conversation", comment: ""), isPresented: $showingDeleteAlert) {
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
                Button(NSLocalizedString("delete", comment: ""), role: .destructive) {
                    if let conversation = conversationToDelete {
                        deleteConversation(conversation)
                    }
                }
            } message: {
                Text(NSLocalizedString("delete_conversation_message", comment: ""))
            }
        }
    }
    
    private func selectConversation(_ conversation: ChatConversation) {
        // 震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        chatHistoryManager.selectConversation(conversation)
        dismiss()
    }
    
    private func createNewConversation() {
        // 震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        _ = chatHistoryManager.createNewConversation()
        dismiss()
    }
    
    private func deleteConversation(_ conversation: ChatConversation) {
        // 震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation {
            chatHistoryManager.deleteConversation(conversation)
        }
    }
}

// MARK: - 对话卡片视图
struct ConversationCard: View {
    let conversation: ChatConversation
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // 顶部：标题和状态
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(conversation.title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if isSelected {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // 最后消息预览
                        Text(conversation.preview)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                    
                    // 删除按钮
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red.opacity(0.7))
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // 底部：时间和消息数
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(formatRelativeTime(conversation.updatedAt))
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 12))
                        Text("\(conversation.messages.count) 条消息")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .background(isSelected ? Color.blue.opacity(0.08) : Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 空历史视图
struct EmptyHistoryView: View {
    @EnvironmentObject var chatHistoryManager: ChatHistoryManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.blue)
            }
            
            // 标题
            Text("暂无对话记录")
                .font(.title2)
                .fontWeight(.bold)
            
            // 描述
            Text("开始您的第一个对话\n与AI医生交流健康问题")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // 新建按钮
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                _ = chatHistoryManager.createNewConversation()
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("创建新对话")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: 200)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ChatHistoryListView()
        .environmentObject(ChatHistoryManager.shared)
}









#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
医学AI问答系统 - 后端API服务
基于微调后的Kimi模型提供专业医学问答服务
"""

import os
import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
from openai import OpenAI
import threading
import time

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# API配置
API_KEY = "sk-wc9tcOA0q2ShfOjKZ91YStbbyyoMGpiegf6zq54i9kpaQtke"

# 初始化OpenAI客户端 (这里假设使用微调后的模型)
client = OpenAI(
    api_key=API_KEY,
    base_url="https://api.moonshot.cn/v1",
)

# Flask应用初始化
app = Flask(__name__)
CORS(app)  # 允许跨域请求

class MedicalAISystem:
    """医学AI问答系统核心类"""
    
    def __init__(self):
        self.model_name = "kimi-k2-0905-preview"  # 这里将来替换为微调后的模型
        self.conversation_history = {}
        self.system_prompt = self.load_medical_system_prompt()
        
    def load_medical_system_prompt(self):
        """加载医学专业系统提示词"""
        return """你是一位资深的医学AI助手，经过专业医学数据微调训练。你具备以下能力：

1. **专业医学知识**: 掌握内科、外科、妇科、儿科等各科室专业知识
2. **诊断辅助**: 能够基于症状提供可能的诊断建议（仅供参考）
3. **治疗建议**: 提供基于循证医学的治疗方案建议
4. **药物咨询**: 提供药物使用、副作用、相互作用等信息
5. **健康教育**: 提供疾病预防、健康生活方式等指导

**重要声明**:
- 我的建议仅供医学参考，不能替代专业医生的诊断和治疗
- 遇到紧急情况请立即就医
- 用药请遵医嘱，不要自行调整药物

请描述您的医学问题，我会提供专业的分析和建议。"""

    def get_medical_response(self, user_question, session_id=None):
        """获取医学AI回答"""
        try:
            # 构建对话历史
            messages = [{"role": "system", "content": self.system_prompt}]
            
            # 添加历史对话（如果有）
            if session_id and session_id in self.conversation_history:
                messages.extend(self.conversation_history[session_id][-6:])  # 保留最近3轮对话
            
            # 添加当前问题
            messages.append({"role": "user", "content": user_question})
            
            # 调用API
            completion = client.chat.completions.create(
                model=self.model_name,
                messages=messages,
                temperature=0.3,  # 较低温度确保回答准确性
                max_tokens=2000,
            )
            
            response = completion.choices[0].message.content
            
            # 保存对话历史
            if session_id:
                if session_id not in self.conversation_history:
                    self.conversation_history[session_id] = []
                
                self.conversation_history[session_id].extend([
                    {"role": "user", "content": user_question},
                    {"role": "assistant", "content": response}
                ])
                
                # 限制历史长度
                if len(self.conversation_history[session_id]) > 20:
                    self.conversation_history[session_id] = self.conversation_history[session_id][-20:]
            
            return {
                "success": True,
                "response": response,
                "model": self.model_name,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"获取医学回答失败: {e}")
            return {
                "success": False,
                "error": str(e),
                "response": "抱歉，系统暂时无法提供回答，请稍后重试。"
            }

    def get_specialized_response(self, question, specialty="general"):
        """获取专科医学回答"""
        specialty_prompts = {
            "cardiology": "作为心血管内科专家，请重点从心血管疾病角度分析：",
            "neurology": "作为神经内科专家，请重点从神经系统疾病角度分析：",
            "gastroenterology": "作为消化内科专家，请重点从消化系统疾病角度分析：",
            "respiratory": "作为呼吸内科专家，请重点从呼吸系统疾病角度分析：",
            "endocrinology": "作为内分泌科专家，请重点从内分泌系统疾病角度分析：",
            "urology": "作为泌尿科专家，请重点从泌尿系统疾病角度分析：",
            "general": "作为全科医生，请综合分析："
        }
        
        specialized_question = specialty_prompts.get(specialty, specialty_prompts["general"]) + question
        return self.get_medical_response(specialized_question)

# 初始化医学AI系统
medical_ai = MedicalAISystem()

# API路由定义
@app.route('/')
def home():
    """主页 - 返回HTML界面"""
    return render_template_string(MEDICAL_AI_HTML_TEMPLATE)

@app.route('/api/ask', methods=['POST'])
def ask_question():
    """医学问答API"""
    try:
        data = request.get_json()
        question = data.get('question', '').strip()
        session_id = data.get('session_id', 'default')
        specialty = data.get('specialty', 'general')
        
        if not question:
            return jsonify({
                "success": False,
                "error": "问题不能为空"
            }), 400
        
        # 记录问题
        logger.info(f"收到医学问题 [{specialty}]: {question[:100]}...")
        
        # 获取回答
        if specialty != 'general':
            result = medical_ai.get_specialized_response(question, specialty)
        else:
            result = medical_ai.get_medical_response(question, session_id)
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"API错误: {e}")
        return jsonify({
            "success": False,
            "error": "服务器内部错误"
        }), 500

@app.route('/api/clear_history', methods=['POST'])
def clear_history():
    """清除对话历史"""
    try:
        data = request.get_json()
        session_id = data.get('session_id', 'default')
        
        if session_id in medical_ai.conversation_history:
            del medical_ai.conversation_history[session_id]
        
        return jsonify({"success": True, "message": "对话历史已清除"})
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """健康检查"""
    return jsonify({
        "status": "healthy",
        "model": medical_ai.model_name,
        "timestamp": datetime.now().isoformat(),
        "active_sessions": len(medical_ai.conversation_history)
    })

# HTML模板
MEDICAL_AI_HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>医学AI问答系统 - 基于微调Kimi模型</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', 'Microsoft YaHei', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #e9ecef;
        }

        .header h1 {
            color: #2c3e50;
            font-size: 2.5em;
            margin-bottom: 10px;
            background: linear-gradient(45deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .header .subtitle {
            color: #7f8c8d;
            font-size: 1.1em;
            margin-bottom: 15px;
        }

        .disclaimer {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 20px;
            color: #856404;
            font-size: 14px;
        }

        .chat-container {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }

        .chat-area {
            flex: 1;
            background: #f8f9fa;
            border-radius: 15px;
            padding: 20px;
            height: 500px;
            display: flex;
            flex-direction: column;
        }

        .specialty-panel {
            width: 250px;
            background: white;
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }

        .specialty-panel h3 {
            color: #2c3e50;
            margin-bottom: 15px;
            font-size: 1.2em;
        }

        .specialty-btn {
            display: block;
            width: 100%;
            padding: 10px 15px;
            margin-bottom: 8px;
            background: #f8f9fa;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            text-align: left;
            font-size: 14px;
            color: #495057;
        }

        .specialty-btn:hover {
            background: #e9ecef;
            border-color: #667eea;
        }

        .specialty-btn.active {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border-color: #667eea;
        }

        .messages {
            flex: 1;
            overflow-y: auto;
            margin-bottom: 20px;
            padding: 10px;
            background: white;
            border-radius: 10px;
            border: 2px solid #e9ecef;
        }

        .message {
            margin-bottom: 15px;
            padding: 12px 15px;
            border-radius: 12px;
            max-width: 80%;
            word-wrap: break-word;
        }

        .message.user {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            margin-left: auto;
        }

        .message.assistant {
            background: #e9ecef;
            color: #2c3e50;
            border-left: 4px solid #667eea;
        }

        .message.system {
            background: #d1ecf1;
            color: #0c5460;
            text-align: center;
            font-size: 14px;
            max-width: 100%;
        }

        .input-area {
            display: flex;
            gap: 10px;
        }

        .question-input {
            flex: 1;
            padding: 12px 15px;
            border: 2px solid #e9ecef;
            border-radius: 25px;
            font-size: 16px;
            outline: none;
            transition: border-color 0.3s ease;
        }

        .question-input:focus {
            border-color: #667eea;
        }

        .send-btn {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 12px 25px;
            border-radius: 25px;
            cursor: pointer;
            font-size: 16px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }

        .send-btn:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
        }

        .send-btn:disabled {
            background: #bdc3c7;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }

        .controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 15px;
        }

        .clear-btn {
            background: #dc3545;
            color: white;
            border: none;
            padding: 8px 15px;
            border-radius: 15px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.3s ease;
        }

        .clear-btn:hover {
            background: #c82333;
        }

        .status {
            font-size: 14px;
            color: #6c757d;
        }

        .loading {
            display: none;
            text-align: center;
            color: #667eea;
            font-style: italic;
        }

        .loading.show {
            display: block;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        .loading {
            animation: pulse 1.5s infinite;
        }

        @media (max-width: 768px) {
            .chat-container {
                flex-direction: column;
            }
            
            .specialty-panel {
                width: 100%;
                order: -1;
            }
            
            .container {
                padding: 15px;
                margin: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏥 医学AI问答系统</h1>
            <div class="subtitle">基于微调Kimi模型的专业医学咨询助手</div>
            <div class="disclaimer">
                ⚠️ <strong>重要提示</strong>: 本系统提供的建议仅供医学参考，不能替代专业医生的诊断和治疗。遇到紧急情况请立即就医。
            </div>
        </div>

        <div class="chat-container">
            <div class="chat-area">
                <div class="messages" id="messages">
                    <div class="message system">
                        🤖 您好！我是专业的医学AI助手，经过医学数据微调训练。请选择专科或描述您的症状，我会为您提供专业的医学建议。
                    </div>
                </div>
                
                <div class="loading" id="loading">
                    🤖 AI正在思考中，请稍候...
                </div>
                
                <div class="input-area">
                    <input type="text" 
                           class="question-input" 
                           id="questionInput" 
                           placeholder="请描述您的症状或医学问题..."
                           onkeypress="handleKeyPress(event)">
                    <button class="send-btn" id="sendBtn" onclick="askQuestion()">
                        发送
                    </button>
                </div>
                
                <div class="controls">
                    <button class="clear-btn" onclick="clearHistory()">
                        🗑️ 清除对话
                    </button>
                    <div class="status" id="status">
                        就绪 | 会话ID: <span id="sessionId">default</span>
                    </div>
                </div>
            </div>

            <div class="specialty-panel">
                <h3>🏥 专科选择</h3>
                <button class="specialty-btn active" data-specialty="general" onclick="selectSpecialty('general', this)">
                    🩺 全科医学
                </button>
                <button class="specialty-btn" data-specialty="cardiology" onclick="selectSpecialty('cardiology', this)">
                    ❤️ 心血管内科
                </button>
                <button class="specialty-btn" data-specialty="neurology" onclick="selectSpecialty('neurology', this)">
                    🧠 神经内科
                </button>
                <button class="specialty-btn" data-specialty="gastroenterology" onclick="selectSpecialty('gastroenterology', this)">
                    🫁 消化内科
                </button>
                <button class="specialty-btn" data-specialty="respiratory" onclick="selectSpecialty('respiratory', this)">
                    🫁 呼吸内科
                </button>
                <button class="specialty-btn" data-specialty="endocrinology" onclick="selectSpecialty('endocrinology', this)">
                    ⚕️ 内分泌科
                </button>
                <button class="specialty-btn" data-specialty="urology" onclick="selectSpecialty('urology', this)">
                    🫘 泌尿科
                </button>
            </div>
        </div>
    </div>

    <script>
        // 全局变量
        let currentSpecialty = 'general';
        let sessionId = 'session_' + Date.now();
        let isLoading = false;

        // 更新会话ID显示
        document.getElementById('sessionId').textContent = sessionId;

        // 选择专科
        function selectSpecialty(specialty, button) {
            // 移除所有按钮的active类
            document.querySelectorAll('.specialty-btn').forEach(btn => {
                btn.classList.remove('active');
            });
            
            // 添加当前按钮的active类
            button.classList.add('active');
            
            // 更新当前专科
            currentSpecialty = specialty;
            
            // 添加系统消息
            const specialtyNames = {
                'general': '全科医学',
                'cardiology': '心血管内科',
                'neurology': '神经内科',
                'gastroenterology': '消化内科',
                'respiratory': '呼吸内科',
                'endocrinology': '内分泌科',
                'urology': '泌尿科'
            };
            
            addMessage('system', `已切换到 ${specialtyNames[specialty]} 模式`);
        }

        // 处理键盘事件
        function handleKeyPress(event) {
            if (event.key === 'Enter' && !event.shiftKey) {
                event.preventDefault();
                askQuestion();
            }
        }

        // 询问问题
        async function askQuestion() {
            const input = document.getElementById('questionInput');
            const question = input.value.trim();
            
            if (!question || isLoading) {
                return;
            }
            
            // 显示用户问题
            addMessage('user', question);
            input.value = '';
            
            // 设置加载状态
            setLoading(true);
            
            try {
                const response = await fetch('/api/ask', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        question: question,
                        session_id: sessionId,
                        specialty: currentSpecialty
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    addMessage('assistant', data.response);
                } else {
                    addMessage('system', '❌ ' + (data.error || '获取回答失败'));
                }
                
            } catch (error) {
                console.error('请求失败:', error);
                addMessage('system', '❌ 网络错误，请检查连接后重试');
            } finally {
                setLoading(false);
            }
        }

        // 添加消息
        function addMessage(type, content) {
            const messages = document.getElementById('messages');
            const message = document.createElement('div');
            message.className = `message ${type}`;
            
            // 处理换行
            const formattedContent = content.replace(/\\n/g, '<br>').replace(/\n/g, '<br>');
            message.innerHTML = formattedContent;
            
            messages.appendChild(message);
            messages.scrollTop = messages.scrollHeight;
        }

        // 设置加载状态
        function setLoading(loading) {
            isLoading = loading;
            const loadingDiv = document.getElementById('loading');
            const sendBtn = document.getElementById('sendBtn');
            const input = document.getElementById('questionInput');
            
            if (loading) {
                loadingDiv.classList.add('show');
                sendBtn.disabled = true;
                sendBtn.textContent = '思考中...';
                input.disabled = true;
            } else {
                loadingDiv.classList.remove('show');
                sendBtn.disabled = false;
                sendBtn.textContent = '发送';
                input.disabled = false;
                input.focus();
            }
        }

        // 清除对话历史
        async function clearHistory() {
            if (!confirm('确定要清除所有对话记录吗？')) {
                return;
            }
            
            try {
                const response = await fetch('/api/clear_history', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        session_id: sessionId
                    })
                });
                
                if (response.ok) {
                    // 清空消息区域
                    const messages = document.getElementById('messages');
                    messages.innerHTML = `
                        <div class="message system">
                            🤖 对话已清除。我是专业的医学AI助手，请描述您的症状或医学问题。
                        </div>
                    `;
                    
                    // 生成新的会话ID
                    sessionId = 'session_' + Date.now();
                    document.getElementById('sessionId').textContent = sessionId;
                }
                
            } catch (error) {
                console.error('清除历史失败:', error);
                addMessage('system', '❌ 清除对话失败');
            }
        }

        // 页面加载完成后聚焦输入框
        document.addEventListener('DOMContentLoaded', function() {
            document.getElementById('questionInput').focus();
        });
    </script>
</body>
</html>
'''

def main():
    """启动医学AI问答系统"""
    print("🏥 医学AI问答系统启动中...")
    print("=" * 60)
    print("🤖 基于微调Kimi模型的专业医学咨询系统")
    print("📡 Web界面: http://localhost:5000")
    print("🔌 API端点: http://localhost:5000/api/ask")
    print("=" * 60)
    print("💡 功能特性:")
    print("   - 专业医学问答")
    print("   - 多专科支持")
    print("   - 对话历史记录")
    print("   - 实时Web界面")
    print("=" * 60)
    print("⚠️  重要提示: 仅供医学参考，不能替代专业医生诊断")
    print("🚀 系统启动完成，请在浏览器中访问 http://localhost:5000")
    
    # 启动Flask应用
    app.run(host='0.0.0.0', port=5000, debug=False)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kimi API 使用示例
基于您提供的API Key和Support文档的完整演示
"""

from openai import OpenAI
import json
import base64
import os
from pathlib import Path

# 您的API Key
API_KEY = "sk-wc9tcOA0q2ShfOjKZ91YStbbyyoMGpiegf6zq54i9kpaQtke"

# 初始化客户端
client = OpenAI(
    api_key=API_KEY,
    base_url="https://api.moonshot.cn/v1",
)

def basic_chat_example():
    """基础对话示例 - 与您提供的示例相同"""
    print("=" * 50)
    print("基础对话示例")
    print("=" * 50)
    
    completion = client.chat.completions.create(
        model="kimi-k2-0905-preview",
        messages=[
            {
                "role": "system", 
                "content": "你是 Kimi，由 Moonshot AI 提供的人工智能助手，你更擅长中文和英文的对话。你会为用户提供安全，有帮助，准确的回答。同时，你会拒绝一切涉及恐怖主义，种族歧视，黄色暴力等问题的回答。Moonshot AI 为专有名词，不可翻译成其他语言。"
            },
            {
                "role": "user", 
                "content": "你好，我叫李雷，1+1等于多少？"
            }
        ],
        temperature=0.6,
    )
    
    print("回答:", completion.choices[0].message.content)
    print()

def json_mode_example():
    """JSON模式示例 - 基于Support文档"""
    print("=" * 50)
    print("JSON模式示例")
    print("=" * 50)
    
    system_prompt = """
你是月之暗面（Kimi）的智能客服，你负责回答用户提出的各种问题。

请使用如下 JSON 格式输出你的回复：

{
    "text": "文字信息",
    "image": "图片地址（如果有的话）",
    "url": "链接地址（如果有的话）"
}

注意，请将文字信息放置在 `text` 字段中，将图片以 `oss://` 开头的链接形式放在 `image` 字段中，将普通链接放置在 `url` 字段中。
"""
    
    completion = client.chat.completions.create(
        model="kimi-k2-0905-preview",
        messages=[
            {"role": "system", "content": "你是 Kimi，由 Moonshot AI 提供的人工智能助手，你更擅长中文和英文的对话。你会为用户提供安全，有帮助，准确的回答。同时，你会拒绝一切涉及恐怖主义，种族歧视，黄色暴力等问题的回答。Moonshot AI 为专有名词，不可翻译成其他语言。"},
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": "你好，我想了解一下Kimi的功能特点"}
        ],
        temperature=0.6,
        response_format={"type": "json_object"},
    )
    
    # 解析JSON响应
    content = json.loads(completion.choices[0].message.content)
    
    print("JSON响应解析:")
    if "text" in content:
        print("文本内容:", content["text"])
    if "image" in content:
        print("图片地址:", content["image"])
    if "url" in content:
        print("链接地址:", content["url"])
    print()

def partial_mode_example():
    """Partial模式示例 - 基于Support文档"""
    print("=" * 50)
    print("Partial模式示例 - 客服场景")
    print("=" * 50)
    
    completion = client.chat.completions.create(
        model="kimi-k2-0905-preview",
        messages=[
            {
                "role": "system", 
                "content": "你是 Kimi，由 Moonshot AI 提供的人工智能助手，你更擅长中文和英文的对话。你会为用户提供安全，有帮助，准确的回答。同时，你会拒绝一切涉及恐怖主义，种族歧视，黄色暴力等问题的回答。Moonshot AI 为专有名词，不可翻译成其他语言。"
            },
            {
                "role": "user", 
                "content": "我想咨询一下API的使用问题"
            },
            {
                "partial": True,
                "role": "assistant",
                "content": "尊敬的用户您好，",
            },
        ],
        temperature=0.6,
    )
    
    # 手动拼接前缀
    full_response = "尊敬的用户您好，" + completion.choices[0].message.content
    print("完整回答:", full_response)
    print()

def role_playing_example():
    """角色扮演示例 - 基于Support文档的凯尔希角色"""
    print("=" * 50)
    print("角色扮演示例 - 凯尔希医生")
    print("=" * 50)
    
    completion = client.chat.completions.create(
        model="kimi-k2-0905-preview",
        messages=[
            {
                "role": "system",
                "content": "下面你扮演凯尔希，请用凯尔希的语气和我对话。凯尔希是手机游戏《明日方舟》中的六星医疗职业医师分支干员。前卡兹戴尔勋爵，前巴别塔成员，罗德岛高层管理人员之一，罗德岛医疗项目领头人。在冶金工业、社会学、源石技艺、考古学、历史系谱学、经济学、植物学、地质学等领域皆拥有渊博学识。于罗德岛部分行动中作为医务人员提供医学理论协助与应急医疗器械，同时也作为罗德岛战略指挥系统的重要组成人员活跃在各项目中。"
            },
            {
                "role": "user",
                "content": "凯尔希医生，您能介绍一下罗德岛的医疗项目吗？",
            },
            {
                "partial": True,
                "role": "assistant",
                "name": "凯尔希",
                "content": "",
            },
        ],
        temperature=0.6,
        max_tokens=65536,
    )
    
    print("凯尔希的回答:", completion.choices[0].message.content)
    print()

def create_sample_file():
    """创建一个示例文件用于文件问答演示"""
    sample_content = """
Kimi API 技术文档

Kimi API 是由 Moonshot AI 提供的人工智能服务接口，具有以下特点：

1. 强大的对话能力
   - 支持中英文对话
   - 上下文理解能力强
   - 回答准确且有帮助

2. 多种功能模式
   - JSON Mode: 结构化输出
   - Partial Mode: 引导式生成
   - Vision Mode: 图像理解
   - 文件问答: 基于文档的问答

3. 技术规格
   - 模型: kimi-k2-0905-preview
   - 支持流式输出
   - 支持工具调用
   - 支持上下文缓存

4. 应用场景
   - 智能客服
   - 内容生成
   - 文档分析
   - 代码助手

使用Kimi API需要先申请API Key，然后通过OpenAI兼容的SDK进行调用。
"""
    
    with open("/Users/plutoguo/Desktop/All code/API KEY/Kimi XunDoc/sample_doc.txt", "w", encoding="utf-8") as f:
        f.write(sample_content)
    
    return "/Users/plutoguo/Desktop/All code/API KEY/Kimi XunDoc/sample_doc.txt"

def file_qa_example():
    """文件问答示例 - 基于Support文档"""
    print("=" * 50)
    print("文件问答示例")
    print("=" * 50)
    
    # 创建示例文件
    file_path = create_sample_file()
    print(f"创建示例文件: {file_path}")
    
    try:
        # 上传文件
        file_object = client.files.create(file=Path(file_path), purpose="file-extract")
        print(f"文件上传成功，ID: {file_object.id}")
        
        # 获取文件内容
        file_content = client.files.content(file_id=file_object.id).text
        
        # 基于文件内容进行问答
        messages = [
            {
                "role": "system",
                "content": "你是 Kimi，由 Moonshot AI 提供的人工智能助手，你更擅长中文和英文的对话。你会为用户提供安全，有帮助，准确的回答。同时，你会拒绝一切涉及恐怖主义，种族歧视，黄色暴力等问题的回答。Moonshot AI 为专有名词，不可翻译成其他语言。",
            },
            {
                "role": "system",
                "content": file_content,
            },
            {
                "role": "user", 
                "content": "请简单总结一下这个文档的主要内容，并说明Kimi API的核心优势是什么？"
            },
        ]
        
        completion = client.chat.completions.create(
            model="kimi-k2-0905-preview",
            messages=messages,
            temperature=0.6,
        )
        
        print("基于文档的回答:", completion.choices[0].message.content)
        
        # 清理上传的文件
        client.files.delete(file_id=file_object.id)
        print("文件已清理")
        
    except Exception as e:
        print(f"文件问答示例执行失败: {e}")
    
    # 清理本地文件
    if os.path.exists(file_path):
        os.remove(file_path)
    
    print()

def main():
    """主函数 - 运行所有示例"""
    print("Kimi API 完整功能演示")
    print(f"使用API Key: {API_KEY}")
    print()
    
    try:
        # 1. 基础对话示例
        basic_chat_example()
        
        # 2. JSON模式示例
        json_mode_example()
        
        # 3. Partial模式示例
        partial_mode_example()
        
        # 4. 角色扮演示例
        role_playing_example()
        
        # 5. 文件问答示例
        file_qa_example()
        
        print("=" * 50)
        print("所有示例执行完成！")
        print("=" * 50)
        
    except Exception as e:
        print(f"执行过程中出现错误: {e}")
        print("请检查您的API Key是否正确，以及网络连接是否正常。")

if __name__ == "__main__":
    main()

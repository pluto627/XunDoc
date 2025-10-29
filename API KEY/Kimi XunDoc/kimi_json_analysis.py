#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kimi API 与 JSON 数据交互完整示例
基于网上资料和jmed_data.json数据文件的实际应用
"""

import os
import json
from openai import OpenAI
from pathlib import Path

# 您的API Key
API_KEY = "sk-wc9tcOA0q2ShfOjKZ91YStbbyyoMGpiegf6zq54i9kpaQtke"

# 初始化Kimi API客户端
client = OpenAI(
    api_key=API_KEY,
    base_url="https://api.moonshot.cn/v1",
)

def load_json_data(file_path):
    """加载本地JSON数据"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"✅ 成功加载JSON数据: {file_path}")
        return data
    except Exception as e:
        print(f"❌ 加载JSON数据失败: {e}")
        return None

def upload_file_to_kimi(file_path):
    """步骤1: 上传JSON文件到Kimi"""
    try:
        print(f"🚀 正在上传文件: {file_path}")
        file_object = client.files.create(file=Path(file_path), purpose="file-extract")
        print(f"✅ 文件上传成功，File ID: {file_object.id}")
        return file_object
    except Exception as e:
        print(f"❌ 文件上传失败: {e}")
        return None

def get_file_content(file_id):
    """步骤2: 获取上传文件的内容"""
    try:
        print(f"📄 正在获取文件内容，File ID: {file_id}")
        file_content = client.files.content(file_id=file_id).text
        print(f"✅ 文件内容获取成功，长度: {len(file_content)} 字符")
        return file_content
    except Exception as e:
        print(f"❌ 获取文件内容失败: {e}")
        return None

def analyze_with_kimi(file_content, analysis_question, model="moonshot-v1-128k"):
    """步骤3: 使用Kimi分析JSON数据"""
    try:
        print(f"🤖 正在使用模型 {model} 分析数据...")
        
        completion = client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": f"你是一个专业的医疗数据分析师。请基于以下JSON文件内容回答用户的问题，提供详细的数据分析和见解。\n\n文件内容：\n{file_content}"
                },
                {
                    "role": "user",
                    "content": analysis_question
                }
            ],
            temperature=0.3,
        )
        
        return completion.choices[0].message.content
    except Exception as e:
        print(f"❌ Kimi分析失败: {e}")
        return None

def stream_analysis_with_kimi(file_content, analysis_question, model="moonshot-v1-128k"):
    """流式输出版本的分析"""
    try:
        print(f"🌊 正在使用流式输出分析数据...")
        
        stream = client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": f"你是一个专业的医疗数据分析师。请基于以下JSON文件内容回答用户的问题，提供详细的数据分析和见解。\n\n文件内容：\n{file_content}"
                },
                {
                    "role": "user",
                    "content": analysis_question
                }
            ],
            temperature=0.3,
            stream=True,  # 启用流式输出
        )
        
        print("📝 Kimi分析结果（流式输出）:")
        full_response = ""
        for chunk in stream:
            if chunk.choices[0].delta.content is not None:
                content = chunk.choices[0].delta.content
                print(content, end="", flush=True)
                full_response += content
        print("\n")
        
        return full_response
    except Exception as e:
        print(f"❌ 流式分析失败: {e}")
        return None

def cleanup_file(file_id):
    """清理上传的文件"""
    try:
        client.files.delete(file_id=file_id)
        print(f"🗑️ 文件已清理: {file_id}")
    except Exception as e:
        print(f"⚠️ 文件清理失败: {e}")

def comprehensive_analysis_demo():
    """完整的分析演示"""
    print("=" * 60)
    print("🏥 Kimi API + jmed_data.json 医疗数据分析演示")
    print("=" * 60)
    
    json_file_path = "/Users/plutoguo/Desktop/All code/API KEY/Kimi XunDoc/jmed_data.json"
    
    # 第一步：加载本地JSON数据（可选，用于预览）
    local_data = load_json_data(json_file_path)
    if local_data:
        print(f"📊 数据概览:")
        print(f"   - 医院名称: {local_data['medical_data']['hospital_info']['name']}")
        print(f"   - 总患者数: {local_data['medical_data']['patient_statistics']['total_patients_2024']}")
        print(f"   - 科室数量: {len(local_data['medical_data']['hospital_info']['departments'])}")
        print()
    
    # 第二步：上传文件到Kimi
    file_object = upload_file_to_kimi(json_file_path)
    if not file_object:
        return
    
    # 第三步：获取文件内容
    file_content = get_file_content(file_object.id)
    if not file_content:
        return
    
    # 第四步：多个分析问题
    analysis_questions = [
        "请分析这家医院2024年的整体运营情况，包括患者流量趋势、财务表现和各科室效率。",
        "根据数据，哪个科室的运营效率最高？请从成功率、平均住院天数和成本效益角度分析。",
        "医院在技术采用方面有什么特点？这些技术如何影响患者满意度？",
        "基于现有数据，为医院未来发展提供3-5个具体的改进建议。"
    ]
    
    print("🔍 开始多维度分析...")
    print()
    
    for i, question in enumerate(analysis_questions, 1):
        print(f"📋 分析问题 {i}: {question}")
        print("-" * 50)
        
        if i == 1:
            # 第一个问题使用流式输出
            result = stream_analysis_with_kimi(file_content, question)
        else:
            # 其他问题使用普通输出
            result = analyze_with_kimi(file_content, question)
            if result:
                print("📝 Kimi分析结果:")
                print(result)
        
        print("\n" + "=" * 60 + "\n")
    
    # 第五步：清理文件
    cleanup_file(file_object.id)

def simple_json_analysis_demo():
    """简化版演示"""
    print("🚀 简化版JSON数据分析演示")
    print("-" * 40)
    
    json_file_path = "/Users/plutoguo/Desktop/All code/API KEY/Kimi XunDoc/jmed_data.json"
    
    # 上传并分析
    file_object = upload_file_to_kimi(json_file_path)
    if file_object:
        file_content = get_file_content(file_object.id)
        if file_content:
            question = "请用3-5句话总结这家医院的核心数据和特点。"
            result = analyze_with_kimi(file_content, question)
            if result:
                print("📊 快速分析结果:")
                print(result)
        
        cleanup_file(file_object.id)

def test_different_models():
    """测试不同模型的表现"""
    print("🧪 测试不同Kimi模型的表现")
    print("-" * 40)
    
    json_file_path = "/Users/plutoguo/Desktop/All code/API KEY/Kimi XunDoc/jmed_data.json"
    models = ["moonshot-v1-8k", "moonshot-v1-128k"]
    
    file_object = upload_file_to_kimi(json_file_path)
    if not file_object:
        return
        
    file_content = get_file_content(file_object.id)
    if not file_content:
        return
    
    question = "请分析医院各科室的患者数量和成功率，找出表现最好的科室。"
    
    for model in models:
        print(f"🤖 测试模型: {model}")
        result = analyze_with_kimi(file_content, question, model)
        if result:
            print(f"结果长度: {len(result)} 字符")
            print(f"结果预览: {result[:200]}...")
        print("-" * 30)
    
    cleanup_file(file_object.id)

def main():
    """主函数 - 自动运行完整演示"""
    print("🎯 自动运行完整的Kimi API + JSON数据分析演示")
    print("=" * 60)
    
    try:
        # 运行完整分析演示
        comprehensive_analysis_demo()
        
        print("\n" + "🔄" * 20 + "\n")
        
        # 运行简化版演示
        simple_json_analysis_demo()
            
    except KeyboardInterrupt:
        print("\n👋 用户取消操作")
    except Exception as e:
        print(f"❌ 运行出错: {e}")

if __name__ == "__main__":
    main()

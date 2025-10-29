#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
多文件医学数据分析系统
支持处理 jmed_chat_format.jsonl, jmed_eval.json, jmed_raw.json 三种格式
"""

import os
import json
from openai import OpenAI
from pathlib import Path
import random
from typing import List, Dict, Any, Tuple

# API配置
API_KEY = "sk-wc9tcOA0q2ShfOjKZ91YStbbyyoMGpiegf6zq54i9kpaQtke"

client = OpenAI(
    api_key=API_KEY,
    base_url="https://api.moonshot.cn/v1",
)

class JmedDataProcessor:
    """医学数据处理器"""
    
    def __init__(self, data_dir="/Users/plutoguo/Desktop/All code/API KEY/Kimi XunDoc/jmed_data"):
        self.data_dir = data_dir
        self.files = {
            'chat_format': os.path.join(data_dir, 'jmed_chat_format.jsonl'),
            'eval': os.path.join(data_dir, 'jmed_eval.json'),
            'raw': os.path.join(data_dir, 'jmed_raw.json')
        }
    
    def load_chat_format_data(self, limit=None):
        """加载对话格式数据(.jsonl文件)"""
        print(f"🔄 正在加载对话格式数据: {self.files['chat_format']}")
        data = []
        try:
            with open(self.files['chat_format'], 'r', encoding='utf-8') as f:
                for i, line in enumerate(f):
                    if limit and i >= limit:
                        break
                    line = line.strip()
                    if line:
                        data.append(json.loads(line))
            print(f"✅ 成功加载 {len(data)} 条对话数据")
            return data
        except Exception as e:
            print(f"❌ 加载对话格式数据失败: {e}")
            return []
    
    def load_eval_data(self, limit=None):
        """加载评估数据"""
        print(f"🔄 正在加载评估数据: {self.files['eval']}")
        try:
            with open(self.files['eval'], 'r', encoding='utf-8') as f:
                data = json.load(f)
            if limit:
                data = data[:limit]
            print(f"✅ 成功加载 {len(data)} 条评估数据")
            return data
        except Exception as e:
            print(f"❌ 加载评估数据失败: {e}")
            return []
    
    def load_raw_data(self, limit=None):
        """加载原始数据"""
        print(f"🔄 正在加载原始数据: {self.files['raw']}")
        try:
            with open(self.files['raw'], 'r', encoding='utf-8') as f:
                data = json.load(f)
            if limit:
                data = data[:limit]
            print(f"✅ 成功加载 {len(data)} 条原始数据")
            return data
        except Exception as e:
            print(f"❌ 加载原始数据失败: {e}")
            return []
    
    def analyze_data_structure(self):
        """分析数据结构"""
        print("=" * 60)
        print("📊 医学数据结构分析")
        print("=" * 60)
        
        # 分析对话格式数据
        chat_data = self.load_chat_format_data(limit=3)
        if chat_data:
            print("\n🗣️ 对话格式数据结构:")
            print(f"   - 总条数: ~1001条")
            print(f"   - 格式: 每条包含messages字段")
            print(f"   - 内容: 医学问答对话")
            print(f"   - 示例: {chat_data[0]['messages'][0]['content'][:100]}...")
        
        # 分析评估数据
        eval_data = self.load_eval_data(limit=3)
        if eval_data:
            print(f"\n📋 评估数据结构:")
            print(f"   - 总条数: {len(eval_data)}条")
            print(f"   - 格式: 包含id, question, options, answer字段")
            print(f"   - 内容: 医学多选题")
            print(f"   - 示例: {eval_data[0]['question'][:100]}...")
        
        # 分析原始数据
        raw_data = self.load_raw_data(limit=3)
        if raw_data:
            print(f"\n📄 原始数据结构:")
            print(f"   - 总条数: {len(raw_data)}条")
            print(f"   - 格式: 包含id, question, options字段")
            print(f"   - 内容: 医学题库原始数据")
            print(f"   - 示例: {raw_data[0]['question'][:100]}...")
        
        return chat_data, eval_data, raw_data

class KimiAnalyzer:
    """Kimi API分析器"""
    
    def __init__(self):
        self.uploaded_files = {}
    
    def upload_data_to_kimi(self, data, filename, data_type="medical"):
        """上传数据到Kimi"""
        try:
            # 创建临时文件
            temp_file = f"/tmp/{filename}"
            
            if filename.endswith('.jsonl'):
                with open(temp_file, 'w', encoding='utf-8') as f:
                    for item in data:
                        f.write(json.dumps(item, ensure_ascii=False) + '\n')
            else:
                with open(temp_file, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
            
            print(f"🚀 正在上传 {filename} 到Kimi...")
            file_object = client.files.create(file=Path(temp_file), purpose="file-extract")
            
            # 获取文件内容
            file_content = client.files.content(file_id=file_object.id).text
            
            self.uploaded_files[filename] = {
                'file_id': file_object.id,
                'content': file_content,
                'data_type': data_type
            }
            
            print(f"✅ {filename} 上传成功，ID: {file_object.id}")
            
            # 清理临时文件
            os.remove(temp_file)
            
            return file_object.id, file_content
            
        except Exception as e:
            print(f"❌ 上传 {filename} 失败: {e}")
            return None, None
    
    def analyze_medical_data(self, file_content, analysis_question, filename=""):
        """分析医学数据"""
        try:
            print(f"🤖 正在分析医学数据 {filename}...")
            
            system_prompt = f"""你是一位资深的医学数据分析专家和临床医生。请基于提供的医学数据进行专业分析。

数据文件: {filename}
分析任务: {analysis_question}

请提供详细、专业的医学分析，包括：
1. 数据概况和特点
2. 医学知识点分布
3. 临床意义和应用价值
4. 数据质量评估
5. 改进建议

文件内容：
{file_content[:8000]}  # 限制长度避免token超限
"""
            
            completion = client.chat.completions.create(
                model="moonshot-v1-128k",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": analysis_question}
                ],
                temperature=0.3,
            )
            
            return completion.choices[0].message.content
            
        except Exception as e:
            print(f"❌ 分析失败: {e}")
            return None
    
    def stream_analysis(self, file_content, analysis_question, filename=""):
        """流式分析医学数据"""
        try:
            print(f"🌊 正在流式分析 {filename}...")
            
            system_prompt = f"""你是一位资深的医学数据分析专家。请基于医学数据文件进行专业分析。

文件: {filename}
任务: {analysis_question}

文件内容：
{file_content[:8000]}
"""
            
            stream = client.chat.completions.create(
                model="moonshot-v1-128k",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": analysis_question}
                ],
                temperature=0.3,
                stream=True,
            )
            
            print("📝 分析结果:")
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
    
    def cleanup_files(self):
        """清理上传的文件"""
        for filename, file_info in self.uploaded_files.items():
            try:
                client.files.delete(file_id=file_info['file_id'])
                print(f"🗑️ 已清理文件: {filename}")
            except Exception as e:
                print(f"⚠️ 清理文件失败 {filename}: {e}")

def comprehensive_medical_analysis():
    """综合医学数据分析"""
    print("=" * 60)
    print("🏥 综合医学数据分析系统")
    print("=" * 60)
    
    # 初始化处理器
    processor = JmedDataProcessor()
    analyzer = KimiAnalyzer()
    
    # 第一步：分析数据结构
    chat_data, eval_data, raw_data = processor.analyze_data_structure()
    
    # 第二步：准备分析数据（取样本避免数据过大）
    analysis_data = {
        'chat_format': chat_data[:50] if chat_data else [],  # 取50个样本
        'eval': eval_data[:100] if eval_data else [],        # 取100个样本  
        'raw': raw_data[:100] if raw_data else []            # 取100个样本
    }
    
    # 第三步：上传数据到Kimi
    print("\n" + "=" * 60)
    print("📤 上传数据到Kimi进行分析")
    print("=" * 60)
    
    uploaded_contents = {}
    
    for data_type, data in analysis_data.items():
        if data:
            filename = f"jmed_{data_type}_sample.{'jsonl' if data_type == 'chat_format' else 'json'}"
            file_id, file_content = analyzer.upload_data_to_kimi(data, filename, data_type)
            if file_content:
                uploaded_contents[data_type] = {
                    'content': file_content,
                    'filename': filename
                }
    
    # 第四步：进行多维度分析
    analysis_questions = [
        "请分析这些医学数据的整体特点，包括涉及的疾病类型、症状分布和诊断模式。",
        "从临床教学角度，评估这些数据的教育价值和知识点覆盖范围。",
        "分析数据中常见的诊断类别，识别高频疾病和症状组合。",
        "评估数据质量，包括问题设计的合理性和答案的准确性。"
    ]
    
    print("\n" + "=" * 60)
    print("🔍 开始多维度医学数据分析")
    print("=" * 60)
    
    for i, question in enumerate(analysis_questions, 1):
        print(f"\n📋 分析维度 {i}: {question}")
        print("-" * 50)
        
        # 选择一个数据集进行分析（轮换使用）
        data_types = list(uploaded_contents.keys())
        if data_types:
            selected_type = data_types[(i-1) % len(data_types)]
            content_info = uploaded_contents[selected_type]
            
            if i == 1:
                # 第一个问题使用流式输出
                analyzer.stream_analysis(
                    content_info['content'], 
                    question, 
                    content_info['filename']
                )
            else:
                # 其他问题使用普通输出
                result = analyzer.analyze_medical_data(
                    content_info['content'], 
                    question, 
                    content_info['filename']
                )
                if result:
                    print("📝 分析结果:")
                    print(result)
        
        print("\n" + "=" * 60)
    
    # 第五步：生成综合报告
    print("\n🎯 生成综合分析报告")
    print("-" * 40)
    
    if uploaded_contents:
        # 使用第一个可用的数据集生成综合报告
        first_type = list(uploaded_contents.keys())[0]
        content_info = uploaded_contents[first_type]
        
        comprehensive_question = """基于这些医学数据，请生成一份综合分析报告，包括：
1. 数据集概况和规模
2. 主要疾病类别分布
3. 临床应用价值评估
4. 数据质量和完整性分析
5. 对医学教育和临床实践的建议
6. 未来改进方向"""
        
        result = analyzer.analyze_medical_data(
            content_info['content'], 
            comprehensive_question, 
            "综合医学数据"
        )
        if result:
            print("📊 综合分析报告:")
            print(result)
    
    # 第六步：清理资源
    analyzer.cleanup_files()
    
    print("\n" + "🎉" * 20)
    print("医学数据分析完成！")
    print("🎉" * 20)

def quick_sample_analysis():
    """快速样本分析"""
    print("🚀 快速医学数据样本分析")
    print("-" * 40)
    
    processor = JmedDataProcessor()
    analyzer = KimiAnalyzer()
    
    # 加载小样本数据
    chat_sample = processor.load_chat_format_data(limit=5)
    
    if chat_sample:
        # 上传样本
        file_id, file_content = analyzer.upload_data_to_kimi(
            chat_sample, 
            "quick_sample.jsonl", 
            "chat_format"
        )
        
        if file_content:
            # 快速分析
            question = "请快速总结这些医学对话数据的特点和主要内容。"
            result = analyzer.analyze_medical_data(file_content, question, "快速样本")
            
            if result:
                print("📊 快速分析结果:")
                print(result)
        
        # 清理
        analyzer.cleanup_files()

def main():
    """主函数"""
    print("🎯 医学数据分析系统")
    print("=" * 40)
    print("自动运行综合分析...")
    
    try:
        # 运行综合分析
        comprehensive_medical_analysis()
        
        print("\n" + "🔄" * 20 + "\n")
        
        # 运行快速分析
        quick_sample_analysis()
        
    except KeyboardInterrupt:
        print("\n👋 用户取消操作")
    except Exception as e:
        print(f"❌ 运行出错: {e}")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kimi微调数据生成器
基于现有医学数据生成适用于模型微调的高质量数据集
支持多种格式转换和QA对生成
"""

import os
import json
import random
from openai import OpenAI
from pathlib import Path
from typing import List, Dict, Any, Tuple
from datetime import datetime

# API配置
API_KEY = "sk-wc9tcOA0q2ShfOjKZ91YStbbyyoMGpiegf6zq54i9kpaQtke"

client = OpenAI(
    api_key=API_KEY,
    base_url="https://api.moonshot.cn/v1",
)

class MedicalDataConverter:
    """医学数据格式转换器"""
    
    def __init__(self, data_dir="/Users/plutoguo/Desktop/All code/API KEY/Kimi XunDoc/jmed_data"):
        self.data_dir = data_dir
        self.output_dir = os.path.join(data_dir, "finetuning_data")
        os.makedirs(self.output_dir, exist_ok=True)
    
    def load_chat_format_data(self, limit=None):
        """加载对话格式数据"""
        chat_file = os.path.join(self.data_dir, "jmed_chat_format.jsonl")
        data = []
        
        try:
            with open(chat_file, 'r', encoding='utf-8') as f:
                for i, line in enumerate(f):
                    if limit and i >= limit:
                        break
                    line = line.strip()
                    if line:
                        data.append(json.loads(line))
            print(f"✅ 加载了 {len(data)} 条对话数据")
            return data
        except Exception as e:
            print(f"❌ 加载对话数据失败: {e}")
            return []
    
    def load_eval_data(self, limit=None):
        """加载评估数据"""
        eval_file = os.path.join(self.data_dir, "jmed_eval.json")
        try:
            with open(eval_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            if limit:
                data = data[:limit]
            print(f"✅ 加载了 {len(data)} 条评估数据")
            return data
        except Exception as e:
            print(f"❌ 加载评估数据失败: {e}")
            return []
    
    def convert_to_alpaca_format(self, chat_data):
        """转换为Alpaca格式"""
        print("🔄 转换为Alpaca格式...")
        alpaca_data = []
        
        for item in chat_data:
            if "messages" in item:
                messages = item["messages"]
                if len(messages) >= 2:
                    user_msg = messages[0]["content"] if messages[0]["role"] == "user" else ""
                    assistant_msg = messages[1]["content"] if messages[1]["role"] == "assistant" else ""
                    
                    # 提取指令和输入
                    if "以下是一道医学多选题" in user_msg:
                        instruction = "请分析医学多选题并给出正确答案和解释。"
                        input_text = user_msg.replace("以下是一道医学多选题，请仔细分析后选择正确答案：\n\n", "")
                        output_text = assistant_msg
                    else:
                        instruction = "请回答医学相关问题。"
                        input_text = user_msg
                        output_text = assistant_msg
                    
                    alpaca_item = {
                        "instruction": instruction,
                        "input": input_text,
                        "output": output_text
                    }
                    alpaca_data.append(alpaca_item)
        
        print(f"✅ 转换了 {len(alpaca_data)} 条Alpaca格式数据")
        return alpaca_data
    
    def convert_to_conversation_format(self, chat_data):
        """转换为对话格式"""
        print("🔄 转换为对话格式...")
        conversation_data = []
        
        for item in chat_data:
            if "messages" in item:
                conversation_item = {
                    "messages": item["messages"]
                }
                conversation_data.append(conversation_item)
        
        print(f"✅ 转换了 {len(conversation_data)} 条对话格式数据")
        return conversation_data
    
    def save_as_jsonl(self, data, filename):
        """保存为JSONL格式"""
        filepath = os.path.join(self.output_dir, filename)
        with open(filepath, 'w', encoding='utf-8') as f:
            for item in data:
                f.write(json.dumps(item, ensure_ascii=False) + '\n')
        print(f"💾 保存了 {len(data)} 条数据到: {filepath}")
        return filepath

class QAGenerator:
    """基于Kimi API的QA对生成器"""
    
    def __init__(self):
        self.generated_qa = []
    
    def generate_qa_from_medical_case(self, case_text, num_questions=3):
        """从医学案例生成QA对"""
        try:
            system_prompt = """你是一位资深的医学教育专家。请基于提供的医学案例生成高质量的问答对，用于医学教育和模型训练。

要求：
1. 生成多个不同角度的问题（症状分析、诊断思路、鉴别诊断、治疗方案等）
2. 每个问题都要有详细、准确的答案
3. 问题应该具有教育价值，帮助医学生理解临床思维
4. 答案要包含医学原理和临床经验

请以JSON格式返回，包含questions数组，每个问题包含question和answer字段。"""

            user_prompt = f"""请基于以下医学案例生成 {num_questions} 个高质量的问答对：

{case_text}

请确保问题涵盖不同的医学角度，答案详细且具有教育价值。"""

            completion = client.chat.completions.create(
                model="moonshot-v1-128k",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.7,
                response_format={"type": "json_object"}
            )
            
            result = json.loads(completion.choices[0].message.content)
            return result.get("questions", [])
            
        except Exception as e:
            print(f"❌ 生成QA对失败: {e}")
            return []
    
    def generate_enhanced_medical_qa(self, original_data, enhancement_types=None):
        """生成增强的医学QA对"""
        if enhancement_types is None:
            enhancement_types = [
                "症状分析", "鉴别诊断", "治疗方案", 
                "病理机制", "预后评估", "预防措施"
            ]
        
        enhanced_qa = []
        
        for i, item in enumerate(original_data[:10]):  # 限制数量避免API费用过高
            print(f"🔄 正在处理第 {i+1}/{min(10, len(original_data))} 个案例...")
            
            if "messages" in item:
                user_content = item["messages"][0]["content"]
                
                # 提取医学案例文本
                if "患者" in user_content:
                    case_start = user_content.find("患者")
                    case_end = user_content.find("根据患者的症状")
                    if case_start != -1 and case_end != -1:
                        case_text = user_content[case_start:case_end].strip()
                    else:
                        case_text = user_content[:500]  # 取前500字符
                    
                    # 生成QA对
                    qa_pairs = self.generate_qa_from_medical_case(case_text, num_questions=3)
                    
                    for qa in qa_pairs:
                        enhanced_item = {
                            "instruction": "请回答以下医学问题。",
                            "input": qa.get("question", ""),
                            "output": qa.get("answer", ""),
                            "source": f"enhanced_case_{i+1}",
                            "category": "medical_education"
                        }
                        enhanced_qa.append(enhanced_item)
        
        print(f"✅ 生成了 {len(enhanced_qa)} 条增强QA对")
        return enhanced_qa
    
    def create_domain_specific_qa(self, domain="医学诊断"):
        """创建特定领域的QA对"""
        try:
            system_prompt = f"""你是一位{domain}专家。请生成一系列高质量的问答对，用于训练专业的AI助手。

要求：
1. 问题要覆盖{domain}的核心知识点
2. 答案要准确、详细、具有实用价值
3. 包含不同难度级别的问题
4. 问题要具有实际应用价值

请生成10个问答对，以JSON格式返回。"""

            completion = client.chat.completions.create(
                model="moonshot-v1-128k",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"请生成关于{domain}的专业问答对"}
                ],
                temperature=0.7,
                response_format={"type": "json_object"}
            )
            
            result = json.loads(completion.choices[0].message.content)
            questions = result.get("questions", [])
            
            domain_qa = []
            for qa in questions:
                domain_item = {
                    "instruction": f"请回答关于{domain}的问题。",
                    "input": qa.get("question", ""),
                    "output": qa.get("answer", ""),
                    "source": f"domain_{domain}",
                    "category": domain
                }
                domain_qa.append(domain_item)
            
            print(f"✅ 生成了 {len(domain_qa)} 条{domain}专业QA对")
            return domain_qa
            
        except Exception as e:
            print(f"❌ 生成{domain}QA对失败: {e}")
            return []

class FineTuningDataPipeline:
    """微调数据处理管道"""
    
    def __init__(self):
        self.converter = MedicalDataConverter()
        self.qa_generator = QAGenerator()
        self.output_dir = self.converter.output_dir
    
    def create_comprehensive_dataset(self):
        """创建综合微调数据集"""
        print("=" * 60)
        print("🚀 开始创建微调数据集")
        print("=" * 60)
        
        all_training_data = []
        
        # 1. 加载和转换现有数据
        print("\n📥 步骤1: 加载现有医学数据")
        chat_data = self.converter.load_chat_format_data(limit=100)  # 限制数量
        
        if chat_data:
            # 转换为Alpaca格式
            alpaca_data = self.converter.convert_to_alpaca_format(chat_data)
            all_training_data.extend(alpaca_data)
            
            # 保存Alpaca格式数据
            self.converter.save_as_jsonl(alpaca_data, "medical_alpaca_format.jsonl")
            
            # 转换为对话格式
            conversation_data = self.converter.convert_to_conversation_format(chat_data)
            self.converter.save_as_jsonl(conversation_data, "medical_conversation_format.jsonl")
        
        # 2. 生成增强QA对
        print("\n🎯 步骤2: 生成增强医学QA对")
        if chat_data:
            enhanced_qa = self.qa_generator.generate_enhanced_medical_qa(chat_data[:5])  # 限制数量
            all_training_data.extend(enhanced_qa)
            
            if enhanced_qa:
                self.converter.save_as_jsonl(enhanced_qa, "enhanced_medical_qa.jsonl")
        
        # 3. 生成领域专业QA对
        print("\n🏥 步骤3: 生成专业领域QA对")
        domains = ["医学诊断", "临床治疗", "病理分析"]
        
        for domain in domains:
            domain_qa = self.qa_generator.create_domain_specific_qa(domain)
            all_training_data.extend(domain_qa)
            
            if domain_qa:
                safe_domain = domain.replace("/", "_")
                self.converter.save_as_jsonl(domain_qa, f"{safe_domain}_qa.jsonl")
        
        # 4. 创建综合训练集
        print("\n📊 步骤4: 创建最终训练数据集")
        if all_training_data:
            # 打乱数据
            random.shuffle(all_training_data)
            
            # 分割训练集和验证集
            split_idx = int(len(all_training_data) * 0.8)
            train_data = all_training_data[:split_idx]
            val_data = all_training_data[split_idx:]
            
            # 保存训练集和验证集
            train_file = self.converter.save_as_jsonl(train_data, "medical_finetune_train.jsonl")
            val_file = self.converter.save_as_jsonl(val_data, "medical_finetune_val.jsonl")
            
            # 生成数据集统计
            self.generate_dataset_stats(all_training_data)
            
            print(f"\n✅ 微调数据集创建完成!")
            print(f"📁 输出目录: {self.output_dir}")
            print(f"📊 训练集: {len(train_data)} 条")
            print(f"📊 验证集: {len(val_data)} 条")
            print(f"📊 总计: {len(all_training_data)} 条")
            
            return train_file, val_file
        
        return None, None
    
    def generate_dataset_stats(self, data):
        """生成数据集统计信息"""
        stats = {
            "total_samples": len(data),
            "categories": {},
            "sources": {},
            "avg_input_length": 0,
            "avg_output_length": 0,
            "created_at": datetime.now().isoformat()
        }
        
        input_lengths = []
        output_lengths = []
        
        for item in data:
            # 统计类别
            category = item.get("category", "unknown")
            stats["categories"][category] = stats["categories"].get(category, 0) + 1
            
            # 统计来源
            source = item.get("source", "original")
            stats["sources"][source] = stats["sources"].get(source, 0) + 1
            
            # 统计长度
            input_len = len(item.get("input", ""))
            output_len = len(item.get("output", ""))
            input_lengths.append(input_len)
            output_lengths.append(output_len)
        
        stats["avg_input_length"] = sum(input_lengths) / len(input_lengths) if input_lengths else 0
        stats["avg_output_length"] = sum(output_lengths) / len(output_lengths) if output_lengths else 0
        
        # 保存统计信息
        stats_file = os.path.join(self.output_dir, "dataset_stats.json")
        with open(stats_file, 'w', encoding='utf-8') as f:
            json.dump(stats, f, ensure_ascii=False, indent=2)
        
        print(f"📈 数据集统计已保存: {stats_file}")
        return stats

def create_llamafactory_config():
    """创建LLaMA-Factory配置文件示例"""
    config = {
        "model_name_or_path": "moonshot-v1-8k",  # 假设的模型路径
        "finetuning_type": "lora",
        "dataset_dir": "./jmed_data/finetuning_data",
        "dataset": "medical_finetune",
        "cutoff_len": 1024,
        "learning_rate": 5e-5,
        "num_train_epochs": 3,
        "max_samples": 1000,
        "per_device_train_batch_size": 2,
        "gradient_accumulation_steps": 4,
        "lr_scheduler_type": "cosine",
        "max_grad_norm": 1.0,
        "logging_steps": 10,
        "save_steps": 500,
        "warmup_steps": 100,
        "lora_rank": 8,
        "lora_alpha": 32,
        "lora_dropout": 0.1,
        "output_dir": "./saves/medical-kimi-lora",
        "fp16": True,
        "plot_loss": True
    }
    
    config_file = "/Users/plutoguo/Desktop/All code/API KEY/Kimi XunDoc/jmed_data/finetuning_data/llamafactory_config.json"
    with open(config_file, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2)
    
    print(f"📝 LLaMA-Factory配置文件已创建: {config_file}")
    return config_file

def main():
    """主函数"""
    print("🎯 Kimi微调数据生成器")
    print("=" * 40)
    
    try:
        # 创建数据处理管道
        pipeline = FineTuningDataPipeline()
        
        # 生成综合数据集
        train_file, val_file = pipeline.create_comprehensive_dataset()
        
        if train_file and val_file:
            # 创建配置文件
            config_file = create_llamafactory_config()
            
            print("\n" + "🎉" * 20)
            print("微调数据准备完成！")
            print("🎉" * 20)
            
            print(f"\n📋 下一步操作建议:")
            print(f"1. 检查生成的数据文件质量")
            print(f"2. 根据需要调整LLaMA-Factory配置")
            print(f"3. 准备GPU环境进行微调训练")
            print(f"4. 监控训练过程和效果评估")
            
        else:
            print("❌ 数据集创建失败，请检查源数据文件")
            
    except Exception as e:
        print(f"❌ 运行出错: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()


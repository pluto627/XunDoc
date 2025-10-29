#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简化版Kimi微调数据生成器
专注于核心功能：数据格式转换和QA对生成
"""

import os
import json
import random
from openai import OpenAI
from datetime import datetime

# API配置
API_KEY = "sk-wc9tcOA0q2ShfOjKZ91YStbbyyoMGpiegf6zq54i9kpaQtke"

client = OpenAI(
    api_key=API_KEY,
    base_url="https://api.moonshot.cn/v1",
)

def load_medical_data():
    """加载医学数据"""
    print("📥 正在加载医学数据...")
    
    # 加载对话格式数据
    chat_file = "jmed_data/jmed_chat_format.jsonl"
    chat_data = []
    
    try:
        with open(chat_file, 'r', encoding='utf-8') as f:
            for i, line in enumerate(f):
                if i >= 20:  # 只取前20条作为示例
                    break
                line = line.strip()
                if line:
                    chat_data.append(json.loads(line))
        print(f"✅ 加载了 {len(chat_data)} 条对话数据")
    except Exception as e:
        print(f"❌ 加载对话数据失败: {e}")
    
    return chat_data

def convert_to_alpaca_format(chat_data):
    """转换为Alpaca格式"""
    print("🔄 转换为Alpaca格式...")
    alpaca_data = []
    
    for i, item in enumerate(chat_data):
        if "messages" in item and len(item["messages"]) >= 2:
            user_msg = item["messages"][0]["content"]
            assistant_msg = item["messages"][1]["content"]
            
            # 处理医学多选题
            if "以下是一道医学多选题" in user_msg:
                instruction = "请分析医学多选题并给出正确答案和详细解释。"
                # 提取题目内容
                input_text = user_msg.replace("以下是一道医学多选题，请仔细分析后选择正确答案：\n\n", "")
                output_text = assistant_msg
            else:
                instruction = "请回答医学相关问题。"
                input_text = user_msg
                output_text = assistant_msg
            
            alpaca_item = {
                "instruction": instruction,
                "input": input_text[:1000],  # 限制长度
                "output": output_text,
                "id": f"medical_{i+1}",
                "source": "jmed_chat_format"
            }
            alpaca_data.append(alpaca_item)
    
    print(f"✅ 转换了 {len(alpaca_data)} 条Alpaca格式数据")
    return alpaca_data

def generate_enhanced_qa(sample_case):
    """生成增强的QA对"""
    try:
        print("🤖 正在生成增强QA对...")
        
        system_prompt = """你是一位资深的医学教育专家。请基于提供的医学案例生成3个不同角度的问答对。

要求：
1. 问题要有教育价值，涵盖症状分析、诊断思路、治疗建议等角度
2. 答案要详细、准确，包含医学原理
3. 以JSON格式返回，包含questions数组

示例格式：
{
  "questions": [
    {
      "question": "问题1",
      "answer": "详细答案1"
    }
  ]
}"""

        # 提取案例文本
        if "患者" in sample_case:
            case_start = sample_case.find("患者")
            case_end = sample_case.find("根据患者的症状")
            if case_start != -1 and case_end != -1:
                case_text = sample_case[case_start:case_end].strip()
            else:
                case_text = sample_case[:800]
        else:
            case_text = sample_case[:800]

        user_prompt = f"请基于以下医学案例生成3个教育性问答对：\n\n{case_text}"

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
        questions = result.get("questions", [])
        
        enhanced_data = []
        for i, qa in enumerate(questions):
            enhanced_item = {
                "instruction": "请回答以下医学教育问题。",
                "input": qa.get("question", ""),
                "output": qa.get("answer", ""),
                "id": f"enhanced_{i+1}",
                "source": "kimi_generated"
            }
            enhanced_data.append(enhanced_item)
        
        print(f"✅ 生成了 {len(enhanced_data)} 条增强QA对")
        return enhanced_data
        
    except Exception as e:
        print(f"❌ 生成增强QA对失败: {e}")
        return []

def create_domain_qa():
    """创建领域专业QA对"""
    try:
        print("🏥 正在生成专业领域QA对...")
        
        system_prompt = """你是一位医学诊断专家。请生成5个关于医学诊断的专业问答对。

要求：
1. 问题要涵盖不同的诊断场景
2. 答案要包含诊断思路和临床经验
3. 具有实用价值
4. 以JSON格式返回

示例格式：
{
  "questions": [
    {
      "question": "如何鉴别诊断急性腹痛？",
      "answer": "急性腹痛的鉴别诊断需要..."
    }
  ]
}"""

        completion = client.chat.completions.create(
            model="moonshot-v1-128k",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": "请生成5个医学诊断专业问答对"}
            ],
            temperature=0.7,
            response_format={"type": "json_object"}
        )
        
        result = json.loads(completion.choices[0].message.content)
        questions = result.get("questions", [])
        
        domain_data = []
        for i, qa in enumerate(questions):
            domain_item = {
                "instruction": "请回答医学诊断专业问题。",
                "input": qa.get("question", ""),
                "output": qa.get("answer", ""),
                "id": f"domain_{i+1}",
                "source": "domain_expert"
            }
            domain_data.append(domain_item)
        
        print(f"✅ 生成了 {len(domain_data)} 条专业QA对")
        return domain_data
        
    except Exception as e:
        print(f"❌ 生成专业QA对失败: {e}")
        return []

def save_jsonl(data, filename):
    """保存为JSONL格式"""
    os.makedirs("finetuning_output", exist_ok=True)
    filepath = f"finetuning_output/{filename}"
    
    with open(filepath, 'w', encoding='utf-8') as f:
        for item in data:
            f.write(json.dumps(item, ensure_ascii=False) + '\n')
    
    print(f"💾 保存了 {len(data)} 条数据到: {filepath}")
    return filepath

def generate_stats(all_data):
    """生成数据统计"""
    stats = {
        "total_samples": len(all_data),
        "sources": {},
        "avg_input_length": 0,
        "avg_output_length": 0,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    
    input_lengths = []
    output_lengths = []
    
    for item in all_data:
        source = item.get("source", "unknown")
        stats["sources"][source] = stats["sources"].get(source, 0) + 1
        
        input_len = len(item.get("input", ""))
        output_len = len(item.get("output", ""))
        input_lengths.append(input_len)
        output_lengths.append(output_len)
    
    if input_lengths:
        stats["avg_input_length"] = sum(input_lengths) / len(input_lengths)
        stats["avg_output_length"] = sum(output_lengths) / len(output_lengths)
    
    # 保存统计
    with open("finetuning_output/dataset_stats.json", 'w', encoding='utf-8') as f:
        json.dump(stats, f, ensure_ascii=False, indent=2)
    
    return stats

def create_llamafactory_config():
    """创建LLaMA-Factory配置示例"""
    config = {
        "model_name_or_path": "moonshot-v1-8k",
        "finetuning_type": "lora",
        "dataset_dir": "./finetuning_output",
        "dataset": "medical_finetune_train",
        "cutoff_len": 1024,
        "learning_rate": 5e-5,
        "num_train_epochs": 3,
        "per_device_train_batch_size": 2,
        "gradient_accumulation_steps": 4,
        "lora_rank": 8,
        "lora_alpha": 32,
        "lora_dropout": 0.1,
        "output_dir": "./saves/medical-kimi-lora",
        "fp16": True,
        "plot_loss": True
    }
    
    with open("finetuning_output/llamafactory_config.json", 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2)
    
    print("📝 LLaMA-Factory配置文件已创建")

def main():
    """主函数"""
    print("🎯 简化版Kimi微调数据生成器")
    print("=" * 50)
    
    try:
        all_training_data = []
        
        # 1. 加载和转换现有数据
        chat_data = load_medical_data()
        if chat_data:
            alpaca_data = convert_to_alpaca_format(chat_data)
            all_training_data.extend(alpaca_data)
        
        # 2. 生成增强QA对（使用第一个案例）
        if chat_data and len(chat_data) > 0:
            sample_case = chat_data[0]["messages"][0]["content"]
            enhanced_qa = generate_enhanced_qa(sample_case)
            all_training_data.extend(enhanced_qa)
        
        # 3. 生成专业领域QA对
        domain_qa = create_domain_qa()
        all_training_data.extend(domain_qa)
        
        if all_training_data:
            # 打乱数据
            random.shuffle(all_training_data)
            
            # 分割训练集和验证集
            split_idx = int(len(all_training_data) * 0.8)
            train_data = all_training_data[:split_idx]
            val_data = all_training_data[split_idx:]
            
            # 保存数据
            train_file = save_jsonl(train_data, "medical_finetune_train.jsonl")
            val_file = save_jsonl(val_data, "medical_finetune_val.jsonl")
            save_jsonl(all_training_data, "medical_finetune_all.jsonl")
            
            # 生成统计和配置
            stats = generate_stats(all_training_data)
            create_llamafactory_config()
            
            print("\n" + "🎉" * 30)
            print("微调数据生成完成！")
            print("🎉" * 30)
            
            print(f"\n📊 数据统计:")
            print(f"   总样本数: {stats['total_samples']}")
            print(f"   训练集: {len(train_data)} 条")
            print(f"   验证集: {len(val_data)} 条")
            print(f"   平均输入长度: {stats['avg_input_length']:.1f} 字符")
            print(f"   平均输出长度: {stats['avg_output_length']:.1f} 字符")
            
            print(f"\n📁 输出文件:")
            print(f"   📄 {train_file}")
            print(f"   📄 {val_file}")
            print(f"   📊 finetuning_output/dataset_stats.json")
            print(f"   ⚙️ finetuning_output/llamafactory_config.json")
            
            print(f"\n🚀 下一步:")
            print(f"   1. 检查生成的数据质量")
            print(f"   2. 根据需要调整配置文件")
            print(f"   3. 使用LLaMA-Factory或其他框架进行微调")
            
        else:
            print("❌ 没有生成任何数据")
            
    except Exception as e:
        print(f"❌ 运行出错: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()


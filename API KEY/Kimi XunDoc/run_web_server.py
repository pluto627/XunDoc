#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kimi微调数据生成器 - Web服务器
提供HTML界面的本地服务器
"""

import http.server
import socketserver
import webbrowser
import os
import json
from pathlib import Path

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="/Users/plutoguo/Desktop/All code/API KEY/Kimi XunDoc", **kwargs)
    
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

def start_web_server(port=8000):
    """启动Web服务器"""
    try:
        with socketserver.TCPServer(("", port), CustomHTTPRequestHandler) as httpd:
            print("=" * 60)
            print("🚀 Kimi微调数据生成器 - Web服务器已启动")
            print("=" * 60)
            print(f"📡 服务器地址: http://localhost:{port}")
            print(f"📄 主页面: http://localhost:{port}/kimi_finetuning_web.html")
            print("=" * 60)
            print("💡 使用说明:")
            print("   1. 浏览器将自动打开主页面")
            print("   2. 按顺序点击按钮完成数据生成")
            print("   3. 最后可以下载生成的微调数据文件")
            print("   4. 按 Ctrl+C 停止服务器")
            print("=" * 60)
            
            # 自动打开浏览器
            url = f"http://localhost:{port}/kimi_finetuning_web.html"
            webbrowser.open(url)
            
            print(f"🌐 正在为您打开浏览器...")
            print(f"🎯 如果浏览器未自动打开，请手动访问: {url}")
            print()
            print("⏳ 服务器运行中... (按 Ctrl+C 停止)")
            
            # 启动服务器
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n\n🛑 服务器已停止")
    except Exception as e:
        print(f"❌ 启动服务器失败: {e}")

def check_files():
    """检查必要文件是否存在"""
    required_files = [
        "kimi_finetuning_web.html",
        "jmed_data/jmed_chat_format.jsonl"
    ]
    
    missing_files = []
    for file in required_files:
        if not os.path.exists(file):
            missing_files.append(file)
    
    if missing_files:
        print("❌ 缺少必要文件:")
        for file in missing_files:
            print(f"   - {file}")
        return False
    
    return True

def show_system_info():
    """显示系统信息"""
    print("🔍 系统信息:")
    print(f"   当前目录: {os.getcwd()}")
    print(f"   Python版本: {os.sys.version}")
    
    # 检查数据文件
    data_dir = "jmed_data"
    if os.path.exists(data_dir):
        files = os.listdir(data_dir)
        print(f"   数据文件: {len(files)} 个")
        for file in files:
            file_path = os.path.join(data_dir, file)
            if os.path.isfile(file_path):
                size = os.path.getsize(file_path)
                print(f"     - {file} ({size:,} 字节)")
    
    # 检查输出目录
    output_dir = "finetuning_output"
    if os.path.exists(output_dir):
        files = os.listdir(output_dir)
        print(f"   输出文件: {len(files)} 个")

def main():
    """主函数"""
    print("🎯 Kimi微调数据生成器 - Web服务器启动器")
    print()
    
    # 显示系统信息
    show_system_info()
    print()
    
    # 检查文件
    if not check_files():
        print("\n请确保所有必要文件都存在后再运行")
        return
    
    # 启动服务器
    try:
        start_web_server(port=8000)
    except OSError as e:
        if "Address already in use" in str(e):
            print("❌ 端口8000已被占用，尝试使用端口8001...")
            start_web_server(port=8001)
        else:
            print(f"❌ 启动失败: {e}")

if __name__ == "__main__":
    main()


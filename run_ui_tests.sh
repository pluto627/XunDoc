#!/bin/bash

# XunDoc UI 测试运行脚本
# 使用方法: ./run_ui_tests.sh

set -e

echo "=========================================="
echo "🔥 XunDoc UI 测试启动器"
echo "=========================================="
echo ""

# 1. 清理派生数据
echo "📦 步骤 1/5: 清理派生数据..."
rm -rf ~/Library/Developer/Xcode/DerivedData/XunDoc-*
echo "   ✓ 派生数据已清理"
echo ""

# 2. 清理构建
echo "🧹 步骤 2/5: 清理项目..."
cd /Users/plutoguo/Desktop/XunDoc
xcodebuild clean -project XunDoc.xcodeproj -scheme XunDoc > /dev/null 2>&1
echo "   ✓ 项目已清理"
echo ""

# 3. 启动模拟器
echo "📱 步骤 3/5: 准备模拟器..."
# 使用 iPhone 15 Pro 模拟器
SIMULATOR_NAME="iPhone 15 Pro"
SIMULATOR_ID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -v "unavailable" | head -n 1 | grep -oE '\(([A-F0-9-]+)\)' | tr -d '()')

if [ -z "$SIMULATOR_ID" ]; then
    echo "   ⚠️  未找到 $SIMULATOR_NAME 模拟器"
    echo "   使用第一个可用的 iPhone 模拟器..."
    SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -n 1 | grep -oE '\(([A-F0-9-]+)\)' | tr -d '()')
fi

echo "   使用模拟器: $SIMULATOR_ID"

# 关闭所有模拟器
xcrun simctl shutdown all > /dev/null 2>&1 || true

# 启动模拟器
xcrun simctl boot "$SIMULATOR_ID" > /dev/null 2>&1 || true
echo "   ✓ 模拟器已启动"
sleep 3
echo ""

# 4. 构建测试
echo "🔨 步骤 4/5: 构建测试..."
xcodebuild build-for-testing \
    -project XunDoc.xcodeproj \
    -scheme XunDoc \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -quiet
echo "   ✓ 构建完成"
echo ""

# 5. 运行测试
echo "🚀 步骤 5/5: 运行压力测试..."
echo "=========================================="
echo ""

xcodebuild test-without-building \
    -project XunDoc.xcodeproj \
    -scheme XunDoc \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:XunDocUITests/XunDocComprehensiveStressTests/testZZZ_RunAllStressTests

echo ""
echo "=========================================="
echo "✅ 测试完成！"
echo "=========================================="



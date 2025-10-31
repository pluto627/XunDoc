#!/bin/bash

# 超级简化的测试运行脚本
# 这个脚本会尝试用最简单的方式运行测试

echo "🚀 准备运行 XunDoc UI 测试..."
echo ""

# 进入项目目录
cd /Users/plutoguo/Desktop/XunDoc

# 查找第一个可用的 iPhone 模拟器
echo "📱 查找模拟器..."
SIMULATOR=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -n 1)
SIMULATOR_ID=$(echo "$SIMULATOR" | grep -oE '\([A-F0-9-]+\)' | tr -d '()')
SIMULATOR_NAME=$(echo "$SIMULATOR" | sed 's/.*iPhone/iPhone/' | sed 's/ (.*//g')

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ 未找到可用的 iPhone 模拟器"
    exit 1
fi

echo "   使用: $SIMULATOR_NAME"
echo ""

# 启动模拟器
echo "🔄 启动模拟器..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
open -a Simulator
sleep 3

# 构建项目
echo "🔨 构建项目..."
xcodebuild build \
    -project XunDoc.xcodeproj \
    -scheme XunDoc \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -quiet

echo "✅ 构建完成"
echo ""
echo "=========================================="
echo "⚠️  重要提示："
echo "=========================================="
echo ""
echo "命令行运行 UI 测试经常会出现 'IDE disconnection' 错误。"
echo ""
echo "🎯 推荐做法："
echo ""
echo "1. 保持模拟器开启（已经为你启动了）"
echo ""
echo "2. 在 Xcode 中："
echo "   - 按 ⌘+6 打开测试导航器"
echo "   - 找到 XunDocUITests → XunDocComprehensiveStressTests"
echo "   - 点击 test000_BasicConnectionTest 旁边的 ▶️"
echo ""
echo "3. 这样运行成功率最高！"
echo ""
echo "=========================================="
echo ""

# 尝试运行测试（但可能会失败）
echo "🔥 尝试运行测试（如果失败请在 Xcode 中手动运行）..."
echo ""

xcodebuild test \
    -project XunDoc.xcodeproj \
    -scheme XunDoc \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:XunDocUITests/XunDocComprehensiveStressTests/test000_BasicConnectionTest \
    2>&1 | grep -E "(Test|✓|✅|❌|passed|failed)" || echo "⚠️  命令行测试失败，请在 Xcode 中手动运行"



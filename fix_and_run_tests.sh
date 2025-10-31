#!/bin/bash

echo "=========================================="
echo "🔧 XunDoc 测试修复和运行脚本"
echo "=========================================="
echo ""

# 设置错误时退出
set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 关闭所有 Xcode 实例
echo "1️⃣  关闭 Xcode..."
killall Xcode 2>/dev/null || true
killall Simulator 2>/dev/null || true
sleep 2
echo -e "${GREEN}   ✓ Xcode 已关闭${NC}"
echo ""

# 2. 清理所有缓存
echo "2️⃣  清理缓存和派生数据..."
rm -rf ~/Library/Developer/Xcode/DerivedData/XunDoc-*
rm -rf ~/Library/Caches/com.apple.dt.Xcode
echo -e "${GREEN}   ✓ 缓存已清理${NC}"
echo ""

# 3. 重置模拟器
echo "3️⃣  重置模拟器..."
xcrun simctl shutdown all 2>/dev/null || true
sleep 2
echo -e "${GREEN}   ✓ 模拟器已重置${NC}"
echo ""

# 4. 清理项目
echo "4️⃣  清理项目..."
cd /Users/plutoguo/Desktop/XunDoc
xcodebuild clean -project XunDoc.xcodeproj -scheme XunDoc -quiet 2>/dev/null || true
echo -e "${GREEN}   ✓ 项目已清理${NC}"
echo ""

# 5. 找到可用的 iPhone 模拟器
echo "5️⃣  查找可用的模拟器..."
SIMULATOR_NAME="iPhone 17"
SIMULATOR_ID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | head -n 1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${YELLOW}   未找到 iPhone 17，尝试其他 iPhone...${NC}"
    SIMULATOR_NAME=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -n 1 | sed 's/.*name:\([^,]*\).*/\1/' | xargs)
    SIMULATOR_ID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | head -n 1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')
fi

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}   ✗ 未找到可用的 iPhone 模拟器${NC}"
    exit 1
fi

echo -e "${GREEN}   ✓ 使用模拟器: $SIMULATOR_NAME ($SIMULATOR_ID)${NC}"
echo ""

# 6. 启动模拟器
echo "6️⃣  启动模拟器..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
open -a Simulator
sleep 5
echo -e "${GREEN}   ✓ 模拟器已启动${NC}"
echo ""

# 7. 重新打开 Xcode
echo "7️⃣  重新打开 Xcode..."
open /Users/plutoguo/Desktop/XunDoc/XunDoc.xcodeproj
sleep 5
echo -e "${GREEN}   ✓ Xcode 已打开${NC}"
echo ""

echo "=========================================="
echo -e "${GREEN}✅ 准备完成！${NC}"
echo "=========================================="
echo ""
echo "📝 接下来请在 Xcode 中手动操作："
echo ""
echo "1. 等待 Xcode 完全加载（顶部状态栏显示 'Ready'）"
echo ""
echo "2. 按 ⌘+6 打开测试导航器"
echo ""
echo "3. 展开: XunDocUITests → XunDocComprehensiveStressTests"
echo ""
echo "4. 点击 test000_BasicConnectionTest 旁边的 ▶️ 按钮"
echo ""
echo "5. 等待测试运行（应该能看到模拟器启动应用）"
echo ""
echo "=========================================="
echo ""
echo "💡 提示："
echo "   - 如果仍然失败，请查看 '测试故障排除指南.md'"
echo "   - 或者运行: /Users/plutoguo/Desktop/XunDoc/run_simple_test.sh"
echo ""



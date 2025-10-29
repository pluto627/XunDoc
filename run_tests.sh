#!/bin/bash

# XunDoc 自动化测试运行脚本
# 使用方法: ./run_tests.sh [选项]

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="XunDoc"
SCHEME="XunDoc"
DEFAULT_DEVICE="iPhone 15 Pro"
DEFAULT_OS="17.0"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  XunDoc 自动化测试运行脚本${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "使用方法:"
    echo "  ./run_tests.sh [选项]"
    echo ""
    echo "选项:"
    echo "  -q, --quick       快速测试（仅核心功能）"
    echo "  -u, --ui          运行UI自动化测试"
    echo "  -a, --all         运行所有测试（单元测试 + UI测试）"
    echo "  -d, --device      指定设备（默认: iPhone 15 Pro）"
    echo "  -c, --clean       清理后重新测试"
    echo "  -r, --report      生成HTML测试报告"
    echo "  -h, --help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./run_tests.sh --quick              # 快速测试"
    echo "  ./run_tests.sh --ui --clean         # 清理后运行UI测试"
    echo "  ./run_tests.sh --all --report       # 运行所有测试并生成报告"
    echo "  ./run_tests.sh --device 'iPhone 14' # 在iPhone 14上测试"
    echo ""
}

# 显示横幅
show_banner() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}     🚀 XunDoc 自动化测试${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 检查环境
check_environment() {
    echo -e "${YELLOW}🔍 检查测试环境...${NC}"
    
    # 检查Xcode
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}❌ 错误: 未找到xcodebuild，请安装Xcode${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Xcode: $(xcodebuild -version | head -n 1)${NC}"
    
    # 检查项目文件
    if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
        echo -e "${RED}❌ 错误: 未找到项目文件${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 项目文件: ${PROJECT_NAME}.xcodeproj${NC}"
    echo ""
}

# 清理构建产物
clean_build() {
    echo -e "${YELLOW}🧹 清理构建产物...${NC}"
    rm -rf build/
    rm -rf DerivedData/
    rm -rf test_output/
    echo -e "${GREEN}✓ 清理完成${NC}"
    echo ""
}

# 运行快速测试
run_quick_test() {
    echo -e "${BLUE}⚡ 开始快速测试（核心功能）...${NC}"
    echo ""
    
    xcodebuild test \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -destination "platform=iOS Simulator,name=${DEVICE},OS=${DEFAULT_OS}" \
        -only-testing:XunDocUITests/XunDocAutomatedTests/test001_AppLaunch \
        -only-testing:XunDocUITests/XunDocAutomatedTests/test002_TabBarNavigation \
        -only-testing:XunDocUITests/XunDocAutomatedTests/test003_CreateHealthRecord \
        | xcpretty --color
    
    echo ""
    echo -e "${GREEN}✅ 快速测试完成！${NC}"
}

# 运行UI测试
run_ui_test() {
    echo -e "${BLUE}🎬 开始UI自动化测试...${NC}"
    echo -e "${YELLOW}设备: ${DEVICE}${NC}"
    echo ""
    
    xcodebuild test \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -destination "platform=iOS Simulator,name=${DEVICE},OS=${DEFAULT_OS}" \
        -only-testing:XunDocUITests \
        | xcpretty --color
    
    echo ""
    echo -e "${GREEN}✅ UI测试完成！${NC}"
}

# 运行所有测试
run_all_tests() {
    echo -e "${BLUE}🔬 开始运行所有测试...${NC}"
    echo ""
    
    xcodebuild test \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -destination "platform=iOS Simulator,name=${DEVICE},OS=${DEFAULT_OS}" \
        -enableCodeCoverage YES \
        | xcpretty --color
    
    echo ""
    echo -e "${GREEN}✅ 所有测试完成！${NC}"
}

# 生成测试报告
generate_report() {
    echo -e "${BLUE}📊 生成测试报告...${NC}"
    
    # 创建输出目录
    mkdir -p test_output
    
    # 查找最新的xcresult文件
    XCRESULT_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" -type d -print0 | xargs -0 ls -t | head -n 1)
    
    if [ -z "$XCRESULT_PATH" ]; then
        echo -e "${YELLOW}⚠️  未找到测试结果文件${NC}"
        return
    fi
    
    echo -e "${YELLOW}结果文件: ${XCRESULT_PATH}${NC}"
    
    # 生成JSON报告
    xcrun xcresulttool get --format json --path "${XCRESULT_PATH}" > test_output/results.json
    
    # 复制xcresult文件
    cp -r "${XCRESULT_PATH}" test_output/
    
    echo -e "${GREEN}✓ 报告已生成到 test_output/ 目录${NC}"
    echo ""
    
    # 打开报告
    echo -e "${YELLOW}📂 打开测试报告...${NC}"
    open "${XCRESULT_PATH}"
}

# 显示测试总结
show_summary() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ 测试执行完成！${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "测试设备: ${DEVICE}"
    echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    if [ "$GENERATE_REPORT" = true ]; then
        echo "📊 测试报告: test_output/"
    fi
    
    echo ""
}

# 主函数
main() {
    # 默认参数
    DEVICE="${DEFAULT_DEVICE}"
    TEST_TYPE="ui"
    CLEAN=false
    GENERATE_REPORT=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -q|--quick)
                TEST_TYPE="quick"
                shift
                ;;
            -u|--ui)
                TEST_TYPE="ui"
                shift
                ;;
            -a|--all)
                TEST_TYPE="all"
                shift
                ;;
            -d|--device)
                DEVICE="$2"
                shift 2
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -r|--report)
                GENERATE_REPORT=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 未知选项: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 显示横幅
    show_banner
    
    # 检查环境
    check_environment
    
    # 清理（如果需要）
    if [ "$CLEAN" = true ]; then
        clean_build
    fi
    
    # 运行测试
    case $TEST_TYPE in
        quick)
            run_quick_test
            ;;
        ui)
            run_ui_test
            ;;
        all)
            run_all_tests
            ;;
    esac
    
    # 生成报告（如果需要）
    if [ "$GENERATE_REPORT" = true ]; then
        generate_report
    fi
    
    # 显示总结
    show_summary
}

# 检查是否安装了xcpretty（用于美化输出）
if ! command -v xcpretty &> /dev/null; then
    echo -e "${YELLOW}💡 提示: 安装 xcpretty 可以获得更好的输出格式${NC}"
    echo -e "${YELLOW}   安装命令: sudo gem install xcpretty${NC}"
    echo ""
fi

# 运行主函数
main "$@"



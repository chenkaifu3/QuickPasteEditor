#!/bin/bash

# QuickPasteEditor 环境检查脚本
# 使用方法: ./check-environment.sh

echo "🔍 检查 QuickPasteEditor 构建环境..."
echo "========================================"

# 检查操作系统
echo "1. 检查操作系统版本..."
sw_vers
echo ""

# 检查Xcode命令行工具
echo "2. 检查Xcode命令行工具..."
if command -v xcode-select > /dev/null 2>&1; then
    xcode-select -p
    if [ $? -eq 0 ]; then
        echo "✅ Xcode命令行工具已安装"
    else
        echo "❌ Xcode命令行工具未安装或损坏"
        echo "   运行: xcode-select --install"
    fi
else
    echo "❌ xcode-select 命令未找到"
fi
echo ""

# 检查Swift编译器
echo "3. 检查Swift编译器..."
if command -v swift > /dev/null 2>&1; then
    swift --version
    echo "✅ Swift编译器已安装"
else
    echo "❌ Swift编译器未安装"
fi
echo ""

# 检查Swift Package Manager
echo "4. 检查Swift Package Manager..."
if command -v swift package > /dev/null 2>&1; then
    echo "✅ Swift Package Manager 可用"
else
    echo "❌ Swift Package Manager 不可用"
fi
echo ""

# 检查Swift版本兼容性
echo "5. 检查Swift版本..."
SWIFT_VERSION=$(swift --version 2>/dev/null | head -1 | grep -o '[0-9]\.[0-9]' | head -1)
if [[ -n "$SWIFT_VERSION" ]]; then
    echo "   当前Swift版本: $SWIFT_VERSION"
    # Swift 5.5+ 支持SwiftUI App生命周期
    if (( $(echo "$SWIFT_VERSION >= 5.5" | bc -l) )); then
        echo "   ✅ Swift版本满足要求 (需要 ≥ 5.5)"
    else
        echo "   ⚠️  Swift版本可能过低 (需要 ≥ 5.5)"
    fi
else
    echo "   ❌ 无法获取Swift版本"
fi
echo ""

# 测试简单Swift编译
echo "6. 测试简单Swift编译..."
cat > /tmp/test_swift.swift << 'EOF'
import Foundation
print("Swift编译测试成功!")
EOF

if swiftc /tmp/test_swift.swift -o /tmp/test_swift 2>/dev/null; then
    /tmp/test_swift
    echo "✅ Swift编译测试通过"
else
    echo "❌ Swift编译测试失败"
    echo "   可能需要更新Xcode命令行工具:"
    echo "   sudo rm -rf /Library/Developer/CommandLineTools"
    echo "   xcode-select --install"
fi
rm -f /tmp/test_swift.swift /tmp/test_swift 2>/dev/null
echo ""

# 检查macOS版本
echo "7. 检查macOS版本兼容性..."
OS_VERSION=$(sw_vers -productVersion)
echo "   当前macOS版本: $OS_VERSION"
# macOS 11.0+ 支持SwiftUI App生命周期
if [[ "$OS_VERSION" =~ ^1[1-9]\. ]] || [[ "$OS_VERSION" =~ ^2[0-9]\. ]]; then
    echo "   ✅ macOS版本满足要求 (需要 ≥ 11.0)"
else
    echo "   ⚠️  macOS版本可能过低 (需要 ≥ 11.0)"
fi
echo ""

echo "========================================"
echo "📋 环境检查完成"
echo ""
echo "如果所有检查都通过✅，可以运行以下命令构建应用:"
echo "   swift build -c release"
echo "或使用打包脚本:"
echo "   ./build-app.sh"
echo ""
echo "如果遇到问题❌，请参考README.md中的故障排除部分。"
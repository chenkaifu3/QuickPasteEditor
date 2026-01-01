#!/bin/bash

# QuickPasteEditor 应用打包脚本
# 使用方法: ./build-app.sh

set -e

echo "🚀 开始构建 QuickPasteEditor..."

# 清理之前的构建
echo "🧹 清理旧构建..."
rm -rf .build
rm -rf QuickPasteEditor.app

# 构建发布版本
echo "🔨 构建应用..."
BUILD_CACHE="$PWD/.build/cache"
BUILD_HOME="$PWD/.build/home"
BUILD_TMP="$PWD/.build/tmp"
mkdir -p "$BUILD_CACHE/clang-module-cache" "$BUILD_HOME" "$BUILD_TMP"
export HOME="$BUILD_HOME"
export TMPDIR="$BUILD_TMP"
export CLANG_MODULE_CACHE_PATH="$BUILD_CACHE/clang-module-cache"
export SWIFTPM_CACHE_PATH="$BUILD_CACHE/swiftpm"
swift build -c release

# 检查构建是否成功
if [ ! -f ".build/release/QuickPasteEditor" ]; then
    echo "❌ 构建失败，可执行文件未找到"
    exit 1
fi

echo "✅ 构建成功"

# 生成应用图标（如果不存在）
ICON_PNG="Sources/Resources/AppIcon.png"
ICON_ICNS="Sources/Resources/AppIcon.icns"
ICON_ICONSET="Sources/Resources/AppIcon.iconset"
if [ ! -f "$ICON_ICNS" ]; then
    echo "🎨 生成应用图标..."
    mkdir -p "Sources/Resources"
    ICON_TMPDIR="$PWD/.build/icon-tmp"
    mkdir -p "$ICON_TMPDIR"
    TMPDIR="$ICON_TMPDIR" swift "Scripts/generate-icon.swift" "$ICON_PNG" "$ICON_ICONSET"
    TMPDIR="$ICON_TMPDIR" iconutil -c icns "$ICON_ICONSET" -o "$ICON_ICNS"
    rm -rf "$ICON_ICONSET"
    if [ ! -s "$ICON_ICNS" ]; then
        echo "❌ 图标生成失败: $ICON_ICNS"
        exit 1
    fi
fi

# 创建应用包目录结构
echo "📦 创建应用包..."
APP_NAME="QuickPasteEditor.app"
APP_CONTENTS="$APP_NAME/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"

# 创建目录
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"

# 复制可执行文件
cp ".build/release/QuickPasteEditor" "$APP_MACOS/"

# 复制Info.plist
if [ -f "Sources/Resources/Info.plist" ]; then
    cp "Sources/Resources/Info.plist" "$APP_CONTENTS/"
    if [ -f "$ICON_ICNS" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon.icns" "$APP_CONTENTS/Info.plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon.icns" "$APP_CONTENTS/Info.plist"
    fi
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable QuickPasteEditor" "$APP_CONTENTS/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string QuickPasteEditor" "$APP_CONTENTS/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleName QuickPasteEditor" "$APP_CONTENTS/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleName string QuickPasteEditor" "$APP_CONTENTS/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDevelopmentRegion en" "$APP_CONTENTS/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleDevelopmentRegion string en" "$APP_CONTENTS/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion 11.0" "$APP_CONTENTS/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 11.0" "$APP_CONTENTS/Info.plist"
else
    echo "⚠️  警告: Info.plist 未找到，创建默认配置..."
    cat > "$APP_CONTENTS/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>QuickPasteEditor</string>
    <key>CFBundleIdentifier</key>
    <string>com.quickpasteeditor.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>QuickPasteEditor</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025. All rights reserved.</string>
</dict>
</plist>
EOF
fi

# 创建简单的PkgInfo（可选）
echo "APPL????" > "$APP_CONTENTS/PkgInfo"

# 复制图标资源
if [ -f "$ICON_ICNS" ]; then
    cp "$ICON_ICNS" "$APP_RESOURCES/"
fi

# 设置可执行权限
chmod +x "$APP_MACOS/QuickPasteEditor"

# 本地临时签名并移除隔离属性，避免 Gatekeeper 拦截
codesign --deep --force --sign - "$APP_NAME" > /dev/null 2>&1 || true
xattr -dr com.apple.quarantine "$APP_NAME" > /dev/null 2>&1 || true
xattr -dr com.apple.provenance "$APP_NAME" > /dev/null 2>&1 || true

echo "🎉 应用包创建完成: $APP_NAME"
echo ""
echo "📝 下一步操作:"
echo "1. 双击 $APP_NAME 运行应用"
echo "2. 首次运行时可能需要授予剪贴板访问权限"
echo "3. 可以将 $APP_NAME 拖到应用程序文件夹中"
echo ""
echo "🔧 应用信息:"
echo "   可执行文件: $APP_MACOS/QuickPasteEditor"
echo "   配置文件: $APP_CONTENTS/Info.plist"
echo "   资源目录: $APP_RESOURCES/"

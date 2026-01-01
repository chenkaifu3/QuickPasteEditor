# QuickPasteEditor - macOS快速粘贴文本编辑器

一个轻量级的macOS原生文本编辑器，启动时自动从剪贴板粘贴内容，专注于快速编辑。

## 功能特性

- 🚀 **快速启动**：简洁界面，快速响应
- 📋 **自动粘贴**：启动时自动读取剪贴板内容
- 📝 **文本编辑**：支持基本的文本编辑操作
- 📊 **实时统计**：显示字数、行数统计
- 🎛️ **字体调整**：可调整编辑器字体大小
- 📋 **剪贴板操作**：一键复制、粘贴、清空

## 系统要求

- macOS 11.0 (Big Sur) 或更高版本
- Xcode 命令行工具 或 Xcode 14.0+

## 构建说明

### 1. 环境准备

确保已安装Xcode命令行工具：

```bash
xcode-select --install
```

或者安装完整Xcode（从App Store安装）。

### 2. 构建应用

在项目目录中执行：

```bash
# 使用Swift Package Manager构建
swift build -c release

# 或者使用Xcode构建（如果安装了Xcode）
xcodebuild -scheme QuickPasteEditor -configuration Release
```

### 3. 创建macOS应用包

构建成功后，可执行文件位于：
```
.build/release/QuickPasteEditor
```

要创建完整的`.app`应用包，可以手动创建目录结构，或使用以下脚本：

```bash
#!/bin/bash

# 创建应用包目录结构
APP_NAME="QuickPasteEditor.app"
APP_CONTENTS="$APP_NAME/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"

# 创建目录
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"

# 复制可执行文件
cp .build/release/QuickPasteEditor "$APP_MACOS/"

# 复制Info.plist
cp Sources/Resources/Info.plist "$APP_CONTENTS/"

# 创建简单的应用图标（可选）
# 可以使用图标工具生成或使用默认图标

echo "应用包创建完成: $APP_NAME"
```

### 4. 直接运行

也可以直接运行可执行文件：

```bash
./.build/release/QuickPasteEditor
```

## 项目结构

```
QuickPasteEditor/
├── Package.swift              # Swift包配置文件
├── Sources/
│   ├── QuickPasteEditorApp.swift  # 应用主入口
│   ├── ContentView.swift          # 主视图界面
│   └── Resources/
│       └── Info.plist            # 应用信息文件
└── README.md                    # 本文档
```

## 故障排除

### 问题：Swift编译器版本不匹配

如果遇到类似错误：
```
failed to build module 'Foundation'; this SDK is not supported by the compiler
```

**解决方案**：
1. 更新Xcode命令行工具：
   ```bash
   sudo rm -rf /Library/Developer/CommandLineTools
   xcode-select --install
   ```

2. 或者使用完整Xcode：
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

### 问题：无法导入SwiftUI

确保：
- macOS版本 ≥ 11.0
- Xcode版本支持SwiftUI

### 问题：剪贴板访问权限

首次运行时，macOS可能会请求剪贴板访问权限。请在系统偏好设置中授予权限：
1. 打开"系统偏好设置" → "安全性与隐私" → "隐私" → "辅助功能"
2. 添加QuickPasteEditor到允许列表

## 使用说明

1. **启动应用**：双击应用图标或运行可执行文件
2. **自动粘贴**：应用启动时自动读取剪贴板内容
3. **编辑文本**：在编辑器中直接修改文本
4. **工具栏功能**：
   - 📋 **粘贴**：从剪贴板粘贴内容（覆盖当前内容）
   - 📄 **复制**：复制当前内容到剪贴板
   - 🗑️ **清空**：清空编辑器内容
   - 🔠 **字体大小**：调整编辑器字体大小
5. **统计信息**：实时显示字数和行数

## 代码说明

### 核心功能实现

- **剪贴板访问**：使用`NSPasteboard.general`读取系统剪贴板
- **文本编辑**：使用SwiftUI的`TextEditor`组件
- **实时统计**：通过`onChange`监听文本变化，计算字数和行数
- **界面布局**：使用SwiftUI的VStack、HStack布局

### 主要文件

1. **QuickPasteEditorApp.swift**：应用主入口，定义窗口大小和样式
2. **ContentView.swift**：主视图，包含编辑器、工具栏和统计信息

## 自定义修改

### 修改窗口大小
编辑`QuickPasteEditorApp.swift`中的`frame`参数：
```swift
.frame(minWidth: 400, minHeight: 300)  // 修改最小窗口尺寸
```

### 添加新功能
在`ContentView.swift`中添加新按钮和功能逻辑。

### 修改应用信息
编辑`Sources/Resources/Info.plist`文件。

## 许可证

自由使用，无需授权。

## 支持

如有问题或建议，请提交Issue或联系开发者。
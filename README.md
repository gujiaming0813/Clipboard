# Clipboard - macOS 剪贴板历史工具

一个轻量、美观的 macOS 原生剪贴板历史管理工具，采用 SwiftUI 开发，完美适配 macOS 15+ 系统。

## ✨ 主要功能

### 核心特性
- **菜单栏常驻**：运行后显示在系统菜单栏，不占用 Dock 空间
- **快捷键呼出**：默认 `⌘⇧V` 快速打开历史记录（可在代码中修改）
- **智能记录**：自动捕获剪贴板中的文本、图片和 GIF 动画
- **历史管理**：最多保存 100 条记录，支持固定、删除
- **一键复制**：点击历史记录即可复制
- **开机自启动**：支持设置开机自动启动（需在偏好设置中开启）

### 智能过滤
- **文件检测**：自动识别并跳过文件类型的剪贴板内容
- **超长文本过滤**：超过 5000 字的文本不保存，节省存储空间
- **去重机制**：自动过滤重复的剪贴板内容

### 用户体验
- **毛玻璃效果**：历史记录弹窗采用 macOS 原生毛玻璃背景
- **悬停高亮**：鼠标悬停历史记录时显示高亮效果
- **复制提示**：复制成功后显示 Toast 提示
- **来源显示**：每条记录显示来源应用名称
- **内容预览**：文本和图片都有预览功能

## 📋 系统要求

- macOS 15.0 或更高版本
- Xcode 15.0 或更高版本（开发环境）

## 🚀 安装与使用

### 从源码构建

1. 克隆或下载项目
2. 使用 Xcode 打开 `Clipboard/Clipboard.xcodeproj`
3. 选择 `Clipboard` scheme，点击运行（⌘R）
4. 首次运行需要在「系统设置 > 隐私与安全性 > 辅助功能」中授予权限（用于全局快捷键）

### 使用说明

1. **查看历史记录**：
   - 点击菜单栏的剪刀图标
   - 或使用快捷键 `⌘⇧V`

2. **复制历史内容**：
   - 点击任意历史记录即可复制
   - 右键菜单也可选择复制

3. **管理历史记录**：
   - 点击图钉图标固定记录（固定记录不会被自动清理）
   - 点击垃圾桶图标删除记录
   - 使用搜索框按来源应用名称搜索

4. **偏好设置**：
   - 点击菜单栏图标，选择「偏好设置」
   - 可设置开机自启动

## 📁 项目结构

```
Clipboard/
├── Clipboard/
│   ├── ClipboardApp.swift          # 应用入口和核心服务
│   ├── Info.plist                   # 应用配置（LSUIElement=1）
│   ├── Models/
│   │   └── ClipboardItem.swift      # 剪贴板项数据模型
│   ├── Services/
│   │   ├── CacheManager.swift       # 缓存管理（文件读写、清理）
│   │   ├── ClipboardHistoryStore.swift  # 历史记录存储管理
│   │   ├── ClipboardMonitor.swift  # 剪贴板监控服务
│   │   └── HotkeyManager.swift      # 全局快捷键管理
│   └── UI/
│       ├── HistoryView.swift        # 历史记录主视图
│       ├── PreferencesView.swift    # 偏好设置视图
│       └── StatusItemController.swift  # 状态栏图标和弹窗控制
├── Package.swift                     # Swift Package 配置
└── README.md                         # 项目说明文档
```

## 🔧 技术实现

### 核心技术栈
- **SwiftUI**：现代化 UI 框架
- **AppKit**：系统集成（剪贴板、状态栏、快捷键）
- **Combine**：响应式数据流
- **UniformTypeIdentifiers**：文件类型识别

### 关键功能实现

1. **剪贴板监控**：
   - 使用 `NSPasteboard` 轮询检测剪贴板变化
   - 支持文本、PNG 图片、GIF 动画的识别和保存

2. **全局快捷键**：
   - 使用 Carbon API 注册全局快捷键
   - 默认快捷键：`⌘⇧V`（Command + Shift + V）

3. **数据持久化**：
   - JSON 格式存储历史记录元数据
   - 图片和 GIF 单独存储为文件
   - 启动时自动清理超限和临时文件

4. **内存优化**：
   - 历史记录上限 100 条
   - 图片使用缩略图预览
   - 懒加载和按需渲染

## ⚙️ 配置说明

### 修改快捷键

在 `Services/HotkeyManager.swift` 中修改 `register` 方法的默认参数：

```swift
func register(keyCode: UInt32 = defaultKeyCode, 
              modifiers: UInt32 = defaultModifiers, 
              handler: @escaping Handler)
```

### 修改历史记录上限

在 `ClipboardApp.swift` 中修改：

```swift
let store = ClipboardHistoryStore(cacheManager: cache, limit: 100)  // 修改 100 为其他值
```

### 修改文本长度限制

在 `Services/ClipboardMonitor.swift` 的 `handleText` 方法中修改：

```swift
if trimmed.count > 5000 {  // 修改 5000 为其他值
    return
}
```

## 📦 打包分发

### 生成 .app 文件

1. 在 Xcode 中选择 `Product > Archive`
2. 在 Organizer 中选择 `Distribute App`
3. 选择 `Copy App` 导出 `.app` 文件

### 生成 DMG 安装包（可选）

使用 `create-dmg` 工具：

```bash
brew install create-dmg

create-dmg --overwrite --volname "Clipboard" \
  --window-size 600 400 --icon-size 96 \
  --icon Clipboard.app 120 200 \
  --app-drop-link 400 200 \
  Clipboard.dmg /path/to/Clipboard.app
```

## 🐛 已知问题

- 首次运行需要手动授予辅助功能权限
- 某些应用复制的特殊格式可能无法正确识别

## 📝 开发计划

- [ ] 支持自定义快捷键设置
- [ ] 支持更多图片格式（WebP、HEIC 等）
- [ ] 支持历史记录导出/导入
- [ ] 支持 iCloud 同步（可选）
- [ ] 添加更多主题选项

## 📄 许可证

本项目仅供学习使用。

## 🙏 致谢

感谢 macOS 开发社区提供的优秀工具和文档。

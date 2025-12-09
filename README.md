# Clipboard (macOS 26 风格剪贴板工具)

SwiftUI 原生实现的轻量剪贴板工具，目标特性：

- 菜单栏常驻，快捷键呼出历史浮层。
- 记录文本与图片，去重与上限 100 条。
- 开机自启动开关，启动时清理旧缓存文件。
- 轻量内存/磁盘占用，图片缩略图缓存。
- 亮/暗主题适配，符合 macOS 26 视觉风格。

## 目录结构

- `Package.swift`：SwiftPM 配置（macOS 14+，SwiftUI）。
- `Sources/ClipboardApp`：应用源码。
  - `Models`：数据模型。
  - `Services`：剪贴板监控、历史存储、缓存、快捷键。
  - `UI`：菜单栏入口、历史/偏好视图。

## 构建与运行

此仓库使用 SwiftPM 组织代码，可在 Xcode 15+ 打开本目录并选择 `ClipboardApp` 方案运行；发布版建议创建对应 App Target 与签名配置。

## 下一步

- 接入签名、沙盒和辅助功能权限提示。
- 验证 SMAppService 自启动、全局快捷键可用性。
- 增加单元测试覆盖逻辑层（去重、上限、缓存清理）。


import AppKit
import SwiftUI

/// 管理状态栏图标与弹出的窗口，点击或快捷键调用同一弹出行为
/// 使用 NSPanel 替代 NSPopover，以支持在全屏应用上显示
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private var panel: NSPanel?
    private let historyStore: ClipboardHistoryStore
    private let monitor: ClipboardMonitor
    private var eventMonitor: Any?

    init(historyStore: ClipboardHistoryStore, monitor: ClipboardMonitor) {
        self.historyStore = historyStore
        self.monitor = monitor
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        createPanel()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Clipboard")
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 520),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性以支持在全屏应用上显示
        panel.level = .floating  // 浮动层级，可以显示在全屏应用之上
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        
        // 创建毛玻璃效果背景
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.frame = panel.contentView?.bounds ?? .zero
        visualEffect.autoresizingMask = [.width, .height]
        
        // 创建 SwiftUI 内容视图
        let hostingView = NSHostingView(
            rootView: HistoryView()
                .environmentObject(historyStore)
                .environmentObject(monitor)
        )
        hostingView.frame = visualEffect.bounds
        hostingView.autoresizingMask = [.width, .height]
        
        visualEffect.addSubview(hostingView)
        panel.contentView = visualEffect
        
        self.panel = panel
    }

    @objc
    func togglePopover() {
        guard let panel = panel else { return }
        
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let panel = panel, let button = statusItem.button else { return }
        
        // 计算窗口位置（在状态栏按钮下方）
        guard let window = button.window else { return }
        let buttonRect = window.convertToScreen(button.frame)
        let screenFrame = NSScreen.main?.frame ?? .zero
        
        // 计算窗口位置，确保不超出屏幕
        var panelFrame = panel.frame
        panelFrame.origin.x = buttonRect.midX - panelFrame.width / 2
        panelFrame.origin.y = screenFrame.height - buttonRect.maxY - panelFrame.height - 8
        
        // 确保窗口不超出屏幕左边界
        if panelFrame.origin.x < 8 {
            panelFrame.origin.x = 8
        }
        // 确保窗口不超出屏幕右边界
        if panelFrame.maxX > screenFrame.width - 8 {
            panelFrame.origin.x = screenFrame.width - panelFrame.width - 8
        }
        // 确保窗口不超出屏幕下边界
        if panelFrame.origin.y < 8 {
            panelFrame.origin.y = screenFrame.height - panelFrame.height - 8
        }
        
        panel.setFrame(panelFrame, display: false)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        startEventMonitor()
    }

    private func closePanel() {
        panel?.orderOut(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        stopEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel else { return }
            // 检查点击是否在窗口内
            if let window = event.window, window == panel {
                return
            }
            // 点击窗口外，关闭窗口
            self.closePanel()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}


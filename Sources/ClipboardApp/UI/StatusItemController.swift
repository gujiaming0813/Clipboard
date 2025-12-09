import AppKit
import SwiftUI

/// 管理状态栏图标与弹出的 NSPopover，点击或快捷键调用同一弹出行为
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let historyStore: ClipboardHistoryStore
    private let monitor: ClipboardMonitor
    private var eventMonitor: Any?

    init(historyStore: ClipboardHistoryStore, monitor: ClipboardMonitor) {
        self.historyStore = historyStore
        self.monitor = monitor
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        configurePopover()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Clipboard")
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    private func configurePopover() {
        popover.contentSize = NSSize(width: 360, height: 520)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(
            rootView: HistoryView()
                .environmentObject(historyStore)
                .environmentObject(monitor)
        )
    }

    @objc
    func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            closePopover()
        } else {
            showPopover(relativeTo: button.bounds, of: button)
        }
    }

    private func showPopover(relativeTo rect: NSRect, of view: NSView) {
        popover.show(relativeTo: rect, of: view, preferredEdge: .minY)
        popover.contentViewController?.view.window?.becomeKey()
        startEventMonitor()
    }

    private func closePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        stopEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}


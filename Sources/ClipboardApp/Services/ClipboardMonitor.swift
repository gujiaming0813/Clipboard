import AppKit
import SwiftUI

final class ClipboardMonitor: ObservableObject {
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var timer: Timer?
    private let history: ClipboardHistoryStore
    private var suppressNextCapture = false

    init(history: ClipboardHistoryStore) {
        self.history = history
        self.changeCount = pasteboard.changeCount
    }

    func start() {
        history.clearCacheOnLaunch()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        guard pasteboard.changeCount != changeCount else { return }
        changeCount = pasteboard.changeCount

        if suppressNextCapture {
            suppressNextCapture = false
            return
        }

        if let image = NSImage(pasteboard: pasteboard) {
            handleImage(image)
        } else if let text = pasteboard.string(forType: .string) {
            handleText(text)
        }
    }

    private func handleText(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let item = ClipboardItem(bundleName: frontmostAppName(), content: .text(text))
        DispatchQueue.main.async { [weak self] in
            self?.history.add(item)
        }
    }

    private func handleImage(_ image: NSImage) {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        let item = ClipboardItem(bundleName: frontmostAppName(), content: .image(png))
        DispatchQueue.main.async { [weak self] in
            self?.history.add(item)
        }
    }

    private func frontmostAppName() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    /// 由 UI 复制历史时调用，避免产生新记录
    func copyFromHistory(_ item: ClipboardItem) {
        suppressNextCapture = true
        pasteboard.clearContents()
        switch item.content {
        case .text(let value):
            pasteboard.setString(value, forType: .string)
        case .image(let data):
            if let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        }
    }
}


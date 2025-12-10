import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

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
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
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

        // 检测是否为文件（如果是文件，不保存）
        if isFileInPasteboard() {
            return
        }

        // 优先检测 GIF（检查多种可能的类型标识符）
        let gifTypes = [
            UTType.gif.identifier,
            "com.compuserve.gif",
            "public.gif"
        ]
        
        var foundGif = false
        for gifType in gifTypes {
            if let gifData = pasteboard.data(forType: .init(gifType)) {
                // 验证数据确实是 GIF（检查文件头）
                if gifData.count >= 6,
                   String(data: gifData.prefix(6), encoding: .ascii) == "GIF89a" ||
                   String(data: gifData.prefix(6), encoding: .ascii) == "GIF87a" {
                    handleGifData(gifData)
                    foundGif = true
                    break
                }
            }
        }
        
        if !foundGif {
            if let image = NSImage(pasteboard: pasteboard) {
                handleImage(image)
            } else if let text = pasteboard.string(forType: .string) {
                handleText(text)
            }
        }
    }
    
    /// 检测剪贴板中是否包含文件
    private func isFileInPasteboard() -> Bool {
        // 检查文件 URL 类型
        if pasteboard.data(forType: .init(UTType.fileURL.identifier)) != nil {
            return true
        }
        
        // 检查文件名列表类型（旧版 API）
        if pasteboard.propertyList(forType: .init("NSFilenamesPboardType")) != nil {
            return true
        }
        
        // 检查文件承诺类型
        if pasteboard.propertyList(forType: .init("NSFilesPromisePboardType")) != nil {
            return true
        }
        
        // 检查是否有文件路径字符串（以 file:// 开头或绝对路径）
        if let text = pasteboard.string(forType: .string) {
            if text.hasPrefix("file://") || text.hasPrefix("/") {
                // 进一步验证是否为有效文件路径
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("/") && FileManager.default.fileExists(atPath: trimmed) {
                    return true
                }
                if let url = URL(string: trimmed), url.scheme == "file" {
                    return true
                }
            }
        }
        
        return false
    }

    private func handleText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 如果文本超过 5000 字，不保存
        if trimmed.count > 5000 {
            return
        }
        
        let item = ClipboardItem(bundleName: frontmostAppName(), content: .text(trimmed))
        DispatchQueue.main.async { [weak self] in
            self?.history.add(item)
        }
    }

    private func handleGifData(_ data: Data) {
        let item = ClipboardItem(bundleName: frontmostAppName(),
                                 content: .image(data: data, uti: UTType.gif.identifier))
        DispatchQueue.main.async { [weak self] in
            self?.history.add(item)
        }
    }

    private func handleImage(_ image: NSImage) {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        let item = ClipboardItem(bundleName: frontmostAppName(), content: .image(data: png, uti: nil))
        DispatchQueue.main.async { [weak self] in
            self?.history.add(item)
        }
    }

    private func frontmostAppName() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    func copyFromHistory(_ item: ClipboardItem) {
        suppressNextCapture = true
        pasteboard.clearContents()
        switch item.content {
        case .text(let value):
            pasteboard.setString(value, forType: .string)
        case .image(let data, let uti):
            // 如果是 GIF，使用原始数据保持格式
            if let uti = uti, (uti == UTType.gif.identifier || uti == "com.compuserve.gif") {
                let pbItem = NSPasteboardItem()
                // 尝试多种 GIF 类型标识符以确保兼容性
                pbItem.setData(data, forType: .init(UTType.gif.identifier))
                pbItem.setData(data, forType: .init("com.compuserve.gif"))
                pasteboard.writeObjects([pbItem])
            } else if let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        }
    }
}


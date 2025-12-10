import Foundation
import SwiftUI

final class CacheManager {
    private let directory: URL
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    init(cacheFolderName: String = "ClipboardCache") {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        directory = base.appendingPathComponent(cacheFolderName, isDirectory: true)
        createDirectoryIfNeeded()
    }

    func save<S: Sequence>(items: S) where S.Element == ClipboardItem {
        let array = Array(items)
        do {
            let data = try encoder.encode(array)
            let url = directory.appendingPathComponent("history.json")
            try data.write(to: url, options: .atomic)
            persistImages(array)
        } catch {
            print("Cache save error: \(error)")
        }
    }

    func load(limit: Int) -> [ClipboardItem] {
        let url = directory.appendingPathComponent("history.json")
        guard let data = try? Data(contentsOf: url),
              let array = try? decoder.decode([ClipboardItem].self, from: data) else {
            return []
        }
        return Array(array.prefix(limit))
    }

    func cleanup(limit: Int) {
        let url = directory.appendingPathComponent("history.json")
        if let data = try? Data(contentsOf: url),
           let array = try? decoder.decode([ClipboardItem].self, from: data),
           array.count > limit {
            save(items: Array(array.prefix(limit)))
        }
        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.hasPrefix("img_") {
            try? fileManager.removeItem(at: file)
        }
    }

    private func persistImages(_ items: [ClipboardItem]) {
        for item in items {
            guard case .image(let data, _) = item.content else { continue }
            // 根据 UTI 决定文件扩展名
            let ext = item.isGif ? "gif" : "png"
            let url = directory.appendingPathComponent("img_\(item.id).\(ext)")
            try? data.write(to: url, options: .atomic)
        }
    }

    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}


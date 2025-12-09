import Foundation
import SwiftUI
import Combine

final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    private let cacheManager: CacheManager
    private let limit: Int

    init(cacheManager: CacheManager, limit: Int = 100) {
        self.cacheManager = cacheManager
        self.limit = limit
        loadFromDisk()
    }

    func add(_ item: ClipboardItem) {
        guard !isDuplicate(item) else { return }
        items.insert(item, at: 0)
        trimIfNeeded()
        saveToDisk()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(of: item) else { return }
        items[idx].pinned.toggle()
        saveToDisk()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveToDisk()
    }

    func clearCacheOnLaunch() {
        cacheManager.cleanup(limit: limit)
    }

    private func isDuplicate(_ item: ClipboardItem) -> Bool {
        guard let first = items.first else { return false }
        return first.content == item.content
    }

    private func trimIfNeeded() {
        let pinned = items.filter(\.pinned)
        let unpinned = items.filter { !$0.pinned }
        let trimmedUnpinned = unpinned.prefix(limit - pinned.count)
        items = pinned + trimmedUnpinned
    }

    private func loadFromDisk() {
        items = cacheManager.load(limit: limit)
    }

    private func saveToDisk() {
        cacheManager.save(items: items.prefix(limit))
    }
}


import SwiftUI
import Combine

@main
struct ClipboardApp: App {
    @StateObject private var services = AppServices()

    var body: some Scene {
        MenuBarExtra("Clipboard", systemImage: "scissors") {
            HistoryView()
                .environmentObject(services.historyStore)
                .environmentObject(services.monitor)
                .frame(width: 360, height: 520)
        }
        Settings {
            PreferencesView()
                .environmentObject(services.historyStore)
                .frame(width: 360, height: 280)
        }
    }
}

@MainActor
final class AppServices: ObservableObject {
    let historyStore: ClipboardHistoryStore
    let monitor: ClipboardMonitor

    init() {
        let cache = CacheManager()
        let store = ClipboardHistoryStore(cacheManager: cache, limit: 100)
        historyStore = store
        monitor = ClipboardMonitor(history: store)

        DispatchQueue.main.async { [weak self] in
            self?.start()
        }
    }

    private func start() {
        monitor.start()
    }
}

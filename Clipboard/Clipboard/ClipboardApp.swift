import SwiftUI
import Combine

@main
struct ClipboardApp: App {
    @StateObject private var services = AppServices()

    var body: some Scene {
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
    let hotkeyManager: HotkeyManager
    let statusController: StatusItemController

    init() {
        let cache = CacheManager()
        let store = ClipboardHistoryStore(cacheManager: cache, limit: 100)
        historyStore = store
        monitor = ClipboardMonitor(history: store)
        hotkeyManager = HotkeyManager()
        statusController = StatusItemController(historyStore: store, monitor: monitor)

        DispatchQueue.main.async { [weak self] in
            self?.start()
        }
    }

    private func start() {
        monitor.start()
        hotkeyManager.register { [weak self] in
            self?.statusController.togglePopover()
        }
    }
}

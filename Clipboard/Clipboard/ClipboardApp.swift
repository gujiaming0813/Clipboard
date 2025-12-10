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
        .menuBarExtraStyle(.window) // 使用窗口样式以支持热键激活
        
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

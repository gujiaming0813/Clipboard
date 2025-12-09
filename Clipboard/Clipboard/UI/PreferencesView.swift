import ServiceManagement
import SwiftUI

struct PreferencesView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @State private var hotkeyDisplay: String = "⌘⇧V"

    var body: some View {
        Form {
            Section("启动") {
                Toggle("开机自启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        toggleLaunchAtLogin(newValue)
                    }
            }

            Section("快捷键") {
                HStack {
                    Text("呼出历史")
                    Spacer()
                    Text(hotkeyDisplay)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.secondary))
                }
                Text("当前使用 Command + Shift + V，可在代码中更改。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("缓存") {
                Text("历史上限 100 条，启动时自动清理超限与临时文件。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private func toggleLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at login change failed: \(error)")
        }
    }
}



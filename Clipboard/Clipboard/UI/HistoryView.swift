import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var history: ClipboardHistoryStore
    @EnvironmentObject private var monitor: ClipboardMonitor
    @State private var searchText: String = ""
    @State private var copyMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 12) {
                header
                list
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .searchable(text: $searchText, placement: .toolbar)

            if let copyMessage {
                ToastView(message: copyMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("剪贴板历史")
                .font(.title3.bold())
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
        }
    }

    private var filtered: [ClipboardItem] {
        guard !searchText.isEmpty else { return history.items }
        return history.items.filter {
            ($0.bundleName ?? "未知应用").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(filtered) { item in
                    HistoryRow(item: item) { message in
                        showCopied(message)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func showCopied(_ message: String) {
        copyMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                copyMessage = nil
            }
        }
    }
}

private struct HistoryRow: View {
    @EnvironmentObject private var history: ClipboardHistoryStore
    @EnvironmentObject private var monitor: ClipboardMonitor
    let item: ClipboardItem
    private let rowHeight: CGFloat = 140
    @State private var isHovering = false
    let onCopy: (String) -> Void

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: 12) {
                summary
                    .frame(width: proxy.size.width * 0.3, alignment: .leading)
                preview
                controls
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovering ? Color.secondary.opacity(0.14) : Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isHovering ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .frame(height: rowHeight)
        .contextMenu {
            Button("复制") { copyToPasteboard(item) }
        }
        .onTapGesture {
            copyToPasteboard(item)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item.content {
        case .text(let value):
            Text(value)
                .font(.callout)
                .lineLimit(4)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .image(let data):
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: rowHeight - 20, alignment: .center)
                    .cornerRadius(10)
            } else {
                Color.secondary.opacity(0.2)
                    .frame(maxWidth: .infinity, maxHeight: rowHeight - 20)
                    .cornerRadius(10)
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.bundleName ?? "未知应用")
                .font(.headline)
                .lineLimit(1)
            Text(item.summaryText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)
        }
    }

    private var controls: some View {
        VStack(spacing: 6) {
            Button {
                history.togglePin(item)
            } label: {
                Image(systemName: item.pinned ? "pin.fill" : "pin")
            }
            .buttonStyle(.borderless)

            Button {
                history.delete(item)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }

    private func copyToPasteboard(_ item: ClipboardItem) {
        monitor.copyFromHistory(item)
        onCopy(item.bundleName ?? "已复制")
    }
}

private struct ToastView: View {
    let message: String

    var body: some View {
        Text("已复制: \(message)")
            .font(.subheadline.bold())
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .shadow(radius: 4, y: 2)
    }
}



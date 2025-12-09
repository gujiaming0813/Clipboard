import Foundation
import SwiftUI

enum ClipboardContent: Equatable, Hashable, Codable {
    case text(String)
    case image(Data) // PNG data for persistence

    private enum CodingKeys: String, CodingKey {
        case type, text, image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            let value = try container.decode(String.self, forKey: .text)
            self = .text(value)
        case "image":
            let data = try container.decode(Data.self, forKey: .image)
            self = .image(data)
        default:
            self = .text("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode("text", forKey: .type)
            try container.encode(value, forKey: .text)
        case .image(let data):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .image)
        }
    }
}

struct ClipboardItem: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let date: Date
    let bundleName: String?
    let content: ClipboardContent
    var pinned: Bool

    init(id: UUID = UUID(),
         date: Date = Date(),
         bundleName: String?,
         content: ClipboardContent,
         pinned: Bool = false) {
        self.id = id
        self.date = date
        self.bundleName = bundleName
        self.content = content
        self.pinned = pinned
    }
}

extension ClipboardItem {
    var summaryText: String {
        switch content {
        case .text(let value):
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .image:
            return "[图片]"
        }
    }
}


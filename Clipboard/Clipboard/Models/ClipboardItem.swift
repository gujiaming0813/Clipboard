import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum ClipboardContent: Equatable, Hashable, Codable {
    case text(String)
    case image(data: Data, uti: String?) // uti 用于区分 GIF 等格式

    private enum CodingKeys: String, CodingKey {
        case type, text, image, uti
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "text":
            let value = try c.decode(String.self, forKey: .text)
            self = .text(value)
        case "image":
            let data = try c.decode(Data.self, forKey: .image)
            let uti = try c.decodeIfPresent(String.self, forKey: .uti)
            self = .image(data: data, uti: uti)
        default:
            self = .text("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try c.encode("text", forKey: .type)
            try c.encode(value, forKey: .text)
        case .image(let data, let uti):
            try c.encode("image", forKey: .type)
            try c.encode(data, forKey: .image)
            try c.encodeIfPresent(uti, forKey: .uti)
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
        case .image(_, let uti):
            if let uti = uti, (uti == UTType.gif.identifier || uti == "com.compuserve.gif") {
                return "[GIF]"
            }
            return "[图片]"
        }
    }
    
    var isGif: Bool {
        switch content {
        case .image(_, let uti):
            if let uti = uti {
                return uti == UTType.gif.identifier || uti == "com.compuserve.gif"
            }
            return false
        default:
            return false
        }
    }
}


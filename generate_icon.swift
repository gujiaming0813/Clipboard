#!/usr/bin/env swift

import AppKit
import SwiftUI

// 创建剪贴板图标
func createClipboardIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let context = NSGraphicsContext.current!.cgContext
    
    // 绘制圆角矩形背景
    let cornerRadius = size * 0.15
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // 渐变背景（从浅蓝到深蓝）
    let gradient = NSGradient(colors: [
        NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0),
        NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
    ])
    gradient?.draw(in: path, angle: 135)
    
    // 绘制剪刀图标（简化版）
    let iconSize = size * 0.6
    let iconRect = NSRect(
        x: (size - iconSize) / 2,
        y: (size - iconSize) / 2,
        width: iconSize,
        height: iconSize
    )
    
    // 使用系统符号：scissors
    if let symbolImage = NSImage(systemSymbolName: "scissors", accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: iconSize * 0.8, weight: .medium)
        if let configuredImage = symbolImage.withSymbolConfiguration(config) {
            configuredImage.draw(
                in: iconRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )
        }
    }
    
    image.unlockFocus()
    return image
}

// 生成所有尺寸的图标
let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

let outputDir = "Clipboard/Clipboard/Assets.xcassets/AppIcon.appiconset"

for (size, filename) in sizes {
    let image = createClipboardIcon(size: size)
    let filePath = "\(outputDir)/\(filename)"
    
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: filePath))
        print("Generated: \(filename) (\(Int(size))x\(Int(size)))")
    }
}

print("\n✅ All icons generated successfully!")


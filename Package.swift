// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clipboard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ClipboardCore",
            targets: ["ClipboardApp"]
        )
    ],
    targets: [
        .target(
            name: "ClipboardApp",
            path: "Sources/ClipboardApp"
        )
    ]
)


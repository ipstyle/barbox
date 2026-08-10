// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AFToolbox",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AFToolbox",
            path: "Sources/AFToolbox"
        )
    ]
)

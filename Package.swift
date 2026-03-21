// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexSwitcher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "CodexSwitcher",
            targets: ["CodexSwitcher"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CodexSwitcher"
        )
    ]
)

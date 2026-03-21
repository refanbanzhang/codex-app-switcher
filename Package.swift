// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "codex-app-switcher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "codex-app-switcher",
            targets: ["CodexAppSwitcher"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CodexAppSwitcher",
            path: "Sources/CodexAppSwitcher"
        )
    ]
)

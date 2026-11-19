// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ClaudeCodeAutoApprover",
    platforms: [.macOS(.v13)],
    targets: [
        // What can be tested without a running Claude app: labels, chats and translations.
        .target(name: "AutoApproverCore", path: "sources/core"),
        .executableTarget(name: "AutoApprover", dependencies: ["AutoApproverCore"], path: "sources/app"),
        .testTarget(name: "AutoApproverCoreTests", dependencies: ["AutoApproverCore"], path: "tests"),
    ],
    swiftLanguageModes: [.v5]
)

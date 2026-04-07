// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "kfs-md",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
        .package(url: "https://github.com/swiftlang/swift-cmark", from: "0.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "KfsMd",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
            ],
            path: "Sources/KfsMd",
            resources: [
                .copy("Resources/Fonts"),
            ]
        ),
    ]
)

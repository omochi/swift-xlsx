// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swift-xlsx",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "XLSX",
            targets: ["XLSX"]
        ),
        .executable(
            name: "xlsx-tool",
            targets: ["XLSXTool"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro.git", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/compnerd/xylem.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "XLSX",
            dependencies: [
                "CXLSXZLib",
                .product(name: "MemberwiseInit", package: "swift-memberwise-init-macro"),
                .product(name: "SAXParser", package: "xylem"),
                .product(name: "XMLCore", package: "xylem"),
            ]
        ),
        .executableTarget(
            name: "XLSXTool",
            dependencies: [
                "XLSX",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .systemLibrary(
            name: "CXLSXZLib",
            path: "Sources/CXLSXZLib"
        ),
        .testTarget(
            name: "XLSXTest",
            dependencies: ["XLSX"],
            resources: [
                .process("Resources/simple.xlsx"),
                .copy("Resources/example-documents"),
            ]
        ),
    ]
)

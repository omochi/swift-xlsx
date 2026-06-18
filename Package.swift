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
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.6.0"),
        .package(url: "https://github.com/compnerd/xylem.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "XLSXXML",
            dependencies: [
                .product(name: "MemberwiseInit", package: "swift-memberwise-init-macro"),
                .product(name: "XMLCore", package: "xylem"),
                .product(name: "SAXParser", package: "xylem"),
            ]
        ),
        .target(
            name: "XLSX",
            dependencies: [
                "CXLSXZLib",
                "XLSXXML",
                .product(name: "MemberwiseInit", package: "swift-memberwise-init-macro"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),
        .target(
            name: "XLSXExamples",
            dependencies: [
                "XLSX",
            ]
        ),
        .executableTarget(
            name: "XLSXTool",
            dependencies: [
                "XLSXXML",
                "XLSX",
                "XLSXExamples",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .systemLibrary(
            name: "CXLSXZLib",
            path: "Sources/CXLSXZLib"
        ),
        .testTarget(
            name: "XLSXTest",
            dependencies: [
                "XLSXXML",
                "XLSX",
                "XLSXExamples",
            ],
            resources: [
                .process("Resources/simple.xlsx"),
                .copy("Resources/example-documents"),
            ]
        ),
    ]
)

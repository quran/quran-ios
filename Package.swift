// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "QuranEngine",
    defaultLocalization: "en",
    products: [
        .library(name: "QuranKit", targets: ["QuranKit"]),
        .library(name: "QuranTextKit", targets: ["QuranTextKit"]),
        .library(name: "SQLitePersistence", targets: ["SQLitePersistence"]),
        .library(name: "BatchDownloader", targets: ["BatchDownloader"]),
        .library(name: "Locking", targets: ["Locking"]),
        .library(name: "Utilities", targets: ["Utilities"]),
        .library(name: "VLogging", targets: ["VLogging"]),
        .library(name: "Crashing", targets: ["Crashing"]),
        .library(name: "Preferences", targets: ["Preferences"]),
        .library(name: "Localization", targets: ["Localization"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.13.1"),
        .package(url: "https://github.com/apple/swift-log", from: "1.4.2"),
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.12.2"),
        .package(url: "https://github.com/marmelroy/Zip", .branch("master")), // TODO: use a release
    ],
    targets: [
        .target(
            name: "QuranKit",
            dependencies: []
        ),
        .testTarget(
            name: "QuranKitTests",
            dependencies: ["QuranKit"]
        ),

        .target(
            name: "QuranTextKit",
            dependencies: [
                "TranslationService",
                "QuranKit",
            ]
        ),
        .testTarget(
            name: "QuranTextKitTests",
            dependencies: ["QuranTextKit"],
            resources: [
                .copy("test_data"),
            ]
        ),

        .target(
            name: "Preferences",
            dependencies: []
        ),

        .target(
            name: "Localization",
            dependencies: []
        ),

        .target(
            name: "VLogging",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ]
        ),

        .target(
            name: "Utilities",
            dependencies: [
                "PromiseKit",
            ]
        ),

        .target(
            name: "SQLitePersistence",
            dependencies: [
                "Utilities",
                "VLogging",
                .product(name: "SQLite", package: "SQLite.swift"),
            ]
        ),

        .target(
            name: "Locking",
            dependencies: []
        ),

        .target(
            name: "WeakSet",
            dependencies: [
                "Locking",
            ]
        ),

        .target(
            name: "Crashing",
            dependencies: [
                "Locking",
            ]
        ),

        .target(
            name: "BatchDownloader",
            dependencies: [
                "SQLitePersistence",
                "Crashing",
                "WeakSet",
            ]
        ),

        .target(
            name: "TranslationService",
            dependencies: [
                "Zip",
                "SQLitePersistence",
                "BatchDownloader",
                "Localization",
                "Preferences",
            ]
        ),
    ]
)

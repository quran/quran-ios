// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "QuranEngine",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(name: "QuranKit", targets: ["QuranKit"]),
        .library(name: "QuranTextKit", targets: ["QuranTextKit"]),
        .library(name: "QuranMadaniData", targets: ["QuranMadaniData"]),
        .library(name: "QuranAudioKit", targets: ["QuranAudioKit"]),
        .library(name: "Caching", targets: ["Caching"]),

        // Utilities packages

        .library(name: "Timing", targets: ["Timing"]),
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
        .package(url: "https://github.com/marmelroy/Zip", from: "2.1.1"),
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.9.0"),
    ],
    targets: [
        .target(name: "QuranKit", dependencies: []),
        .testTarget(name: "QuranKitTests", dependencies: [
            "QuranKit",
        ]),

        .target(name: "QuranTextKit", dependencies: [
            "TranslationService",
            "QuranKit",
        ]),
        .testTarget(name: "QuranTextKitTests", dependencies: [
            "QuranTextKit",
            "QuranMadaniData",
            "SnapshotTesting",
            "TestUtilities",
        ],
        exclude: [
            "__Snapshots__",
        ],
        resources: [
            .copy("test_data"),
        ]),

        .target(name: "QuranAudioKit", dependencies: [
            "SQLitePersistence",
            "BatchDownloader",
            "QuranTextKit",
            "QueuePlayer",
            "Zip",
        ]),

        .target(name: "QuranMadaniData", dependencies: [], resources: [
            .process("quran.ar.uthmani.v2.db"),
            .copy("images_1280"),
        ]),

        .target(name: "TranslationService", dependencies: [
            "Zip",
            "SQLitePersistence",
            "BatchDownloader",
            "Localization",
            "Preferences",
        ]),

        .target(name: "QueuePlayer", dependencies: [
            "Timing",
            "QueuePlayerObjc",
        ]),
        .target(name: "QueuePlayerObjc", dependencies: []),

        .target(name: "BatchDownloader", dependencies: [
            "SQLitePersistence",
            "Crashing",
            "WeakSet",
        ]),

        .target(name: "SQLitePersistence", dependencies: [
            "Utilities",
            "VLogging",
            .product(name: "SQLite", package: "SQLite.swift"),
        ]),

        .target(name: "Caching", dependencies: [
            "Locking",
            "PromiseKit",
        ]),

        .target(name: "Utilities", dependencies: [
            "PromiseKit",
        ]),

        .target(name: "Timing", dependencies: [
            "Locking",
        ]),

        .target(name: "WeakSet", dependencies: [
            "Locking",
        ]),

        .target(name: "Crashing", dependencies: [
            "Locking",
        ]),

        .target(name: "VLogging", dependencies: [
            .product(name: "Logging", package: "swift-log"),
        ]),

        .target(name: "Locking", dependencies: []),
        .target(name: "Preferences", dependencies: []),
        .target(name: "Localization", dependencies: []),

        // Testing helpers
        .target(name: "TestUtilities", dependencies: [
            "PromiseKit",
        ]),
    ]
)

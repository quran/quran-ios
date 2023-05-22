// swift-tools-version:5.5

import PackageDescription

// Disable before commit, see https://forums.swift.org/t/concurrency-checking-in-swift-packages-unsafeflags/61135
let enforceSwiftConcurrencyChecks = false

let swiftConcurrencySettings: [SwiftSetting] = [
    .unsafeFlags([
        "-Xfrontend", "-strict-concurrency=complete",
    ]),
]

let settings = enforceSwiftConcurrencyChecks ? swiftConcurrencySettings : []

let package = Package(
    name: "QuranEngine",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "QuranKit", targets: ["QuranKit"]),
        .library(name: "QuranTextKit", targets: ["QuranTextKit"]),
        .library(name: "QuranAudioKit", targets: ["QuranAudioKit"]),
        .library(name: "BatchDownloader", targets: ["BatchDownloader"]),
        .library(name: "Caching", targets: ["Caching"]),
        .library(name: "VersionUpdater", targets: ["VersionUpdater"]),

        // Utilities packages

        .library(name: "Timing", targets: ["Timing"]),
        .library(name: "Utilities", targets: ["Utilities"]),
        .library(name: "VLogging", targets: ["VLogging"]),
        .library(name: "Crashing", targets: ["Crashing"]),
        .library(name: "Preferences", targets: ["Preferences"]),
        .library(name: "Localization", targets: ["Localization"]),
        .library(name: "SystemDependencies", targets: ["SystemDependencies"]),
        .library(name: "SystemDependenciesFake", targets: ["SystemDependenciesFake"]),

        .library(name: "TranslationService", targets: ["TranslationService"]),

        // Testing

        .library(name: "TestUtilities", targets: ["TestUtilities"]),

    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.13.1"),
        .package(url: "https://github.com/apple/swift-log", from: "1.4.2"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.12.2"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.13.0"),
        .package(url: "https://github.com/marmelroy/Zip", from: "2.1.1"),
        .package(url: "https://github.com/sideeffect-io/AsyncExtensions", from: "0.5.2"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.9.0"),
    ],
    targets: [
        .target(name: "QuranKit", dependencies: [],
                swiftSettings: settings),
        .testTarget(name: "QuranKitTests", dependencies: [
            "QuranKit",
        ]),

        .target(name: "QuranTextKit", dependencies: [
            "TranslationService",
            "QuranKit",
        ]),
        .testTarget(name: "QuranTextKitTests", dependencies: [
            "QuranTextKit",
            "SnapshotTesting",
            "TestUtilities",
            "SystemDependenciesFake",
        ],
        exclude: [
            "__Snapshots__",
        ]),

        .target(name: "QuranAudioKit", dependencies: [
            "SQLitePersistence",
            "BatchDownloader",
            "QuranTextKit",
            "QueuePlayer",
            "SystemDependencies",
            "Zip",
            .product(name: "OrderedCollections", package: "swift-collections"),
        ],
        swiftSettings: settings),
        .testTarget(name: "QuranAudioKitTests", dependencies: [
            "QuranAudioKit",
            "SystemDependenciesFake",
            "TestUtilities",
            "SnapshotTesting",
        ],
        exclude: [
            "__Snapshots__",
        ],
        resources: [
            .copy("test_data"),
        ],
        swiftSettings: settings),

        .target(name: "TranslationService", dependencies: [
            "Zip",
            "SQLitePersistence",
            "BatchDownloader",
            "Localization",
            "Preferences",
            "SystemDependencies",
        ]),
        .testTarget(name: "TranslationServiceTests", dependencies: [
            "TranslationService",
            "TestUtilities",
        ]),

        .target(name: "QueuePlayer", dependencies: [
            "Timing",
            "QueuePlayerObjc",
        ],
        swiftSettings: settings),
        .target(name: "QueuePlayerObjc", dependencies: []),

        .target(name: "BatchDownloader", dependencies: [
            "SQLitePersistence",
            "Crashing",
            "WeakSet",
            "AsyncExtensions",
        ],
        swiftSettings: settings),
        .testTarget(name: "BatchDownloaderTests", dependencies: [
            "BatchDownloader",
            "TestUtilities",
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        ],
        swiftSettings: settings),

        .target(name: "SQLitePersistence", dependencies: [
            "Utilities",
            "VLogging",
            .product(name: "SQLite", package: "SQLite.swift"),
            .product(name: "GRDB", package: "GRDB.swift"),
        ]),

        .target(name: "Caching", dependencies: [
            "Locking",
            "PromiseKit",
        ]),

        .target(name: "Utilities", dependencies: [
            "PromiseKit",
            "AsyncExtensions",
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        ],
        swiftSettings: settings),

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
        .target(name: "SystemDependencies", dependencies: []),
        .target(name: "SystemDependenciesFake", dependencies: [
            "SystemDependencies",
            "Utilities",
        ]),

        .target(name: "VersionUpdater", dependencies: [
            "Preferences",
            "VLogging",
            "SystemDependencies",
        ]),
        .testTarget(name: "VersionUpdaterTests", dependencies: [
            "VersionUpdater",
            "SystemDependenciesFake",
        ]),

        // Testing helpers
        .target(name: "TestUtilities", dependencies: [
            "PromiseKit",
            "BatchDownloader",
            "TranslationService",
            "SystemDependenciesFake",
            "Utilities",
        ],
        resources: [
            .copy("test_data"),
        ]),
    ]
)

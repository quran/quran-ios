// swift-tools-version:5.8

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

        .library(name: "NotePersistence", targets: ["NotePersistence"]),
        .library(name: "LastPagePersistence", targets: ["LastPagePersistence"]),
        .library(name: "PageBookmarkPersistence", targets: ["PageBookmarkPersistence"]),

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
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.13.0"),
        .package(url: "https://github.com/marmelroy/Zip", from: "2.1.1"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.9.0"),
    ], targets: [
        coreTargets(),
        dataTargets(),
        domainTargets(),
    ]
    .flatMap { $0 }
    .flatMap { $0 }
)

private func coreTargets() -> [[Target]] {
    [
        target(.core, name: "SystemDependencies", hasTests: false, dependencies: []),
        target(.core, name: "SystemDependenciesFake", hasTests: false, dependencies: [
            "SystemDependencies",
            "Utilities",
        ]),

        target(.core, name: "Locking", hasTests: false, dependencies: []),
        target(.core, name: "Preferences", hasTests: false, dependencies: []),

        target(.core, name: "VLogging", hasTests: false, dependencies: [
            .product(name: "Logging", package: "swift-log"),
        ]),

        target(.core, name: "Caching", dependencies: [
            "Locking",
            "Utilities",
        ], testDependencies: [
            "TestUtilities",
        ]),

        target(.core, name: "Timing", hasTests: false, dependencies: [
            "Locking",
        ]),

        target(.core, name: "WeakSet", hasTests: false, dependencies: [
            "Locking",
        ]),

        target(.core, name: "Crashing", hasTests: false, dependencies: [
            "Locking",
        ]),

        target(.core, name: "Utilities", dependencies: [
            "PromiseKit",
        ], testDependencies: [
            "TestUtilities",
        ]),

        target(.core, name: "VersionUpdater", dependencies: [
            "Preferences",
            "VLogging",
            "SystemDependencies",
        ], testDependencies: [
            "SystemDependenciesFake",
        ]),

        target(.core, name: "Localization", hasTests: false, dependencies: []),

        target(.core, name: "QueuePlayer", hasTests: false, dependencies: [
            "Timing",
            "QueuePlayerObjc",
        ]),

        target(.core, name: "QueuePlayerObjc", hasTests: false, dependencies: []),

        // TODO: Break up
        target(.core, name: "TestUtilities", hasTests: false, dependencies: [
            "PromiseKit",
            "BatchDownloader",
            "TranslationService",
            "SystemDependenciesFake",
            "Utilities",
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        ],
        resources: [
            .copy("test_data"),
        ]),
    ]
}

private func dataTargets() -> [[Target]] {
    [
        // MARK: - Core Data

        target(.data, name: "LastPagePersistence", dependencies: [
            "CoreDataModel",
            "CoreDataPersistence",
        ], testDependencies: [
            "TestUtilities",
            "CoreDataPersistenceTestSupport",
        ]),

        target(.data, name: "PageBookmarkPersistence", dependencies: [
            "CoreDataModel",
            "CoreDataPersistence",
        ], testDependencies: [
            "TestUtilities",
            "CoreDataPersistenceTestSupport",
        ]),

        target(.data, name: "NotePersistence", dependencies: [
            "CoreDataModel",
            "CoreDataPersistence",
            "SystemDependencies",
        ], testDependencies: [
            "TestUtilities",
            "CoreDataPersistenceTestSupport",
        ]),

        target(.data, name: "CoreDataPersistence", dependencies: [
            "Utilities",
            "VLogging",
            "Crashing",
            "PromiseKit",
            "SystemDependencies",
        ], testDependencies: [
            "TestUtilities",
            "CoreDataModel",
            "CoreDataPersistenceTestSupport",
        ]),

        target(.data, name: "CoreDataPersistenceTestSupport", hasTests: false, dependencies: [
            "CoreDataPersistence",
            "CoreDataModel",
            "SystemDependenciesFake",
        ]),

        target(.data, name: "CoreDataModel", hasTests: false, dependencies: [
            "CoreDataPersistence",
        ]),

        // MARK: - SQLite

        target(.data, name: "SQLitePersistence", dependencies: [
            "Utilities",
            "VLogging",
            .product(name: "GRDB", package: "GRDB.swift"),
        ], testDependencies: [
            "TestUtilities",
        ]),

        // MARK: - Networking

        target(.data, name: "BatchDownloader", dependencies: [
            "SQLitePersistence",
            "Crashing",
            "WeakSet",
        ], testDependencies: [
            "TestUtilities",
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        ]),
    ]
}

private func domainTargets() -> [[Target]] {
    [
        target(.domain, name: "QuranKit", dependencies: [],
               testDependencies: []),

        target(.domain, name: "QuranTextKit", dependencies: [
            "TranslationService",
            "QuranKit",
        ], testDependencies: [
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            "TestUtilities",
            "SystemDependenciesFake",
        ], testExclude: [
            "__Snapshots__",
        ]),

        target(.domain, name: "QuranAudioKit", dependencies: [
            "SQLitePersistence",
            "BatchDownloader",
            "QuranTextKit",
            "QueuePlayer",
            "SystemDependencies",
            "Zip",
            .product(name: "OrderedCollections", package: "swift-collections"),
        ], testDependencies: [
            "SystemDependenciesFake",
            "TestUtilities",
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        ], testExclude: [
            "__Snapshots__",
        ], testResources: [
            .copy("test_data"),
        ]),

        target(.domain, name: "TranslationService", dependencies: [
            "Zip",
            "SQLitePersistence",
            "BatchDownloader",
            "Localization",
            "Preferences",
            "SystemDependencies",
        ], testDependencies: [
            "TestUtilities",
        ]),
    ]
}

// MARK: - Builders

enum TargetType: String {
    case core = "Core"
    case domain = "Domain"
    case data = "Data"
}

func target(
    _ type: TargetType,
    name: String,
    hasTests: Bool = true,
    dependencies: [Target.Dependency] = [],
    resources: [Resource]? = nil,
    testDependencies: [Target.Dependency] = [],
    testExclude: [String] = [],
    testResources: [Resource]? = nil
) -> [Target] {
    var targets: [Target] = [
        .target(name: name,
                dependencies: dependencies,
                path: type.rawValue + "/" + name + (hasTests ? "/Sources" : ""),
                resources: resources,
                swiftSettings: settings),
    ]
    guard hasTests else {
        return targets
    }
    targets.append(
        .testTarget(name: name + "Tests",
                    dependencies: [.init(stringLiteral: name)] + testDependencies,
                    path: type.rawValue + "/" + name + "/Tests",
                    exclude: testExclude,
                    resources: testResources,
                    swiftSettings: settings)
    )
    return targets
}

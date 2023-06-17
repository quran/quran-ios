// swift-tools-version:5.8

import Foundation
import PackageDescription

// Disable before commit, see https://forums.swift.org/t/concurrency-checking-in-swift-packages-unsafeflags/61135
let enforceSwiftConcurrencyChecks = false

let swiftConcurrencySettings: [SwiftSetting] = [
    .unsafeFlags([
        "-Xfrontend", "-strict-concurrency=complete",
    ]),
]

let settings = enforceSwiftConcurrencyChecks ? swiftConcurrencySettings : []

let targets = [
    coreTargets(),
    modelTargets(),
    uiTargets(),
    dataTargets(),
    domainTargets(),
]
.flatMap { $0 }
.flatMap { $0 }

let package = Package(
    name: "QuranEngine",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        library("QuranKit"),
        library("QuranTextKit"),
        library("QuranText"),
        library("QuranAudioKit"),
        library("AudioUpdater"),
        library("BatchDownloader"),
        library("Caching"),
        library("VersionUpdater"),
        library("ReadingService"),
        library("ImageService"),
        library("WordTextService"),
        library("TranslationService"),
        library("AnnotationsService"),
        library("NoorUI"),

        // Utilities packages

        library("Timing"),
        library("Utilities"),
        library("VLogging"),
        library("Crashing"),
        library("Preferences"),
        library("Localization"),
        library("SystemDependencies"),
        library("SystemDependenciesFake"),
    ],
    dependencies: [
        // Logging
        .package(url: "https://github.com/apple/swift-log", from: "1.4.2"),

        // Helpers
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),

        // Zip
        .package(url: "https://github.com/marmelroy/Zip", from: "2.1.1"),

        // Database
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.13.0"),

        // Async
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.13.1"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),

        // UI
        .package(url: "https://github.com/mohamede1945/DownloadButton", branch: "master"),

        // Testing
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.9.0"),

    ], targets: validated(targets) + [testTargetLinkingAllPackageTargets(targets)]
)

private func coreTargets() -> [[Target]] {
    let type = TargetType.core
    return [
        target(type, name: "SystemDependencies", hasTests: false, dependencies: []),
        target(type, name: "SystemDependenciesFake", hasTests: false, dependencies: [
            "SystemDependencies",
            "Utilities",
        ]),

        target(type, name: "Locking", hasTests: false, dependencies: []),
        target(type, name: "Preferences", hasTests: false, dependencies: []),

        target(type, name: "VLogging", hasTests: false, dependencies: [
            .product(name: "Logging", package: "swift-log"),
        ]),

        target(type, name: "Analytics", hasTests: false, dependencies: [
            "VLogging",
        ]),

        target(type, name: "Caching", dependencies: [
            "Locking",
            "Utilities",
        ], testDependencies: [
            "AsyncUtilitiesForTesting",
        ]),

        target(type, name: "Timing", hasTests: false, dependencies: [
            "Locking",
        ]),

        target(type, name: "WeakSet", hasTests: false, dependencies: [
            "Locking",
        ]),

        target(type, name: "Crashing", hasTests: false, dependencies: [
            "Locking",
        ]),

        target(type, name: "Utilities", dependencies: [
            "PromiseKit",
        ], testDependencies: [
            "AsyncUtilitiesForTesting",
        ]),

        target(type, name: "VersionUpdater", dependencies: [
            "Preferences",
            "VLogging",
            "SystemDependencies",
        ], testDependencies: [
            "SystemDependenciesFake",
        ]),

        target(type, name: "Localization", hasTests: false, dependencies: []),

        target(type, name: "QueuePlayer", hasTests: false, dependencies: [
            "Timing",
            "QueuePlayerObjc",
        ]),

        target(type, name: "QueuePlayerObjc", hasTests: false, dependencies: []),

        target(type, name: "AsyncUtilitiesForTesting", hasTests: false, dependencies: [
            "PromiseKit",
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        ]),
    ]
}

private func modelTargets() -> [[Target]] {
    let type = TargetType.model
    return [
        target(type, name: "QuranKit"),
        target(type, name: "QuranGeometry", hasTests: false, dependencies: [
            "QuranKit",
        ]),
        target(type, name: "QuranAudio", hasTests: false, dependencies: [
            "Utilities",
            "QuranKit",
        ]),
        target(type, name: "QuranText", hasTests: false, dependencies: [
            "Utilities",
            "QuranKit",
        ]),
        target(type, name: "QuranAnnotations", hasTests: false, dependencies: [
            "QuranKit",
        ]),
    ]
}

private func uiTargets() -> [[Target]] {
    let type = TargetType.ui
    return [
        target(type, name: "ViewConstrainer", hasTests: false),
        target(type, name: "UIx", hasTests: false, dependencies: [
            "ViewConstrainer",
        ]),
        target(type, name: "NoorUI", hasTests: false, dependencies: [
            "UIx",
            "Localization",
            "QuranText",
            "DownloadButton",
        ]),
    ]
}

private func dataTargets() -> [[Target]] {
    let type = TargetType.data
    return [
        // MARK: - Core Data

        target(type, name: "LastPagePersistence", dependencies: [
            "CoreDataModel",
            "CoreDataPersistence",
        ], testDependencies: [
            "AsyncUtilitiesForTesting",
            "CoreDataPersistenceTestSupport",
        ]),

        target(type, name: "PageBookmarkPersistence", dependencies: [
            "CoreDataModel",
            "CoreDataPersistence",
        ], testDependencies: [
            "AsyncUtilitiesForTesting",
            "CoreDataPersistenceTestSupport",
        ]),

        target(type, name: "NotePersistence", dependencies: [
            "CoreDataModel",
            "CoreDataPersistence",
            "SystemDependencies",
        ], testDependencies: [
            "AsyncUtilitiesForTesting",
            "CoreDataPersistenceTestSupport",
        ]),

        target(type, name: "CoreDataPersistence", dependencies: [
            "Utilities",
            "VLogging",
            "Crashing",
            "PromiseKit",
            "SystemDependencies",
        ], testDependencies: [
            "AsyncUtilitiesForTesting",
            "CoreDataModel",
            "CoreDataPersistenceTestSupport",
        ]),

        target(type, name: "CoreDataPersistenceTestSupport", hasTests: false, dependencies: [
            "CoreDataPersistence",
            "CoreDataModel",
            "SystemDependenciesFake",
        ]),

        target(type, name: "CoreDataModel", hasTests: false, dependencies: [
            "CoreDataPersistence",
        ]),

        // MARK: - SQLite

        target(type, name: "SQLitePersistence", dependencies: [
            "Utilities",
            "VLogging",
            .product(name: "GRDB", package: "GRDB.swift"),
        ], testDependencies: [
            "AsyncUtilitiesForTesting",
        ]),

        target(type, name: "AudioTimingPersistence", hasTests: false, dependencies: [
            "SQLitePersistence",
            "QuranAudio",
        ]),

        target(type, name: "WordFramePersistence", hasTests: false, dependencies: [
            "SQLitePersistence",
            "QuranGeometry",
        ]),

        target(type, name: "WordTextPersistence", hasTests: false, dependencies: [
            "SQLitePersistence",
            "QuranKit",
        ]),

        target(type, name: "VerseTextPersistence", hasTests: false, dependencies: [
            "SQLitePersistence",
            "QuranKit",
        ]),

        target(type, name: "TranslationPersistence", hasTests: false, dependencies: [
            "SQLitePersistence",
            "QuranText",
        ]),

        // MARK: - Networking

        target(type, name: "NetworkSupport", dependencies: [
            "Crashing",
        ], testDependencies: [
            "Utilities",
            "AsyncUtilitiesForTesting",
            "NetworkSupportFake",
        ]),

        target(type, name: "NetworkSupportFake", hasTests: false, dependencies: [
            "NetworkSupport",
            "AsyncUtilitiesForTesting",
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        ]),

        target(type, name: "BatchDownloader", dependencies: [
            "SQLitePersistence",
            "Crashing",
            "WeakSet",
            "NetworkSupport",
        ], testDependencies: [
            "BatchDownloaderFake",
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        ]),

        target(type, name: "BatchDownloaderFake", hasTests: false, dependencies: [
            "BatchDownloader",
            "NetworkSupportFake",
        ]),
    ]
}

private func domainTargets() -> [[Target]] {
    let type = TargetType.domain
    return [
        target(type, name: "TestResources", hasTests: false, resources: [
            .copy("test_data"),
        ]),

        target(type, name: "ReciterService", dependencies: [
            "Localization",
            "SystemDependencies",
            "Utilities",
            "QuranKit",
            "Preferences",
            "QuranAudio",
            "VLogging",
            "Crashing",
            "Zip",
            .product(name: "OrderedCollections", package: "swift-collections"),
        ], testDependencies: [
            "ReciterServiceFake",
            "SystemDependenciesFake",
        ]),

        target(type, name: "ReciterServiceFake", hasTests: false, dependencies: [
            "ReciterService",
            "SystemDependenciesFake",
            "TestResources",
        ]),

        target(type, name: "AudioUpdater", dependencies: [
            "NetworkSupport",
            "Preferences",
            "AudioTimingPersistence",
            "SystemDependencies",
            "VLogging",
            "Crashing",
            "ReciterService",
        ], testDependencies: [
            "NetworkSupportFake",
            "ReciterServiceFake",
            "SystemDependenciesFake",
        ]),

        target(type, name: "AudioTimingService", hasTests: false, dependencies: [
            "AudioTimingPersistence",
        ]),

        target(type, name: "QuranAudioKit", dependencies: [
            "BatchDownloader",
            "AudioTimingService",
            "ReciterService",
            "QuranTextKit",
            "QueuePlayer",
            "TestResources",
            "SystemDependencies",
            "Zip",
        ], testDependencies: [
            "SystemDependenciesFake",
            "TranslationServiceFake",
            "BatchDownloaderFake",
            "ReciterServiceFake",
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        ], testExclude: [
            "__Snapshots__",
        ]),

        target(type, name: "QuranTextKit", dependencies: [
            "TranslationService",
            "WordFrameService",
            "QuranKit",
            "VerseTextPersistence",
        ], testDependencies: [
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            "ReadingService",
            "TranslationServiceFake",
            "SystemDependenciesFake",
            "TestResources",
        ], testExclude: [
            "__Snapshots__",
        ]),

        target(type, name: "TranslationService", dependencies: [
            "QuranText",
            "TranslationPersistence",
            "VerseTextPersistence",
            "BatchDownloader",
            "Localization",
            "Preferences",
            "SystemDependencies",
            "Zip",
        ], testDependencies: [
            "TranslationServiceFake",
            "BatchDownloaderFake",
        ]),

        target(type, name: "TranslationServiceFake", hasTests: false, dependencies: [
            "TranslationService",
            "SystemDependenciesFake",
            "Utilities",
            "TestResources",
            "AsyncUtilitiesForTesting",
        ]),

        target(type, name: "WordFrameService", hasTests: false, dependencies: [
            "WordFramePersistence",
        ]),

        target(type, name: "WordTextService", dependencies: [
            "WordTextPersistence",
            "Preferences",
            "Crashing",
        ], testDependencies: [
            "TestResources",
        ]),

        target(type, name: "ImageService", dependencies: [
            "WordFrameService",
        ], testDependencies: [
            "ReadingService",
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            "TestResources",
        ], testExclude: [
            "__Snapshots__",
        ]),

        target(type, name: "ReadingService", dependencies: [
            "QuranKit",
            "VLogging",
            "Preferences",
            "SystemDependencies",
        ], testDependencies: [
            "AsyncUtilitiesForTesting",
            "SystemDependenciesFake",
        ]),

        target(type, name: "AnnotationsService", dependencies: [
            "QuranAnnotations",
            "LastPagePersistence",
            "NotePersistence",
            "PageBookmarkPersistence",
            "Preferences",
            "QuranTextKit",
            "Localization",
            "Analytics",
        ], testDependencies: [
        ]),
    ]
}

// MARK: - Builders

enum TargetType: String {
    case core = "Core"
    case data = "Data"
    case domain = "Domain"
    case model = "Model"
    case ui = "UI"

    // MARK: Internal

    // swiftformat:disable consecutiveSpaces
    static let validDependencies: [TargetType: Set<TargetType>] = [
        .core:   [.core],
        .model:  [.core, .model],
        .data:   [.core, .model, .data],
        .domain: [.core, .model, .data, .domain],
        .ui:     [.core, .model, .ui],
    ]
    // swiftformat:enable consecutiveSpaces
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
        .target(
            name: name,
            dependencies: dependencies,
            path: type.rawValue + "/" + name + (hasTests ? "/Sources" : ""),
            resources: resources,
            swiftSettings: settings
        ),
    ]
    guard hasTests else {
        return targets
    }
    targets.append(
        .testTarget(
            name: name + "Tests",
            dependencies: [.init(stringLiteral: name)] + testDependencies,
            path: type.rawValue + "/" + name + "/Tests",
            exclude: testExclude,
            resources: testResources,
            swiftSettings: settings
        )
    )
    return targets
}

func library(_ name: String) -> PackageDescription.Product {
    .library(name: name, targets: [name])
}

func validated(_ targets: [Target]) -> [Target] {
    var targetTypes: [String: TargetType] = [:]
    for target in targets {
        let parentDirectory = target.path!.components(separatedBy: "/")[0]
        targetTypes[target.name] = TargetType(rawValue: parentDirectory)!
    }

    for target in targets {
        let targetType = targetTypes[target.name]!
        let validDependencyTypes = TargetType.validDependencies[targetType]!
        for dependency in target.dependencies {
            let dependencyName = dependencyName(of: dependency)
            guard let dependencyType = targetTypes[dependencyName] else {
                continue
            }
            if !validDependencyTypes.contains(dependencyType) {
                fatalError("""

                Incorrect dependency.
                Target \(targetType.rawValue)\\\(target.name) shouldn't depend on \(dependencyType.rawValue)\\\(dependencyName).

                """)
            }
        }
    }

    return targets
}

func dependencyName(of dependency: Target.Dependency) -> String {
    if case .byNameItem(name: let name, condition: _) = dependency {
        return name
    }
    return ""
}

func testTargetLinkingAllPackageTargets(_ targets: [Target]) -> Target {
    let nonTestTargets = targets.filter { !$0.isTest }
    return .testTarget(
        name: "AllTargetsTests",
        dependencies: nonTestTargets.map { .init(stringLiteral: $0.name) },
        path: "AllTargetsTests",
        swiftSettings: settings
    )
}

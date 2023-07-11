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
    featuresTargets(),
]
.flatMap { $0 }
.flatMap { $0 }

let package = Package(
    name: "QuranEngine",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
    ],
    products: libraries(from: targets),
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
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),

        // UI
        .package(url: "https://github.com/GenericDataSource/GenericDataSource", from: "3.1.1"),
        .package(url: "https://github.com/SvenTiigi/WhatsNewKit.git", from: "1.3.7"),
        .package(url: "https://github.com/mohamede1945/Popover", branch: "master"),
        .package(url: "https://github.com/ninjaprox/NVActivityIndicatorView", from: "5.0.0"),

        // Testing
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.9.0"),

    ], targets: validated(targets) + [testTargetLinkingAllPackageTargets(targets)]
)

private func coreTargets() -> [[Target]] {
    let type = TargetType.core
    return [
        target(type, name: "SystemDependencies", hasTests: false, dependencies: [
            "Utilities",
        ]),
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
        ], testDependencies: [
            "AsyncUtilitiesForTesting",
        ]),

        target(type, name: "AppMigrator", dependencies: [
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
        target(type, name: "NoorFont", hasTests: false, resources: [
            .process("Resources"),
        ]),
        target(type, name: "NoorUI", hasTests: false, dependencies: [
            "UIx",
            "Crashing",
            "Localization",
            "Preferences",
            "QuranText",
            "QuranAnnotations",
            "QuranGeometry",
            "NoorFont",
            .product(name: "GenericDataSources", package: "GenericDataSource"),
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
            "QuranKit",
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
        target(type, name: "QuranResources", hasTests: false, resources: [
            .copy("Databases"),
        ]),

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
            "QuranResources",
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

        target(type, name: "SettingsService", hasTests: false, dependencies: [
            "Analytics",
            "Preferences",
            "Utilities",

        ]),
    ]
}

private func featuresTargets() -> [[Target]] {
    let type = TargetType.features
    return [
        target(type, name: "AppDependencies", hasTests: false, dependencies: [
            "NotePersistence",
            "QuranTextKit",
            "Analytics",
            "AnnotationsService",
            "BatchDownloader",
            "LastPagePersistence",
            "ReadingService",
            "QuranResources",
        ]),

        target(type, name: "FeaturesSupport", hasTests: false, dependencies: [
            "BatchDownloader",
            "Localization",
            "Analytics",
            "QuranAnnotations",
            "NoorUI",
        ]),

        target(type, name: "ReciterListFeature", hasTests: false, dependencies: [
            "QuranAudio",
            "NoorUI",
            "ReciterService",
        ]),

        target(type, name: "AyahMenuFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "QuranAudioKit",
            "AnnotationsService",
            "NoorUI",
        ]),

        target(type, name: "WhatsNewFeature", hasTests: false, dependencies: [
            "WhatsNewKit",
            "NoorUI",
            "Analytics",
        ], resources: [
            .copy("whats-new.plist"),
        ]),

        target(type, name: "WordPointerFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "WordTextService",
            "NoorUI",
            .product(name: "Popover_OC", package: "Popover"),
        ]),

        target(type, name: "AppMigrationFeature", hasTests: false, dependencies: [
            "AppMigrator",
            "ReciterService",
            "Utilities",
            "NVActivityIndicatorView",
            "NoorUI",
        ]),

        target(type, name: "AdvancedAudioOptionsFeature", hasTests: false, dependencies: [
            "ReciterListFeature",
            "QuranAudioKit",
        ]),

        target(type, name: "AudioBannerFeature", hasTests: false, dependencies: [
            "Caching",
            "AppDependencies",
            "ReciterListFeature",
            "AdvancedAudioOptionsFeature",
        ]),

        target(type, name: "AudioDownloadsFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "QuranAudioKit",
            "NoorUI",
            "ReadingService",
        ]),

        target(type, name: "MoreMenuFeature", hasTests: false, dependencies: [
            "NoorUI",
            "QuranTextKit",
            "WordTextService",
        ]),

        target(type, name: "NoteEditorFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "AnnotationsService",
            "NoorUI",
        ]),

        target(type, name: "BookmarksFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "FeaturesSupport",
            "AnnotationsService",
            "NoorUI",
            "ReadingService",
        ]),

        target(type, name: "QuranPagesFeature", hasTests: false, dependencies: [
            "NoorUI",
            "WeakSet",
            "QuranTextKit",
            "Caching",
        ]),

        target(type, name: "QuranImageFeature", hasTests: false, dependencies: [
            "NoorUI",
            "ImageService",
            "ReadingService",
            "QuranPagesFeature",
            "QuranTextKit",
            "Caching",
        ]),

        target(type, name: "ReadingSelectorFeature", hasTests: false, dependencies: [
            "ReadingService",
            "NoorUI",
            "QuranImageFeature",
        ]),

        target(type, name: "QuranTranslationFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "NoorUI",
            "ReadingService",
            "QuranPagesFeature",
            "QuranTextKit",
        ]),

        target(type, name: "QuranContentFeature", hasTests: false, dependencies: [
            "QuranImageFeature",
            "QuranTranslationFeature",
        ]),

        target(type, name: "TranslationsFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "TranslationService",
            "NoorUI",
        ]),

        target(type, name: "NotesFeature", hasTests: false, dependencies: [
            "AnnotationsService",
            "QuranTextKit",
            "AppDependencies",
            "FeaturesSupport",
            "ReadingService",
            "NoorUI",
        ]),

        target(type, name: "TranslationVerseFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "MoreMenuFeature",
            "TranslationsFeature",
            "QuranTranslationFeature",
            "QuranTextKit",
            "Caching",
        ]),

        target(type, name: "SearchFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "QuranTextKit",
            "FeaturesSupport",
            "ReadingService",
            "NoorUI",
        ]),

        target(type, name: "HomeFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "ReadingSelectorFeature",
            "AnnotationsService",
            "FeaturesSupport",
        ]),

        target(type, name: "QuranViewFeature", hasTests: false, dependencies: [
            "AudioBannerFeature",
            "QuranContentFeature",
            "AyahMenuFeature",
            "MoreMenuFeature",
            "NoteEditorFeature",
            "WordPointerFeature",
            "TranslationsFeature",
            "TranslationVerseFeature",
            "FeaturesSupport",
        ]),

        target(type, name: "SettingsFeature", hasTests: false, dependencies: [
            "AppDependencies",
            "SettingsService",
            "NoorUI",
            "VLogging",
            "AudioDownloadsFeature",
            "TranslationsFeature",
        ]),

        target(type, name: "AppStructureFeature", hasTests: false, dependencies: [
            "HomeFeature",
            "BookmarksFeature",
            "NotesFeature",
            "SearchFeature",
            "SettingsFeature",
            "QuranViewFeature",
            "WhatsNewFeature",
            "AudioUpdater",
            "AppMigrationFeature",
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
    case features = "Features"

    // MARK: Internal

    // swiftformat:disable consecutiveSpaces
    static let validDependencies: [TargetType: Set<TargetType>] = [
        .core:     [.core],
        .model:    [.core, .model],
        .ui:       [.core, .model, .ui],
        .data:     [.core, .model, .data],
        .domain:   [.core, .model, .data, .domain],
        .features: [.core, .model, .data, .domain, .ui, .features],
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
    validateDependenciesStructure(targets)
    validateNoTestDependenciesInAppTargets(targets)
    return targets
}

func validateNoTestDependenciesInAppTargets(_ targets: [Target]) {
    func isTestRelatedTargetName(_ name: String) -> Bool {
        ["fake", "test"].contains { testName in name.lowercased().contains(testName) }
    }

    let targets = targets.filter { target in !target.isTest && !isTestRelatedTargetName(target.name) }
    for target in targets {
        for dependency in target.dependencies {
            let dependencyName = dependencyName(of: dependency)
            if isTestRelatedTargetName(dependencyName) {
                fatalError("""

                Incorrect dependency.
                Target \(target.name) shouldn't depend on \(dependencyName) as it's a test dependency.

                """)
            }
        }
    }
}

func validateDependenciesStructure(_ targets: [Target]) {
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

func libraries(from targets: [Target]) -> [PackageDescription.Product] {
    let nonTestTargets = targets.filter { !$0.isTest }
    return nonTestTargets.map {
        library($0.name)
    }
}

//
//  AppDependenciesFake.swift
//
//
//  Created by Mohamed Afifi on 2026-10-30.
//

import Analytics
import AnalyticsFake
import AppDependencies
import BatchDownloader
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import Foundation
import LastPagePersistence
import NoorUI
import NotePersistence
import PageBookmarkPersistence
import ReadingService
#if QURAN_SYNC
import AuthenticationClient
import AuthenticationClientFake
import LegacyDataMigration
import LegacyDataPersistence
import MobileSync
import MobileSyncTestSupport
#endif

/// The dependencies feature builders read in tests, backed by real temporary stores; the rest are unused.
public final class AppDependenciesFake: AppDependencies {
    // MARK: Lifecycle

    #if QURAN_SYNC
    public init(
        appIconCatalog: AppIconCatalog = primaryIconCatalog,
        authenticationClient: any AuthenticationClient = AuthenticationClientFake()
    ) {
        self.appIconCatalog = appIconCatalog
        self.authenticationClient = authenticationClient
    }
    #else
    public init(appIconCatalog: AppIconCatalog = primaryIconCatalog) {
        self.appIconCatalog = appIconCatalog
    }
    #endif

    // MARK: Public

    #if QURAN_SYNC
    public let authenticationClient: any AuthenticationClient

    public var legacyDataImportCoordinator: LegacyDataImportCoordinator {
        LegacyDataImportCoordinator(
            reader: CoreDataLegacyDataReader(stack: store.stack()),
            quranDataService: quranDataService
        )
    }

    public var quranDataService: MobileSyncDataService { MobileSyncTestDatabase.shared.quranDataService }
    public var lastPagePersistence: LastPagePersistence { fatalError("Unused in tests") }
    #else
    public private(set) lazy var lastPagePersistence: LastPagePersistence = CoreDataLastPagePersistence(stack: store.stack())
    #endif

    public let appIconCatalog: AppIconCatalog

    public var databasesURL: URL { URL(fileURLWithPath: "/tmp") }
    public var wordsDatabase: URL { URL(fileURLWithPath: "/tmp/words.db") }
    public var appHost: URL { URL(string: "https://quran.com")! }
    public var filesAppHost: URL { URL(string: "https://files.quran.com")! }
    public var quranProfileURL: URL { URL(string: "https://quran.com/profile")! }
    public var logsDirectory: URL { URL(fileURLWithPath: "/tmp/logs") }
    public var isDebugLoggingAlwaysEnabled: Bool { false }
    public var databasesDirectory: URL { URL(fileURLWithPath: "/tmp") }
    public var supportsCloudKit: Bool { false }
    public var downloadManager: DownloadManager { fatalError("Unused in tests") }
    public var analytics: AnalyticsLibrary { AnalyticsLibrarySpy() }
    public var readingResources: ReadingResourcesService { fatalError("Unused in tests") }
    public var remoteResources: ReadingRemoteResources? { nil }
    public var coreDataStack: CoreDataStack { fatalError("Unused in tests") }
    public var notePersistence: NotePersistence { fatalError("Unused in tests") }
    public var pageBookmarkPersistence: PageBookmarkPersistence { fatalError("Unused in tests") }

    // MARK: Internal

    /// A catalog with only the primary icon.
    @usableFromInline static var primaryIconCatalog: AppIconCatalog {
        AppIconCatalog(sections: [
            .init(id: "all", title: "All", previewSize: .large, options: [
                AppIconOption(
                    id: "primary",
                    alternateIconName: nil,
                    name: "Primary",
                    previewImageName: "app-icon-primary",
                    accent: AppIconAccent(light: .black, dark: .white, onDark: .black)
                ),
            ]),
        ])
    }

    // MARK: Private

    /// Backs the last page store without sync, and the legacy import with sync.
    private let store = TemporaryCoreDataStore()
}

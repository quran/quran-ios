//
//  AppDependenciesStub.swift
//
//
//  Created by Mohamed Afifi on 2026-10-29.
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
import LegacyDataMigration
import MobileSync
import MobileSyncTestSupport
#endif

/// The dependencies `ContentViewModel` reads: a real last page store. The rest are unused in these tests.
final class AppDependenciesStub: AppDependencies {
    // MARK: Lifecycle

    init() {
        #if !QURAN_SYNC
        lastPagePersistence = CoreDataLastPagePersistence(stack: store.stack())
        #endif
    }

    // MARK: Internal

    #if QURAN_SYNC
    var quranDataService: MobileSyncDataService { MobileSyncTestDatabase.shared.quranDataService }
    var authenticationClient: any AuthenticationClient { fatalError("Unused in tests") }
    var legacyDataImportCoordinator: LegacyDataImportCoordinator { fatalError("Unused in tests") }
    var lastPagePersistence: LastPagePersistence { fatalError("Unused in tests") }
    #else
    let lastPagePersistence: LastPagePersistence
    #endif

    var appIconCatalog: AppIconCatalog { fatalError("Unused in tests") }
    var databasesURL: URL { fatalError("Unused in tests") }
    var wordsDatabase: URL { fatalError("Unused in tests") }
    var appHost: URL { fatalError("Unused in tests") }
    var filesAppHost: URL { fatalError("Unused in tests") }
    var quranProfileURL: URL { fatalError("Unused in tests") }
    var logsDirectory: URL { fatalError("Unused in tests") }
    var isDebugLoggingAlwaysEnabled: Bool { false }
    var databasesDirectory: URL { fatalError("Unused in tests") }
    var supportsCloudKit: Bool { false }
    var downloadManager: DownloadManager { fatalError("Unused in tests") }
    var analytics: AnalyticsLibrary { AnalyticsLibrarySpy() }
    var readingResources: ReadingResourcesService { fatalError("Unused in tests") }
    var remoteResources: ReadingRemoteResources? { nil }
    var coreDataStack: CoreDataStack { fatalError("Unused in tests") }
    var notePersistence: NotePersistence { fatalError("Unused in tests") }
    var pageBookmarkPersistence: PageBookmarkPersistence { fatalError("Unused in tests") }

    // MARK: Private

    private let store = TemporaryCoreDataStore()
}

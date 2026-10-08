//
//  AppDependencies.swift
//
//
//  Created by Mohamed Afifi on 2023-06-18.
//

import Analytics
import AnnotationsService
import AuthenticationClient
import BatchDownloader
import CoreDataModel
import CoreDataPersistence
import Foundation
import LastPagePersistence
#if QURAN_SYNC
import LegacyDataMigration
import LegacyDataPersistence
import MobileSync
#endif
import NoorUI
import NotePersistence
import PageBookmarkPersistence
import QuranResources
import QuranTextKit
import ReadingService
import SystemDependencies

/// What the app provides. None of it needs the Core Data store, so it's available before launch opens it.
public protocol AppHostDependencies {
    var databasesURL: URL { get }
    var quranUthmaniV2Database: URL { get }
    var wordsDatabase: URL { get }
    var appHost: URL { get }
    var filesAppHost: URL { get }
    var quranProfileURL: URL { get }
    var logsDirectory: URL { get }
    var databasesDirectory: URL { get }

    var supportsCloudKit: Bool { get }

    var downloadManager: DownloadManager { get }
    var analytics: AnalyticsLibrary { get }
    var readingResources: ReadingResourcesService { get }
    var remoteResources: ReadingRemoteResources? { get }

    /// The Home Screen icons the app offers.
    var appIconCatalog: AppIconCatalog { get }

    #if QURAN_SYNC
    var authenticationClient: any AuthenticationClient { get }
    var quranDataService: QuranDataService { get }
    #endif
}

/// The host app's dependencies plus the services backed by the Core Data store.
///
/// Launch creates it once the store opens. It can't be created without a loaded store, so
/// nothing can read the store before launch opens it.
public final class AppDependencies: AppHostDependencies {
    // MARK: Lifecycle

    public init(host: AppHostDependencies, coreDataStack: CoreDataStack) {
        self.host = host
        self.coreDataStack = coreDataStack
    }

    // MARK: Public

    public private(set) lazy var lastPagePersistence: LastPagePersistence = CoreDataLastPagePersistence(stack: coreDataStack)
    public private(set) lazy var notePersistence: NotePersistence = CoreDataNotePersistence(stack: coreDataStack)
    public private(set) lazy var pageBookmarkPersistence: PageBookmarkPersistence = CoreDataPageBookmarkPersistence(stack: coreDataStack)

    #if QURAN_SYNC
    /// Imports the legacy Core Data store. Share one instance so scans never overlap.
    public private(set) lazy var legacyDataImportCoordinator = LegacyDataImportCoordinator(
        reader: CoreDataLegacyDataReader(stack: coreDataStack),
        quranDataService: quranDataService
    )
    #endif

    public var databasesURL: URL { host.databasesURL }
    public var quranUthmaniV2Database: URL { host.quranUthmaniV2Database }
    public var wordsDatabase: URL { host.wordsDatabase }
    public var appHost: URL { host.appHost }
    public var filesAppHost: URL { host.filesAppHost }
    public var quranProfileURL: URL { host.quranProfileURL }
    public var logsDirectory: URL { host.logsDirectory }
    public var databasesDirectory: URL { host.databasesDirectory }

    public var supportsCloudKit: Bool { host.supportsCloudKit }

    public var downloadManager: DownloadManager { host.downloadManager }
    public var analytics: AnalyticsLibrary { host.analytics }
    public var readingResources: ReadingResourcesService { host.readingResources }
    public var remoteResources: ReadingRemoteResources? { host.remoteResources }

    public var appIconCatalog: AppIconCatalog { host.appIconCatalog }

    #if QURAN_SYNC
    public var authenticationClient: any AuthenticationClient { host.authenticationClient }
    public var quranDataService: QuranDataService { host.quranDataService }
    #endif

    /// Loads the app's Core Data store, migrating it if needed.
    ///
    /// A failure, such as the device being out of storage, is thrown; call again to retry.
    public static func loadCoreDataStack() throws -> CoreDataStack {
        try CoreDataStack(name: "Quran", modelUrl: CoreDataModelResources.quranModel) {
            let lastPage = CoreDataLastPageUniquifier()
            let pageBookmark = CoreDataPageBookmarkUniquifier()
            return [lastPage, pageBookmark]
        }
    }

    @MainActor
    public func lastPageService() -> any LastPageService {
        #if QURAN_SYNC
        return MobileSyncLastPageService(quranDataService: quranDataService)
        #else
        return PersistenceLastPageService(persistence: lastPagePersistence)
        #endif
    }

    public func noteService() -> NoteService {
        NoteService(
            persistence: notePersistence,
            analytics: analytics
        )
    }

    // MARK: Private

    private let host: AppHostDependencies
    private let coreDataStack: CoreDataStack
}

extension AppHostDependencies {
    public var quranUthmaniV2Database: URL { QuranResources.quranUthmaniV2Database }

    public func textDataService() -> QuranTextDataService {
        QuranTextDataService(
            databasesURL: databasesURL,
            quranFileURL: quranUthmaniV2Database
        )
    }

    @MainActor
    public func appIconService() -> AppIconService {
        AppIconService(
            catalog: appIconCatalog,
            iconAccess: DefaultAlternateIconAccess(),
            bundle: DefaultSystemBundle()
        )
    }

    #if QURAN_SYNC
    public func readingBookmarkService() -> MobileSyncReadingBookmarkService {
        MobileSyncReadingBookmarkService(quranDataService: quranDataService)
    }

    public func mobileSyncNoteService() -> MobileSyncNoteService {
        MobileSyncNoteService(quranDataService: quranDataService)
    }

    public func ayahBookmarkCollectionService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: quranDataService)
    }

    public func ayahHighlightService() -> MobileSyncAyahHighlightService {
        MobileSyncAyahHighlightService(quranDataService: quranDataService)
    }
    #endif
}

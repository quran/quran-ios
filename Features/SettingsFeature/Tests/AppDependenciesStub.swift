//
//  AppDependenciesStub.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Analytics
import AppDependencies
import BatchDownloader
import Foundation
import LastPagePersistence
import NoorUI
import NotePersistence
import PageBookmarkPersistence
import ReadingService
#if QURAN_SYNC
import AuthenticationClient
import AuthenticationClientFake
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import LegacyDataMigration
import LegacyDataPersistence
import MobileSync
import MobileSyncTestSupport
#endif

/// The dependencies the Settings builders read; the rest are unused in these tests.
struct AppDependenciesStub: AppDependencies {
    var appIconCatalog = AppIconCatalog(sections: [
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

    #if QURAN_SYNC
    var authenticationClient: any AuthenticationClient = AuthenticationClientFake()
    let legacyDataImportCoordinator = LegacyDataImportCoordinator(
        reader: CoreDataLegacyDataReader(stack: CoreDataStack.testingStack()),
        quranDataService: MobileSyncTestDatabase.shared.quranDataService
    )
    var quranDataService: QuranDataService { MobileSyncTestDatabase.shared.quranDataService }
    #endif

    var databasesURL: URL { URL(fileURLWithPath: "/tmp") }
    var wordsDatabase: URL { URL(fileURLWithPath: "/tmp/words.db") }
    var appHost: URL { URL(string: "https://quran.com")! }
    var filesAppHost: URL { URL(string: "https://files.quran.com")! }
    var quranProfileURL: URL { URL(string: "https://quran.com/profile")! }
    var logsDirectory: URL { URL(fileURLWithPath: "/tmp/logs") }
    var databasesDirectory: URL { URL(fileURLWithPath: "/tmp") }
    var supportsCloudKit: Bool { false }
    var downloadManager: DownloadManager { fatalError("Unused in tests") }
    var analytics: AnalyticsLibrary { NoopAnalytics() }
    var readingResources: ReadingResourcesService { fatalError("Unused in tests") }
    var remoteResources: ReadingRemoteResources? { nil }
    var lastPagePersistence: LastPagePersistence { fatalError("Unused in tests") }
    var notePersistence: NotePersistence { fatalError("Unused in tests") }
    var pageBookmarkPersistence: PageBookmarkPersistence { fatalError("Unused in tests") }
}

struct NoopAnalytics: AnalyticsLibrary {
    func logEvent(_: String, value _: String) {}
}

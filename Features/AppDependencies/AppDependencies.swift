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
import Foundation
import LastPagePersistence
#if QURAN_SYNC
import MobileSync
#endif
import NotePersistence
import PageBookmarkPersistence
import QuranResources
import QuranTextKit
import ReadingService

public protocol AppDependencies {
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

    var lastPagePersistence: LastPagePersistence { get }
    var notePersistence: NotePersistence { get }
    var pageBookmarkPersistence: PageBookmarkPersistence { get }

    #if QURAN_SYNC
    var authenticationClient: (any AuthenticationClient)? { get }
    var quranDataService: QuranDataService { get }
    #endif
}

extension AppDependencies {
    public var quranUthmaniV2Database: URL { QuranResources.quranUthmaniV2Database }

    public func lastPageService() -> any LastPageService {
        #if QURAN_SYNC
        return MobileSyncLastPageService(quranDataService: quranDataService)
        #else
        return PersistenceLastPageService(persistence: lastPagePersistence)
        #endif
    }

    public func textDataService() -> QuranTextDataService {
        QuranTextDataService(
            databasesURL: databasesURL,
            quranFileURL: quranUthmaniV2Database
        )
    }

    public func noteService() -> NoteService {
        NoteService(
            persistence: notePersistence,
            analytics: analytics
        )
    }

    public func noteVerseTextService() -> NoteVerseTextService {
        NoteVerseTextService(textService: textDataService())
    }

    #if QURAN_SYNC
    public func mobileSyncNoteService() -> MobileSyncNoteService {
        MobileSyncNoteService(quranDataService: quranDataService)
    }
    #endif
}

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

    var oauthClient: AuthentincationDataManager { get }
}

extension AppDependencies {
    public var quranUthmaniV2Database: URL { QuranResources.quranUthmaniV2Database }

    public func textDataService() -> QuranTextDataService {
        QuranTextDataService(
            databasesURL: databasesURL,
            quranFileURL: quranUthmaniV2Database
        )
    }

    public func noteService() -> NoteService {
        NoteService(
            persistence: notePersistence,
            textService: textDataService(),
            analytics: analytics
        )
    }
}

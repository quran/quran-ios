//
//  BookmarksViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

import Analytics
import AnnotationsService
#if QURAN_SYNC
import AuthenticationClient
#endif
import Combine
import FeaturesSupport
import QuranAnnotations
import QuranKit
import ReadingService
import SwiftUI
import UIKit
import VLogging

@MainActor
final class BookmarksViewModel: ObservableObject {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        analytics: AnalyticsLibrary,
        service: PageBookmarkService,
        authenticationClient: (any AuthenticationClient)?,
        navigateTo: @escaping (Page) -> Void,
        showCollectionsAction: (@MainActor (UIViewController) async -> Void)? = nil,
        showOldPageBookmarksAction: (@MainActor (UIViewController) async -> Void)? = nil
    ) {
        self.analytics = analytics
        self.service = service
        self.authenticationClient = authenticationClient
        self.navigateTo = navigateTo
        presentCollectionsAction = showCollectionsAction
        presentOldPageBookmarksAction = showOldPageBookmarksAction
        isSyncBannerDismissed = preferences.isSyncBannerDismissed
    }
    #else
    init(
        analytics: AnalyticsLibrary,
        service: PageBookmarkService,
        navigateTo: @escaping (Page) -> Void
    ) {
        self.analytics = analytics
        self.service = service
        self.navigateTo = navigateTo
    }
    #endif

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error? = nil
    @Published var bookmarks: [PageBookmark] = []
    #if QURAN_SYNC
    @Published var isAuthenticated: Bool = false
    @Published var isSyncBannerDismissed: Bool

    weak var presenter: UIViewController?

    var shouldShowSyncBanner: Bool {
        !isAuthenticated && !isSyncBannerDismissed
    }

    var showCollectionsAction: (@MainActor @Sendable () async -> Void)? {
        guard presentCollectionsAction != nil else {
            return nil
        }
        return { [weak self] in
            await self?.showCollections()
        }
    }

    var showOldPageBookmarksAction: (@MainActor @Sendable () async -> Void)? {
        guard presentOldPageBookmarksAction != nil else {
            return nil
        }
        return { [weak self] in
            await self?.showOldPageBookmarks()
        }
    }
    #endif

    func start() async {
        #if QURAN_SYNC
        if let authenticationClient {
            isAuthenticated = await authenticationClient.safelyRestoreState() == .authenticated
        } else {
            isAuthenticated = false
        }
        #endif

        let bookmarksSequence = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .map { [service] reading in
                service.pageBookmarks(quran: reading.quran)
            }
            .switchToLatest()
            .values()

        for await bookmarks in bookmarksSequence {
            self.bookmarks = bookmarks
                .sorted { $0.creationDate > $1.creationDate }
        }
    }

    func navigateTo(_ item: PageBookmark) {
        logger.info("Bookmarks: select bookmark at \(item.page)")
        analytics.openingQuran(from: .bookmarks)
        navigateTo(item.page)
    }

    func deleteItem(_ pageBookmark: PageBookmark) async {
        logger.info("Bookmarks: delete bookmark at \(pageBookmark.page)")
        analytics.removeBookmarkPage(pageBookmark.page)
        do {
            try await service.removePageBookmark(pageBookmark.page)
        } catch {
            self.error = error
        }
    }

    func deleteAll() async {
        logger.info("Bookmarks: delete all bookmarks")
        do {
            try await service.removeAllPageBookmarks()
        } catch {
            self.error = error
        }
    }

    #if QURAN_SYNC
    func loginToQuranCom() async {
        guard let presenter else {
            return
        }

        do {
            let authenticationClient = try requireAuthenticationClient()
            try await authenticationClient.login(on: presenter)
            isAuthenticated = true
        } catch {
            logger.error("Failed to login to Quran.com from bookmarks: \(error)")
            self.error = error
        }
    }

    func dismissSyncBanner() {
        isSyncBannerDismissed = true
        preferences.isSyncBannerDismissed = true
    }

    func showCollections() async {
        guard let presenter else {
            return
        }
        await presentCollectionsAction?(presenter)
    }

    func showOldPageBookmarks() async {
        guard let presenter else {
            return
        }
        await presentOldPageBookmarksAction?(presenter)
    }
    #endif

    // MARK: Private

    private let navigateTo: (Page) -> Void
    private let analytics: AnalyticsLibrary
    private let service: PageBookmarkService
    private let readingPreferences = ReadingPreferences.shared
    #if QURAN_SYNC
    private var authenticationClient: (any AuthenticationClient)?
    private var presentCollectionsAction: (@MainActor (UIViewController) async -> Void)?
    private var presentOldPageBookmarksAction: (@MainActor (UIViewController) async -> Void)?
    private let preferences = BookmarksPreferences.shared

    private func requireAuthenticationClient() throws -> any AuthenticationClient {
        guard let authenticationClient else {
            throw AuthenticationClientError.clientIsNotAuthenticated(nil)
        }
        return authenticationClient
    }
    #endif
}

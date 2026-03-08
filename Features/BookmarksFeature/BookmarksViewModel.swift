//
//  BookmarksViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

import Analytics
import AnnotationsService
import Combine
import FeaturesSupport
import QuranAnnotations
import QuranKit
import QuranProfileService
import ReadingService
import SwiftUI
import UIKit
import VLogging

@MainActor
final class BookmarksViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        service: PageBookmarkService,
        quranProfileService: QuranProfileService,
        navigateTo: @escaping (Page) -> Void
    ) {
        self.analytics = analytics
        self.service = service
        self.quranProfileService = quranProfileService
        self.navigateTo = navigateTo
        isSyncBannerDismissed = preferences.isSyncBannerDismissed
    }

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error? = nil
    @Published var bookmarks: [PageBookmark] = []
    @Published var isAuthenticated: Bool = false
    @Published var isSyncBannerDismissed: Bool

    weak var presenter: UIViewController?

    var shouldShowSyncBanner: Bool {
        !isAuthenticated && !isSyncBannerDismissed
    }

    func start() async {
        isAuthenticated = await quranProfileService.refreshAuthenticationState() == .authenticated
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

    func dismissSyncBanner() {
        isSyncBannerDismissed = true
        preferences.isSyncBannerDismissed = true
    }

    func loginToQuranCom() async {
        guard let presenter else {
            return
        }

        do {
            try await quranProfileService.login(on: presenter)
            isAuthenticated = true
        } catch {
            logger.error("Failed to login to Quran.com from bookmarks: \(error)")
            self.error = error
        }
    }

    // MARK: Private

    private let navigateTo: (Page) -> Void
    private let analytics: AnalyticsLibrary
    private let service: PageBookmarkService
    private let quranProfileService: QuranProfileService
    private let readingPreferences = ReadingPreferences.shared
    private let preferences = BookmarksPreferences.shared
}

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
import QuranProfileService
import QuranAnnotations
import QuranKit
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
        isSyncBannerDismissed = UserDefaults.standard.bool(forKey: Self.bannerDismissedPreferenceKey)
    }

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error? = nil
    @Published var bookmarks: [PageBookmark] = []
    @Published var isAuthenticated: Bool = false
    @Published var isSyncBannerDismissed: Bool

    weak var presenter: UIViewController?

    var isAuthenticationAvailable: Bool {
        quranProfileService.isAuthenticationAvailable
    }

    var shouldShowSyncBanner: Bool {
        isAuthenticationAvailable && !isAuthenticated && !isSyncBannerDismissed
    }

    func start() async {
        await refreshAuthenticationState()
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

    func dismissSyncBanner() {
        isSyncBannerDismissed = true
        UserDefaults.standard.set(true, forKey: Self.bannerDismissedPreferenceKey)
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

    func refreshAuthenticationState() async {
        guard isAuthenticationAvailable else {
            isAuthenticated = false
            return
        }

        do {
            isAuthenticated = try await quranProfileService.restoreState() == .authenticated
        } catch {
            logger.error("Failed to restore Quran.com auth state in bookmarks: \(error)")
            isAuthenticated = await quranProfileService.authenticationState() == .authenticated
        }
    }

    // MARK: Private

    private static let bannerDismissedPreferenceKey = "com.quran.sync.bookmarks.banner-dismissed"

    private let navigateTo: (Page) -> Void
    private let analytics: AnalyticsLibrary
    private let service: PageBookmarkService
    private let quranProfileService: QuranProfileService
    private let readingPreferences = ReadingPreferences.shared
}

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
import ReadingService
import SwiftUI
import VLogging

@MainActor
final class BookmarksViewModel: ObservableObject {
    // MARK: Lifecycle

    init(analytics: AnalyticsLibrary, service: PageBookmarkService, navigateTo: @escaping (Page) -> Void) {
        self.analytics = analytics
        self.service = service
        self.navigateTo = navigateTo
    }

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error? = nil
    @Published var bookmarks: [PageBookmark] = []

    func start() async {
        let bookmarksSequence = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .map { [service] reading in
                service.pageBookmarks(quran: reading.quran)
            }
            .switchToLatest()
            .values()

        for await bookmarks in bookmarksSequence {
            self.bookmarks = bookmarks
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

    // MARK: Private

    private let navigateTo: (Page) -> Void
    private let analytics: AnalyticsLibrary
    private let service: PageBookmarkService
    private let readingPreferences = ReadingPreferences.shared
}

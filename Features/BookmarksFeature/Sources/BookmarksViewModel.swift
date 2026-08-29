//
//  BookmarksViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

#if !QURAN_SYNC
import Analytics
import AnnotationsService
import Combine
import QuranAnnotations
import QuranKit
import ReadingService
import SwiftUI
import UIx
import VLogging

@MainActor
final class BookmarksViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        service: PageBookmarkService,
        navigateTo: @escaping (Page) -> Void
    ) {
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
                .filter { !pendingDeletionBookmarks.contains($0.id) }
                .sorted { $0.creationDate > $1.creationDate }
        }
    }

    func navigateTo(_ item: PageBookmark) {
        logger.info("Bookmarks: select bookmark at \(item.page)")
        analytics.openingQuran(from: .bookmarks)
        navigateTo(item.page)
    }

    func deleteItem(_ pageBookmark: PageBookmark) -> AsyncAction? {
        guard pendingDeletionBookmarks.insert(pageBookmark.id).inserted else {
            return nil
        }

        logger.info("Bookmarks: delete bookmark at \(pageBookmark.page)")
        analytics.removeBookmarkPage(pageBookmark.page)
        bookmarks.removeAll { $0.id == pageBookmark.id }

        return { [weak self] in
            guard let self else { return }
            do {
                try await service.removePageBookmark(pageBookmark)
            } catch {
                bookmarks.append(pageBookmark)
                bookmarks.sort { $0.creationDate > $1.creationDate }
                self.error = error
            }
            pendingDeletionBookmarks.remove(pageBookmark.id)
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

    // MARK: Private

    private let navigateTo: (Page) -> Void
    private let analytics: AnalyticsLibrary
    private let service: PageBookmarkService
    private let readingPreferences = ReadingPreferences.shared
    private var pendingDeletionBookmarks: Set<Page> = []
}
#endif

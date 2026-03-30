//
//  BookmarksViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

import Analytics
import AnnotationsService
import Combine
import CompletionService
import FeaturesSupport
import QuranAnnotations
import QuranKit
import ReadingService
import SwiftUI
import VLogging

@MainActor
final class BookmarksViewModel: ObservableObject {
    // MARK: Lifecycle

    init(analytics: AnalyticsLibrary, service: PageBookmarkService, completionService: CompletionService?, navigateTo: @escaping (Page) -> Void) {
        self.analytics = analytics
        self.service = service
        self.completionService = completionService
        self.navigateTo = navigateTo
    }

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error?
    @Published var bookmarks: [PageBookmark] = []

    /// Maps page number to completion name for the most recent CompletionBookmark on that page.
    @Published var completionNameByPage: [Int: String] = [:]

    func start() async {
        async let bookmarksTask: Void = subscribeToBookmarks()
        async let completionBookmarksTask: Void = subscribeToCompletionBookmarks()
        async let completionsTask: Void = subscribeToCompletions()
        _ = await (bookmarksTask, completionBookmarksTask, completionsTask)
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

    // MARK: Private

    private let navigateTo: (Page) -> Void
    private let analytics: AnalyticsLibrary
    private let service: PageBookmarkService
    private let completionService: CompletionService?
    private let readingPreferences = ReadingPreferences.shared

    private var rawBookmarks: [PageBookmark] = []
    private var allCompletionBookmarks: [CompletionBookmark] = []
    private var completionNamesById: [UUID: String] = [:]

    private func subscribeToBookmarks() async {
        let bookmarksSequence = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .map { [service] reading in
                service.pageBookmarks(quran: reading.quran)
            }
            .switchToLatest()
            .values()

        for await newBookmarks in bookmarksSequence {
            rawBookmarks = newBookmarks.sorted { $0.creationDate > $1.creationDate }
            updateFilteredBookmarks()
        }
    }

    private func subscribeToCompletionBookmarks() async {
        guard let completionService else { return }
        let quran = readingPreferences.reading.quran
        let sequence = completionService.allCompletionBookmarks(quran: quran).values()
        for await allCBs in sequence {
            allCompletionBookmarks = allCBs
            updateFilteredBookmarks()
        }
    }

    private func subscribeToCompletions() async {
        guard let completionService else { return }
        let quran = readingPreferences.reading.quran
        let sequence = completionService.completions(quran: quran).values()
        for await completions in sequence {
            completionNamesById = Dictionary(
                completions.compactMap { c in c.name.map { (c.id, $0) } },
                uniquingKeysWith: { first, _ in first }
            )
            updateFilteredBookmarks()
        }
    }

    private func updateFilteredBookmarks() {
        if allCompletionBookmarks.isEmpty {
            bookmarks = rawBookmarks
            completionNameByPage = [:]
            return
        }
        bookmarks = filterBookmarks(rawBookmarks, completionBookmarks: allCompletionBookmarks)
        completionNameByPage = buildCompletionNameByPage(allCompletionBookmarks)
    }

    private func filterBookmarks(
        _ bookmarks: [PageBookmark],
        completionBookmarks: [CompletionBookmark]
    ) -> [PageBookmark] {
        var highestPagePerCompletion: [UUID: Int] = [:]
        for cb in completionBookmarks {
            let current = highestPagePerCompletion[cb.completionId] ?? 0
            if cb.page.pageNumber > current {
                highestPagePerCompletion[cb.completionId] = cb.page.pageNumber
            }
        }

        let pageToCompletion: [Int: UUID] = Dictionary(
            completionBookmarks.map { ($0.page.pageNumber, $0.completionId) },
            uniquingKeysWith: { _, new in new }
        )

        return bookmarks.filter { bookmark in
            let pageNum = bookmark.page.pageNumber
            if let cid = pageToCompletion[pageNum] {
                return highestPagePerCompletion[cid] == pageNum
            }
            return true
        }
    }

    private func buildCompletionNameByPage(_ completionBookmarks: [CompletionBookmark]) -> [Int: String] {
        // Map page → most recent CompletionBookmark
        var pageToLatestCB: [Int: CompletionBookmark] = [:]
        for cb in completionBookmarks {
            let pageNum = cb.page.pageNumber
            if let existing = pageToLatestCB[pageNum] {
                if cb.createdAt > existing.createdAt {
                    pageToLatestCB[pageNum] = cb
                }
            } else {
                pageToLatestCB[pageNum] = cb
            }
        }

        var result: [Int: String] = [:]
        for (pageNum, cb) in pageToLatestCB {
            if let name = completionNamesById[cb.completionId] {
                result[pageNum] = name
            }
        }
        return result
    }
}

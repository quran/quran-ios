//
//  BookmarksInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Analytics
import AnnotationsService
import Combine
import Crashing
import FeaturesSupport
import Foundation
import QuranAnnotations
import QuranKit
import ReadingService
import VLogging

@MainActor
protocol BookmarksPresentable: AnyObject {
    func setItems(_ items: [PageBookmark])
    func showErrorAlert(error: Error)
}

@MainActor
final class BookmarksInteractor {
    // MARK: Lifecycle

    init(analytics: AnalyticsLibrary, service: PageBookmarkService) {
        self.analytics = analytics
        self.service = service
    }

    // MARK: Internal

    weak var presenter: BookmarksPresentable?
    weak var listener: QuranNavigator?

    func viewDidLoad() {
        // Observe persistence changes
        loadBookmarks()
    }

    func selectItem(_ item: PageBookmark) {
        logger.info("Bookmarks: select bookmark at \(item.page)")
        navigateTo(page: item.page)
    }

    func deleteItem(_ pageBookmark: PageBookmark) {
        logger.info("Bookmarks: delete bookmark at \(pageBookmark.page)")
        analytics.removeBookmarkPage(pageBookmark.page)
        service.removePageBookmark(pageBookmark.page)
            .catch(on: .main) { error in
                self.presenter?.showErrorAlert(error: error)
            }
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary

    private let service: PageBookmarkService
    private let readingPreferences = ReadingPreferences.shared

    private var cancellables: Set<AnyCancellable> = []

    private func loadBookmarks() {
        readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .map { [service] reading in
                service.pageBookmarks(quran: reading.quran)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak presenter] bookmarks in
                presenter?.setItems(bookmarks)
            }
            .store(in: &cancellables)
    }

    private func navigateTo(page: Page) {
        analytics.openingQuran(from: .bookmarks)
        listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
    }
}

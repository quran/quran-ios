//
//  ReadingBookmarkService.swift
//
//  Created by Ahmed Nabil on 2026-05-09.
//

import Foundation
#if QURAN_SYNC
    import MobileSync
    import ReadingService
#endif
import QuranKit

public enum QuranReadingBookmark: Equatable {
    case ayah(AyahNumber, Date)
    case page(Page, Date)

    public var ayah: AyahNumber {
        switch self {
        case .ayah(let ayah, _): ayah
        case .page(let page, _): page.firstVerse
        }
    }

    public var page: Page {
        switch self {
        case .ayah(let ayah, _): ayah.page
        case .page(let page, _): page
        }
    }

    public var lastUpdated: Date {
        switch self {
        case .ayah(_, let lastUpdated), .page(_, let lastUpdated): lastUpdated
        }
    }

    public func isAyahBookmark(for ayah: AyahNumber) -> Bool {
        guard case .ayah(let bookmarkedAyah, _) = self else {
            return false
        }
        return bookmarkedAyah == ayah
    }

    public func isReadingBookmark(for ayah: AyahNumber) -> Bool {
        switch self {
        case .ayah(let bookmarkedAyah, _):
            return bookmarkedAyah == ayah
        case .page(let page, _):
            return page == ayah.page
        }
    }

    public func isPageBookmark(for pages: [Page]) -> Bool {
        pages.contains(page)
    }
}

#if QURAN_SYNC
    public struct ReadingBookmarkSequence: AsyncSequence {
        public typealias Element = QuranReadingBookmark?

        public struct AsyncIterator: AsyncIteratorProtocol {
            init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
                var iterator = sequence.makeAsyncIterator()
                nextValue = {
                    try await iterator.next()
                }
            }

            public mutating func next() async throws -> Element? {
                try await nextValue()
            }

            private let nextValue: () async throws -> Element?
        }

        init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
            makeIterator = {
                AsyncIterator(sequence)
            }
        }

        public func makeAsyncIterator() -> AsyncIterator {
            makeIterator()
        }

        private let makeIterator: () -> AsyncIterator
    }

    public struct ReadingBookmarkService {
        // MARK: Lifecycle

        public init(syncService: SyncService, readingPreferences: ReadingPreferences = .shared) {
            self.syncService = syncService
            self.readingPreferences = readingPreferences
        }

        // MARK: Public

        public func nextEducationPresentationIsExpanded() -> Bool {
            let isExpanded = !ReadingBookmarkPreferences.shared.isEducationShown
            ReadingBookmarkPreferences.shared.isEducationShown = true
            return isExpanded
        }

        public func readingBookmarkSequence() -> ReadingBookmarkSequence {
            let sequence = syncService.readingBookmarkSequence()
                .map { bookmark in
                    Self.bookmark(from: bookmark, quran: readingPreferences.reading.quran)
                }
            return ReadingBookmarkSequence(sequence)
        }

        @discardableResult
        public func addReadingBookmark(page: Page) async throws -> QuranReadingBookmark {
            let bookmark = try await syncService.addPageReadingBookmark(page: Int32(page.pageNumber))
            return .page(page, bookmark.lastUpdated)
        }

        @discardableResult
        public func addReadingBookmark(ayah: AyahNumber) async throws -> QuranReadingBookmark {
            let bookmark = try await syncService.addAyahReadingBookmark(
                sura: Int32(ayah.sura.suraNumber),
                ayah: Int32(ayah.ayah)
            )
            return .ayah(ayah, bookmark.lastUpdated)
        }

        public func removeReadingBookmark() async throws {
            _ = try await syncService.removeReadingBookmark()
        }

        public static func bookmark(from bookmark: (any ReadingBookmark)?, quran: Quran) -> QuranReadingBookmark? {
            switch bookmark {
            case let bookmark as AyahReadingBookmark:
                return AyahNumber(quran: quran, sura: Int(bookmark.sura), ayah: Int(bookmark.ayah)).map {
                    QuranReadingBookmark.ayah($0, bookmark.lastUpdated)
                }
            case let bookmark as PageReadingBookmark:
                return Page(quran: quran, pageNumber: Int(bookmark.page)).map {
                    QuranReadingBookmark.page($0, bookmark.lastUpdated)
                }
            default:
                return nil
            }
        }

        // MARK: Private

        private let syncService: SyncService
        private let readingPreferences: ReadingPreferences
    }
#else
    public struct ReadingBookmarkService {}
#endif

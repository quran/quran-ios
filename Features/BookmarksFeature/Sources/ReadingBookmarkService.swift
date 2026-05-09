#if QURAN_SYNC
    //
    //  ReadingBookmarkService.swift
    //
    //  Created by OpenAI on 2026-05-09.
    //

    import MobileSync
    import QuranKit
    import ReadingService

    public enum QuranReadingBookmark: Equatable {
        case ayah(AyahNumber)
        case page(Page)

        public var page: Page {
            switch self {
            case .ayah(let ayah): ayah.page
            case .page(let page): page
            }
        }
    }

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

        public func addReadingBookmark(page: Page) async throws {
            _ = try await syncService.addPageReadingBookmark(page: Int32(page.pageNumber))
        }

        public func addReadingBookmark(ayah: AyahNumber) async throws {
            _ = try await syncService.addAyahReadingBookmark(
                sura: Int32(ayah.sura.suraNumber),
                ayah: Int32(ayah.ayah)
            )
        }

        public func removeReadingBookmark() async throws {
            _ = try await syncService.removeReadingBookmark()
        }

        public static func bookmark(from bookmark: (any ReadingBookmark)?, quran: Quran) -> QuranReadingBookmark? {
            switch bookmark {
            case let bookmark as AyahReadingBookmark:
                return AyahNumber(quran: quran, sura: Int(bookmark.sura), ayah: Int(bookmark.ayah)).map(QuranReadingBookmark.ayah)
            case let bookmark as PageReadingBookmark:
                return Page(quran: quran, pageNumber: Int(bookmark.page)).map(QuranReadingBookmark.page)
            default:
                return nil
            }
        }

        // MARK: Private

        private let syncService: SyncService
        private let readingPreferences: ReadingPreferences
    }
#endif

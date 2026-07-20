#if QURAN_SYNC
//
//  MobileSyncReadingBookmarkService.swift
//

@preconcurrency import MobileSync
import QuranAnnotations
import QuranKit
import Utilities

public struct MobileSyncReadingBookmarkService {
    // MARK: Lifecycle

    public init(quranDataService: QuranDataService, storedPageQuran: Quran = .hafsMadani1405) {
        self.quranDataService = quranDataService
        self.storedPageQuran = storedPageQuran
    }

    // MARK: Public

    public func readingBookmarkSequence(quran: Quran) -> AnyAsyncSequence<ReadingPositionBookmark?> {
        let storedPageQuran = storedPageQuran
        let sequence = quranDataService.readingBookmarkSequence()
            .map { bookmark in
                bookmark.flatMap {
                    Self.readingBookmark(from: $0, quran: quran, storedPageQuran: storedPageQuran)
                }
            }
        return .init(sequence)
    }

    @discardableResult
    public func addReadingBookmark(
        at location: ReadingPositionBookmark.Location
    ) async throws -> ReadingPositionBookmark {
        switch location {
        case .ayah(let ayah):
            let bookmark = try await quranDataService.addAyahReadingBookmark(
                sura: Int32(ayah.sura.suraNumber),
                ayah: Int32(ayah.ayah)
            )
            return ReadingPositionBookmark(
                id: bookmark.id,
                location: location,
                modifiedOn: bookmark.lastUpdated
            )
        case .page(let page):
            let storedPage = try storedPage(for: page)
            let bookmark = try await quranDataService.addPageReadingBookmark(page: Int32(storedPage.pageNumber))
            return ReadingPositionBookmark(
                id: bookmark.id,
                location: location,
                modifiedOn: bookmark.lastUpdated
            )
        }
    }

    public func removeReadingBookmark() async throws -> Bool {
        try await quranDataService.removeReadingBookmark()
    }

    // MARK: Private

    private let quranDataService: QuranDataService
    private let storedPageQuran: Quran

    private static func readingBookmark(
        from bookmark: any ReadingBookmark,
        quran: Quran,
        storedPageQuran: Quran
    ) -> ReadingPositionBookmark? {
        let location: ReadingPositionBookmark.Location
        switch bookmark {
        case let bookmark as AyahReadingBookmark:
            guard let ayah = AyahNumber(
                quran: quran,
                sura: Int(bookmark.sura),
                ayah: Int(bookmark.ayah)
            ) else {
                return nil
            }
            location = .ayah(ayah)
        case let bookmark as PageReadingBookmark:
            guard let storedPage = Page(quran: storedPageQuran, pageNumber: Int(bookmark.page)),
                  let page = QuranPageMapper(destination: quran).mapPage(storedPage)
            else {
                return nil
            }
            location = .page(page)
        default:
            return nil
        }
        return ReadingPositionBookmark(
            id: bookmark.id,
            location: location,
            modifiedOn: bookmark.lastUpdated
        )
    }

    private func storedPage(for page: Page) throws -> Page {
        guard let storedPage = QuranPageMapper(destination: storedPageQuran).mapPage(page) else {
            throw PageMappingError.unableToMapPage(
                pageNumber: page.pageNumber,
                source: page.quran,
                destination: storedPageQuran
            )
        }
        return storedPage
    }
}
#endif

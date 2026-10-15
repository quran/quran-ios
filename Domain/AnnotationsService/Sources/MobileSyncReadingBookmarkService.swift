#if QURAN_SYNC
//
//  MobileSyncReadingBookmarkService.swift
//

import MobileSync
import QuranAnnotations
import QuranKit
import Utilities

public struct MobileSyncReadingBookmarkService {
    // MARK: Lifecycle

    public init(quranDataService: MobileSyncDataService, storedPageQuran: Quran = .hafsMadani1405) {
        self.quranDataService = quranDataService
        self.storedPageQuran = storedPageQuran
    }

    // MARK: Public

    public func placedReadingBookmarksSequence(quran: Quran) -> AnyAsyncSequence<[PlacedReadingBookmark]> {
        .init(readingBookmarksSequence(quran: quran).map { bookmarks in
            bookmarks.compactMap(PlacedReadingBookmark.init)
        })
    }

    public func readingBookmarksSequence(quran: Quran) -> AnyAsyncSequence<[QuranAnnotations.ReadingBookmark]> {
        let storedPageQuran = storedPageQuran
        let sequence = quranDataService.readingBookmarksSequence()
            .map { bookmarks in
                bookmarks.compactMap {
                    Self.readingBookmark(from: $0, quran: quran, storedPageQuran: storedPageQuran)
                }
                .sorted { $0.slot.sortIndex < $1.slot.sortIndex }
            }
        return .init(sequence)
    }

    @discardableResult
    public func addReadingBookmark(
        at placement: PlacedReadingBookmark.Placement,
        slot: QuranAnnotations.ReadingBookmarkSlot
    ) async throws -> PlacedReadingBookmark {
        switch placement {
        case .ayah(let ayah):
            let bookmark = try await quranDataService.setAyahReadingBookmark(
                slot: slot.mobileSyncSlot,
                sura: ayah.sura.suraNumber,
                ayah: ayah.ayah
            )
            return PlacedReadingBookmark(
                id: bookmark.id,
                slot: slot,
                placement: .ayah(ayah),
                modifiedOn: bookmark.lastUpdated,
                name: bookmark.name
            )
        case .page(let page):
            let storedPage = try storedPage(for: page)
            let bookmark = try await quranDataService.setPageReadingBookmark(
                slot: slot.mobileSyncSlot,
                page: storedPage.pageNumber
            )
            return PlacedReadingBookmark(
                id: bookmark.id,
                slot: slot,
                placement: .page(page),
                modifiedOn: bookmark.lastUpdated,
                name: bookmark.name
            )
        }
    }

    @discardableResult
    public func clearReadingBookmark(in slot: QuranAnnotations.ReadingBookmarkSlot) async throws -> QuranAnnotations.ReadingBookmark {
        let bookmark = try await quranDataService.clearReadingBookmark(slot: slot.mobileSyncSlot)
        return QuranAnnotations.ReadingBookmark(
            id: bookmark.id,
            slot: slot,
            placement: .unplaced,
            modifiedOn: bookmark.lastUpdated,
            name: bookmark.name
        )
    }

    @discardableResult
    public func renameReadingBookmark(
        in slot: QuranAnnotations.ReadingBookmarkSlot,
        name: String?,
        quran: Quran
    ) async throws -> QuranAnnotations.ReadingBookmark {
        let bookmark = try await quranDataService.renameReadingBookmark(slot: slot.mobileSyncSlot, name: name)
        guard let renamed = Self.readingBookmark(from: bookmark, quran: quran, storedPageQuran: storedPageQuran) else {
            throw MappingError.invalidBookmark
        }
        return renamed
    }

    // MARK: Internal

    static func readingBookmark(
        from bookmark: MobileSyncReadingBookmark,
        quran: Quran,
        storedPageQuran: Quran
    ) -> QuranAnnotations.ReadingBookmark? {
        let placement: QuranAnnotations.ReadingBookmark.Placement
        switch bookmark.placement {
        case let .ayah(sura, ayah):
            guard let ayah = AyahNumber(quran: quran, sura: sura, ayah: ayah) else {
                return nil
            }
            placement = .ayah(ayah)
        case let .page(pageNumber, mushafID):
            // The web numbers IndoPak pages in its own mushafs, which have no page mapping here, so such a
            // bookmark shows as empty, like a sura or juz bookmark set on the web.
            guard mushafID == MobileSyncReadingBookmark.madaniMushafID else {
                placement = .unplaced
                break
            }
            guard let storedPage = Page(quran: storedPageQuran, pageNumber: pageNumber),
                  let page = QuranPageMapper(destination: quran).mapPage(storedPage)
            else {
                return nil
            }
            placement = .page(page)
        case .unplaced:
            placement = .unplaced
        }
        return QuranAnnotations.ReadingBookmark(
            id: bookmark.id,
            slot: ReadingBookmarkSlot(mobileSyncSlot: bookmark.slot),
            placement: placement,
            modifiedOn: bookmark.lastUpdated,
            name: bookmark.name
        )
    }

    // MARK: Private

    private enum MappingError: Error {
        case invalidBookmark
    }

    private let quranDataService: MobileSyncDataService
    private let storedPageQuran: Quran

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

private extension QuranAnnotations.ReadingBookmarkSlot {
    var sortIndex: Int {
        switch self {
        case .teal: return 0
        case .orange: return 1
        case .red: return 2
        }
    }

    init(mobileSyncSlot: MobileSyncReadingBookmarkSlot) {
        switch mobileSyncSlot {
        case .teal: self = .teal
        case .orange: self = .orange
        case .red: self = .red
        }
    }

    var mobileSyncSlot: MobileSyncReadingBookmarkSlot {
        switch self {
        case .teal:
            .teal
        case .orange:
            .orange
        case .red:
            .red
        }
    }
}
#endif

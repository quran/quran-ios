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

    public init(quranDataService: MobileSyncDataService) {
        self.quranDataService = quranDataService
    }

    // MARK: Public

    public func placedReadingBookmarksSequence(quran: Quran) -> AnyAsyncSequence<[PlacedReadingBookmark]> {
        .init(readingBookmarksSequence(quran: quran).map { bookmarks in
            bookmarks.compactMap(PlacedReadingBookmark.init)
        })
    }

    public func readingBookmarksSequence(quran: Quran) -> AnyAsyncSequence<[QuranAnnotations.ReadingBookmark]> {
        let sequence = quranDataService.readingBookmarksSequence(mushaf: quran.mobileSyncMushaf)
            .map { bookmarks in
                bookmarks.compactMap {
                    Self.readingBookmark(from: $0, quran: quran)
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
            let bookmark = try await quranDataService.setPageReadingBookmark(
                slot: slot.mobileSyncSlot,
                page: page.pageNumber,
                mushaf: page.quran.mobileSyncMushaf
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
        let bookmark = try await quranDataService.renameReadingBookmark(
            slot: slot.mobileSyncSlot,
            name: name,
            mushaf: quran.mobileSyncMushaf
        )
        guard let renamed = Self.readingBookmark(from: bookmark, quran: quran) else {
            throw MappingError.invalidBookmark
        }
        return renamed
    }

    // MARK: Internal

    static func readingBookmark(
        from bookmark: MobileSyncReadingBookmark,
        quran: Quran
    ) -> QuranAnnotations.ReadingBookmark? {
        let placement: QuranAnnotations.ReadingBookmark.Placement
        switch bookmark.placement {
        case let .ayah(sura, ayah):
            guard let ayah = AyahNumber(quran: quran, sura: sura, ayah: ayah) else {
                return nil
            }
            placement = .ayah(ayah)
        case let .page(pageNumber, mushaf):
            // MobileSync maps pages into the mushaf they were read in; a page it couldn't map arrives unplaced.
            // A page that still isn't one of the reader's pages keeps the slot and its name, like that case.
            guard mushaf == quran.mobileSyncMushaf, let page = Page(quran: quran, pageNumber: pageNumber) else {
                placement = .unplaced
                break
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
}

private extension Quran {
    /// The page layout MobileSync sets and reads this Quran's page bookmarks in. Every reading shares one of
    /// these layouts, and IndoPak's page numbers, 2...611, are already the ones MobileSync expects.
    var mobileSyncMushaf: MobileSyncMushaf {
        switch pageMushaf {
        case .madani1405: .madani1405
        case .madani1440: .madani1440
        case .indoPak: .indopak15Lines
        }
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

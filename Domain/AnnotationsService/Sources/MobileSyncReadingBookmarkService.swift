#if QURAN_SYNC
//
//  MobileSyncReadingBookmarkService.swift
//

@preconcurrency import MobileSync
import QuranAnnotations
import QuranKit
import Utilities
import VLogging

public struct MobileSyncReadingBookmarkService {
    // MARK: Lifecycle

    public init(quranDataService: QuranDataService, storedPageQuran: Quran = .hafsMadani1405) {
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
                sura: Int32(ayah.sura.suraNumber),
                ayah: Int32(ayah.ayah)
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
                page: Int32(storedPage.pageNumber)
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

    // MARK: Private

    private enum MappingError: Error {
        case invalidBookmark
    }

    private let quranDataService: QuranDataService
    private let storedPageQuran: Quran

    private static func readingBookmark(
        from bookmark: any MobileSync.ReadingBookmark,
        quran: Quran,
        storedPageQuran: Quran
    ) -> QuranAnnotations.ReadingBookmark? {
        let placement: QuranAnnotations.ReadingBookmark.Placement
        switch bookmark {
        case let bookmark as AyahReadingBookmark:
            guard let ayah = AyahNumber(
                quran: quran,
                sura: Int(bookmark.sura),
                ayah: Int(bookmark.ayah)
            ) else {
                return nil
            }
            placement = .ayah(ayah)
        case let bookmark as PageReadingBookmark:
            guard let storedPage = Page(quran: storedPageQuran, pageNumber: Int(bookmark.page)),
                  let page = QuranPageMapper(destination: quran).mapPage(storedPage)
            else {
                return nil
            }
            placement = .page(page)
        case is EmptyReadingBookmark:
            placement = .unplaced
        default:
            return nil
        }
        guard let slot = ReadingBookmarkSlot(mobileSyncSlot: bookmark.slot) else {
            return nil
        }
        return QuranAnnotations.ReadingBookmark(
            id: bookmark.id,
            slot: slot,
            placement: placement,
            modifiedOn: bookmark.lastUpdated,
            name: bookmark.name
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

private extension QuranAnnotations.ReadingBookmarkSlot {
    var sortIndex: Int {
        switch self {
        case .coral: return 0
        case .teal: return 1
        case .indigo: return 2
        }
    }

    init?(mobileSyncSlot: MobileSync.ReadingBookmarkSlot) {
        if mobileSyncSlot == .coral {
            self = .coral
        } else if mobileSyncSlot == .teal {
            self = .teal
        } else if mobileSyncSlot == .indigo {
            self = .indigo
        } else {
            logger.error("Unsupported mobile sync slot \(mobileSyncSlot.name)")
            return nil
        }
    }

    var mobileSyncSlot: MobileSync.ReadingBookmarkSlot {
        switch self {
        case .coral:
            .coral
        case .teal:
            .teal
        case .indigo:
            .indigo
        }
    }
}
#endif

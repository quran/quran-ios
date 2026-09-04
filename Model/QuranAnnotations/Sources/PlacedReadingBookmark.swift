#if QURAN_SYNC
import Foundation
import QuranKit

public struct PlacedReadingBookmark: Equatable {
    // MARK: Lifecycle

    public init(id: String, slot: ReadingBookmarkSlot, placement: Placement, modifiedOn: Date, name: String? = nil) {
        self.id = id
        self.slot = slot
        self.placement = placement
        self.modifiedOn = modifiedOn
        self.name = name
    }

    public init?(_ bookmark: ReadingBookmark) {
        let placement: Placement
        switch bookmark.placement {
        case .unplaced:
            return nil
        case .ayah(let ayah):
            placement = .ayah(ayah)
        case .page(let page):
            placement = .page(page)
        }
        self.init(
            id: bookmark.id,
            slot: bookmark.slot,
            placement: placement,
            modifiedOn: bookmark.modifiedOn,
            name: bookmark.name
        )
    }

    // MARK: Public

    public enum Placement: Equatable {
        case ayah(AyahNumber)
        case page(Page)
    }

    public let id: String
    public let slot: ReadingBookmarkSlot
    public let placement: Placement
    public let modifiedOn: Date
    public let name: String?

    public var sura: Sura {
        switch placement {
        case .ayah(let ayah):
            ayah.sura
        case .page(let page):
            page.firstVerse.sura
        }
    }

    public func isAt(_ ayah: AyahNumber) -> Bool {
        switch placement {
        case .ayah(let bookmarkedAyah):
            return bookmarkedAyah == ayah
        case .page:
            return false
        }
    }
}
#endif

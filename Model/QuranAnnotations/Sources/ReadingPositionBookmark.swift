#if QURAN_SYNC
//
//  ReadingPositionBookmark.swift
//

import Foundation
import QuranKit

public enum ReadingBookmarkSlot: CaseIterable, Sendable {
    case coral
    case teal
    case indigo
}

public struct ReadingPositionBookmark: Equatable {
    // MARK: Lifecycle

    public init(id: String, slot: ReadingBookmarkSlot, location: Location, modifiedOn: Date) {
        self.id = id
        self.slot = slot
        self.location = location
        self.modifiedOn = modifiedOn
    }

    // MARK: Public

    public enum Location: Equatable {
        case ayah(AyahNumber)
        case page(Page)
    }

    public let id: String
    public let slot: ReadingBookmarkSlot
    public let location: Location
    public let modifiedOn: Date

    public var sura: Sura {
        switch location {
        case .ayah(let ayah):
            ayah.sura
        case .page(let page):
            page.firstVerse.sura
        }
    }

    public func isAt(_ ayah: AyahNumber) -> Bool {
        switch location {
        case .ayah(let bookmarkedAyah):
            return bookmarkedAyah == ayah
        case .page:
            return false
        }
    }
}
#endif

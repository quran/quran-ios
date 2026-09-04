#if QURAN_SYNC
//
//  ReadingBookmark.swift
//

import Foundation
import QuranKit

public enum ReadingBookmarkSlot: CaseIterable, Sendable {
    case coral
    case teal
    case indigo
}

public struct ReadingBookmark: Equatable {
    // MARK: Lifecycle

    public init(id: String, slot: ReadingBookmarkSlot, placement: Placement, modifiedOn: Date, name: String? = nil) {
        self.id = id
        self.slot = slot
        self.placement = placement
        self.modifiedOn = modifiedOn
        self.name = name
    }

    public init(_ bookmark: PlacedReadingBookmark) {
        let placement: Placement = switch bookmark.placement {
        case .ayah(let ayah):
            .ayah(ayah)
        case .page(let page):
            .page(page)
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
        case unplaced
        case ayah(AyahNumber)
        case page(Page)
    }

    public let id: String
    public let slot: ReadingBookmarkSlot
    public let placement: Placement
    public let modifiedOn: Date
    public let name: String?
}
#endif

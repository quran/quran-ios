#if QURAN_SYNC
//
//  HeldItemRow.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Foundation
import Localization
import MobileSync
import NoorUI
import QuranAnnotations
import QuranKit

/// An item that doesn't sync, as the Not syncing list shows it.
struct HeldItemRow: Identifiable {
    enum Kind: Equatable {
        case note
        case collection
        case bookmark
    }

    // MARK: Internal

    let item: MobileSyncHeldItem
    let kind: Kind
    let title: MultipartText
    let reason: String
    /// How many held items wait on this one, or `nil` when none do.
    let waiting: String?

    var id: String {
        [item.type.idPrefix, item.collectionID, item.id].compactMap { $0 }.joined(separator: "/")
    }

    /// A row for each held item the user can fix, in MobileSync's order.
    static func rows(for items: [MobileSyncHeldItem], lookup: HeldItemLookup) -> [HeldItemRow] {
        items.filter { $0.waitingOn == nil }.map { item in
            let waitingItems = items.filter { $0.waitingOn == item }
            return HeldItemRow(
                item: item,
                kind: item.type.rowKind,
                title: title(of: item, lookup: lookup),
                reason: reason(for: item),
                waiting: waiting(waitingItems)
            )
        }
    }

    // MARK: Private

    private static func title(of item: MobileSyncHeldItem, lookup: HeldItemLookup) -> MultipartText {
        switch item.type {
        case .note:
            guard let range = lookup.notesByID[item.id]?.ranges.first.flatMap(ayahRange) else {
                return .text(l("sync.held.deleted-note"))
            }
            return .localizedFormat("sync.held.note", "\(ayahRange: range)")
        case .collection:
            guard let collection = lookup.collectionsByID[item.id] else {
                return .text(l("sync.held.deleted-collection"))
            }
            return .localizedFormat("sync.held.collection", .text(collection.displayName))
        case .collectionBookmark:
            guard let ayah = bookmarkedAyah(item.id) else {
                return .text(l("sync.held.deleted-bookmark"))
            }
            return .localizedFormat("sync.held.bookmark", "\(ayah: ayah)")
        case .readingBookmark:
            guard let bookmark = lookup.readingBookmarksByID[item.id] else {
                return .text(l("sync.held.deleted-bookmark"))
            }
            let name = bookmark.name.flatMap { $0.isEmpty ? nil : $0 } ?? ReadingBookmarkSlot(bookmark.slot).displayName
            return .localizedFormat("sync.held.reading-bookmark", .text(name))
        case .readingSession:
            return .text(l("sync.held.reading-progress"))
        }
    }

    private static func reason(for item: MobileSyncHeldItem) -> String {
        switch item.reason {
        case .tooShort:
            l("sync.held.reason.too-short")
        case .tooLong:
            l("sync.held.reason.too-long")
        case .invalidRange, .invalidVerse:
            l("sync.held.reason.invalid-verses")
        case .invalidLocation:
            l("sync.held.reason.invalid-location")
        case .reservedName:
            l("sync.held.reason.reserved-name")
        case .readOnly:
            l("sync.held.reason.read-only")
        case .invalidSlot, .tooMuchMetadata, .rejectedByServer:
            notAccepted(item.type)
        case .waitingOnParent:
            l("sync.held.reason.waiting-on-collection")
        case .waitingOnOtherItem:
            l("sync.held.reason.waiting-on-other")
        case .notYetLinked:
            l("sync.held.reason.not-linked")
        }
    }

    private static func notAccepted(_ type: MobileSyncResourceType) -> String {
        switch type {
        case .note: l("sync.held.reason.not-accepted.note")
        case .collection: l("sync.held.reason.not-accepted.collection")
        case .collectionBookmark, .readingBookmark: l("sync.held.reason.not-accepted.bookmark")
        case .readingSession: l("sync.held.reason.not-accepted")
        }
    }

    private static func waiting(_ items: [MobileSyncHeldItem]) -> String? {
        guard !items.isEmpty else {
            return nil
        }
        let areVerses = items.allSatisfy { $0.type == .collectionBookmark }
        return lFormat(areVerses ? "sync.held.waiting.verses" : "sync.held.waiting.items", items.count)
    }

    private static func ayahRange(_ range: MobileSyncNoteRange) -> ClosedRange<AyahNumber>? {
        guard let start = AyahNumber(quran: quran, sura: range.startSura, ayah: range.startAyah),
              let end = AyahNumber(quran: quran, sura: range.endSura, ayah: range.endAyah),
              start <= end
        else {
            return nil
        }
        return start ... end
    }

    /// A collection bookmark's id is its `sura:ayah`.
    private static func bookmarkedAyah(_ id: String) -> AyahNumber? {
        let numbers = id.split(separator: ":").compactMap { Int($0) }
        guard numbers.count == 2 else {
            return nil
        }
        return AyahNumber(quran: quran, sura: numbers[0], ayah: numbers[1])
    }

    /// Sync identifies verses by sura and ayah, which every Hafs mushaf numbers the same.
    private static let quran = Quran.hafsMadani1405
}

private extension MobileSyncResourceType {
    var rowKind: HeldItemRow.Kind {
        switch self {
        case .note: .note
        case .collection: .collection
        case .collectionBookmark, .readingBookmark, .readingSession: .bookmark
        }
    }

    var idPrefix: String {
        switch self {
        case .note: "note"
        case .collection: "collection"
        case .collectionBookmark: "collection-bookmark"
        case .readingSession: "reading-session"
        case .readingBookmark: "reading-bookmark"
        }
    }
}

private extension MobileSyncCollection {
    var displayName: String {
        isDefault ? l("bookmarks.collections.favorites") : name
    }
}

private extension ReadingBookmarkSlot {
    init(_ slot: MobileSyncReadingBookmarkSlot) {
        switch slot {
        case .teal: self = .teal
        case .orange: self = .orange
        case .red: self = .red
        }
    }
}
#endif

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

    /// How the user fixes the item.
    enum Edit: Equatable {
        /// Opens the note editor; a note's verses never change, so only its text can.
        case note(id: String)
        /// Renames the collection, now called `name`.
        case collection(id: String, name: String)
        /// Renames the reading bookmark in `slot`, now called `name`, or unnamed when it's empty.
        case readingBookmark(slot: ReadingBookmarkSlot, name: String)
    }

    // MARK: Internal

    let item: MobileSyncHeldItem
    let kind: Kind
    let title: MultipartText
    let reason: String
    /// How many held items wait on this one, or `nil` when none do.
    let waiting: String?
    /// `nil` when editing can't fix the item, such as a deleted note.
    let edit: Edit?

    var id: String {
        [item.type.idPrefix, item.collectionID, item.id].compactMap { $0 }.joined(separator: "/")
    }

    /// A row for each held item the user can fix, in MobileSync's order.
    static func rows(for items: [MobileSyncHeldItem], lookup: HeldItemLookup) -> [HeldItemRow] {
        items.filter { $0.waitingOn == nil }.map { item in
            let waitingItems = items.filter { $0.waitingOn?.names(item) == true }
            return HeldItemRow(
                item: item,
                kind: item.type.rowKind,
                title: title(of: item, lookup: lookup),
                reason: reason(for: item),
                waiting: waiting(waitingItems),
                edit: edit(item, lookup: lookup)
            )
        }
    }

    // MARK: Private

    private static func title(of item: MobileSyncHeldItem, lookup: HeldItemLookup) -> MultipartText {
        switch item.type {
        case .note:
            // Only a note missing from this device is deleted. One whose verses don't exist shows their numbers.
            guard let range = lookup.notesByID[item.id]?.ranges.first else {
                return .text(l("sync.held.deleted-note"))
            }
            guard let ayahs = ayahRange(range) else {
                return .localizedFormat("sync.held.note", .text(rawRange(range)))
            }
            return .localizedFormat("sync.held.note", "\(ayahRange: ayahs)")
        case .collection:
            guard let collection = lookup.collectionsByID[item.id] else {
                return .text(l("sync.held.deleted-collection"))
            }
            return .localizedFormat("sync.held.collection", .text(collection.displayName))
        case .collectionBookmark:
            // The id names the verse even when the verse doesn't exist, so show its numbers then.
            guard let ayah = bookmarkedAyah(item.id) else {
                return .localizedFormat("sync.held.bookmark", .text(rawVerse(item.id)))
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

    private static func edit(_ item: MobileSyncHeldItem, lookup: HeldItemLookup) -> Edit? {
        switch (item.type, item.reason) {
        case (.note, .tooShort), (.note, .tooLong), (.note, .rejectedByServer):
            guard lookup.notesByID[item.id] != nil else {
                return nil
            }
            return .note(id: item.id)
        case (.collection, .tooShort), (.collection, .tooLong), (.collection, .reservedName),
             (.collection, .rejectedByServer), (.collection, .waitingOnOtherItem):
            // Favorites and read-only collections can't be renamed.
            guard let collection = lookup.collectionsByID[item.id], !collection.isDefault, !collection.isReadOnly else {
                return nil
            }
            return .collection(id: item.id, name: collection.name)
        case (.readingBookmark, .tooLong), (.readingBookmark, .rejectedByServer):
            guard let bookmark = lookup.readingBookmarksByID[item.id] else {
                return nil
            }
            return .readingBookmark(slot: ReadingBookmarkSlot(bookmark.slot), name: bookmark.name ?? "")
        default:
            return nil
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

    /// `2:300`, or `2:300–3:1`, with the app's digits.
    private static func rawRange(_ range: MobileSyncNoteRange) -> String {
        let start = rawVerse(sura: range.startSura, ayah: range.startAyah)
        guard range.startSura != range.endSura || range.startAyah != range.endAyah else {
            return start
        }
        return start + "–" + rawVerse(sura: range.endSura, ayah: range.endAyah)
    }

    private static func rawVerse(_ id: String) -> String {
        let numbers = id.split(separator: ":").compactMap { Int($0) }
        guard numbers.count == 2 else {
            return id
        }
        return rawVerse(sura: numbers[0], ayah: numbers[1])
    }

    private static func rawVerse(sura: Int, ayah: Int) -> String {
        "\(NumberFormatter.shared.format(sura)):\(NumberFormatter.shared.format(ayah))"
    }

    /// Sync identifies verses by sura and ayah, which every Hafs mushaf numbers the same.
    private static let quran = Quran.hafsMadani1405
}

private extension MobileSyncHeldItem.Blocker {
    /// Whether it is `item`, which it names by identity.
    func names(_ item: MobileSyncHeldItem) -> Bool {
        type == item.type && id == item.id && collectionID == item.collectionID
    }
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

#if QURAN_SYNC
//
//  HeldItemLookup.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Foundation
import MobileSync

/// The local items that held items refer to by id, to name them.
struct HeldItemLookup: Equatable {
    enum Change {
        case notes([MobileSyncNote])
        case collections([MobileSyncCollectionWithBookmarks])
        case readingBookmarks([MobileSyncReadingBookmark])
    }

    // MARK: Lifecycle

    init(
        notes: [MobileSyncNote] = [],
        collections: [MobileSyncCollection] = [],
        readingBookmarks: [MobileSyncReadingBookmark] = []
    ) {
        notesByID = Self.byID(notes, id: \.id)
        collectionsByID = Self.byID(collections, id: \.id)
        readingBookmarksByID = Self.byID(readingBookmarks, id: \.id)
    }

    // MARK: Internal

    private(set) var notesByID: [String: MobileSyncNote]
    private(set) var collectionsByID: [String: MobileSyncCollection]
    private(set) var readingBookmarksByID: [String: MobileSyncReadingBookmark]

    /// Follows the notes, collections and reading bookmarks until the task iterating it is cancelled.
    static func changes(of service: MobileSyncDataService) -> AsyncStream<Change> {
        AsyncStream { continuation in
            let tasks = [
                forward(service.notesSequence(), to: continuation, as: Change.notes),
                forward(service.collectionsWithBookmarksSequence(), to: continuation, as: Change.collections),
                // Only names are read, which are the same in every mushaf.
                forward(service.readingBookmarksSequence(mushaf: .madani1405), to: continuation, as: Change.readingBookmarks),
            ]
            continuation.onTermination = { _ in
                tasks.forEach { $0.cancel() }
            }
        }
    }

    mutating func apply(_ change: Change) {
        switch change {
        case .notes(let notes):
            notesByID = Self.byID(notes, id: \.id)
        case .collections(let collections):
            collectionsByID = Self.byID(collections.map(\.collection), id: \.id)
        case .readingBookmarks(let readingBookmarks):
            readingBookmarksByID = Self.byID(readingBookmarks, id: \.id)
        }
    }

    // MARK: Private

    private static func byID<Item>(_ items: [Item], id: (Item) -> String) -> [String: Item] {
        Dictionary(items.map { (id($0), $0) }, uniquingKeysWith: { first, _ in first })
    }
}
#endif

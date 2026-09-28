#if QURAN_SYNC
//
//  AyahBookmarkCollection.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import Foundation
import QuranKit

public struct AyahBookmarkCollection: Identifiable {
    // MARK: Lifecycle

    public init(id: String, name: String, isDefault: Bool, isSystem: Bool, bookmarks: [AyahCollectionBookmark]) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.isSystem = isSystem
        self.bookmarks = bookmarks
    }

    // MARK: Public

    /// The collection that holds bookmarks migrated from legacy page bookmarks. It stays the same in
    /// every locale, so migrated and presented collections always match.
    public static let oldPageBookmarksName = "Old Page Bookmarks"

    public let id: String
    public let name: String
    public let isDefault: Bool
    public let isSystem: Bool
    public let bookmarks: [AyahCollectionBookmark]

    public var canDelete: Bool { !isSystem }
    public var canRename: Bool { !isSystem }

    public var kind: AyahBookmarkCollectionKind {
        if isDefault {
            .defaultBookmarks
        } else if name.caseInsensitiveCompare(Self.oldPageBookmarksName) == .orderedSame {
            .oldPageBookmarks
        } else {
            .user
        }
    }
}

public struct AyahCollectionBookmark: Identifiable {
    // MARK: Lifecycle

    public init(id: String, collectionID: String, ayah: AyahNumber) {
        self.id = id
        self.collectionID = collectionID
        self.ayah = ayah
    }

    // MARK: Public

    public let id: String
    public let collectionID: String
    public let ayah: AyahNumber
}

public enum AyahBookmarkCollectionKind: Equatable {
    case defaultBookmarks
    case oldPageBookmarks
    case user
}
#endif

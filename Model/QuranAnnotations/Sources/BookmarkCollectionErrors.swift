#if QURAN_SYNC
//
//  BookmarkCollectionErrors.swift
//
//  Created by Mohamed Afifi on 2026-10-14.
//

/// Renaming or deleting a collection users can't change: Favorites, and the color collections older
/// Quran.com apps created, which the server protects.
public struct ReadOnlyCollectionError: Error, Equatable, Sendable {
    // MARK: Lifecycle

    public init(collectionID: String) {
        self.collectionID = collectionID
    }

    // MARK: Public

    public let collectionID: String
}

/// Renaming a collection to a name another collection has. Names compare trimmed and case-insensitively.
public struct DuplicateCollectionNameError: Error, Equatable, Sendable {
    // MARK: Lifecycle

    public init(name: String) {
        self.name = name
    }

    // MARK: Public

    /// The existing collection's name, which can differ from the typed name in case or surrounding spaces.
    public let name: String
}

/// Creating or renaming a collection with a name users can't give one: Favorites, and the server's reserved
/// `system:` names.
public struct ReservedCollectionNameError: Error, Equatable, Sendable {
    // MARK: Lifecycle

    public init(name: String) {
        self.name = name
    }

    // MARK: Public

    public let name: String
}
#endif

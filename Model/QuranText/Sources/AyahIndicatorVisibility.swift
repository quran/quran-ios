#if QURAN_SYNC
//
//  AyahIndicatorVisibility.swift
//

/// Which indicators the reader shows next to ayah numbers.
public enum AyahIndicatorVisibility: String, CaseIterable, Sendable {
    case all
    case readingBookmark
    case none

    // MARK: Public

    public var showsReadingBookmarks: Bool {
        self != .none
    }

    public var showsNotesAndCollections: Bool {
        self == .all
    }
}

#endif

#if QURAN_SYNC
//
//  AyahIndicators.swift
//

/// Which annotations the reader shows next to ayah numbers.
public enum AyahIndicators: String, CaseIterable, Sendable {
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
